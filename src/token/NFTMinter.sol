// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControlEnumerable, AccessControl} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NFTMinter is ERC721, AccessControlEnumerable, Pausable {
    using SafeERC20 for IERC20;

    enum ProposalType { AddUser, RemoveUser, AddAdmin, RemoveAdmin }

    bytes32 public constant NFT_ADMIN_ROLE = keccak256("NFT_ADMIN_ROLE");

    address public recipient; // Address to automatically send ETH to after NFT purchase
    address public developer = 0xce7a6f6a800A632341061c007faa3c4068D3F72e; // dev address for refferal

    mapping(address => bool) public whitelist; // Mapping for whitelist
    mapping(address => bool) public hasMinted; // Mapping to track if an address has minted an NFT

    // Corrected mapping names
    mapping(address => bool) public proposedAddUserAddresses;
    mapping(address => bool) public proposedRemoveAddresses;
    mapping(address => bool) public proposedAddAdminAddresses;
    mapping(address => bool) public proposedRemoveAdminAddresses;

    mapping(address => address) public proposedBy; // Маппинг для хранения того, кто предложил нового пользователя

    /// The counter is always incremented by 1 every mint, so the total number and IDs of all NFTs
    /// can be determined using this variable alone.
    uint256 public nft_counter = 0;

    uint256 public nftPrice; // Price of each NFT in WETH
    IERC20 public weth; // Interface for WETH token

    // Referral system
    mapping(address => address) public referrer; // Stores the referrer for each user
    mapping(address => uint256) public referralRewards; // Stores rewards for each referrer
    uint256 public referralPercentage = 5; // 5% referral reward

    modifier onlyAdmin() {
        require(hasRole(NFT_ADMIN_ROLE, msg.sender), "Only an admin can perform this action");
        _;
    }

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only the owner can perform this action");
        _;
    }

    // Constructor accepts the address of the admin, NFT price, WETH contract address, and recipient address
    constructor(
        address _admin,
        uint256 _nftPrice,
        address _wethAddress,
        address _recipient
    ) ERC721("WeRa", "WeR") {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin); // main owner who can grant and revoke other roles
        _grantRole(NFT_ADMIN_ROLE, _admin);

        nftPrice = _nftPrice;
        weth = IERC20(_wethAddress);

        recipient = _recipient;
        whitelist[_admin] = true;

    }

    // Добавляем новый параметр в функцию предложения
    function proposeAddUser(address _newUser) external onlyAdmin {
        require(!whitelist[_newUser], "User is already in the whitelist");
        proposedBy[_newUser] = msg.sender; // Store the proposer
        proposedAddUserAddresses[_newUser] = true;
    }

    function proposeRemoveUser(address _removeUser) external onlyAdmin {
        require(whitelist[_removeUser], "Proposed user is not in the whitelist");
        proposedRemoveAddresses[_removeUser] = true;
    }

    function proposeAddAdmin(address _newAdmin) external onlyAdmin {
        require(!hasRole(NFT_ADMIN_ROLE, _newAdmin), "Proposed user is already an admin");
        proposedAddAdminAddresses[_newAdmin] = true;
    }

    function proposeRemoveAdmin(address _removeAdmin) external onlyAdmin {
        require(hasRole(NFT_ADMIN_ROLE, _removeAdmin), "Proposed user is not an admin");
        proposedRemoveAdminAddresses[_removeAdmin] = true;
    }

    // Универсальная функция для одобрения или отклонения предложений
    // Function to decide on proposals
    function decideOnProposal(address _target, ProposalType _proposalType, bool approve) external onlyOwner {
        // Example correction in decideOnProposal function
        if (_proposalType == ProposalType.AddUser) {
            require(proposedAddUserAddresses[_target], "No proposal to add user");

            if (approve) {
                // Add user to whitelist
                whitelist[_target] = true;

                // Set referrer if proposer exists
                address proposer = proposedBy[_target];
                if (proposer != address(0)) {
                    // Assuming you have a referrer mapping
                    // referrer[_target] = proposer;
                }
            }

        } else if (_proposalType == ProposalType.RemoveUser) {
            require(proposedRemoveAddresses[_target], "No proposal to remove user");

            if (approve) {
                // Remove user from whitelist
                whitelist[_target] = false;
            }
            // Remove proposal
            proposedRemoveAddresses[_target] = false;

        } else if (_proposalType == ProposalType.AddAdmin) {
            require(proposedAddAdminAddresses[_target], "No proposal to add admin");

            if (approve) {
                // Add user to admin list
                _grantRole(NFT_ADMIN_ROLE, _target);
            }
            // Remove proposal
            proposedAddAdminAddresses[_target] = false;

        } else if (_proposalType == ProposalType.RemoveAdmin) {
            require(proposedRemoveAdminAddresses[_target], "No proposal to remove admin");

            if (approve) {
                // Remove user from admin list
                _revokeRole(NFT_ADMIN_ROLE, _target);
            }
            // Remove proposal
            proposedRemoveAdminAddresses[_target] = false;
        }
    }

    // Функция для постановки на паузу (только админ может вызывать)
    function pauseContract() external onlyAdmin {
        _pause();
    }

    // Функция для снятия с паузы (только админ может вызывать)
    function unpauseContract() external onlyAdmin {
        _unpause();
    }

    // Function to add an address to the whitelist (default admin only)
    function addToWhitelist(address _user) external onlyOwner {
        whitelist[_user] = true;
    }

    // Function to remove an address from the whitelist (default admin only)
    function removeFromWhitelist(address _user) external onlyOwner() {
        whitelist[_user] = false;
    }

    function addNewAdmin(address _user) external onlyOwner {
        _grantRole(NFT_ADMIN_ROLE, _user);
    }

    // Function to remove an address from the admins (admin only)
    function removeAdmin(address _user) external onlyOwner() {
        _revokeRole(NFT_ADMIN_ROLE, _user);
    }

    // Function to set the price of the NFT (only owner)
    function setNftPrice(uint256 _price) external onlyOwner {
        nftPrice = _price;
    }

    // Function to set the recipient address (only owner)
    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    // Function to set referral percentage (only owner)
    function setReferralPercentage(uint256 _percentage) external onlyOwner {
        referralPercentage = _percentage;
    }

    // Function to safely mint an NFT (only owner)
    function safeMint(address to) external onlyOwner whenNotPaused {
        require(whitelist[to], "Address is not in the whitelist");

        nft_counter += 1;
        _safeMint(to, nft_counter);
    }

    function purchaseNft() external whenNotPaused {
        require(whitelist[msg.sender], "Address is not in the whitelist");
        require(weth.balanceOf(msg.sender) >= nftPrice, "Insufficient WETH balance");
        require(!hasMinted[msg.sender], "Address has already minted an NFT");

        // Используем proposedBy как реферера, если он есть
        if (proposedBy[msg.sender] != address(0) && referrer[msg.sender] == address(0)) {
            referrer[msg.sender] = proposedBy[msg.sender];

            // Remove proposal
            proposedAddUserAddresses[msg.sender] = false;
            delete proposedBy[msg.sender];
        }

        uint256 referralAmount = 0;
        if (referrer[msg.sender] != address(0)) {
            referralAmount = (nftPrice * referralPercentage) / 100;
            referralRewards[referrer[msg.sender]] += referralAmount;
        }

        // Рассчитываем 2% для разработчика
        uint256 developerAmount = (nftPrice * 2) / 100;

        // Оставшаяся сумма, которая пойдет получателю
        uint256 recipientAmount = nftPrice - referralAmount - developerAmount;

        // Перевод WETH получателю, рефереру и разработчику
        weth.safeTransferFrom(msg.sender, recipient, recipientAmount);

        if (referralAmount > 0) {
            // store referralAmount for withdrawReferralRewards
            weth.safeTransferFrom(msg.sender, address(this), referralAmount);
        }

        // Перевод 2% разработчику
        weth.safeTransferFrom(msg.sender, developer, developerAmount);

        // Чеканим NFT для покупателя
        nft_counter += 1;
        _safeMint(msg.sender, nft_counter);

        hasMinted[msg.sender] = true;
    }

    // Function to withdraw referral rewards
    function withdrawReferralRewards() external whenNotPaused {
        uint256 rewards = referralRewards[msg.sender];
        require(rewards > 0, "No rewards to withdraw");
        referralRewards[msg.sender] = 0;
        weth.safeTransfer(msg.sender, rewards);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControlEnumerable) returns (bool) {
        return (ERC721.supportsInterface(interfaceId) || AccessControlEnumerable.supportsInterface(interfaceId));
    }
}
