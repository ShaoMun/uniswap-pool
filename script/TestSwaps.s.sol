// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MockToken.sol";
import "../src/SimplePool.sol";

/**
 * @title TestSwaps
 * @notice Test swaps on both pools
 */
contract TestSwaps is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        // Token addresses from deployment
        address ethToken = 0x715f70ef11A65b4c8A7CCAa32E8aAaeE5011F15e;
        address usdtToken = 0xa3750d39Fa8c377a7FB87FD1F2Be4321722E2c58;
        address eURcToken = 0x326c5d56646A513151c75DFa5923eF6875dE53d5;

        // Pool addresses
        address poolETH_USDT = 0xD8abab3a58b8c5F9d888dE55ab5EaCAB7C875340;
        address poolEURC_USDT = 0x7f8Ac573Eb95b79e422a77FD01386afbB8e265bc;

        MockToken eth = MockToken(ethToken);
        MockToken usdt = MockToken(usdtToken);
        MockToken eurc = MockToken(eURcToken);

        SimplePool pool1 = SimplePool(poolETH_USDT);
        SimplePool pool2 = SimplePool(poolEURC_USDT);

        console.log("\n=== Testing Swaps ===");

        // Test 1: Swap ETH -> USDT
        console.log("\n--- Test 1: Swap 1000 ETH -> USDT ---");
        testSwap(deployer, pk, eth, usdt, pool1, "ETH", "USDT", 1000 * 1e18);

        // Test 2: Swap USDT -> EURC
        console.log("\n--- Test 2: Swap 1000 USDT -> EURC ---");
        testSwap(deployer, pk, usdt, eurc, pool2, "USDT", "EURC", 1000 * 1e18);

        // Test 3: Reverse swap EURC -> USDT
        console.log("\n--- Test 3: Swap 500 EURC -> USDT (reverse) ---");
        testSwap(deployer, pk, eurc, usdt, pool2, "EURC", "USDT", 500 * 1e18);

        // Test 4: Reverse swap USDT -> ETH
        console.log("\n--- Test 4: Swap 50 USDT -> ETH (reverse) ---");
        testSwap(deployer, pk, usdt, eth, pool1, "USDT", "ETH", 50 * 1e18);

        console.log("\n=== All Swaps Completed Successfully! ===");

        // Show final balances
        uint256 ethBal = eth.balanceOf(deployer);
        uint256 usdtBal = usdt.balanceOf(deployer);
        uint256 eurcBal = eurc.balanceOf(deployer);

        console.log("\n=== Final Balances ===");
        console.log("ETH:", ethBal);
        console.log("USDT:", usdtBal);
        console.log("EURC:", eurcBal);
    }

    function testSwap(
        address deployer,
        uint256 privateKey,
        MockToken tokenIn,
        MockToken tokenOut,
        SimplePool pool,
        string memory nameIn,
        string memory nameOut,
        uint256 amount
    ) internal {
        uint256 balanceBefore = tokenOut.balanceOf(deployer);
        console.log(nameOut, "balance before:", balanceBefore);

        vm.startBroadcast(privateKey);

        tokenIn.approve(address(pool), amount);

        // Determine which token is which for the swap call
        address poolToken0 = address(pool.token0());
        bool zeroForOne = address(tokenIn) == poolToken0;

        (uint256 amount0Out, uint256 amount1Out) = pool.swap(
            zeroForOne ? amount : 0,
            zeroForOne ? 0 : amount,
            0, // amount0OutMinimum
            0, // amount1OutMinimum
            deployer
        );

        vm.stopBroadcast();

        uint256 balanceAfter = tokenOut.balanceOf(deployer);
        uint256 received = balanceAfter - balanceBefore;
        uint256 sent = zeroForOne ? amount1Out : amount0Out;

        console.log(nameIn, "sent:", amount);
        console.log(nameOut, "received:", received);
    }
}
