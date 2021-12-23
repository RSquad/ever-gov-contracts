pragma ton-solidity >= 0.42.0;

import '../Proposal.sol';
import '../interfaces/IProposalResolver.sol';

contract ProposalResolver is IProposalResolver {
    TvmCell _codeProposal;

    function resolveCodeHashProposal(address addrRoot) override public returns (uint256 codeHashProposal) {
        codeHashProposal = tvm.hash(_buildProposalCode(addrRoot));
    }

    function resolveProposal(address addrRoot, uint32 id) override public returns (address addrProposal) {
        TvmCell state = _buildProposalState(addrRoot, id);
        uint256 hashState = tvm.hash(state);
        addrProposal = address.makeAddrStd(0, hashState);
    }

    function _buildProposalState(address addrRoot, uint32 id) internal view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Proposal,
            varInit: {_id: id},
            code: _buildProposalCode(addrRoot)
        });
    }

    function _buildProposalCode(
        address addrRoot
    ) internal view inline returns (TvmCell) {
        TvmBuilder salt;
        salt.store(addrRoot);
        return tvm.setCodeSalt(_codeProposal, salt.toCell());
    }
}
