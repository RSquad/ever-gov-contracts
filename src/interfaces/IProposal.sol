pragma ton-solidity >= 0.53.0;

struct ProposalResults {
    bool completed;
    bool passed;
    uint128 votesFor;
    uint128 votesAgainst;
    uint256 totalVotes;
    VoteCountModel model;
}

struct ProposalData {
    address addr;
    string title;
    string description;
    TvmCell payload;
    address client;
    ProposalState state;
    uint32 start;
    uint32 end;
    uint128 votesFor;
    uint128 votesAgainst;
    uint128 totalVotes;
    address[] addrsVotingWallet;
    uint32 commentsCounter;
}

enum VoteCountModel {
    Undefined,
    Majority,
    SoftMajority,
    SuperMajority,
    Other,
    Reserved,
    Last
}

enum ProposalState {
    Undefined,
    New,
    OnVoting,
    Ended,
    Passed,
    NotPassed,
    Finalized,
    Distributed,
    Reserved,
    Last
}


interface IProposal {

    function vote(
        address addrVotingWalletOwner,
        bool choice,
        uint128 votes
    ) external;

    function getExt() external view returns (ProposalData data);
    function queryStatus() external;
    function wrapUp() external;
}
