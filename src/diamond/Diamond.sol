// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "./interfaces/IDiamondLoupe.sol";
import { IERC165 } from "./interfaces/IERC165.sol";

import { IWeRaStakingFacet } from "../staking/interfaces/IWeRaStakingFacet.sol";

contract Diamond {
    constructor(
        address _diamondOwner,
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _weRaStakingFacet
    ) payable {
        LibDiamond.setContractOwner(_diamondOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);

        // Diamond Cut Facet
        bytes4[] memory cutFacetSelectors = new bytes4[](1);
        cutFacetSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: cutFacetSelectors
        });

        // Diamond Loupe Facet
        bytes4[] memory loupeFacetSelectors = new bytes4[](5);
        loupeFacetSelectors[0] = IDiamondLoupe.facets.selector;
        loupeFacetSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        loupeFacetSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        loupeFacetSelectors[3] = IDiamondLoupe.facetAddress.selector;
        loupeFacetSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeFacetSelectors
        });

        // WeRaStaking Facet
        bytes4[] memory weRaStakingFacetSelectors = new bytes4[](10);
        weRaStakingFacetSelectors[0] = IWeRaStakingFacet.initialize.selector;
        weRaStakingFacetSelectors[1] = IWeRaStakingFacet.stakeFor.selector;
        weRaStakingFacetSelectors[2] = IWeRaStakingFacet.stake.selector;
        weRaStakingFacetSelectors[3] = IWeRaStakingFacet.unstake.selector;
        weRaStakingFacetSelectors[4] = IWeRaStakingFacet.addStakeToken.selector;
        weRaStakingFacetSelectors[5] = IWeRaStakingFacet.getTokenBalance.selector;
        weRaStakingFacetSelectors[6] = IWeRaStakingFacet.getTokenTotalBalance.selector;
        weRaStakingFacetSelectors[7] = IWeRaStakingFacet.stakeTokensLength.selector;
        weRaStakingFacetSelectors[8] = IWeRaStakingFacet.stakeTokensAt.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: _weRaStakingFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: weRaStakingFacetSelectors
        });

        LibDiamond.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {}
}
