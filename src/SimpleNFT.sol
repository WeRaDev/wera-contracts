// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

contract MyToken is ERC721, Ownable {
    address public initialOwner; // Владелец контракта
    address public admin; // Адрес администратора
    mapping(address => bool) public whitelist; // Маппинг для белого списка
    address[] public nftIds;
    uint[] public arrayValue = [1,2,3];

    uint256 nft_counter = 0;


    // Конструктор принимает адрес владельца, администратора и количество токенов для минтинга
    constructor(address _initialOwner, address _admin)
        ERC721("MyToken", "MTK")
        Ownable(_initialOwner)
    {
        initialOwner = _initialOwner;
        admin = _admin;
    }

    // Модификатор, чтобы позволить действия только администратору
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    // Функция для добавления адреса в белый список (только админ)
    function addToWhitelist(address _user) external onlyAdmin {
        whitelist[_user] = true;
    }

    // Функция для удаления адреса из белого списка (только админ)
    function removeFromWhitelist(address _user) external onlyAdmin {
        whitelist[_user] = false;
    }

    // Функция для безопасного минтинга NFT
    function safeMint(address to) public onlyOwner {
        require(whitelist[to], "Address is not in the whitelist");

        nft_counter += 1;
        arrayValue.push(nft_counter);

        _safeMint(to, nft_counter);
    }
}
