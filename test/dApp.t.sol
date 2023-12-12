// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {dApp} from "../src/dApp.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
contract DappTest is Test {
    dApp public dapp;
    address constant USDCE = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;
    address constant PSM = 0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5;
    address constant WETH9 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    address constant PORTAL = 0x24b7d3034C711497c81ed5f70BEE2280907Ea1Fa;

    address constant alice = address(0x11111555);

    function setUp() public {
        dapp = new dApp();
        deal(PSM, alice, 2e23);
    }
    function test_getPrice() public {
        (uint256 profitARB, uint256 totalARB, uint256 worthARB) = dapp.checkARB(100);
        console2.log("ARB: $", profitARB/10**18);
        console2.log("ARB: $", totalARB/10**18);
        console2.log("ARB: $", worthARB/10**18);
        (uint256 profitUSDCE, uint256 totalUSDCE, uint256 worthUSDCE) = dapp.checkUSDCE(90);
        console2.log("USDCE: $", profitUSDCE/10**18);  
        console2.log("USDCE: $", totalUSDCE/10**18);
        console2.log("USDCE: $", worthUSDCE/10**18); 
    }
    function testrevert_owner() public {
        vm.startPrank(alice);
        vm.expectRevert();
        dapp.changeOwner(alice);
    }
    function test_USDC() public {
        uint256 balanceThis = address(this).balance;
        uint256 balanceAlice = address(alice).balance;
        vm.startPrank(alice);
        IERC20(PSM).approve(address(dapp), 1e23);
        dapp.convertUSDCE(80,5);
        console2.log(IERC20(WETH9).balanceOf(address(this)));   
        console2.log("this", address(this).balance-balanceThis);
        console2.log("alice", address(alice).balance-balanceAlice);    
        console2.log(address(dapp).balance); 
    }
    function test_ARB() public {
        uint256 balance = address(this).balance;
        vm.startPrank(alice);
        IERC20(PSM).approve(address(dapp), 1e23);
        dapp.convertARB(100, 6);
        console2.log(IERC20(WETH9).balanceOf(address(this))); 
        console2.log(address(this).balance-balance);
        console2.log(address(alice).balance);   
    }
    // function test_USDC1() public {
    //     vm.startPrank(alice);
    //     IERC20(PSM).approve(address(dapp), 100_000e18);
    //     dapp.convertUSDCE(50,1);
    //     console2.log("````````````````````````````````````````````");
    //     console2.log(IERC20(USDCE).balanceOf(address(this)));
    //     console2.log(IERC20(USDCE).balanceOf(address(alice)));
    //     console2.log(IERC20(USDCE).balanceOf(address(dapp)));
    //     console2.log(IERC20(USDCE).balanceOf(address(PORTAL)));
    // }
    // function test_USDC2() public {
    //     vm.startPrank(alice);
    //     IERC20(PSM).approve(address(dapp), 100_000e18);
    //     dapp.convertUSDCE(80,80);
    //     console2.log("````````````````````````````````````````````");
    //     console2.log(IERC20(USDCE).balanceOf(address(this)));
    //     console2.log(IERC20(USDCE).balanceOf(address(alice)));
    //     console2.log(IERC20(USDCE).balanceOf(address(dapp)));
    //     console2.log(IERC20(USDCE).balanceOf(address(PORTAL)));
    // }
    // function test_USDC3() public {
    //     vm.startPrank(alice);
    //     IERC20(PSM).approve(address(dapp), 100_000e18);
    //     dapp.convertUSDCE(150,2);
    //     console2.log("````````````````````````````````````````````");
    //     console2.log(IERC20(USDCE).balanceOf(address(this)));
    //     console2.log(IERC20(USDCE).balanceOf(address(alice)));
    //     console2.log(IERC20(USDCE).balanceOf(address(dapp)));
    //     console2.log(IERC20(USDCE).balanceOf(address(PORTAL)));
    // }
    // function test_ARB1() public {
    //     vm.startPrank(alice);
    //     IERC20(PSM).approve(address(dapp), 100_000e18);
    //     dapp.convertARB(50, 1);
    //     console2.log("````````````````````````````````````````````");
    //     console2.log(IERC20(ARB).balanceOf(address(this)));
    //     console2.log(IERC20(ARB).balanceOf(address(alice)));
    //     console2.log(IERC20(ARB).balanceOf(address(dapp)));
    //     console2.log(IERC20(ARB).balanceOf(address(PORTAL)));
    // }
    // function test_ARB2() public {
    //     vm.startPrank(alice);
    //     IERC20(PSM).approve(address(dapp), 100_000e18);
    //     dapp.convertARB(50, 50);
    //     console2.log("````````````````````````````````````````````");
    //     console2.log(IERC20(ARB).balanceOf(address(this)));
    //     console2.log(IERC20(ARB).balanceOf(address(alice)));
    //     console2.log(IERC20(ARB).balanceOf(address(dapp)));
    //     console2.log(IERC20(ARB).balanceOf(address(PORTAL)));
    // }
    // function test_ARB3() public {
    //     vm.startPrank(alice);
    //     IERC20(PSM).approve(address(dapp), 100_000e18);
    //     dapp.convertARB(150, 2);
    //     console2.log("````````````````````````````````````````````");
    //     console2.log(IERC20(ARB).balanceOf(address(this)));
    //     console2.log(IERC20(ARB).balanceOf(address(alice)));
    //     console2.log(IERC20(ARB).balanceOf(address(dapp)));
    //     console2.log(IERC20(ARB).balanceOf(address(PORTAL)));
    // }
    receive() external payable {}
}
