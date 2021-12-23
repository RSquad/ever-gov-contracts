pragma ton-solidity >= 0.53.0;

library Errors {
    uint16 constant INVALID_CALLER = 100;
    uint16 constant INVALID_VALUE = 101;
    uint16 constant INVALID_ARGUMENTS = 102;
    uint16 constant CONTRACT_INITED = 103;

/* -------------------------------------------------------------------------- */
/*                                 200 CrystalVotingWallet                                */
/* -------------------------------------------------------------------------- */

    uint16 constant VOTING_WALLET_NOT_ENOUGH_VOTES = 200;
    uint16 constant VOTING_WALLET_INVALID_RETURN_ADDRESS = 201;

/* -------------------------------------------------------------------------- */
/*                                 300 Proposal                               */
/* -------------------------------------------------------------------------- */

    uint16 constant PROPOSAL_VOTING_NOT_STARTED = 300;
    uint16 constant PROPOSAL_VOTING_HAS_ENDED = 301;
}
