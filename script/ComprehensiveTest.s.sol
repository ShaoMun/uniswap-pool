// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MockToken.sol";
import "../src/CrossChainPool.sol";

/**
 * @title ComprehensiveTest
 * @notice Test swap, bridge, and cross-chain swap functionality
 *
 * Tests:
 * 1. Swap - Different currency, same chain
 * 2. Bridge - Same currency, different chain
 * 3. Cross-chain swap - Different currency, different chain
 */
contract ComprehensiveTest is Script {
    // Token addresses (v2 deployment)
    address constant TOKEN_ETH = 0xd33B31e46A8546a34Bd51403C39529fDD1d32334;
    address constant TOKEN_USDT = 0x85C805b1f1179cb41B41Fc900A74d2329b52a6D5;
    address constant TOKEN_EURC = 0x04f97dc5AE8b1CC5182cfF9F3d0aB2b172C07E42;

    // Pool addresses (v2 deployment)
    address constant POOL_ETH_USDT = 0x9ebeE6de9CcBf810313c73F21E3c448068BbB4FD;
    address constant POOL_EURC_USDT = 0x178D446bFCd5F01423Cbe2860131834a6d1F9979;
    address constant POOL_ETH_EURC = 0xb8E46b55979d36ea33FDE5acf455021b25E50d8C;

    // Chain IDs
    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ARB_SEPOLIA_CHAIN_ID = 421614;
    uint256 constant AMOY_CHAIN_ID = 80002;

    uint256 constant TEST_AMOUNT = 10 * 1e18; // 10 tokens

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        MockToken ethToken = MockToken(TOKEN_ETH);
        MockToken usdtToken = MockToken(TOKEN_USDT);
        CrossChainPool pool = CrossChainPool(POOL_ETH_USDT);

        console.log("\n========================================");
        console.log("   COMPREHENSIVE CROSS-CHAIN TEST     ");
        console.log("========================================");
        console.log("Chain ID:", block.chainid);
        console.log("Tester:", deployer);
        console.log("Pool:", POOL_ETH_USDT);

        uint256 ethBefore = ethToken.balanceOf(deployer);
        uint256 usdtBefore = usdtToken.balanceOf(deployer);
        uint256 poolReserve0Before = pool.reserve0();
        uint256 poolReserve1Before = pool.reserve1();

        console.log("\n=== BEFORE TEST ===");
        console.log("Your ETH:", ethBefore / 1e18);
        console.log("Your USDT:", usdtBefore / 1e18);
        console.log("Pool Reserve0 (USDT):", poolReserve0Before / 1e18);
        console.log("Pool Reserve1 (ETH):", poolReserve1Before / 1e18);

        vm.startBroadcast(pk);

        // ==================================================================
        // TEST 1: SWAP (Different Currency, Same Chain)
        // ==================================================================
        console.log("\n========================================");
        console.log("   TEST 1: SWAP (Same Chain)          ");
        console.log("========================================");
        console.log("Action: Swap 10 ETH -> USDT");

        ethToken.approve(POOL_ETH_USDT, TEST_AMOUNT);
        (uint256 amount0Out, uint256 amount1Out) = pool.swap(
            0,            // amount0In (USDT - none)
            TEST_AMOUNT,  // amount1In (ETH input)
            0,            // min amount0Out (none)
            0,            // min amount1Out (none)
            deployer      // recipient
        );

        console.log("Swapped:", TEST_AMOUNT / 1e18, "ETH");
        console.log("Received:", amount0Out / 1e18, "USDT");

        // ==================================================================
        // TEST 2: BRIDGE (Same Currency, Different Chain)
        // ==================================================================
        console.log("\n========================================");
        console.log("   TEST 2: BRIDGE (Cross-Chain)        ");
        console.log("========================================");

        uint256 destChainId;
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            destChainId = ARB_SEPOLIA_CHAIN_ID;
            console.log("Action: Bridge 5 ETH from Sepolia -> Arbitrum Sepolia");
        } else if (block.chainid == ARB_SEPOLIA_CHAIN_ID) {
            destChainId = SEPOLIA_CHAIN_ID;
            console.log("Action: Bridge 5 ETH from Arbitrum Sepolia -> Sepolia");
        } else {
            destChainId = SEPOLIA_CHAIN_ID;
            console.log("Action: Bridge 5 ETH from Polygon Amoy -> Sepolia");
        }

        uint256 bridgeAmount = 5 * 1e18;
        ethToken.approve(POOL_ETH_USDT, bridgeAmount);
        pool.crossChainTransfer(destChainId, deployer, bridgeAmount, 0);

        console.log("Bridged:", bridgeAmount / 1e18, "ETH to chain", destChainId);
        console.log("\nNOTE: To complete the bridge, run 'completeBridge' on destination chain");

        // ==================================================================
        // TEST 3: CROSS-CHAIN SWAP (Different Currency, Different Chain)
        // ==================================================================
        console.log("\n========================================");
        console.log("   TEST 3: CROSS-CHAIN SWAP            ");
        console.log("========================================");

        uint256 crossChainAmount = 3 * 1e18;
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            console.log("Action: Swap 3 ETH -> USDT from Sepolia -> Arbitrum Sepolia");
        } else if (block.chainid == ARB_SEPOLIA_CHAIN_ID) {
            console.log("Action: Swap 3 ETH -> USDT from Arbitrum Sepolia -> Sepolia");
        } else {
            console.log("Action: Swap 3 ETH -> USDT from Polygon Amoy -> Sepolia");
        }

        ethToken.approve(POOL_ETH_USDT, crossChainAmount);
        pool.crossChainSwap(
            destChainId,       // destination chain
            crossChainAmount,  // ETH input
            0                  // min output (slippage protection)
        );

        console.log("Initiated cross-chain swap:");
        console.log("  - Input:", crossChainAmount / 1e18, "ETH");
        console.log("  - Output: USDT (to be received on chain", destChainId, ")");
        console.log("\nNOTE: To complete, run 'completeCrossChainSwap' on destination chain");

        vm.stopBroadcast();

        // ==================================================================
        // FINAL BALANCES
        // ==================================================================
        uint256 ethAfter = ethToken.balanceOf(deployer);
        uint256 usdtAfter = usdtToken.balanceOf(deployer);
        uint256 poolReserve0After = pool.reserve0();
        uint256 poolReserve1After = pool.reserve1();

        console.log("\n=== AFTER TEST ===");
        console.log("Your ETH:", ethAfter / 1e18);
        console.log("Your USDT:", usdtAfter / 1e18);
        console.log("Pool Reserve0 (USDT):", poolReserve0After / 1e18);
        console.log("Pool Reserve1 (ETH):", poolReserve1After / 1e18);

        console.log("\n=== SUMMARY ===");
        uint256 ethSpent = ethBefore - ethAfter;
        uint256 usdtReceived = usdtAfter - usdtBefore;
        uint256 ethBridged = bridgeAmount + crossChainAmount;
        console.log("ETH spent:", ethSpent / 1e18);
        console.log("USDT received:", usdtReceived / 1e18);
        console.log("ETH bridged (pending):", ethBridged / 1e18);

        console.log("\n=== TESTS COMPLETED ===");
        console.log("\nTransaction hashes saved to broadcast directory");
        console.log("Check: broadcast/ComprehensiveTest.s.sol/");
    }

    // ==================================================================
    // HELPER FUNCTIONS TO COMPLETE BRIDGE OPERATIONS
    // ==================================================================

    /**
     * @notice Complete pending bridge on destination chain
     * @param sourceChainId Source chain ID
     */
    function completeBridge(uint256 sourceChainId) external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        console.log("\n=== COMPLETING BRIDGE ===");
        console.log("Source Chain:", sourceChainId);
        console.log("Destination Chain:", block.chainid);

        MockToken ethToken = MockToken(TOKEN_ETH);
        CrossChainPool pool = CrossChainPool(POOL_ETH_USDT);

        uint256 nonce = pool.getNonce(deployer);
        uint256 balanceBefore = ethToken.balanceOf(deployer);

        console.log("Nonce:", nonce);
        console.log("ETH before:", balanceBefore / 1e18);

        // Create and sign message
        ICrossChainMessenger.CrossChainMessage memory message = ICrossChainMessenger.CrossChainMessage({
            sourceChainId: sourceChainId,
            destChainId: block.chainid,
            sender: deployer,
            recipient: deployer,
            amount0: 5 * 1e18,  // Must match bridgeAmount from source
            amount1: 0,
            nonce: nonce,
            data: ""
        });

        bytes32 messageHash = keccak256(abi.encode(message));
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, ethSignedHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startBroadcast(pk);
        pool.receiveMessage(message, signature);
        vm.stopBroadcast();

        uint256 balanceAfter = ethToken.balanceOf(deployer);
        console.log("ETH after:", balanceAfter / 1e18);
        console.log("ETH received:", (balanceAfter - balanceBefore) / 1e18);
        console.log("\n=== BRIDGE COMPLETED ===");
    }

    /**
     * @notice Complete cross-chain swap on destination chain
     * @param sourceChainId Source chain ID
     */
    function completeCrossChainSwap(uint256 sourceChainId) external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        console.log("\n=== COMPLETING CROSS-CHAIN SWAP ===");
        console.log("Source Chain:", sourceChainId);
        console.log("Destination Chain:", block.chainid);

        MockToken ethToken = MockToken(TOKEN_ETH);
        MockToken usdtToken = MockToken(TOKEN_USDT);
        CrossChainPool pool = CrossChainPool(POOL_ETH_USDT);

        uint256 nonce = pool.getNonce(deployer);
        uint256 usdtBefore = usdtToken.balanceOf(deployer);

        console.log("Nonce:", nonce);
        console.log("USDT before:", usdtBefore / 1e18);

        // Create and sign message for cross-chain swap
        ICrossChainMessenger.CrossChainMessage memory message = ICrossChainMessenger.CrossChainMessage({
            sourceChainId: sourceChainId,
            destChainId: block.chainid,
            sender: deployer,
            recipient: deployer,
            amount0: 3 * 1e18,  // ETH input from source
            amount1: 0,
            nonce: nonce,
            data: ""  // Could include swap calldata
        });

        bytes32 messageHash = keccak256(abi.encode(message));
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, ethSignedHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.startBroadcast(pk);
        pool.receiveMessage(message, signature);
        vm.stopBroadcast();

        uint256 usdtAfter = usdtToken.balanceOf(deployer);
        console.log("USDT after:", usdtAfter / 1e18);
        console.log("USDT received from swap:", (usdtAfter - usdtBefore) / 1e18);
        console.log("\n=== CROSS-CHAIN SWAP COMPLETED ===");
    }
}
