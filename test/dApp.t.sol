// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Test, console2} from "forge-std/Test.sol";
import {dApp} from "../src/dApp.sol";

contract DappTest is Test {
    dApp public dapp;
    address constant USDCE = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;
    address constant PSM = 0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5;
    address constant PORTAL = 0x24b7d3034C711497c81ed5f70BEE2280907Ea1Fa;

    address alice = address(0x11111555);

    function setUp() public {
        dapp = new dApp();
    
    deal(PSM, alice, 200_000e18);
    deal(PSM, address(this), 200_000e18);
    }

    function test_USDC() public {
        console2.log(IERC20(PSM).balanceOf(address(alice)));
        console2.log(IERC20(PSM).balanceOf(address(PORTAL)));
        vm.startPrank(alice);
        IERC20(PSM).approve(address(dapp), 100_000e18);
        dapp.convertUSDCE(100, 1);
        console2.log("````````````````````````````````````````````");
        console2.log(IERC20(USDCE).balanceOf(address(this)));
        console2.log(IERC20(USDCE).balanceOf(address(alice)));
        console2.log(IERC20(USDCE).balanceOf(address(dapp)));
        console2.log(IERC20(USDCE).balanceOf(address(PORTAL)));
        console2.log(IERC20(PSM).balanceOf(address(alice)));
        console2.log(IERC20(PSM).balanceOf(address(dapp)));
        console2.log(IERC20(PSM).balanceOf(address(PORTAL)));
    }
    function test_ARB() public {
        console2.log(IERC20(PSM).balanceOf(address(alice)));
        console2.log(IERC20(PSM).balanceOf(address(PORTAL)));
        vm.startPrank(alice);
        IERC20(PSM).approve(address(dapp), 100_000e18);
        dapp.convertARB(50, 1);
        console2.log("````````````````````````````````````````````");
        console2.log(IERC20(ARB).balanceOf(address(this)));
        console2.log(IERC20(ARB).balanceOf(address(alice)));
        console2.log(IERC20(ARB).balanceOf(address(dapp)));
        console2.log(IERC20(ARB).balanceOf(address(PORTAL)));
        console2.log(IERC20(PSM).balanceOf(address(alice)));
        console2.log(IERC20(PSM).balanceOf(address(dapp)));
        console2.log(IERC20(PSM).balanceOf(address(PORTAL)));
    }
}
