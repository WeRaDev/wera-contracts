// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/SimpleNFT.sol";

contract MyTokenTest is Test {
    MyToken public token;
    address public owner;
    address public admin;
    address public user_address;
    address public userInWhitelist;
    address public userNotInWhitelist;
    uint256 public mintingTokensRequired;


    function setUp() public {
        // Адреса для тестирования
        owner = address(this); // Текущий контракт — владелец
        admin = address(1); // Адрес администратора
        user_address = address(23); // Адрес теста

        userInWhitelist = address(2); // Пользователь в белом списке
        userNotInWhitelist = address(3); // Пользователь не в белом списке

        // Разворачиваем контракт MyToken с указанными параметрами
        token = new MyToken(owner, admin);
    }

    function testAddToWhitelist() public {
        // Выполняем тест как администратор
        vm.prank(admin);
        token.addToWhitelist(userInWhitelist);

        // Проверяем, что пользователь добавлен в белый список
        assertTrue(token.whitelist(userInWhitelist));
    }

    function testRemoveFromWhitelist() public {
        // Добавляем пользователя в белый список
        vm.prank(admin);
        token.addToWhitelist(userInWhitelist);

        // Удаляем пользователя из белого списка
        vm.prank(admin);
        token.removeFromWhitelist(userInWhitelist);

        // Проверяем, что пользователь удален из белого списка
        assertFalse(token.whitelist(userInWhitelist));
    }

    function testSafeMintWithWhitelistedUser() public {
        // Добавляем пользователя в белый список
        vm.prank(admin);
        token.addToWhitelist(userInWhitelist);

        // Владелец минтит NFT для пользователя в белом списке
        token.safeMint(userInWhitelist);

        // Проверяем, что NFT заминтен для пользователя
        assertEq(token.ownerOf(1), userInWhitelist);
    }

    function testSafeMintWithoutWhitelist() public {
        uint256 tokenId = 23;

        // Попытка минтинга NFT для пользователя, не находящегося в белом списке
        vm.expectRevert("Address is not in the whitelist");
        token.safeMint(userNotInWhitelist);
    }

}
