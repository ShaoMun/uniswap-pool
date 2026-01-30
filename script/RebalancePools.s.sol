// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MockToken.sol";
import "../src/CrossChainPool.sol";

/**
 * @title RebalancePools
 * @notice Rebalance pools to realistic exchange rates
 *
 * Target Rates:
 * - 1 ETH = 2,733.72 USDT
 * - 1 ETH = 2,296.99 EUR
 * - 1 USDT = 0.84 EUR
 */
contract RebalancePools is Script {
    // Token addresses (same on all chains)
    address constant TOKEN_ETH = 0x7150257b0c582acF77F2e3B9A3D4FCf7b662e4c7;
    address constant TOKEN_USDT = 0xC71e691B5E5d9d84E72a0dc70B503Aba21dadB18;
    address constant TOKEN_EURC = 0x1b90Cc8d04911C038c13e2b03f1B31650B8b5965;

    // Pool addresses (same on all chains)
    address constant POOL_ETH_USDT = 0x4be8ed579a195B6ffb65AC1C378cD01363b39DE9;
    address constant POOL_EURC_USDT = 0xc763354f1A7586ca9893CCa33C464AF84f6f0aa8;
    address constant POOL_ETH_EURC = 0xb7B369236F78C6B952A8c643753ed259041aa1b4;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n=== REBALANCING POOLS ===");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);

        MockToken tokenETH = MockToken(TOKEN_ETH);
        MockToken tokenUSDT = MockToken(TOKEN_USDT);
        MockToken tokenEURC = MockToken(TOKEN_EURC);

        CrossChainPool poolETH_USDT = CrossChainPool(POOL_ETH_USDT);
        CrossChainPool poolEURC_USDT = CrossChainPool(POOL_EURC_USDT);
        CrossChainPool poolETH_EURC = CrossChainPool(POOL_ETH_EURC);

        vm.startBroadcast(deployerPrivateKey);

        // Mint additional tokens needed for realistic rates
        console.log("\n--- Minting Additional Tokens ---");
        tokenETH.mint(500000 * 1e18);  // 500k more ETH
        tokenUSDT.mint(1500000 * 1e18);  // 1.5M more USDT
        tokenEURC.mint(500000 * 1e18);  // 500k more EURC
        console.log("Minted additional tokens");

        // === Remove existing liquidity ===
        console.log("\n--- Removing Existing Liquidity ---");

        uint256 liquidityETH_USDT = poolETH_USDT.balanceOf(deployer);
        uint256 liquidityEURC_USDT = poolEURC_USDT.balanceOf(deployer);
        uint256 liquidityETH_EURC = poolETH_EURC.balanceOf(deployer);

        console.log("ETH/USDT LP tokens:", liquidityETH_USDT);
        console.log("EURC/USDT LP tokens:", liquidityEURC_USDT);
        console.log("ETH/EURC LP tokens:", liquidityETH_EURC);

        if (liquidityETH_USDT > 0) {
            poolETH_USDT.removeLiquidity(liquidityETH_USDT);
            console.log("Removed ETH/USDT liquidity");
        }

        if (liquidityEURC_USDT > 0) {
            poolEURC_USDT.removeLiquidity(liquidityEURC_USDT);
            console.log("Removed EURC/USDT liquidity");
        }

        if (liquidityETH_EURC > 0) {
            poolETH_EURC.removeLiquidity(liquidityETH_EURC);
            console.log("Removed ETH/EURC liquidity");
        }

        // === Add new liquidity with realistic rates ===
        console.log("\n--- Adding New Liquidity ---");

        // Target rates:
        // 1 ETH = 2,733.72 USDT
        // 1 ETH = 2,296.99 EUR
        // 1 USDT = 0.84 EUR

        // ETH/USDT Pool: For 100 ETH, we need 273,372 USDT
        uint256 ethAmount = 100 * 1e18;
        uint256 usdtAmountForEth = 273372 * 1e18;  // 273,372 USDT for 100 ETH

        tokenETH.approve(POOL_ETH_USDT, type(uint256).max);
        tokenUSDT.approve(POOL_ETH_USDT, type(uint256).max);
        poolETH_USDT.addLiquidity(ethAmount, usdtAmountForEth);
        console.log("Added ETH/USDT: 100 ETH / 273,372 USDT");

        // EURC/USDT Pool: For 100,000 EURC, we need 84,000 USDT
        uint256 eurcAmount = 100000 * 1e18;
        uint256 usdtAmountForEurc = 84000 * 1e18;  // 84,000 USDT for 100,000 EURC

        tokenEURC.approve(POOL_EURC_USDT, type(uint256).max);
        tokenUSDT.approve(POOL_EURC_USDT, type(uint256).max);
        poolEURC_USDT.addLiquidity(eurcAmount, usdtAmountForEurc);
        console.log("Added EURC/USDT: 100,000 EURC / 84,000 USDT");

        // ETH/EURC Pool: For 100 ETH, we need 229,699 EURC
        tokenETH.approve(POOL_ETH_EURC, type(uint256).max);
        tokenEURC.approve(POOL_ETH_EURC, type(uint256).max);
        uint256 eurcAmountForEth = 229699 * 1e18;  // 229,699 EURC for 100 ETH
        poolETH_EURC.addLiquidity(eurcAmountForEth, ethAmount);
        console.log("Added ETH/EURC: 229,699 EURC / 100 ETH");

        vm.stopBroadcast();

        // === Display new rates ===
        console.log("\n=== NEW POOL RATES ===");

        uint256 reserve0_ETH_USDT = poolETH_USDT.reserve0();
        uint256 reserve1_ETH_USDT = poolETH_USDT.reserve1();
        console.log("\nETH/USDT Pool:");
        console.log("  ETH:", reserve0_ETH_USDT / 1e18);
        console.log("  USDT:", reserve1_ETH_USDT / 1e18);
        console.log("  Rate: 1 ETH =", (reserve1_ETH_USDT * 1e18 / reserve0_ETH_USDT) / 1e18, "USDT");

        uint256 reserve0_EURC_USDT = poolEURC_USDT.reserve0();
        uint256 reserve1_EURC_USDT = poolEURC_USDT.reserve1();
        console.log("\nEURC/USDT Pool:");
        console.log("  EURC:", reserve0_EURC_USDT / 1e18);
        console.log("  USDT:", reserve1_EURC_USDT / 1e18);
        console.log("  Rate: 1 EURC =", (reserve1_EURC_USDT * 1e18 / reserve0_EURC_USDT) / 1e18, "USDT");

        uint256 reserve0_ETH_EURC = poolETH_EURC.reserve0();
        uint256 reserve1_ETH_EURC = poolETH_EURC.reserve1();
        console.log("\nETH/EURC Pool:");
        console.log("  EURC:", reserve0_ETH_EURC / 1e18);
        console.log("  ETH:", reserve1_ETH_EURC / 1e18);
        console.log("  Rate: 1 ETH =", (reserve0_ETH_EURC * 1e18 / reserve1_ETH_EURC) / 1e18, "EURC");

        console.log("\n=== REBALANCING COMPLETE ===");
    }
}
