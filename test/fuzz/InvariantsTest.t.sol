// SPDX-License-Identifier: MIT
// invariants or properties??

// 1. The total supply of DSC should be less than the total value of collateral
// 2. Getter view functions should never revert <- evergreen invariant

pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {StdInvariant} from "../../lib/forge-std/src/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantsTest is StdInvariant, Test {
    DSCEngine engine;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address wETH;
    address wBTC;
    Handler handler;

    function setUp() public {
        DeployDSC deployer = new DeployDSC();
        (engine, dsc, config) = deployer.run();
        (,,wETH,wBTC,) = config.activeNetworkConfig();
        // targetContract(address(engine));
        handler = new Handler(engine, dsc);
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = dsc.totalSupply();

        uint256 totalwETHDeposited = IERC20(wETH).balanceOf(address(engine));
        uint256 totalwBTCDeposited = IERC20(wBTC).balanceOf(address(engine));

        uint256 wETHValue = engine.getUSDValue(wETH, totalwETHDeposited);
        uint256 wBTCValue = engine.getUSDValue(wBTC, totalwBTCDeposited);

        assert(wETHValue + wBTCValue >= totalSupply);
        console.log("total supply: ",totalSupply);
        console.log("mint called: ",handler.timesMintCalled());
    }

    // function invariant_gettersShouldNotRevert() public view{

    // }
    // future scope
}
