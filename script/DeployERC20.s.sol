// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {TokenMock} from "../src/test/TokenMock.sol";

contract DeployNFTMinter is Script {
    string name = "Test Wrapped Ether";
    string symbol = "WETH";
    uint256 supply = 21000000 * 1e18;
    uint8 decimals = 18;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        TokenMock erc20 = new TokenMock(name, symbol, supply, decimals);

        console.log("ERC20 Token deployed at:", address(erc20));

        // optional: transfer newly created token to other accounts:
        // testWETH.transfer(account1, 1000e18);
        // testWETH.transfer(account2, 1000e18);

        vm.stopBroadcast();
    }
}
