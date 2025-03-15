// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDSC is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run()
        external
        returns (DSCEngine, DecentralizedStableCoin, HelperConfig)
    {
        HelperConfig config = new HelperConfig();

        (
            address wETHPriceFeed,
            address wBTCPriceFeed,
            address wETH,
            address wBTC,
            uint256 deployerKey
        ) = config.activeNetworkConfig();
        tokenAddresses = [wETH, wBTC];
        priceFeedAddresses = [wETHPriceFeed, wBTCPriceFeed];

        vm.startBroadcast(deployerKey);

        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        DSCEngine engine = new DSCEngine(
            tokenAddresses,
            priceFeedAddresses,
            address(dsc)
        );
        dsc.transferOwnership(address(engine));
        vm.stopBroadcast();
        return (engine, dsc, config);
    }
}
