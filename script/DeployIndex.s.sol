// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/IndexRegistry.sol";

contract DeployIndex is Script {

    function run() external {

        uint256 privateKey =
            vm.envUint("PRIVATE_KEY");

        address registryAddress =
            vm.envAddress("INDEX_REGISTRY");

        address nvda =
            vm.envAddress("NVDA");

        address aapl =
            vm.envAddress("AAPL");

        address msft =
            vm.envAddress("MSFT");

        address amzn =
            vm.envAddress("AMZN");

        address googl =
            vm.envAddress("GOOGL");

        vm.startBroadcast(privateKey);

        IndexRegistry registry =
            IndexRegistry(registryAddress);

        bytes32 indexId =
            keccak256(
                abi.encodePacked("TECH100")
            );

        registry.createIndex(
            indexId,
            "TECH100"
        );

        registry.addComponent(
            indexId,
            nvda,
            2500
        );

        registry.addComponent(
            indexId,
            aapl,
            2000
        );

        registry.addComponent(
            indexId,
            msft,
            2000
        );

        registry.addComponent(
            indexId,
            amzn,
            2000
        );

        registry.addComponent(
            indexId,
            googl,
            1500
        );

        vm.stopBroadcast();
    }
}
