// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGTXRouter} from "../src/interfaces/IGTXRouter.sol";
import {IPoolManager} from "../src/interfaces/IPoolManager.sol";
import {IBalanceManager} from "../src/interfaces/IBalanceManager.sol";
import {PoolKey, Price, Quantity, Side, OrderId, Currency} from "../src/types/types.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {MockWETH} from "../src/mocks/MockWETH.sol";

contract CLOBTest is Test {
    IGTXRouter public router;
    IPoolManager private poolManager;
    IBalanceManager private balanceManager;
    Currency private weth;
    Currency private usdc;
    MockUSDC private mockUSDC;
    MockWETH private mockWETH;

    address private user = makeAddr("user");

    uint256 private initialBalanceUSDC = 100_000_000_000;
    uint256 private initialBalanceWETH = 10 ether;

    function setUp() public {
        vm.createSelectFork("https://testnet.riselabs.xyz", 5205643);
        router = IGTXRouter(
            address(0xed2582315b355ad0FFdF4928Ca353773c9a588e3)
        );

        mockUSDC = new MockUSDC();
        mockWETH = new MockWETH();

        balanceManager = IBalanceManager(
            address(0x9B4fD469B6236c27190749bFE3227b85c25462D7)
        );

        poolManager = IPoolManager(
            address(0x9B4fD469B6236c27190749bFE3227b85c25462D7)
        );

        mockUSDC.mint(user, initialBalanceUSDC);
        mockWETH.mint(user, initialBalanceWETH);
        usdc = Currency.wrap(address(mockUSDC));
        weth = Currency.wrap(address(mockWETH));
    }

    function test_CLOB() public {
        uint256 depositAmount = 4 ether;
        vm.startPrank(user);
        IERC20(Currency.unwrap(weth)).approve(
            address(balanceManager),
            depositAmount
        );
        balanceManager.deposit(weth, depositAmount);
        // PoolKey memory key = PoolKey(
        //     address(0x7FB2a815Fa88c2096960999EC8371BccDF147874),
        //     address(0x02950119C4CCD1993f7938A55B8Ab8384C3CcE4F)
        // );
        // IPoolManager.Pool memory pool = poolManager.getPool(key);
        // Price price = Price.wrap(100);
        // Quantity quantity = Quantity.wrap(100);
        // Side side = Side.BUY;
        // OrderId orderId = router.placeOrder(key, price, quantity, side);
        // (uint48 orderCount, uint256 totalVolume) = router.getOrderQueue(
        //     key,
        //     side,
        //     price
        // );

        // console.log("Order Count:", orderCount);
        // console.log("Total Volume:", totalVolume);
        // assertEq(orderCount, 1);
        // assertEq(totalVolume, Quantity.unwrap(quantity));

        // // Check the balance and locked balance from the balance manager
        // uint256 balance = balanceManager.getBalance(user, weth);
        // uint256 lockedBalance = balanceManager.getLockedBalance(
        //     user,
        //     address(pool.orderBook),
        //     weth
        // );

        // console.log("User Balance:", balance);
        // console.log("User Locked Balance:", lockedBalance);
        // console.log("Order placed with ID:", OrderId.unwrap(orderId));
    }
}
