pragma ton-solidity >= 0.53.0;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IProposal.sol";
import "./interfaces/IVotingWallet.sol";

import "./interfaces/IRootTokenContract.sol";
import "./interfaces/ITONTokenWallet.sol";
import "./interfaces/IExpectedWalletAddressCallback.sol";
import "./interfaces/ITokensReceivedCallback.sol";


import "./Errors.sol";
import "./Fees.sol";

contract VotingWallet is IVotingWallet, ITokensReceivedCallback {
    address public _addrRoot;
    address public _addrTokenRoot;
    address public _addrTokenWallet;
    address static public _addrOwner;

    mapping(address => uint128) public _proposals;
    uint128 public _proposalsCount;

    uint128 public _requestedVotes;
    uint128 public _totalVotes;
    uint128 public _lockedVotes;

    address _returnTo;

    constructor(address addrTokenRoot) public {
        optional(TvmCell) oSalt = tvm.codeSalt(tvm.code());
        require(oSalt.hasValue(), Errors.INVALID_ARGUMENTS);
        (address addrRoot) = oSalt.get().toSlice().decode(address);
        require(msg.sender == addrRoot, Errors.INVALID_CALLER);
        _addrRoot = addrRoot;
        _addrTokenRoot = addrTokenRoot;

        IRootTokenContract(addrTokenRoot).deployEmptyWallet
            {value: Fees.DEPLOY_MIN, flag: 3, bounce: false}
            (Fees.PROCESS_SM, uint256(0), address(this), _addrOwner);

        IRootTokenContract(addrTokenRoot).getWalletAddress{
            value: Fees.PROCESS_SM,
            flag: 3,
            callback: notifyWalletDeployed
        }(0, address(this));
    }

    function notifyWalletDeployed(address wallet) public {
        _addrTokenWallet = wallet;

        ITONTokenWallet(_addrTokenWallet).setReceiveCallback
            {value: Fees.PROCESS_SM, flag: 3, bounce: true}
            (address(this), true);
    }

/* -------------------------------------------------------------------------- */
/*                                ANCHOR Voting                               */
/* -------------------------------------------------------------------------- */

    function vote(
        address addrProposal,
        bool choice,
        uint128 votes
    ) override external {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= 1 ton, Errors.INVALID_VALUE);

        optional(uint128) oProposal = _proposals.fetch(addrProposal);
        uint128 proposalVotes = oProposal.hasValue() ? oProposal.get() : 0;
        uint128 availableVotes = _totalVotes - proposalVotes;
        require(votes <= availableVotes, Errors.VOTING_WALLET_NOT_ENOUGH_VOTES);

        if(_proposals[addrProposal] == 0) {
            _proposalsCount += 1;
        }
        _proposals[addrProposal] += votes;

        IProposal(addrProposal).vote
            {value: 0, flag: 64, bounce: true}
            (_addrOwner, choice, votes);
    }

    function confirmVote(uint128 votes) override external {
        require(msg.sender != address(0), Errors.INVALID_CALLER);
        optional(uint128) oProposal = _proposals.fetch(msg.sender);
        require(oProposal.hasValue(), Errors.INVALID_CALLER);

        _updateLockedVotes();

        _addrOwner.transfer(0, false, 64);
    }

    function rejectVote(uint128 votes) override external {
        require(msg.sender != address(0), Errors.INVALID_CALLER);
        optional(uint128) oProposal = _proposals.fetch(msg.sender);
        require(oProposal.hasValue(), Errors.INVALID_CALLER);

        uint128 proposalVotes = oProposal.get() - votes;

        if (proposalVotes == 0) {
            _proposalsCount -= 1;
            delete _proposals[msg.sender];
        } else {
            _proposals[msg.sender] -= votes;
        }

        _addrOwner.transfer(0, false, 64);
    }

/* -------------------------------------------------------------------------- */
/*                               ANCHOR Deposits                              */
/* -------------------------------------------------------------------------- */

    function tokensReceivedCallback(
        address token_wallet,
        address token_root,
        uint128 amount,
        uint256 sender_public_key,
        address sender_address,
        address sender_wallet,
        address original_gas_to,
        uint128 updated_balance,
        TvmCell payload
    ) override public {
        require(msg.sender == _addrTokenWallet, Errors.INVALID_CALLER);

        _totalVotes += amount;
    }

/* -------------------------------------------------------------------------- */
/*                               ANCHOR Reclaim                               */
/* -------------------------------------------------------------------------- */

    function reclaim(uint128 votes, address returnTo) external {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= Fees.PROCESS * _proposalsCount + Fees.PROCESS_SM, Errors.INVALID_VALUE);
        require(returnTo != address(0), Errors.VOTING_WALLET_INVALID_RETURN_ADDRESS);

        _returnTo = returnTo;
        _requestedVotes = votes;

        if (_requestedVotes <= _totalVotes - _lockedVotes) {
            _transferRequestedVotes();
        }

        _queryProposalStatuses();
    }

    function updateLockedVotes() external {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= Fees.PROCESS * _proposalsCount + Fees.PROCESS_SM, Errors.INVALID_VALUE);
        _queryProposalStatuses();
    }

    function queryStatusCb(ProposalState state) external override {
        require(msg.sender != address(0), Errors.INVALID_CALLER);
        optional(uint128) oProposal = _proposals.fetch(msg.sender);
        require(oProposal.hasValue(), Errors.INVALID_CALLER);

        if (state >= ProposalState.Ended) {
            if(_proposals[msg.sender] == _lockedVotes)
            delete _proposals[msg.sender];
            _updateLockedVotes();
        }

        if (_requestedVotes != 0 && _requestedVotes <= _totalVotes - _lockedVotes) {
            _transferRequestedVotes();
        }
    }

    function _transferRequestedVotes() private inline {

        TvmCell empty;
        ITONTokenWallet(_addrTokenWallet).transfer
            {value: 0, flag: 64, bounce: false}
            (_returnTo, _requestedVotes, Fees.PROCESS_SM, _addrOwner, false, empty);

        _totalVotes -= _requestedVotes;
        _requestedVotes = 0;
        _returnTo = address(0);
    }

    function _queryProposalStatuses() private inline {
        optional(address, uint128) oProposal = _proposals.min();
        while (oProposal.hasValue()) {
            (address addr,) = oProposal.get();
            IProposal(addr).queryStatus
                {value: Fees.PROCESS, bounce: false, flag: 1}
                ();
            oProposal = _proposals.next(addr);
        }
    }

    function _updateLockedVotes() private inline {
        optional(address, uint128) oProposal = _proposals.min();
        uint128 lockedVotes;
        while (oProposal.hasValue()) {
            (address addr, uint128 votes) = oProposal.get();
            if (votes > lockedVotes) {
                lockedVotes = votes;
            }
            oProposal = _proposals.next(addr);
        }
        _lockedVotes = lockedVotes;
    }
}
