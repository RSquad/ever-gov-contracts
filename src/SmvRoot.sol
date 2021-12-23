pragma ton-solidity >= 0.53.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import "./Proposal.sol";
import "./SmvRootStore.sol";

import "./interfaces/IProposal.sol";
import "./interfaces/ISmvRoot.sol";
import "./interfaces/ISmvRootStore.sol";
import "./interfaces/IRootTokenContract.sol";

import "./resolvers/VotingWalletResolver.sol";
import "./resolvers/ProposalResolver.sol";

import './Checks.sol';
import "./Errors.sol";
import "./Fees.sol";


contract SmvRoot is
    ISmvRoot,
    VotingWalletResolver,
    ProposalResolver,
    ISmvRootStoreCb,
    Checks {

    uint8 constant CHECK_PROPOSAL = 1;
    uint8 constant CHECK_VOTING_WALLET = 2;

    function _createChecks() private inline {
        _checkList =
            CHECK_PROPOSAL |
            CHECK_VOTING_WALLET;
    }

    uint16 public _version = 4;

    uint32 public _deployedVotingWalletsCounter = 0;
    uint32 public _deployedProposalsCounter = 0;

    address public _addrSmvStore;
    address public _addrTokenRoot;

    string public _title;

    bool public _inited = false;

    uint8 _pendingCallbackCounter;
    mapping(uint32 => PendingProposal) public _pendingProposals;

    constructor(address addrSmvStore, address addrTokenRoot, string title) public {
        if (msg.sender == address(0)) {
            require(msg.pubkey() == tvm.pubkey(), 101);
            tvm.accept();
        }

        require(addrSmvStore != address(0));

        _addrTokenRoot = addrTokenRoot;
        _addrSmvStore = addrSmvStore;
        _title = title;

        SmvRootStore(_addrSmvStore).queryCode
            {value: 0.2 ton, bounce: true}
            (ContractCode.Proposal);

        SmvRootStore(_addrSmvStore).queryCode
            {value: 0.2 ton, bounce: true}
            (ContractCode.VotingWallet);

        _createChecks();
    }

    function _onInit() private {
        if(_isCheckListEmpty() && !_inited) {
            _inited = true;
        }
    }

    function updateCode(
        ContractCode kind,
        TvmCell code
    ) external override {
        require(msg.sender == _addrSmvStore, Errors.INVALID_CALLER);
        if (kind == ContractCode.Proposal) {
            _codeProposal = code;
            _passCheck(CHECK_PROPOSAL);
        } else if (kind == ContractCode.VotingWallet) {
            _codeVotingWallet = code;
            _passCheck(CHECK_VOTING_WALLET);
        }
        _onInit();
    }

    function deployVotingWallet(address addrOwner) external override {
        require(msg.value >= Fees.DEPLOY_SM + Fees.PROCESS_SM, Errors.INVALID_VALUE);
        require(msg.sender != address(0), Errors.INVALID_CALLER);
        require(addrOwner != address(0), Errors.INVALID_ARGUMENTS);

        tvm.rawReserve(address(this).balance - msg.value, 2);

        TvmCell state = _buildVotingWalletState(address(this), addrOwner);
        new VotingWallet
            {stateInit: state, value: Fees.DEPLOY_SM}
            (_addrTokenRoot);
        _deployedVotingWalletsCounter += 1;

        msg.sender.transfer({ value: 0, flag: 128 });
    }

    function deployProposal(
        address addrClient,
        string title,
        string description,
        TvmCell payload
    ) external override {
        require(msg.value >= Fees.DEPLOY_MIN + Fees.PROCESS_SM, Errors.INVALID_VALUE);
        TvmBuilder builder;
        builder.store(payload);
        TvmCell cellpayload = builder.toCell();
        TvmCell emptyCell;

        _pendingProposals[_deployedProposalsCounter] = PendingProposal(
            addrClient,
            msg.sender,
            title,
            description,
            payload
        );

        IRootTokenContract(_addrTokenRoot).getTotalSupply
            {value: Fees.PROCESS_SM, callback: SmvRoot.getTotalGrantedCb}
            ();

        _deployedProposalsCounter++;
        _pendingCallbackCounter++;
    }

    function getTotalGrantedCb(uint128 total_supply) public {
        require(msg.sender == _addrTokenRoot, Errors.INVALID_CALLER);
        TvmCell emptyCell;

        _pendingCallbackCounter--;

        if(_pendingCallbackCounter == 0) {
            optional(uint32, PendingProposal) pendingProposal = _pendingProposals.min();
            while (pendingProposal.hasValue()) {
                (uint32 proposalId, PendingProposal proposal) = pendingProposal.get();

                new Proposal {
                    stateInit: _buildProposalState(address(this), proposalId),
                    value: Fees.DEPLOY_MIN + Fees.PROCESS_MIN
                }(
                    _addrSmvStore,
                    _pendingProposals[proposalId].title,
                    _pendingProposals[proposalId].description,
                    total_supply,
                    _pendingProposals[proposalId].addrClient,
                    _pendingProposals[proposalId].addrChange,
                    _pendingProposals[proposalId].payload
                );

                delete _pendingProposals[proposalId];

                pendingProposal = _pendingProposals.next(proposalId);
            }
        }
    }

    function onProposalPassed(
        uint32 id,
        address addrClient,
        TvmCell payload
    )
        override public
    {
        require(msg.sender == resolveProposal(address(this), id), Errors.INVALID_CALLER);
        IClient(addrClient).onProposalPassed
                {value: msg.value}
                (msg.sender, payload);
    }

    function onProposalNotPassed(
        uint32 id,
        address addrClient,
        TvmCell payload
    )
        override public
    {
        require(msg.sender == resolveProposal(address(this), id), Errors.INVALID_CALLER);
        IClient(addrClient).onProposalNotPassed
                {value: msg.value}
                (msg.sender, payload);
    }

/* -------------------------------------------------------------------------- */
/*                           ANCHOR External Getters                          */
/* -------------------------------------------------------------------------- */

    function getPublic() public returns (
        uint32 deployedVotingWalletsCounter,
        uint32 deployedProposalsCounter,
        uint16 version,
        address addrSmvStore,
        address addrTokenRoot,
        bool inited,
        string title
    ) {
        deployedVotingWalletsCounter = _deployedVotingWalletsCounter;
        deployedProposalsCounter = _deployedProposalsCounter;
        version = _version;
        addrSmvStore = _addrSmvStore;
        inited = _inited;
        addrTokenRoot = _addrTokenRoot;
        title = _title;
    }
}
