// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IWeRaStakingFacet} from "../interfaces/IWeRaStakingFacet.sol";
import {IWeP} from "../../tokens/IWeP.sol";
import {LibWeRaStaking as Storage} from "../libraries/LibWeRaStaking.sol";

/// @title WeRaStakingFacet
contract WeRaStakingFacet is IWeRaStakingFacet, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // TODO add modifier to check if token is in stakeTokens

    bytes32 public constant STAKE_TOKENS_MANAGER = keccak256("STAKE_TOKENS_MANAGER");

    //============================================================================================//
    //                                       MODIFIERS                                            //
    //============================================================================================//

    /**
     * @dev Prevents second initialization
     */
    modifier notInitialized() {
        Storage.WeRaStakingStorage storage s = Storage.getStorage();

        if (s.initialized) revert AlreadyInitialized();
        s.initialized = true;
        _;
    }

    //============================================================================================//
    //                                      CONSTRUCTOR                                           //
    //============================================================================================//

    /// @dev Contrcutor can not be used in proxy contracts
    function initialize(
        address weRaToken_,
        address tokenManager_
    ) external notInitialized {
        _grantRole(STAKE_TOKENS_MANAGER, tokenManager_);

        Storage.getStorage().weRaToken = weRaToken_;
    }

    //============================================================================================//
    //                                        EXTERNAL                                            //
    //============================================================================================//

    function stakeFor(address token_, address receiver_, uint256 amount_)
        external
        nonReentrant
    {
        _stake(token_, msg.sender, receiver_, amount_);
    }

    function stake(address token_, uint256 amount_)
        external
        nonReentrant
    {
        _stake(token_, msg.sender, msg.sender, amount_);
    }

    function unstake(address token_, address receiver_, uint256 amount_)
        external
        nonReentrant
    {
        _unstake(token_, msg.sender, receiver_, amount_);
    }

    // ========= RESTRICTED ========= //

    function addStakeToken(address token_) external onlyRole(STAKE_TOKENS_MANAGER) {
        Storage.getStorage().stakeTokens.add(token_);
    }

    // Different strategy must be used to remove tokens, simple remove stakeToken is too risky,
    // as it can lead to loss the ability for users to unstake their tokens
    // function removeStakeToken(address token_) external onlyRole(STAKE_TOKENS_MANAGER) {
    //     Storage.getStorage().stakeTokens.add(token_);
    // }

    // ========= VIEW ========= //

    function getTokenBalance(address token_, address staker_) external view returns (uint256) {
        return Storage.getStorage().stakeBalances[token_].balances[staker_];
    }

    function getTokenTotalBalance(address token_) external view returns (uint256) {
        return Storage.getStorage().stakeBalances[token_].totalBalance;
    }

    function stakeTokensLength() external view returns (uint256) {
        return Storage.getStorage().stakeTokens.length();
    }

    function stakeTokensAt(uint256 index_) external view returns (address) {
        return Storage.getStorage().stakeTokens.at(index_);
    }

    //============================================================================================//
    //                                        INTERNAL                                            //
    //============================================================================================//

    function _stake(
        address token_,
        address supplier_,
        address receiver_,
        uint256 amount_
    ) internal {
        if (amount_ == 0) revert ZeroStake();

        Storage.WeRaStakingStorage storage s = Storage.getStorage();

        s.stakeBalances[token_].balances[receiver_] += amount_;
        s.stakeBalances[token_].totalBalance += amount_;

        IERC20(token_).safeTransferFrom(supplier_, address(this), amount_);
        IWeP(s.weRaToken).mint(receiver_, amount_); // mint 1:1

        emit StakeAdded(token_, supplier_, receiver_, amount_);
    }

    function _unstake(
        address token_,
        address staker_,
        address receiver_,
        uint256 amount_
    ) internal {
        if (amount_ == 0) revert ZeroUnstake();

        Storage.WeRaStakingStorage storage s = Storage.getStorage();

        if (amount_ > s.stakeBalances[token_].balances[staker_]) revert UnstakeExceedsBalance();
        s.stakeBalances[token_].balances[staker_] -= amount_;
        s.stakeBalances[token_].totalBalance -= amount_;

        IERC20(token_).safeTransfer(receiver_, amount_);
        ERC20BurnableUpgradeable(s.weRaToken).burnFrom(staker_, amount_); // burn 1:1, require spend allowance

        emit StakeRemoved(token_, staker_, receiver_, amount_);
    }
}
