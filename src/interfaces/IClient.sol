pragma ton-solidity >= 0.53.0;

import './IProposal.sol';

interface IClient {
    function onProposalNotPassed(address addrProposal, TvmCell payload) external;
    function onProposalPassed(address addrProposal, TvmCell payload) external;
    function onProposalDeployed(ProposalData data) external;
}
