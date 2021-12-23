pragma ton-solidity >= 0.36.0;
pragma AbiHeader expire;
pragma AbiHeader time;

import '../VotingWallet.sol';

contract VotingWalletResolver {
    TvmCell _codeVotingWallet;

    function resolveVotingWallet(
        address addrRoot,
        address addrOwner
    ) public view returns (address addrVotingWallet) {
        TvmCell state = _buildVotingWalletState(addrRoot, addrOwner);
        uint256 hashState = tvm.hash(state);
        addrVotingWallet = address.makeAddrStd(0, hashState);
    }

    function _buildVotingWalletState(
        address addrRoot,
        address addrOwner
    ) internal view inline returns (TvmCell) {
        return tvm.buildStateInit({
            contr: VotingWallet,
            varInit: {_addrOwner: addrOwner},
            code: _buildVotingWalletCode(addrRoot)
        });
    }

    function _buildVotingWalletCode(
        address addrRoot
    ) internal view inline returns (TvmCell) {
        TvmBuilder salt;
        salt.store(addrRoot);
        return tvm.setCodeSalt(_codeVotingWallet, salt.toCell());
    }
}
