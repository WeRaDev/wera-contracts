// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {Script, console} from "forge-std/Script.sol";

import {Diamond} from "../src/diamond/Diamond.sol";
import {DiamondCutFacet} from "../src/diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/diamond/facets/DiamondLoupeFacet.sol";

import {WeP} from "../src/token/WeP.sol";
import {WeRaStakingFacet} from "../src/staking/facets/WeRaStakingFacet.sol";
import {IWeRaStakingFacet} from "../src/staking/interfaces/IWeRaStakingFacet.sol";

import {TokenMock} from "../src/test/TokenMock.sol";

contract DeployDiamond is Script {
    address diamondOwner = 0x85d4a79A07824fD59B25377E65c8f6969Fae073B;
    address wepAdmin = 0x85d4a79A07824fD59B25377E65c8f6969Fae073B;
    address stakingTokenManager = 0x85d4a79A07824fD59B25377E65c8f6969Fae073B;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ALICE_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        WeRaStakingFacet weRaStakingFacet = new WeRaStakingFacet();

        Diamond diamond = new Diamond(
            diamondOwner,
            address(diamondCutFacet),
            address(diamondLoupeFacet),
            address(weRaStakingFacet)
        );

        IWeRaStakingFacet staking = IWeRaStakingFacet(address(diamond));

        address wepMinter = address(staking);
        WeP wep = new WeP(wepAdmin, wepMinter);
        staking.initialize(stakingTokenManager, address(wep));

        // TokenMock testUSD = new TokenMock("Test USD", "TUSD", 1000e18, 18);
        // staking.addStakeToken(address(testUSD));
        //
        // testUSD.mint(diamondOwner, 100e18);

        vm.stopBroadcast();
    }
}
