// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

/// @title IWeRaStakingFacet
interface IWeRaStakingFacet {
    // ========= ERRORS ========= //

    /// @notice Thrown when initialize the contract a second time
    error AlreadyInitialized();

    /// @notice Thrown when trying to stake a token that is not allowed
    error BadStakeToken();

    /// @notice Thrown when stake zero tokens
    error ZeroStake();

    /// @notice Thrown when unstake zero tokens
    error ZeroUnstake();

    /// @notice Thrown when unstake more tokens than have staked
    error UnstakeExceedsBalance();

    // ========= STRUCTS ========= //

    struct StakeBalance {
        mapping (address => uint256) balances;
        uint256 totalBalance;
    }

    // ========= EVENTS ========= //

    event StakeAdded(
        address indexed token,
        address indexed supplier,
        address indexed receiver,
        uint256 value
    );

    event StakeRemoved(
        address indexed token,
        address indexed staker,
        address indexed receiver,
        uint256 value
    );

    // ========= ROLE ========= //

    function STAKE_TOKENS_MANAGER() external view returns (bytes32);

    // ========= FUNCTIONS ========= //


    function initialize(address tokenManager_, address weRaToken_) external;

    function stakeFor(address token_, address receiver_, uint256 amount_) external;

    function stake(address token_, uint256 amount_) external;

    function unstake(address token_, address receiver_, uint256 amount_) external;

    function addStakeToken(address token_) external;


    function getTokenBalance(address token_, address staker_) external view returns (uint256);

    function getTokenTotalBalance(address token_) external view returns (uint256);

    function stakeTokensLength() external view returns (uint256);

    function stakeTokensAt(uint256 index_) external view returns (address);
}
