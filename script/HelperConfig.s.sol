// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address wETHPriceFeed;
        address wBTCPriceFeed;
        address wETH;
        address wBTC;
        uint256 deployerKey;
    }

    uint8 public constant DECIMAL = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant BCT_USD_PRICE = 1000e8;
    uint256 private DEFAULT_ANVIL_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepliaETHConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilETHConfig();
        }
    }

    function getSepliaETHConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                wETHPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
                wBTCPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
                wETH: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
                wBTC: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
                deployerKey: vm.envUint("PRIVATE_KEY")
            });
    }

    function getOrCreateAnvilETHConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.wETHPriceFeed != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator ethUSDPriceFeed = new MockV3Aggregator(
            DECIMAL,
            ETH_USD_PRICE
        );

        ERC20Mock ethMock = new ERC20Mock();
        MockV3Aggregator btcUSDPriceFeed = new MockV3Aggregator(
            DECIMAL,
            BCT_USD_PRICE
        );
        ERC20Mock btcMock = new ERC20Mock();
        vm.stopBroadcast();
        return
            NetworkConfig({
                wETHPriceFeed: address(ethUSDPriceFeed),
                wBTCPriceFeed: address(btcUSDPriceFeed),
                wETH: address(ethMock),
                wBTC: address(btcMock),
                deployerKey: DEFAULT_ANVIL_KEY
            });
    }
}
