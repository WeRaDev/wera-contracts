// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import "forge-std/Test.sol";
import {Diamond} from "../src/diamond/Diamond.sol";
import {DiamondCutFacet} from "../src/diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/diamond/facets/DiamondLoupeFacet.sol";

import {WeRaStakingFacet} from "../src/staking/facets/WeRaStakingFacet.sol";
import {IWeRaStakingFacet} from "../src/staking/interfaces/IWeRaStakingFacet.sol";
import {WeP} from "../src/token/WeP.sol";
import {TokenMock} from "../src/test/TokenMock.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract TokenFaucetTest is Test {
    Diamond public diamond;
    IWeRaStakingFacet public staking;

    WeP public wep;
    TokenMock public testUSD;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.startPrank(alice);

        address wepAdmin = alice;
        address diamondOwner = alice;
        address stakingTokenManager = alice;


        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        WeRaStakingFacet weRaStakingFacet = new WeRaStakingFacet();

        diamond = new Diamond(
            diamondOwner,
            address(diamondCutFacet),
            address(diamondLoupeFacet),
            address(weRaStakingFacet)
        );

        staking = IWeRaStakingFacet(address(diamond));

        address wepMinter = address(staking);
        wep = new WeP(wepAdmin, wepMinter);
        staking.initialize(stakingTokenManager, address(wep));

        testUSD = new TokenMock("Test USD", "TUSD", 1000e18, 18);
        staking.addStakeToken(address(testUSD));

        testUSD.mint(bob, 100e18);
    }

    function testRevert_AlreadyInitialized() public {
        vm.expectRevert(IWeRaStakingFacet.AlreadyInitialized.selector);
        staking.initialize(alice, address(wep));
    }

    function testRevert_BadStakeToken() public {
        vm.expectRevert(IWeRaStakingFacet.BadStakeToken.selector);
        staking.stakeFor(address(wep), alice, 100);
    }

    function testRevert_ZeroStake() public {
        vm.expectRevert(IWeRaStakingFacet.ZeroStake.selector);
        staking.stakeFor(address(testUSD), alice, 0);
    }

    function testRevert_ZeroUnstake() public {
        vm.expectRevert(IWeRaStakingFacet.ZeroUnstake.selector);
        staking.unstake(address(testUSD), alice, 0);
    }

    function testRevert_ExceedsBalance() public {
        vm.expectRevert(IWeRaStakingFacet.UnstakeExceedsBalance.selector);
        staking.unstake(address(testUSD), alice, 10);
    }

    function testStake() public {
        vm.startPrank(bob);

        assertEq(staking.getTokenBalance(address(testUSD), bob), 0);
        assertEq(staking.getTokenTotalBalance(address(testUSD)), 0);

        testUSD.approve(address(staking), 1e18);
        staking.stake(address(testUSD), 1e18);

        assertEq(staking.getTokenBalance(address(testUSD), bob), 1e18);

        assertEq(staking.getTokenBalance(address(testUSD), bob), 1e18);
        assertEq(staking.getTokenTotalBalance(address(testUSD)), 1e18);

        testUSD.approve(address(staking), 5e18);
        staking.stakeFor(address(testUSD), alice, 5e18);

        assertEq(staking.getTokenBalance(address(testUSD), alice), 5e18);
        assertEq(staking.getTokenTotalBalance(address(testUSD)), 6e18);
    }

    function testUnstake() public {
        vm.startPrank(alice);

        testUSD.approve(address(staking), 5e18);
        staking.stake(address(testUSD), 5e18);

        wep.approve(address(staking), 2e18);
        staking.unstake(address(testUSD), bob, 2e18);

        assertEq(staking.getTokenBalance(address(testUSD), alice), 3e18);
        assertEq(staking.getTokenBalance(address(testUSD), bob), 0);
        assertEq(testUSD.balanceOf(bob), 102e18);
    }

    function testStakeTokens() public {
        vm.startPrank(alice);

        assertEq(staking.stakeTokensLength(), 1);
        assertEq(staking.stakeTokensAt(0), address(testUSD));

        TokenMock testUSD2 = new TokenMock("Test USD 2", "TUSD2", 1000e18, 18);

        staking.addStakeToken(address(testUSD2));

        assertEq(staking.stakeTokensLength(), 2);
        assertEq(staking.stakeTokensAt(0), address(testUSD));
        assertEq(staking.stakeTokensAt(1), address(testUSD2));
    }

    function testGrantRole() public {
        vm.startPrank(alice);

        IAccessControl ac = IAccessControl(address(staking));
        assertTrue(ac.hasRole(staking.STAKE_TOKENS_MANAGER(), alice));

        bytes32 DEFAULT_ADMIN_ROLE = 0x00;
        assertTrue(ac.hasRole(DEFAULT_ADMIN_ROLE, alice));
        assertTrue(!ac.hasRole(DEFAULT_ADMIN_ROLE, bob));
        assertTrue(!ac.hasRole(staking.STAKE_TOKENS_MANAGER(), bob));

        ac.grantRole(staking.STAKE_TOKENS_MANAGER(), bob);
        assertTrue(ac.hasRole(DEFAULT_ADMIN_ROLE, alice));
        assertTrue(!ac.hasRole(DEFAULT_ADMIN_ROLE, bob));
        assertTrue(ac.hasRole(staking.STAKE_TOKENS_MANAGER(), bob));

        vm.startPrank(bob);
        TokenMock testUSD2 = new TokenMock("Test USD 2", "TUSD2", 1000e18, 18);
        staking.addStakeToken(address(testUSD2));

        assertEq(staking.stakeTokensAt(1), address(testUSD2));
    }
}
