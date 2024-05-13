// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit, Nonces} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

import {IWeP} from "./IWeP.sol";

/// @title WeP
contract WeP is IWeP, ERC20, ERC20Burnable, AccessControl, ERC20Permit, ERC20Votes {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address defaultAdmin_, address minter_)
        ERC20("WeP", "WeP")
        ERC20Permit("WeP")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin_);
        _grantRole(MINTER_ROLE, minter_);
    }

    function mint(address to_, uint256 amount_) public onlyRole(MINTER_ROLE) {
        _mint(to_, amount_);
    }

    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    // The following functions are overrides required by Solidity.

    function _update(address from_, address to_, uint256 value_)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from_, to_, value_);
    }

    function nonces(address owner_)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner_);
    }
}
