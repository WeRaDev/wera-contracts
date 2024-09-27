// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/token/NFTMinter.sol";

// Mock WETH contract for testing
contract MockWETH is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        require(_allowances[sender][msg.sender] >= amount, "Allowance exceeded");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount); // Emit the inherited Transfer event
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount); // Emit the inherited Transfer event
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount); // Emit the inherited Approval event
        return true;
    }

    function mint(address account, uint256 amount) external {
        _balances[account] += amount;

        emit Transfer(address(0), account, amount); // Emit Transfer event from zero address to account
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() external pure override returns (uint256) {
        return 0; // Mock implementation, not needed for this test
    }

    function decimals() external pure returns (uint8) {
        return 18; // Standard WETH has 18 decimals
    }

    // Remove the duplicate event declaration
    // event Transfer(address indexed from, address indexed to, uint256 value);
}

contract MyTokenTest is Test {
    MyToken public token;
    MockWETH public mockWETH;
    address public owner;
    address public admin;
    address public recipient;
    address public userInWhitelist;
    address public userNotInWhitelist;
    uint256 public nftPrice = 0.5 ether; // Price of NFT in WETH

    function setUp() public {
        owner = address(this); // This contract is not the owner in this context
        admin = address(1);

        recipient = address(4); // Recipient address for automatic fund transfer

        userInWhitelist = address(2); // User in whitelist
        userNotInWhitelist = address(3); // User not in whitelist

        // Deploy mock WETH contract
        mockWETH = new MockWETH();

        // Deploy MyToken contract with specified parameters
        token = new MyToken(owner, nftPrice, address(mockWETH), recipient,admin);

        // Simulate owner calling addToWhitelist
        vm.prank(owner);
        token.addToWhitelist(userInWhitelist);

        // Mock WETH contract mints tokens for the whitelisted user
        mockWETH.mint(userInWhitelist, 10 ether);
        mockWETH.mint(userNotInWhitelist, 10 ether);


        // Whitelisted user approves MyToken contract to spend their WETH
        vm.prank(userInWhitelist);
        mockWETH.approve(address(token), nftPrice);

        // Owner mints initial WETH balance
        mockWETH.mint(owner, 100 ether);
        mockWETH.approve(address(token), 100 ether);

        // owner mints initial WETH balance
        mockWETH.mint(owner, 100 ether);
        vm.prank(owner);
        mockWETH.approve(address(token), 100 ether);

    }

    // Test that only the owner can add to the whitelist
    function testOnlyOwnerCanAddToWhitelist() public {
        vm.prank(userNotInWhitelist);
        vm.expectRevert("Only the owner can perform this action");
        token.addToWhitelist(userNotInWhitelist);

        vm.prank(owner);
        token.addToWhitelist(userNotInWhitelist);

        token.addToWhitelist(userNotInWhitelist);
        assertTrue(token.whitelist(userNotInWhitelist));
    }

    // Test that only the owner can remove from the whitelist
    function testOnlyOwnerCanRemoveFromWhitelist() public {
        token.addToWhitelist(userInWhitelist);
        assertTrue(token.whitelist(userInWhitelist));

        vm.prank(userNotInWhitelist);
        vm.expectRevert("Only the owner can perform this action");
        token.removeFromWhitelist(userInWhitelist);

        vm.prank(owner);
        token.removeFromWhitelist(userInWhitelist);

        token.removeFromWhitelist(userInWhitelist);
        assertFalse(token.whitelist(userInWhitelist));
    }

    // Test that only admins can propose adding a user
    function testOnlyAdminCanProposeAddUser() public {
        vm.prank(userNotInWhitelist);
        vm.expectRevert();
        token.proposeAddUser(userNotInWhitelist);

        vm.prank(admin);
        token.proposeAddUser(userNotInWhitelist);
        assertTrue(token.proposedAddUserAddresses(userNotInWhitelist));
    }

    // Test that owner can decide on proposals
    function testAdminCanDecideOnProposal() public {
        // Admin proposes to add userNotInWhitelist
        vm.prank(owner);
        token.proposeAddUser(userNotInWhitelist);

        // Another owner approves the proposal
        vm.prank(owner);
        token.decideOnProposal(userNotInWhitelist, MyToken.ProposalType.AddUser, true);

        // Verify that the user is now in the whitelist
        assertTrue(token.whitelist(userNotInWhitelist));
    }

    // Test purchasing NFT by a whitelisted user
    function testPurchaseNftByWhitelistedUser() public {
        uint256 tokenId = 1;

        // Whitelisted user purchases NFT
        vm.prank(userInWhitelist);
        token.purchaseNft(); // No referrer

        // Verify NFT ownership
        assertEq(token.ownerOf(tokenId), userInWhitelist);

        // Verify that hasMinted is updated
        assertTrue(token.hasMinted(userInWhitelist));
    }

    // Test that a user cannot purchase more than once
    function testCannotPurchaseMoreThanOnce() public {
        vm.prank(userInWhitelist);
        token.purchaseNft();

        vm.prank(userInWhitelist);
        vm.expectRevert("Address has already minted an NFT");
        token.purchaseNft();
    }

    // Test purchasing NFT by a non-whitelisted user
    function testNonWhitelistedUserCannotPurchase() public {
        vm.prank(userNotInWhitelist);
        vm.expectRevert("Address is not in the whitelist");
        token.purchaseNft();
    }

    // Test referral system
    function testReferralSystem() public {
        // Admin adds userNotInWhitelist to whitelist directly
        token.addToWhitelist(userNotInWhitelist);

        // userInWhitelist is the referrer
        vm.prank(userNotInWhitelist);
        mockWETH.mint(userNotInWhitelist, 1 ether);
        vm.prank(userNotInWhitelist);
        mockWETH.approve(address(token), nftPrice);

        vm.prank(userNotInWhitelist);
        token.purchaseNft();

        // Verify that referral reward is recorded
        uint256 expectedReward = (nftPrice * token.referralPercentage()) / 100;
        assertEq(token.referralRewards(userInWhitelist), expectedReward);
    }

    // Test withdrawing referral rewards
    // Test withdrawReferralRewards when rewards exist
    function testWithdrawReferralRewards() public {
        // Step 1: Реферер (admin) предлагает пользователя (userNotInWhitelist)
        vm.prank(admin); // Имитация вызова от реферера
        token.proposeAddUser(userNotInWhitelist); // Администратор предлагает пользователя

        // Step 2: Одобряем предложение
        vm.prank(owner); // Имитация вызова от владельца
        token.decideOnProposal(userNotInWhitelist, MyToken.ProposalType.AddUser, true);

        // Step 3: Пользователь (userNotInWhitelist) одобряет контракт для списания WETH
        vm.prank(userNotInWhitelist); // Имитация вызова от имени предложенного пользователя
        mockWETH.approve(address(token), 0.5 ether); // Пользователь даёт разрешение на перевод 0.5 ETH для контракта

        // Step 4: Пользователь покупает NFT
        vm.prank(userNotInWhitelist); // Имитация вызова от имени предложенного пользователя
        token.purchaseNft();  // Пользователь покупает NFT

        // Step 5: Проверяем, что рефереру (admin) начислена реферальная награда
        uint256 expectedReward = (token.nftPrice() * token.referralPercentage()) / 100;
        console.log("expectedReward",expectedReward);
        assertEq(token.referralRewards(admin), expectedReward); // Проверяем, что награда начислена

        // Step 6: Реферер (admin) выводит свою награду
        vm.prank(admin); // Имитация вызова от администратора
        token.withdrawReferralRewards(); // Реферер выводит свои реферальные награды

        // Проверяем, что после вывода награда обнулена
        assertEq(token.referralRewards(admin), 0); // Убедимся, что награда обнулилась после вывода
    }



    // Test pausing and unpausing the contract
    function testPauseAndUnpause() public {
        // owner pauses the contract
        vm.prank(owner);
        token.pauseContract();

        // Attempt to purchase NFT while paused
        vm.prank(userInWhitelist);
        vm.expectRevert("Contract is paused");
        token.purchaseNft();

        // owner unpauses the contract
        vm.prank(owner);
        token.unpauseContract();

        // Purchase should succeed now
        vm.prank(userInWhitelist);
        token.purchaseNft();
    }

    // Test that non-admin cannot pause the contract
    function testNonAdminCannotPause() public {
        vm.prank(userInWhitelist);
        vm.expectRevert("Only an admin can perform this action");
        token.pauseContract();
    }

    // Test safeMint function
    function testSafeMintByOwner() public {
        // Owner mints NFT to userInWhitelist
        vm.prank(userInWhitelist);
        token.purchaseNft();

        uint256 tokenId = 1;
        assertEq(token.ownerOf(tokenId), userInWhitelist);
    }

    // Test that non-owner cannot mint
    function testNonOwnerCannotMint() public {
        vm.prank(userInWhitelist);
        token.purchaseNft();
    }

    // Test getAllMintedNFTs function
    function testGetAllMintedNFTs() public {
        // Mint multiple NFTs
        vm.prank(userInWhitelist);
        token.purchaseNft();

        // vm.prank(userInWhitelist);
        // token.purchaseNft(userInWhitelist);

        uint256[] memory mintedNFTs = token.getAllMintedNFTs();
        assertEq(mintedNFTs.length, 1);
        assertEq(mintedNFTs[0], 1);
        //assertEq(mintedNFTs[1], 2);
    }

    // Test proposing and approving adding an admin
    function testProposeAndApproveAddAdmin() public {
        // Admin proposes to add userNotInWhitelist as admin
        vm.prank(admin);
        token.proposeAddAdmin(userNotInWhitelist);

        // Verify proposal exists
        assertTrue(token.proposedAddAdminAddresses(userNotInWhitelist));

        // Admin approves the proposal
        vm.prank(owner);
        token.decideOnProposal(userNotInWhitelist, MyToken.ProposalType.AddAdmin, true);

        // Verify user is now an admin
        assertTrue(token.admin_list(userNotInWhitelist));
    }

    // Test proposing and rejecting adding an admin
    function testProposeAndRejectAddAdmin() public {
        // Admin proposes to add userNotInWhitelist as admin
        vm.prank(admin);
        token.proposeAddAdmin(userNotInWhitelist);

        // Admin rejects the proposal
        vm.prank(owner);
        token.decideOnProposal(userNotInWhitelist, MyToken.ProposalType.AddAdmin, false);

        // Verify user is not an admin
        assertFalse(token.admin_list(userNotInWhitelist));
    }

    // Test that only admin can decide on proposals
    function testOnlyAdminCanDecideOnProposal() public {
        // Admin proposes to add userNotInWhitelist as admin
        vm.prank(admin);
        token.proposeAddAdmin(userNotInWhitelist);

        // Non-admin tries to decide on proposal
        vm.prank(admin);
        vm.expectRevert();
        token.decideOnProposal(userNotInWhitelist, MyToken.ProposalType.AddAdmin, true);
        //vm.expectRevert("Only an Owner can perform this action");

    }

    // Test setting NFT price by owner
    function testSetNftPriceByOwner() public {
        vm.prank(owner);
        uint256 newPrice = 1 ether;
        token.setNftPrice(newPrice);
        assertEq(token.nftPrice(), newPrice);
    }

    // Test that non-owner cannot set NFT price
    function testNonOwnerCannotSetNftPrice() public {
        vm.prank(admin);
        vm.expectRevert();
        token.setNftPrice(1 ether);

    }


    // Test that referral reward is zero if no referrer
    function testNoReferralRewardIfNoReferrer() public {
        vm.prank(userInWhitelist);
        token.purchaseNft();

        // Verify that referral reward is zero
        assertEq(token.referralRewards(userInWhitelist), 0);
    }

    // Test withdrawReferralRewards when no rewards
    function testWithdrawReferralRewardsNoRewards() public {
        vm.prank(userInWhitelist);
        vm.expectRevert("No rewards to withdraw");
        token.withdrawReferralRewards();
    }

    // Test that only owner can add/remove admins directly
    function testOnlyOwnerCanAddRemoveAdmins() public {
        vm.prank(admin);
        vm.expectRevert("Only the owner can perform this action");
        token.addNewAdmin(userInWhitelist);

        token.addNewAdmin(userNotInWhitelist);
        assertTrue(token.admin_list(userNotInWhitelist));

        vm.prank(admin);
        vm.expectRevert("Only the owner can perform this action");
        token.removeAdmin(userNotInWhitelist);

        token.removeAdmin(userNotInWhitelist);
        assertFalse(token.admin_list(userNotInWhitelist));
    }
    // Тест, который проверяет, что разработчик получает свою комиссию
    function testDeveloperReceivesCommission() public {
        // Адрес разработчика уже установлен в контракте
        address developer = token.developer();

        // Предварительно проверяем баланс разработчика
        uint256 initialDeveloperBalance = mockWETH.balanceOf(developer);

        // Совершаем покупку NFT whitelisted пользователем
        vm.prank(userInWhitelist);
        token.purchaseNft();

        // Рассчитываем 2% от цены NFT
        uint256 expectedCommission = (nftPrice * 2) / 100;

        // Проверяем, что баланс разработчика увеличился на ожидаемую сумму
        uint256 finalDeveloperBalance = mockWETH.balanceOf(developer);
        assertEq(finalDeveloperBalance, initialDeveloperBalance + expectedCommission, "Developer did not receive the correct commission");
    }


}
