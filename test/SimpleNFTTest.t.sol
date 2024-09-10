// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/SimpleNFT.sol";

// Моковый контракт WETH для тестирования
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
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }

    function mint(address account, uint256 amount) external {
        _balances[account] += amount;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() external pure override returns (uint256) {
        return 0; // Mock implementation, not needed for this test
    }

    function transfer(address recipient, uint256 amount) external pure override returns (bool) {
        return false; // Mock implementation, not needed for this test
    }

    function decimals() external pure returns (uint8) {
        return 18; // Standard WETH has 18 decimals
    }
}

contract MyTokenTest is Test {
    MyToken public token;
    MockWETH public mockWETH;
    address public owner;
    address public admin;
    address public recipient;
    address public userInWhitelist;
    address public userNotInWhitelist;
    uint256 public nftPrice = 0.5 ether; // Цена NFT в WETH

    function setUp() public {
        // Адреса для тестирования
        owner = address(this); // Текущий контракт — владелец
        admin = address(1); // Адрес администратора
        recipient = address(4); // Адрес получателя для автоматической отправки средств

        userInWhitelist = address(2); // Пользователь в белом списке
        userNotInWhitelist = address(3); // Пользователь не в белом списке

        // Разворачиваем моковый WETH контракт
        mockWETH = new MockWETH();

        // Разворачиваем контракт MyToken с указанными параметрами
        token = new MyToken(admin, nftPrice, address(mockWETH), recipient);

        // Добавляем пользователя в белый список
        vm.prank(admin);
        token.addToWhitelist(userInWhitelist);

        // Моковый контракт WETH минтит токены для пользователя в белом списке
        mockWETH.mint(userInWhitelist, 1 ether);

        // Пользователь в белом списке разрешает контракту MyToken тратить его WETH
        vm.prank(userInWhitelist);
        mockWETH.approve(address(token), nftPrice);
    }

    function testPurchaseWithWETH() public {
        uint256 tokenId = 1;

        // Покупка NFT пользователем в белом списке с достаточным количеством WETH
        vm.prank(userInWhitelist);
        token.purchaseNft();

        // Проверяем, что NFT заминчен для пользователя
        assertEq(token.ownerOf(tokenId), userInWhitelist);
    }

    function testPurchaseWithMATIC() public {
        // Попытка покупки NFT с использованием MATIC (нативной валюты)
        vm.prank(userInWhitelist);
        vm.deal(userInWhitelist, 1 ether); // Добавляем MATIC на счет пользователя

        // Ожидаем ошибку, так как контракт принимает только WETH
        //vm.expectRevert("Failed to transfer WETH");
        token.purchaseNft();
    }

}
