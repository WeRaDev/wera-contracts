//SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {MintableToken} from "./MintableToken.sol";

/// @title TokenFaucet
contract TokenFaucet is Ownable {
    using SafeERC20 for IERC20;

    /// Faucet settings for token.
    /// `claimAmount` amount of tokens possible to claim.
    /// `withholdPeriod` period time during which it will not be possible to make another claim.
    struct ClaimSettings {
        uint256 claimAmount;
        uint256 withholdPeriod;
    }

    /// Information needed to create new token.
    /// `name` name of created ERC20 token.
    /// `symbol` symbol of created ERC20 token.
    /// `decimals` decimal number of created token.
    /// `claimSettings` defines the token claim behavior.
    struct TokenDefinition {
        string name;
        string symbol;
        uint8 decimals;
        ClaimSettings claimSettings;
    }

    // ========= STORAGE ========= //

    TokenDefinition public tokenDefinition;

    /// Tokens deployed and controlled by this contract.
    address public faucetToken;

    /// Store information about last accounts claims.
    /// @dev accountAddress => claimTimestamp
    mapping(address => uint256) public lastAccountsClaims;

    // ========= EVENTS ========= //

    event TokenAdded(address indexed tokenAddress, uint256 claimAmount, uint256 withholdPeriod);
    event Claim(address indexed account, uint256 claimAmount);
    event ClaimSettingsUpdated(uint256 claimAmount, uint256 withholdPeriod);

    //============================================================================================//
    //                                       CONSTRUCTOR                                          //
    //============================================================================================//

    /// @notice Initializes the contract.
    /// @dev Deploys ERC20 Tokens for given definitions and allow to claim it.
    constructor(TokenDefinition memory initToken_) Ownable(msg.sender) {
        _deployFaucetToken(initToken_);
    }

    //============================================================================================//
    //                                        EXTERNAL                                            //
    //============================================================================================//

    function claim() external {
        ClaimSettings memory settings = tokenDefinition.claimSettings;

        if (lastAccountsClaims[msg.sender] != 0) {
            // require account withholdPeriod to pass
            require(
                lastAccountsClaims[msg.sender] + settings.withholdPeriod < block.timestamp,
                "claim exhausted"
            );
        }

        // save timestamp
        lastAccountsClaims[msg.sender] = block.timestamp;

        // actual mint
        MintableToken(faucetToken).mint(msg.sender, settings.claimAmount);

        emit Claim(msg.sender, settings.claimAmount);
    }

    // ========= OWNER ========= //

    /// @notice Allows the owner to change token claim settings.
    function updateClaimSettings(ClaimSettings memory claimSettings_) external onlyOwner {
        tokenDefinition.claimSettings = claimSettings_;

        emit ClaimSettingsUpdated(
            claimSettings_.claimAmount,
            claimSettings_.withholdPeriod
        );
    }

    // ========= VIEW ========= //

    /// @notice Allows to check if given account can claim faucet token.
    function isClaimable(address account_) external view returns (bool) {
        uint256 lastClaim = lastAccountsClaims[account_];

        // account have never made a claim yet
        if (lastClaim == 0) {
            return true;
        }

        // check if withholdPeriod has passed
        return (lastClaim + tokenDefinition.claimSettings.withholdPeriod) < block.timestamp;
    }

    //============================================================================================//
    //                                        INTERNAL                                            //
    //============================================================================================//

    /// @dev Deploys Faucet ERC20 Token.
    function _deployFaucetToken(TokenDefinition memory tokenDefinition_) internal {
        tokenDefinition = tokenDefinition_;

        MintableToken token = new MintableToken(
            tokenDefinition_.name,
            tokenDefinition_.symbol,
            tokenDefinition_.decimals
        );

        faucetToken = address(token);

        emit TokenAdded(
            address(token),
            tokenDefinition_.claimSettings.claimAmount,
            tokenDefinition_.claimSettings.withholdPeriod
        );
    }
}
