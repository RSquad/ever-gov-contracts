pragma ton-solidity >= 0.53.0;


import './IProposal.sol';


struct PendingProposal {
    address addrClient;
    address addrChange;
    string title;
    string description;
    TvmCell payload;
}

interface ISmvRoot {
    function deployVotingWallet(
        address addrOwner
    ) external;
    function deployProposal(
        address addrClient,
        string title,
        string description,
        TvmCell payload
    ) external;


    function onProposalNotPassed(
        uint32 id,
        address addrClient,
        TvmCell payload
    ) external;
    function onProposalPassed(
        uint32 id,
        address addrClient,
        TvmCell payload
    ) external;
}
