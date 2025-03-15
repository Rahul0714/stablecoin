// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {ERC20Mock} from "../../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
// import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract Handler is Test {

    DSCEngine engine;
    DecentralizedStableCoin dsc;
    
    ERC20Mock wETH;
    ERC20Mock wBTC;

    uint256 private constant MAX_DEPOSIT_SIZE = type(uint96).max; 
    uint256 public timesMintCalled = 0;
    // MockV3Aggregator public  not necessary just seen

    address[] public usersCollateralDeposited;

    constructor(DSCEngine _engine, DecentralizedStableCoin _dsc) {
        engine = _engine;
        dsc = _dsc;
        address[] memory collateralAddresses = engine.getCollateralTokens();
        wETH = ERC20Mock(collateralAddresses[0]);
        wBTC = ERC20Mock(collateralAddresses[1]);
    }
    function mint(uint256 amount, uint256 userSeed) public {

        if(usersCollateralDeposited.length == 0) {
            return;
        }
        address user = usersCollateralDeposited[userSeed % usersCollateralDeposited.length];


        (uint256 totalDSCMinted, uint256 collateralValueInUSD) = engine.getAccountInformation(user);
        int256 maxDSCToMint = (int256(collateralValueInUSD)/2) - int256(totalDSCMinted);
        if(maxDSCToMint < 0) {
            return;
        }
        amount= bound(amount, 0, uint256(maxDSCToMint));
        if(amount == 0) {
            return;
        }
        vm.startPrank(user);
        engine.mintDSC(amount);
        vm.stopPrank();
        timesMintCalled++;
    }
    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);
        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(engine), amountCollateral);
        engine.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
        usersCollateralDeposited.push(msg.sender);
    }
    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralBalance = engine.getCollateralBalanceOfUser(msg.sender, address(collateral));
        amountCollateral = bound(amountCollateral, 0, maxCollateralBalance);
        if(amountCollateral == 0) {
            return;
        }
        engine.redeemCollateral(address(collateral), amountCollateral);
    }
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns(ERC20Mock) {
        if(collateralSeed % 2 == 0) {
            return wETH;
        } 
        return wBTC;
    }
}