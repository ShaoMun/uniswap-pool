// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MockToken.sol";
import "../src/SimplePool.sol";

/**
 * @title CreatePoolETH_EURC
 * @notice Create ETH/EURC pool and add liquidity
 */
contract CreatePoolETH_EURC is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        // Existing tokens
        address ethToken = 0x715f70ef11A65b4c8A7CCAa32E8aAaeE5011F15e;
        address eurcToken = 0x326c5d56646A513151c75DFa5923eF6875dE53d5;

        MockToken eth = MockToken(ethToken);
        MockToken eurc = MockToken(eurcToken);

        vm.startBroadcast(pk);

        // Create pool (token0 must have lower address than token1)
        SimplePool poolETH_EURC = ethToken < eurcToken
            ? new SimplePool(eth, eurc)
            : new SimplePool(eurc, eth);

        console.log("ETH/EURC Pool:", address(poolETH_EURC));

        // Approve pool
        eth.approve(address(poolETH_EURC), type(uint256).max);
        eurc.approve(address(poolETH_EURC), type(uint256).max);

        // Add liquidity
        console.log("\n=== Adding Liquidity: ETH/EURC ===");
        (uint256 amt0, uint256 amt1, uint256 liq) = poolETH_EURC.addLiquidity(100000 * 1e18, 100000 * 1e18);
        console.log("Amount0 added:", amt0);
        console.log("Amount1 added:", amt1);
        console.log("LP Tokens:", liq);

        // Test swap
        console.log("\n=== Testing Swap: ETH -> EURC ===");
        (uint256 amount0Out, uint256 amount1Out) = poolETH_EURC.swap(1000 * 1e18, 0, 0, 0, deployer);
        console.log("Swapped 1000 ETH for", amount0Out > 0 ? amount0Out : amount1Out, "EURC");

        vm.stopBroadcast();

        console.log("\n=== SAVE THIS ADDRESS ===");
        console.log("POOL_ETH_EURC=%s", address(poolETH_EURC));
    }
}
