pragma ton-solidity >= 0.53.0;

library Fees {
    uint128 constant PROCESS_MIN = 0.1 ton;
    uint128 constant PROCESS_SM = 0.2 ton;
    uint128 constant PROCESS = 0.4 ton;

    uint128 constant DEPLOY_MIN = 1 ton;
    uint128 constant DEPLOY_SM = 2 ton;
    uint128 constant DEPLOY = 3 ton;
}
