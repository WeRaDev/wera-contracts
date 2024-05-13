// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

/// @title MintableToken
contract MintableToken is Ownable, MockERC20 {

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) Ownable(msg.sender) MockERC20(name_, symbol_, decimals_) {}

    function mint(address to_, uint256 amount_) public override onlyOwner {
        _mint(to_, amount_);
    }
}
