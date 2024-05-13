// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IWeP
interface IWeP is IERC20 {
    function mint(address to_, uint256 amount_) external;
}
