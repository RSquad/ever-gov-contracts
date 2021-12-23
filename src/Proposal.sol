pragma ton-solidity >= 0.53.0;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./resolvers/VotingWalletResolver.sol";
import "./resolvers/CommentResolver.sol";
import "./Checks.sol";

import "./interfaces/IClient.sol";
import "./interfaces/IProposal.sol";
import "./interfaces/IVotingWallet.sol";
import "./interfaces/ISmvRoot.sol";
import "./interfaces/ISmvRootStore.sol";

import "./Fees.sol";
import "./Errors.sol";

contract Proposal is CommentResolver, VotingWalletResolver, Checks, IProposal, ISmvRootStoreCb {

/* -------------------------------------------------------------------------- */
/*                                ANCHOR Checks                               */
/* -------------------------------------------------------------------------- */

    uint8 constant CHECK_VOTING_WALLET = 1;
    uint8 constant CHECK_COMMENT = 2;

    function _createChecks() private inline {
        _checkList =
            CHECK_VOTING_WALLET |
            CHECK_COMMENT;
    }

/* -------------------------------------------------------------------------- */
/*                                ANCHOR Init                                 */
/* -------------------------------------------------------------------------- */

    address public _addrRoot;
    address public _addrSmvStore;
    address public _addrChange;
    uint32 static public _id;

    ProposalData public _data;
    ProposalResults public _results;
    VoteCountModel public _voteCountModel;

    bool public _inited = false;

    uint32 public _commentsCounter = 0;

    constructor(
        address addrSmvStore,
        string title,
        string description,
        uint128 totalVotes,
        address addrClient,
        address addrChange,
        TvmCell payload
    ) public {
        optional(TvmCell) oSalt = tvm.codeSalt(tvm.code());
        require(oSalt.hasValue());
        (address addrRoot) = oSalt.get().toSlice().decode(address);
        require(msg.sender == addrRoot, Errors.INVALID_CALLER);

        _addrRoot = addrRoot;
        _addrSmvStore = addrSmvStore;
        _addrChange = addrChange;

        _data.addr = address(this);
        _data.title = title;
        _data.description = description;
        _data.payload = payload;
        _data.client = addrClient;
        _data.start = uint32(now);
        _data.end = uint32(now + 60 * 60 * 24 * 7);
        _data.state = ProposalState.New;
        _data.totalVotes = totalVotes;

        _voteCountModel = VoteCountModel.SoftMajority;


        ISmvRootStore(_addrSmvStore).queryCode
            {value: Fees.PROCESS_SM, bounce: true}
            (ContractCode.VotingWallet);

        ISmvRootStore(_addrSmvStore).queryCode
            {value: Fees.PROCESS_SM, bounce: true}
            (ContractCode.Comment);

        IClient(_data.client).onProposalDeployed
            {value: Fees.PROCESS_MIN}
            (_data);
    }


    function _onInit() private {
        if(_isCheckListEmpty() && !_inited) {
            _inited = true;
            if(_data.start <= uint32(now)) {
                _data.state = ProposalState.OnVoting;
            }
        }
    }

    function updateCode(
        ContractCode kind,
        TvmCell code
    ) external override {
        require(msg.sender == _addrSmvStore, Errors.INVALID_CALLER);
        if (kind == ContractCode.VotingWallet) {
            _codeVotingWallet = code;
            _passCheck(CHECK_VOTING_WALLET);
        } else if (kind == ContractCode.Comment) {
            _codeComment = code;
            _passCheck(CHECK_COMMENT);
        }
        _addrChange.transfer(0, false, 64);
        _onInit();
    }

    function wrapUp() external override {
        _wrapUp();
        msg.sender.transfer(0, false, 64);
    }

    function vote(
        address addrVotingWalletOwner,
        bool choice,
        uint128 votes
    ) external override {
        require(msg.value >= Fees.PROCESS, Errors.INVALID_VALUE);

        address addrVotingWallet = resolveVotingWallet(_addrRoot, addrVotingWalletOwner);

        uint16 errorCode = 0;
        bool exists;
        if(_data.addrsVotingWallet.length != 0 ) {
            for(uint8 i = 0; i < _data.addrsVotingWallet.length; i++) {
                if(_data.addrsVotingWallet[i] == addrVotingWallet) {
                    exists = true;
                }
            }
        } else {
            exists = true;
        }

        if(exists) {
            if (addrVotingWallet != msg.sender) {
            errorCode = Errors.INVALID_CALLER;
            } else if (now < _data.start) {
                errorCode = Errors.PROPOSAL_VOTING_NOT_STARTED;
            } else if (now > _data.end) {
                errorCode = Errors.PROPOSAL_VOTING_HAS_ENDED;
            }

            if (errorCode > 0) {
                IVotingWallet(msg.sender).rejectVote{value: Fees.PROCESS_MIN, flag: 3, bounce: true}(votes);
            } else {
                IVotingWallet(msg.sender).confirmVote{value: Fees.PROCESS_MIN, flag: 3, bounce: true}(votes);
                if (choice) {
                    _data.votesFor += votes;
                } else {
                    _data.votesAgainst += votes;
                }
            }
            _wrapUp();
        }
        msg.sender.transfer(0, false, 64);
    }

    function _finalize(bool passed) private {
        _results = ProposalResults(
            true,
            passed,
            _data.votesFor,
            _data.votesAgainst,
            _data.totalVotes,
            _voteCountModel
        );

        ProposalState state = passed ? ProposalState.Passed : ProposalState.NotPassed;

        _changeState(state);

        if(passed) {
            ISmvRoot(_addrRoot).onProposalPassed
                {value: Fees.PROCESS}
                (_id, _data.client, _data.payload);
        } else {
            ISmvRoot(_addrRoot).onProposalNotPassed
                {value: Fees.PROCESS}
                (_id, _data.client, _data.payload);
        }
    }

    function _tryEarlyComplete(
        uint128 yes,
        uint128 no
    ) private view returns (bool, bool) {
        (bool completed, bool passed) = (false, false);
        if (yes * 2 > _data.totalVotes) {
            completed = true;
            passed = true;
        } else if(no * 2 >= _data.totalVotes) {
            completed = true;
            passed = false;
        }
        return (completed, passed);
    }

    function _wrapUp() private {
        (bool completed, bool passed) = (false, false);

        if (now > _data.end) {
            completed = true;
            passed = _calculateVotes(_data.votesFor, _data.votesAgainst);
        } else {
            (completed, passed) = _tryEarlyComplete(_data.votesFor, _data.votesAgainst);
        }

        if (completed) {
            _changeState(ProposalState.Ended);
            _finalize(passed);
        }
    }

    function _calculateVotes(
        uint128 yes,
        uint128 no
    ) private view returns (bool) {
        bool passed = false;
        passed = _softMajority(yes, no);
        return passed;
    }

    function _softMajority(
        uint128 yes,
        uint128 no
    ) private view returns (bool) {
        bool passed = false;
        passed = yes >= 1 + (_data.totalVotes / 10) + (no * ((_data.totalVotes / 2) - (_data.totalVotes / 10))) / (_data.totalVotes / 2);
        return passed;
    }

    function _changeState(ProposalState state) private inline {
        _data.state = state;
    }

    function queryStatus() external override {
        IVotingWallet(msg.sender).queryStatusCb{value: 0, flag: 64, bounce: true}(_data.state);
    }

    function getExt() public view override returns (ProposalData data) {
        data = _data;
    }

    function addComment(address addrReply, string content) external {
        require(msg.value >= Fees.PROCESS_SM, Errors.INVALID_VALUE);
        require(msg.sender != address(0), Errors.INVALID_CALLER);

        TvmCell state = _buildCommentState(address(this), _commentsCounter);
        new Comment
            {stateInit: state, value: Fees.PROCESS_MIN}
            (msg.sender, addrReply, content);

        _commentsCounter++;
        _data.commentsCounter = _commentsCounter;
    }
}
