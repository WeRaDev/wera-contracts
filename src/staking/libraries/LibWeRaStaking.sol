// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IWeRaStakingFacet} from "../interfaces/IWeRaStakingFacet.sol";

/// @title WeRaStaking library
library LibWeRaStaking {
    bytes32 internal constant WERA_STAKING_STORAGE_SLOT = keccak256("WERA.STAKING.STORAGE");

    // ========= STORAGE ========= //

    struct WeRaStakingStorage {
        bool initialized;
        /// WeRa Token, minted and burned based on staking contracts
        address weRaToken;
        EnumerableSet.AddressSet stakeTokens;
        mapping(address => IWeRaStakingFacet.StakeBalance) stakeBalances;
    }

    function getStorage() internal pure returns (WeRaStakingStorage storage s) {
        bytes32 position = WERA_STAKING_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}
