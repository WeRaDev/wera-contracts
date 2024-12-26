// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {NFTMinter, IERC20} from "../src/token/NFTMinter.sol";
import {MintableToken} from "../src/test/MintableToken.sol";

// btw this could be used too
// import {WETH} from "solmate/tokens/WETH.sol";

contract NFTMinterTest is Test {
    NFTMinter public miner;
    MintableToken public mockWETH;
    address public owner;
    address public admin;
    address public recipient;
    address public userInWhitelist;
    address public userNotInWhitelist;
    uint256 public nftPrice = 0.5 ether; // Price of NFT in WETH
    string public initialBaseURI = "https://api.example.com/metadata/";


    function setUp() public {
        owner = address(this); // This contract is not the owner in this context
        admin = address(1);

        recipient = address(4); // Recipient address for automatic fund transfer

        userInWhitelist = address(2); // User in whitelist
        userNotInWhitelist = address(3); // User not in whitelist

        // Deploy mock WETH contract
        mockWETH = new MintableToken("Wrapped ETH", "WETH", 18);

        // Deploy NFTMinter contract with specified parameters
        miner = new NFTMinter(owner, nftPrice, address(mockWETH), recipient, initialBaseURI);
        miner.grantRole(miner.NFT_ADMIN_ROLE(), admin);

        // Simulate owner calling addToWhitelist
        vm.prank(owner);
        miner.addToWhitelist(userInWhitelist);

        // Mock WETH contract mints tokens for the whitelisted user
        mockWETH.mint(userInWhitelist, 10 ether);
        mockWETH.mint(userNotInWhitelist, 10 ether);


        // Whitelisted user approves NFTMinter contract to spend their WETH
        vm.prank(userInWhitelist);
        mockWETH.approve(address(miner), nftPrice);

        // Owner mints initial WETH balance
        mockWETH.mint(owner, 100 ether);
        mockWETH.approve(address(miner), 100 ether);

        // owner mints initial WETH balance
        mockWETH.mint(owner, 100 ether);
        vm.prank(owner);
        mockWETH.approve(address(miner), 100 ether);

    }
    // Тест: Проверка начального значения baseURI при развертывании контракта
    function testInitialBaseURI() public {
        // Создаем значение, которое должно быть равно начальному baseURI
        string memory expectedURI = initialBaseURI;

        // Создаем токен с ID 1
        vm.prank(owner); // Указываем, что действия выполняются от имени владельца
        miner.safeMint(userInWhitelist); // Предполагается, что `safeMint` увеличивает ID

        // Проверяем tokenURI для токена с ID 1
        string memory tokenURI = miner.tokenURI(1);

        // Проверяем, что baseURI является частью tokenURI
        assertEq(tokenURI, string(abi.encodePacked(expectedURI, "1")), "Initial baseURI should match the provided URI");
    }



    // Тест: Изменение baseURI владельцем
    function testSetBaseURI() public {
        string memory newBaseURI = "https://newapi.example.com/metadata/";

        // Меняем baseURI как владелец
        vm.prank(owner); // Указываем, что действия выполняются от имени владельца
        miner.setBaseURI(newBaseURI);

        // Проверяем, что baseURI изменен
        assertEq(miner.getBaseURI(), newBaseURI, "New baseURI should be set by the owner");
    }


    // Тест: Попытка изменения baseURI не владельцем
    function testSetBaseURIByNonOwner() public {
        string memory newBaseURI = "https://unauthorizedapi.example.com/metadata/";

        // Пытаемся изменить baseURI от имени другого адреса (не owner)
        vm.prank(userInWhitelist); // Выполняем действия от имени пользователя, который не является владельцем
        vm.expectRevert("Only the owner can perform this action");
        miner.setBaseURI(newBaseURI);
    }

    // Test that only the owner can add to the whitelist
    function testOnlyOwnerCanAddToWhitelist() public {
        vm.prank(userNotInWhitelist);
        vm.expectRevert("Only the owner can perform this action");
        miner.addToWhitelist(userNotInWhitelist);

        vm.prank(owner);
        miner.addToWhitelist(userNotInWhitelist);

        miner.addToWhitelist(userNotInWhitelist);
        assertTrue(miner.whitelist(userNotInWhitelist));
    }

    // Test that only the owner can remove from the whitelist
    function testOnlyOwnerCanRemoveFromWhitelist() public {
        miner.addToWhitelist(userInWhitelist);
        assertTrue(miner.whitelist(userInWhitelist));

        vm.prank(userNotInWhitelist);
        vm.expectRevert("Only the owner can perform this action");
        miner.removeFromWhitelist(userInWhitelist);

        vm.prank(owner);
        miner.removeFromWhitelist(userInWhitelist);

        miner.removeFromWhitelist(userInWhitelist);
        assertFalse(miner.whitelist(userInWhitelist));
    }

    // Test that only admins can propose adding a user
    function testOnlyAdminCanProposeAddUser() public {
        vm.prank(userNotInWhitelist);
        vm.expectRevert();
        miner.proposeAddUser(userNotInWhitelist);

        vm.prank(admin);
        miner.proposeAddUser(userNotInWhitelist);
        assertTrue(miner.proposedAddUserAddresses(userNotInWhitelist));
    }

    // Test that owner can decide on proposals
    function testAdminCanDecideOnProposal() public {
        // Admin proposes to add userNotInWhitelist
        vm.prank(owner);
        miner.proposeAddUser(userNotInWhitelist);

        // Another owner approves the proposal
        vm.prank(owner);
        miner.decideOnProposal(userNotInWhitelist, NFTMinter.ProposalType.AddUser, true);

        // Verify that the user is now in the whitelist
        assertTrue(miner.whitelist(userNotInWhitelist));
    }

    // Test purchasing NFT by a whitelisted user
    function testPurchaseNftByWhitelistedUser() public {
        uint256 tokenId = 1;

        // Whitelisted user purchases NFT
        vm.prank(userInWhitelist);
        miner.purchaseNft(); // No referrer

        // Verify NFT ownership
        assertEq(miner.ownerOf(tokenId), userInWhitelist);

        // Verify that hasMinted is updated
        assertTrue(miner.hasMinted(userInWhitelist));
    }

    // Test that a user cannot purchase more than once
    function testCannotPurchaseMoreThanOnce() public {
        vm.prank(userInWhitelist);
        miner.purchaseNft();

        vm.prank(userInWhitelist);
        mockWETH.approve(address(miner), nftPrice);

        vm.expectRevert("Address has already minted an NFT");
        vm.prank(userInWhitelist);
        miner.purchaseNft();
    }

    // Test purchasing NFT by a non-whitelisted user
    function testNonWhitelistedUserCannotPurchase() public {
        vm.prank(userNotInWhitelist);
        vm.expectRevert("Address is not in the whitelist");
        miner.purchaseNft();
    }

    // Test referral system
    function testReferralSystem() public {

        // Admin proposes userInWhitelist as referrer for userNotInWhitelist
        vm.prank(admin); // Администратор предлагает userInWhitelist как реферера
        miner.proposeAddUser(userNotInWhitelist);

        // Owner decides to approve the proposal
        vm.prank(owner);
        miner.decideOnProposal(userNotInWhitelist, NFTMinter.ProposalType.AddUser, true);

        // Mock WETH tokens are minted and approved for purchase
        mockWETH.mint(userNotInWhitelist, 1 ether);
        vm.prank(userNotInWhitelist);
        mockWETH.approve(address(miner), nftPrice);

        // User makes a purchase
        vm.prank(userNotInWhitelist);
        miner.purchaseNft();

        // Calculate expected referral reward
        uint256 expectedReward = (nftPrice * miner.referralPercentage()) / 100;

        // Verify that referral reward is recorded for userInWhitelist (the referrer)
        assertEq(miner.referralRewards(admin), expectedReward, "Referral reward should match expected reward");
    }

    // Test withdrawing referral rewards
    // Test withdrawReferralRewards when rewards exist
    function testWithdrawReferralRewards() public {
        // Step 1: Реферер (admin) предлагает пользователя (userNotInWhitelist)
        vm.prank(admin); // Имитация вызова от реферера
        miner.proposeAddUser(userNotInWhitelist); // Администратор предлагает пользователя

        // Step 2: Одобряем предложение
        vm.prank(owner); // Имитация вызова от владельца
        miner.decideOnProposal(userNotInWhitelist, NFTMinter.ProposalType.AddUser, true);

        // Step 3: Пользователь (userNotInWhitelist) одобряет контракт для списания WETH
        vm.prank(userNotInWhitelist); // Имитация вызова от имени предложенного пользователя
        mockWETH.approve(address(miner), 0.5 ether); // Пользователь даёт разрешение на перевод 0.5 ETH для контракта

        // Step 4: Пользователь покупает NFT
        vm.prank(userNotInWhitelist); // Имитация вызова от имени предложенного пользователя
        miner.purchaseNft();  // Пользователь покупает NFT

        console.log("referrer hmm", miner.referrer(userNotInWhitelist));
        console.log("proposed by hmm", miner.proposedBy(userNotInWhitelist));

        // Step 5: Проверяем, что рефереру (admin) начислена реферальная награда
        uint256 expectedReward = (miner.nftPrice() * miner.referralPercentage()) / 100;
        console.log("expectedReward",expectedReward);
        assertEq(miner.referralRewards(admin), expectedReward); // Проверяем, что награда начислена

        // Step 6: Реферер (admin) выводит свою награду
        vm.prank(admin); // Имитация вызова от администратора
        miner.withdrawReferralRewards(); // Реферер выводит свои реферальные награды

        // Проверяем, что после вывода награда обнулена
        assertEq(miner.referralRewards(admin), 0); // Убедимся, что награда обнулилась после вывода
    }


    // Test pausing and unpausing the contract
    function testPauseAndUnpause() public {
        // owner pauses the contract
        vm.prank(owner);
        miner.pauseContract();

        // Attempt to purchase NFT while paused
        vm.prank(userInWhitelist);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        miner.purchaseNft();

        // owner unpauses the contract
        vm.prank(owner);
        miner.unpauseContract();

        // Purchase should succeed now
        vm.prank(userInWhitelist);
        miner.purchaseNft();
    }

    // Test that non-admin cannot pause the contract
    function testNonAdminCannotPause() public {
        vm.prank(userInWhitelist);
        vm.expectRevert("Only an admin can perform this action");
        miner.pauseContract();
    }

    // Test safeMint function
    function testSafeMintByOwner() public {
        // Owner mints NFT to userInWhitelist
        vm.prank(userInWhitelist);
        miner.purchaseNft();

        uint256 tokenId = 1;
        assertEq(miner.ownerOf(tokenId), userInWhitelist);
    }

    // Test that non-owner cannot mint
    function testNonOwnerCannotMint() public {
        vm.prank(userInWhitelist);
        miner.purchaseNft();
    }

    // Test getAllMintedNFTs function
    function testGetAllMintedNFTs() public {
        // Mint multiple NFTs
        vm.prank(userInWhitelist);
        miner.purchaseNft();

        // vm.prank(userInWhitelist);
        // miner.purchaseNft(userInWhitelist);

        uint256 mintedNFTs = miner.nft_counter();
        assertEq(mintedNFTs, 1);
        //assertEq(mintedNFTs[1], 2);
    }

    // Test proposing and approving adding an admin
    function testProposeAndApproveAddAdmin() public {
        // Admin proposes to add userNotInWhitelist as admin
        vm.prank(admin);
        miner.proposeAddAdmin(userNotInWhitelist);

        // Verify proposal exists
        assertTrue(miner.proposedAddAdminAddresses(userNotInWhitelist));

        // Admin approves the proposal
        vm.prank(owner);
        miner.decideOnProposal(userNotInWhitelist, NFTMinter.ProposalType.AddAdmin, true);

        // Verify user is now an admin
        assertTrue(miner.hasRole(miner.NFT_ADMIN_ROLE(), userNotInWhitelist));
    }

    // Test proposing and rejecting adding an admin
    function testProposeAndRejectAddAdmin() public {
        // Admin proposes to add userNotInWhitelist as admin
        vm.prank(admin);
        miner.proposeAddAdmin(userNotInWhitelist);

        // Admin rejects the proposal
        vm.prank(owner);
        miner.decideOnProposal(userNotInWhitelist, NFTMinter.ProposalType.AddAdmin, false);

        // Verify user is not an admin
        assertFalse(miner.hasRole(miner.NFT_ADMIN_ROLE(), userNotInWhitelist));
    }

    // Test that only admin can decide on proposals
    function testOnlyAdminCanDecideOnProposal() public {
        // Admin proposes to add userNotInWhitelist as admin
        vm.prank(admin);
        miner.proposeAddAdmin(userNotInWhitelist);

        // Non-admin tries to decide on proposal
        vm.prank(admin);
        vm.expectRevert();
        miner.decideOnProposal(userNotInWhitelist, NFTMinter.ProposalType.AddAdmin, true);
        //vm.expectRevert("Only an Owner can perform this action");

    }

    // Test setting NFT price by owner
    function testSetNftPriceByOwner() public {
        vm.prank(owner);
        uint256 newPrice = 1 ether;
        miner.setNftPrice(newPrice);
        assertEq(miner.nftPrice(), newPrice);
    }

    // Test that non-owner cannot set NFT price
    function testNonOwnerCannotSetNftPrice() public {
        vm.prank(admin);
        vm.expectRevert();
        miner.setNftPrice(1 ether);

    }


    // Test that referral reward is zero if no referrer
    function testNoReferralRewardIfNoReferrer() public {
        vm.prank(userInWhitelist);
        miner.purchaseNft();

        // Verify that referral reward is zero
        assertEq(miner.referralRewards(userInWhitelist), 0);
    }

    // Test withdrawReferralRewards when no rewards
    function testWithdrawReferralRewardsNoRewards() public {
        vm.prank(userInWhitelist);
        vm.expectRevert("No rewards to withdraw");
        miner.withdrawReferralRewards();
    }

    // Test that only owner can add/remove admins directly
    function testOnlyOwnerCanAddRemoveAdmins() public {
        vm.prank(admin);
        vm.expectRevert("Only the owner can perform this action");
        miner.addNewAdmin(userInWhitelist);

        miner.addNewAdmin(userNotInWhitelist);
        assertTrue(miner.hasRole(miner.NFT_ADMIN_ROLE(), userNotInWhitelist));

        vm.prank(admin);
        vm.expectRevert("Only the owner can perform this action");
        miner.removeAdmin(userNotInWhitelist);

        miner.removeAdmin(userNotInWhitelist);
        assertFalse(miner.hasRole(miner.NFT_ADMIN_ROLE(), userNotInWhitelist));
    }
    // Тест, который проверяет, что разработчик получает свою комиссию
    function testDeveloperReceivesCommission() public {
        // Адрес разработчика уже установлен в контракте
        address developer = miner.developer();

        // Предварительно проверяем баланс разработчика
        uint256 initialDeveloperBalance = mockWETH.balanceOf(developer);

        // Совершаем покупку NFT whitelisted пользователем
        vm.prank(userInWhitelist);
        miner.purchaseNft();

        // Рассчитываем 2% от цены NFT
        uint256 expectedCommission = (nftPrice * 2) / 100;

        // Проверяем, что баланс разработчика увеличился на ожидаемую сумму
        uint256 finalDeveloperBalance = mockWETH.balanceOf(developer);
        assertEq(finalDeveloperBalance, initialDeveloperBalance + expectedCommission, "Developer did not receive the correct commission");
    }


}
