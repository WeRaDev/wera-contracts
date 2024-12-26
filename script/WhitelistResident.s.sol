// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {Script, console} from "forge-std/Script.sol";

import {NFTMinter} from "../src/token/NFTMinter.sol";

contract DeployNFTMinter is Script {
    address nftMinter = 0x7202eCFD5A7c38425308874673ff7E0d6D8367C1;
    address resident = address(0); // TODO put correct address here

    function run() public {
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        vm.startBroadcast(adminPrivateKey);

        NFTMinter minter = NFTMinter(nftMinter);

        bool approve = true;
        minter.proposeAddUser(resident);
        minter.decideOnProposal(resident, NFTMinter.ProposalType.AddUser, approve);

        console.log("Address whitelisted:", resident);

        vm.stopBroadcast();
    }
}
