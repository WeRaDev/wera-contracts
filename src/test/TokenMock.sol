// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

/// @title TokenMock
contract TokenMock is MockERC20 {

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 supply_,
        uint8 decimals_
    ) MockERC20(name_, symbol_, decimals_) {
        _mint(msg.sender, supply_);
    }
}
