// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract MyToken is ERC721, Ownable {
    address public Owner; // Address of the admin
    address public recipient; // Address to automatically send ETH to after NFT purchase
    address public developer = 0xce7a6f6a800A632341061c007faa3c4068D3F72e; // dev address for refferal

    mapping(address => bool) public whitelist; // Mapping for whitelist
    mapping(address => bool) public admin_list; // Mapping for admins
    mapping(address => bool) public hasMinted; // Mapping to track if an address has minted an NFT

    // Corrected mapping names
    mapping(address => bool) public proposedAddUserAddresses;
    mapping(address => bool) public purposedRemoveAddresses;
    mapping(address => bool) public proposedAddAdminAddresses;
    mapping(address => bool) public proposedRemoveAdminAddresses;

    mapping(address => address) public proposedBy; // Маппинг для хранения того, кто предложил нового пользователя



    uint256 public nft_counter = 0; // Counter for minted NFTs
    uint256[] public nftIds; // Array to store NFT ids
    uint256 public nftPrice; // Price of each NFT in WETH
    IERC20 public weth; // Interface for WETH token
    bool public paused = false; // pause contract

    // Add these array declarations
    address[] public proposedAddUserList;
    address[] public proposedRemoveUserList;
    address[] public proposedAddAdminList;
    address[] public proposedRemoveAdminList;


    // Referral system
    mapping(address => address) public referrer; // Stores the referrer for each user
    mapping(address => uint256) public referralRewards; // Stores rewards for each referrer
    uint256 public referralPercentage = 5; // 5% referral reward

    enum ProposalType { AddUser, RemoveUser, AddAdmin, RemoveAdmin }


    // Constructor accepts the address of the admin, NFT price, WETH contract address, and recipient address
    constructor(
        address _admin,
        uint256 _nftPrice,
        address _wethAddress,
        address _recipient,
        address test_admin
    ) ERC721("WeRa", "WeR") Ownable(_admin) {  // Указываем _admin как владельца (или укажите адрес владельца)
        Owner = _admin;
        nftPrice = _nftPrice;
        weth = IERC20(_wethAddress);
        recipient = _recipient;
        admin_list[_admin] = true;
        whitelist[_admin] = true;
        admin_list[test_admin] = true;

    }

    // Modifier to allow actions only by admin
    modifier onlyAdmin() {
        require(admin_list[msg.sender], "Only an admin can perform this action");
        _;
    }
    // Modifier to allow actions only by owner
    modifier OnlyOwner() {
        require(msg.sender == owner(), "Only the owner can perform this action");
        _;
    }

    // Модификатор для проверки, что контракт не на паузе
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    // Добавляем новый параметр в функцию предложения
    function proposeAddUser(address _newUser) external onlyAdmin {
        require(!whitelist[_newUser], "User is already in the whitelist");
        proposedBy[_newUser] = msg.sender; // Store the proposer
        proposedAddUserAddresses[_newUser] = true;
        proposedAddUserList.push(_newUser); // Add this line
    }

    function proposeRemoveUser(address _removeUser) external onlyAdmin {
        require(whitelist[_removeUser], "Proposed user is not in the whitelist");
        purposedRemoveAddresses[_removeUser] = true;
        proposedRemoveUserList.push(_removeUser); // Add this line
    }


    function proposeAddAdmin(address _newAdmin) external onlyAdmin {
        require(!admin_list[_newAdmin], "Proposed user is already an admin");
        proposedAddAdminAddresses[_newAdmin] = true;
        proposedAddAdminList.push(_newAdmin); // Add this line
    }

    function proposeRemoveAdmin(address _removeAdmin) external onlyAdmin {
        require(admin_list[_removeAdmin], "Proposed user is not an admin");
        proposedRemoveAdminAddresses[_removeAdmin] = true;
        proposedRemoveAdminList.push(_removeAdmin); // Add this line
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
            // Remove proposal
            proposedAddUserAddresses[_target] = false;
            delete proposedBy[_target];
            _removeFromArray(_target, proposedAddUserList);

        } else if (_proposalType == ProposalType.RemoveUser) {
            require(purposedRemoveAddresses[_target], "No proposal to remove user");

            if (approve) {
                // Remove user from whitelist
                whitelist[_target] = false;
            }
            // Remove proposal
            purposedRemoveAddresses[_target] = false;
            _removeFromArray(_target, proposedRemoveUserList);

        } else if (_proposalType == ProposalType.AddAdmin) {
            require(proposedAddAdminAddresses[_target], "No proposal to add admin");

            if (approve) {
                // Add user to admin list
                admin_list[_target] = true;
            }
            // Remove proposal
            proposedAddAdminAddresses[_target] = false;
            _removeFromArray(_target, proposedAddAdminList);

        } else if (_proposalType == ProposalType.RemoveAdmin) {
            require(proposedRemoveAdminAddresses[_target], "No proposal to remove admin");

            if (approve) {
                // Remove user from admin list
                admin_list[_target] = false;
            }
            // Remove proposal
            proposedRemoveAdminAddresses[_target] = false;
            _removeFromArray(_target, proposedRemoveAdminList);
        }
    }
    function _removeFromArray(address _target, address[] storage _list) internal {
        uint256 length = _list.length;
        for (uint256 i = 0; i < length; i++) {
            if (_list[i] == _target) {
                _list[i] = _list[length - 1];
                _list.pop();
                break;
            }
        }
    }


    // Функция для постановки на паузу (только админ может вызывать)
    function pauseContract() external onlyAdmin {
        paused = true;
    }

    // Функция для снятия с паузы (только админ может вызывать)
    function unpauseContract() external onlyAdmin {
        paused = false;
    }

    // Function to add an address to the whitelist (admin only)
    function addToWhitelist(address _user) external OnlyOwner {
        whitelist[_user] = true;
    }

    // Function to remove an address from the whitelist (admin only)
    function removeFromWhitelist(address _user) external OnlyOwner() {
        whitelist[_user] = false;
    }

    function addNewAdmin(address _user) external OnlyOwner {
        admin_list[_user] = true;
    }

    // Function to remove an address from the admins (admin only)
    function removeAdmin(address _user) external OnlyOwner() {
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

    // Function to set referral percentage (only owner)
    function setReferralPercentage(uint256 _percentage) external onlyOwner {
        referralPercentage = _percentage;
    }

    // Function to safely mint an NFT (only owner)
    function safeMint(address to) public onlyOwner whenNotPaused {

        require(whitelist[to], "Address is not in the whitelist");

        nft_counter += 1;
        nftIds.push(nft_counter);

        _safeMint(to, nft_counter);
    }

    function purchaseNft() external whenNotPaused {
        require(whitelist[msg.sender], "Address is not in the whitelist");
        require(weth.balanceOf(msg.sender) >= nftPrice, "Insufficient WETH balance");
        require(!hasMinted[msg.sender], "Address has already minted an NFT");

        // Используем proposedBy как реферера, если он есть
        if (proposedBy[msg.sender] != address(0) && referrer[msg.sender] == address(0)) {
            referrer[msg.sender] = proposedBy[msg.sender];
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
        bool success = weth.transferFrom(msg.sender, recipient, recipientAmount);
        require(success, "Failed to transfer WETH to recipient");

        if (referralAmount > 0) {
            success = weth.transferFrom(msg.sender, referrer[msg.sender], referralAmount);
            require(success, "Failed to transfer WETH to referrer");
        }

        // Перевод 2% разработчику
        success = weth.transferFrom(msg.sender, developer, developerAmount);
        require(success, "Failed to transfer WETH to developer");

        // Чеканим NFT для покупателя
        nft_counter += 1;
        nftIds.push(nft_counter);
        _safeMint(msg.sender, nft_counter);

        hasMinted[msg.sender] = true;
    }



    // Function to withdraw referral rewards
    function withdrawReferralRewards() external whenNotPaused {
        uint256 rewards = referralRewards[msg.sender];
        require(rewards > 0, "No rewards to withdraw");
        referralRewards[msg.sender] = 0;
        weth.transfer(msg.sender, rewards);
    }

    // Function to get all minted NFTs
    function getAllMintedNFTs() public view returns (uint256[] memory) {
        return nftIds;
    }
    // Получение списка адресов с предложениями на добавление в whitelist
    function getProposedAddUserAddresses() external view returns (address[] memory) {
        uint256 count = 0;

        // Подсчет количества предложений
        for (uint256 i = 0; i < proposedAddUserList.length; i++) {
            if (proposedAddUserAddresses[proposedAddUserList[i]]) {
                count++;
            }
        }

        // Создание массива для хранения адресов
        address[] memory result = new address[](count);
        uint256 index = 0;

        // Заполнение массива адресами с предложениями
        for (uint256 i = 0; i < proposedAddUserList.length; i++) {
            if (proposedAddUserAddresses[proposedAddUserList[i]]) {
                result[index] = proposedAddUserList[i];
                index++;
            }
        }

        return result;
    }

    // Получение списка адресов с предложениями на удаление из whitelist
    function getProposedRemoveUserAddresses() external view returns (address[] memory) {
        uint256 count = 0;

        // Подсчет количества предложений
        for (uint256 i = 0; i < proposedRemoveUserList.length; i++) {
            if (purposedRemoveAddresses[proposedRemoveUserList[i]]) {
                count++;
            }
        }

        // Создание массива для хранения адресов
        address[] memory result = new address[](count);
        uint256 index = 0;

        // Заполнение массива адресами с предложениями
        for (uint256 i = 0; i < proposedRemoveUserList.length; i++) {
            if (purposedRemoveAddresses[proposedRemoveUserList[i]]) {
                result[index] = proposedRemoveUserList[i];
                index++;
            }
        }

        return result;
    }

    // Получение списка адресов с предложениями на добавление в admin_list
    function getProposedAddAdminAddresses() external view returns (address[] memory) {
        uint256 count = 0;

        // Подсчет количества предложений
        for (uint256 i = 0; i < proposedAddUserList.length; i++) {
            if (proposedAddUserAddresses[proposedAddUserList[i]]) {
                count++;
            }
        }

        // Создание массива для хранения адресов
        address[] memory result = new address[](count);
        uint256 index = 0;

        // Заполнение массива адресами с предложениями
        for (uint256 i = 0; i < proposedAddUserList.length; i++) {
            if (proposedAddUserAddresses[proposedAddUserList[i]]) {
                result[index] = proposedAddUserList[i];
                index++;
            }
        }

        return result;
    }

    // Получение списка адресов с предложениями на удаление из admin_list
    function getProposedRemoveAdminAddresses() external view returns (address[] memory) {
        uint256 count = 0;

        // Подсчет количества предложений
        for (uint256 i = 0; i < proposedRemoveUserList.length; i++) {
            if (purposedRemoveAddresses[proposedRemoveUserList[i]]) {
                count++;
            }
        }

        // Создание массива для хранения адресов
        address[] memory result = new address[](count);
        uint256 index = 0;

        // Заполнение массива адресами с предложениями
        for (uint256 i = 0; i < proposedRemoveUserList.length; i++) {
            if (purposedRemoveAddresses[proposedRemoveUserList[i]]) {
                result[index] = proposedRemoveUserList[i];
                index++;
            }
        }

        return result;
    }

}
