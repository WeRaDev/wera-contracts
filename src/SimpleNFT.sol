// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

// Import the referral library from ThunderCore
import "@thundercore/referral/ReferralLibrary.sol";

contract MyToken is ERC721, Ownable {
    using ReferralLibrary for ReferralLibrary.Referral;

    ReferralLibrary.Referral private referralSystem; // Initialize the referral system

    address public admin; // Address of the admin
    address public recipient; // Address to automatically send ETH to after NFT purchase
    mapping(address => bool) public whitelist; // Mapping for whitelist
    mapping(address => bool) public admin_list; // Mapping for admins
    mapping(address => bool) public hasMinted; // Mapping to track if an address has minted an NFT
    uint256 public nft_counter = 0; // Counter for minted NFTs
    uint256[] public nftIds; // Array to store NFT ids
    uint256 public nftPrice; // Price of each NFT in WETH
    IERC20 public weth; // Interface for WETH token

    // Rewards for referrer and referee
    uint256 public referrerReward; // Reward for referrer
    uint256 public refereeReward; // Reward for referee

    // Constructor accepts the address of the admin, NFT price, WETH contract address, and recipient address
    constructor(
        address _admin,
        uint256 _nftPrice,
        address _wethAddress,
        address _recipient
    ) ERC721("WeRa", "WeR") Ownable(_admin) {
        admin = _admin;
        nftPrice = _nftPrice;
        weth = IERC20(_wethAddress);
        recipient = _recipient;
        admin_list[_admin] = true;
        whitelist[_admin] = true;
    }

    // Modifier to allow actions only by admin
    modifier onlyAdmin() {
        require(admin_list[msg.sender], "Only an admin can perform this action");
        _;
    }

    // Function to add an address to the whitelist (admin only)
    function addToWhitelist(address _user) external onlyAdmin {
        whitelist[_user] = true;
    }

    // Function to remove an address from the admins (admin only)
    function removeFromWhitelist(address _user) external onlyAdmin {
        whitelist[_user] = false;
    }

    function addNewAdmin(address _user) external onlyAdmin {
        admin_list[_user] = true;
    }

    // Function to remove an address from the admins (admin only)
    function removeAdmis(address _user) external onlyAdmin {
        admin_list[_user] = false;
    }

    // Function to set the price of the NFT (only owner)
    function setNftPrice(uint256 _price) external onlyOwner {
        nftPrice = _price;
    }

    // Function to set the recipient address (only owner)
    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    // Set rewards for referral program
    function setReferralRewards(uint256 _referrerReward, uint256 _refereeReward) external onlyOwner {
        referrerReward = _referrerReward;
        refereeReward = _refereeReward;
    }

    // Function to safely mint an NFT (only owner)
    function safeMint(address to, address referrer) public onlyOwner {
        require(whitelist[to], "Address is not in the whitelist");

        // Track the referral
        if (referrer != address(0)) {
            referralSystem.recordReferral(to, referrer);
        }

        nft_counter += 1;
        nftIds.push(nft_counter);

        _safeMint(to, nft_counter);

        // Reward referrer and referee if applicable
        if (referrer != address(0)) {
            rewardReferral(to, referrer);
        }
    }

    // Function to reward referrals
    function rewardReferral(address referee, address referrer) internal {
        if (weth.balanceOf(address(this)) >= referrerReward + refereeReward) {
            weth.transfer(referrer, referrerReward);
            weth.transfer(referee, refereeReward);
        }
    }

    function purchaseNft(address referrer) external {
        require(whitelist[msg.sender], "Address is not in the whitelist");
        require(weth.balanceOf(msg.sender) >= nftPrice, "Insufficient WETH balance");
        require(!hasMinted[msg.sender], "Address has already minted an NFT");

        // Попытка перевода WETH от покупателя к получателю
        console.log("ETH balance", weth.balanceOf(msg.sender));
        console.log("Price", nftPrice);

        bool success = weth.transferFrom(msg.sender, recipient, nftPrice);
        require(success, "Failed to transfer WETH");

        console.log("Balance recipient", weth.balanceOf(recipient));
        console.log("ETH balance", weth.balanceOf(msg.sender));

        // Минтим NFT для покупателя
        nft_counter += 1;
        nftIds.push(nft_counter);
        _safeMint(msg.sender, nft_counter);

        // Track referral if applicable
        if (referrer != address(0)) {
            referralSystem.recordReferral(msg.sender, referrer);
            rewardReferral(msg.sender, referrer);
        }
    }

    // Function to get all minted NFTs
    function getAllMintedNFTs() public view returns (uint256[] memory) {
        return nftIds;
    }
}
