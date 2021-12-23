pragma ton-solidity >= 0.53.0;
pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/ISmvRootStore.sol';

import './Errors.sol';

contract SmvRootStore is ISmvRootStore {
    mapping(uint8 => TvmCell) public _codes;

    function setVotingWalletCode(TvmCell code) public override {
        require(msg.pubkey() == tvm.pubkey(), Errors.INVALID_CALLER);
        tvm.accept();
        _codes[uint8(ContractCode.VotingWallet)] = code;
    }
    function setProposalCode(TvmCell code) public override {
        require(msg.pubkey() == tvm.pubkey(), Errors.INVALID_CALLER);
        tvm.accept();
        _codes[uint8(ContractCode.Proposal)] = code;
    }
    function setCommentCode(TvmCell code) public override {
        require(msg.pubkey() == tvm.pubkey(), Errors.INVALID_CALLER);
        tvm.accept();
        _codes[uint8(ContractCode.Comment)] = code;
    }
    function queryCode(ContractCode kind) public override {
        TvmCell code = _codes[uint8(kind)];
        ISmvRootStoreCb(msg.sender).updateCode
            {value: 0, flag: 64, bounce: false}
            (kind, code);
    }
}
