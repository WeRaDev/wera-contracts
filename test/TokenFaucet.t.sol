// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {TokenFaucet} from "../src/test/TokenFaucet.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TokenFaucetTest is Test {
    TokenFaucet public faucet;
    address public token;

    TokenFaucet.ClaimSettings public claimSettings = TokenFaucet.ClaimSettings({
        claimAmount: 100 * 1e18,
        withholdPeriod: 3600
    });

    TokenFaucet.TokenDefinition public tokenDefinition = TokenFaucet.TokenDefinition({
        name: "TestToken",
        symbol: "TT",
        decimals: 18,
        claimSettings: claimSettings
    });

    function setUp() public {
        vm.startPrank(msg.sender);
        faucet = new TokenFaucet(tokenDefinition);
        token = faucet.faucetToken();
    }

    function test_Claim() public {
        assertEq(IERC20(token).balanceOf(msg.sender), 0);
        faucet.claim();

        assertEq(Ownable(token).owner(), address(faucet));

        assertEq(IERC20(token).balanceOf(msg.sender), claimSettings.claimAmount);
        assertEq(IERC20(token).totalSupply(), claimSettings.claimAmount);
        assertGt(faucet.lastAccountsClaims(msg.sender), 0);
    }

    function testRevert_ExchausedClaim() public {
        assertTrue(faucet.isClaimable(msg.sender));
        faucet.claim();

        assertTrue(!faucet.isClaimable(msg.sender));
        vm.expectRevert("claim exhausted");
        faucet.claim();
    }
}
