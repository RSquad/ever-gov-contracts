pragma ton-solidity >= 0.42.0;

enum ContractCode {
    VotingWallet,
    Proposal,
    Comment
}

interface ISmvRootStore {
    function setVotingWalletCode(TvmCell code) external;
    function setProposalCode(TvmCell code) external;
    function setCommentCode(TvmCell code) external;

    function queryCode(ContractCode kind) external;
}

interface ISmvRootStoreCb {
    function updateCode(ContractCode kind, TvmCell code) external;
}
