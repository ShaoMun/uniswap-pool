// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MockToken.sol";
import "../src/SimplePool.sol";

/**
 * @title DeployThreeTokenPools
 * @notice Deploy 3 tokens (ETH, USDT, EURC) and create 2 pools: ETH/USDT and EURC/USDT
 */
contract DeployThreeTokenPools is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        vm.startBroadcast(pk);

        // Deploy 3 tokens
        MockToken ethToken = new MockToken("Ethereum", "ETH");
        MockToken usdtToken = new MockToken("Tether", "USDT");
        MockToken eurcToken = new MockToken("Euro Coin", "EURC");

        console.log("ETH Token:", address(ethToken));
        console.log("USDT Token:", address(usdtToken));
        console.log("EURC Token:", address(eurcToken));

        // Create pools (token0 must have lower address than token1)
        // Pool 1: ETH/USDT
        SimplePool poolETH_USDT = address(ethToken) < address(usdtToken)
            ? new SimplePool(ethToken, usdtToken)
            : new SimplePool(usdtToken, ethToken);
        console.log("\nETH/USDT Pool:", address(poolETH_USDT));

        // Pool 2: EURC/USDT
        SimplePool poolEURC_USDT = address(eurcToken) < address(usdtToken)
            ? new SimplePool(eurcToken, usdtToken)
            : new SimplePool(usdtToken, eurcToken);
        console.log("EURC/USDT Pool:", address(poolEURC_USDT));

        // Mint tokens to deployer
        ethToken.faucet(deployer, 1000000 * 1e18);
        usdtToken.faucet(deployer, 1000000 * 1e18);
        eurcToken.faucet(deployer, 1000000 * 1e18);

        // Approve pools
        ethToken.approve(address(poolETH_USDT), type(uint256).max);
        usdtToken.approve(address(poolETH_USDT), type(uint256).max);
        eurcToken.approve(address(poolEURC_USDT), type(uint256).max);
        usdtToken.approve(address(poolEURC_USDT), type(uint256).max);

        // Add liquidity to ETH/USDT pool
        console.log("\n=== Adding Liquidity: ETH/USDT ===");
        (uint256 amt0, uint256 amt1, uint256 liq) = poolETH_USDT.addLiquidity(100000 * 1e18, 100000 * 1e18);
        console.log("Amount0 added:", amt0);
        console.log("Amount1 added:", amt1);
        console.log("LP Tokens:", liq);

        // Add liquidity to EURC/USDT pool
        console.log("\n=== Adding Liquidity: EURC/USDT ===");
        (amt0, amt1, liq) = poolEURC_USDT.addLiquidity(100000 * 1e18, 100000 * 1e18);
        console.log("Amount0 added:", amt0);
        console.log("Amount1 added:", amt1);
        console.log("LP Tokens:", liq);

        // Test swap: ETH -> USDT
        console.log("\n=== Testing Swap: ETH -> USDT ===");
        (uint256 amount0Out, uint256 amount1Out) = poolETH_USDT.swap(1000 * 1e18, 0, 0, 0, deployer);
        console.log("Swapped 1000 ETH for", amount0Out > 0 ? amount0Out : amount1Out, "USDT");

        vm.stopBroadcast();

        console.log("\n=== SAVE THESE ADDRESSES ===");
        console.log("TOKEN_ETH=%s", address(ethToken));
        console.log("TOKEN_USDT=%s", address(usdtToken));
        console.log("TOKEN_EURC=%s", address(eurcToken));
        console.log("POOL_ETH_USDT=%s", address(poolETH_USDT));
        console.log("POOL_EURC_USDT=%s", address(poolEURC_USDT));
    }
}
