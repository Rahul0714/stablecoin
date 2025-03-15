// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "../../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DSCEngine engine;
    DecentralizedStableCoin dsc;
    HelperConfig config;

    address wETHPriceFeed;
    address wBTCPriceFeed;
    address wETH;

    address private USER = makeAddr("User");
    uint256 private constant AMOUNT_COLLATERAL = 10 ether;
    uint256 private constant STARTING_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (engine, dsc, config) = deployer.run();
        (wETHPriceFeed, wBTCPriceFeed, wETH, , ) = config.activeNetworkConfig();

        ERC20Mock(wETH).mint(USER, STARTING_BALANCE);
    }
    address[] private tokenAddresses;
    address[] private priceFeedAddresses;

    function testRevertsIfTokenLengthDoesNotMatchPriceFeeds() public {
        tokenAddresses.push(wETH);
        priceFeedAddresses.push(wETHPriceFeed);
        priceFeedAddresses.push(wBTCPriceFeed);
        
        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSame.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }
    function testGetUSDValue() public view{
        uint256 ethAmount = 15e18;
        uint256 exptectedUSD = 30000e18;
        uint256 actualUSD = engine.getUSDValue(wETH, ethAmount);
        assertEq(exptectedUSD, actualUSD);
    }
    function testGetTokenAmountInUSD() public view{
        uint256 USDAmount = 1000 ether;
        uint256 expectedwETH = 0.5 ether;
        uint256 actualwETH = engine.getTokenAmountFromUSD(wETH, USDAmount);
        assertEq(expectedwETH, actualwETH);
    }

    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(wETH).approve(address(engine), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__MustBeMoreThanZero.selector);
        engine.depositCollateral(wETH, 0);
        vm.stopPrank();
    }

    function testRevertsIfUnapprovedCollateral() public {
        ERC20Mock testToken = new ERC20Mock();
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        engine.depositCollateral(address(testToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }
    modifier depositedCollateral {
        vm.startPrank(USER);
        ERC20Mock(wETH).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(wETH, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }
    // function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
    //     (uint256 totalDSCMinted, uint256 collateralValueInUSD) = engine.getAccountInformation(USER);
    //     uint256 expectedTotalDSCMinted = 0;
    //     assertEq(totalDSCMinted, expectedTotalDSCMinted);
    //     uint256 expectedDepositAmount = engine.getTokenAmountFromUSD(wETH, collateralValueInUSD);
    //     assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    // }

}
