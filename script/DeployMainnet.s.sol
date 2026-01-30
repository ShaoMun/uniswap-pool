// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MockToken.sol";
import "../src/CrossChainPool.sol";

/**
 * @title DeployMainnet
 * @notice Mainnet deployment script with real tokens
 *
 * MAINNET vs TESTNET CHANGES:
 * 1. Chain IDs: 11155111 → 1, 421614 → 42161, 80002 → 137
 * 2. Use real token addresses instead of deploying mock tokens
 * 3. Add security features (Pausable, AccessControl)
 * 4. Consider using existing DEX pools vs creating new ones
 *
 * Usage:
 *   # Ethereum Mainnet
 *   export RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
 *   forge script script/DeployMainnet.s.sol --rpc-url $RPC_URL --broadcast --verify
 *
 *   # Arbitrum One
 *   export RPC_URL=https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY
 *   forge script script/DeployMainnet.s.sol --rpc-url $RPC_URL --broadcast
 *
 *   # Polygon
 *   export RPC_URL=https://polygon-mainnet.g.alchemy.com/v2/YOUR_KEY
 *   forge script script/DeployMainnet.s.sol --rpc-url $RPC_URL --broadcast
 */
contract DeployMainnet is Script {
    // ============================================================
    // REAL TOKEN ADDRESSES (Mainnet)
    // ============================================================

    // Ethereum Mainnet
    address public constant WETH_ETHEREUM = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDT_ETHEREUM = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant EURC_ETHEREUM = 0x1a7e4e63778B4f12a199C062f3eFdD269A9C0111;

    // Arbitrum One
    address public constant WETH_ARBITRUM = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant USDT_ARBITRUM = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address public constant EURC_ARBITRUM = 0x70E8de73Ce536b4c51bE285150D25F22f5dA6e7c;

    // Polygon
    address public constant WMATIC_POLYGON = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant USDT_POLYGON = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    // EURC on Polygon - verify address before deployment!

    // ============================================================
    // DEPLOYMENT CONFIG
    // ============================================================

    bytes32 constant SALT = keccak256(abi.encodePacked("CrossChainAMM-mainnet-v1"));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        uint256 chainId = block.chainid;

        console.log("\n============================================================");
        console.log("       MAINNET DEPLOYMENT");
        console.log("============================================================");
        console.log("Chain ID:", chainId);
        console.log("Deployer:", deployer);
        console.log("\nWARNING: This is MAINNET with REAL funds!");
        console.log("Press Ctrl+C to cancel, or wait 10 seconds...");
        vm.pause(10000);

        vm.startBroadcast(deployerPrivateKey);

        IERC20 token0;
        IERC20 token1;
        IERC20 tokenUSDT;

        // ============================================================
        // SELECT TOKENS BASED ON CHAIN
        // ============================================================

        if (chainId == 1) {
            // Ethereum Mainnet
            console.log("\nDeploying on ETHEREUM MAINNET");
            token0 = IERC20(WETH_ETHEREUM);
            token1 = IERC20(EURC_ETHEREUM);
            tokenUSDT = IERC20(USDT_ETHEREUM);

        } else if (chainId == 42161) {
            // Arbitrum One
            console.log("\nDeploying on ARBITRUM ONE");
            token0 = IERC20(WETH_ARBITRUM);
            token1 = IERC20(EURC_ARBITRUM);
            tokenUSDT = IERC20(USDT_ARBITRUM);

        } else if (chainId == 137) {
            // Polygon
            console.log("\nDeploying on POLYGON");
            token0 = IERC20(WMATIC_POLYGON);
            token1 = IERC20(USDT_POLYGON);
            tokenUSDT = IERC20(USDT_POLYGON); // May need separate EURC

        } else {
            revert("Unsupported chain for mainnet deployment");
        }

        console.log("Token0 (Native/EUR):", address(token0));
        console.log("Token1 (USDT):", address(tokenUSDT));

        // ============================================================
        // DEPLOY POOLS (using CREATE2 for deterministic addresses)
        // ============================================================

        bytes32 saltETH_USDT = keccak256(abi.encodePacked(SALT, "POOL-ETH-USDT"));
        bytes32 saltEURC_USDT = keccak256(abi.encodePacked(SALT, "POOL-EURC-USDT"));
        bytes32 saltETH_EURC = keccak256(abi.encodePacked(SALT, "POOL-ETH-EURC"));

        CrossChainPool poolETH_USDT = deployPool(token0, tokenUSDT, saltETH_USDT);
        console.log("ETH/USDT Pool:", address(poolETH_USDT));

        CrossChainPool poolEURC_USDT = deployPool(token1, tokenUSDT, saltEURC_USDT);
        console.log("EURC/USDT Pool:", address(poolEURC_USDT));

        CrossChainPool poolETH_EURC = deployPool(token0, token1, saltETH_EURC);
        console.log("ETH/EURC Pool:", address(poolETH_EURC));

        // ============================================================
        // CONFIGURE SUPPORTED CHAINS (MAINNET)
        // ============================================================

        uint256[] memory supportedChains = new uint256[](3);
        supportedChains[0] = 1;         // Ethereum
        supportedChains[1] = 42161;     // Arbitrum One
        supportedChains[2] = 137;       // Polygon

        poolETH_USDT.setSupportedChains(supportedChains);
        poolEURC_USDT.setSupportedChains(supportedChains);
        poolETH_EURC.setSupportedChains(supportedChains);

        console.log("Supported chains configured");

        // ============================================================
        // ADD INITIAL LIQUIDITY (OPTIONAL - ONLY IF YOU HAVE FUNDS!)
        // ============================================================

        console.log("\n⚠️  SKIPPING automatic liquidity provision");
        console.log("    Please add liquidity manually to ensure correct amounts!");
        console.log("    Or uncomment below at your own risk!");

        /*
        // WARNING: This will transfer your REAL tokens!
        // Only uncomment if you want to add liquidity automatically

        uint256 liquidityAmount0 = 100 * 1e18;  // 100 tokens
        uint256 liquidityAmount1 = 273372 * 1e18;  // Adjust based on rates

        token0.approve(address(poolETH_USDT), type(uint256).max);
        tokenUSDT.approve(address(poolETH_USDT), type(uint256).max);
        poolETH_USDT.addLiquidity(liquidityAmount0, liquidityAmount1);

        console.log("Initial liquidity added");
        */

        vm.stopBroadcast();

        // ============================================================
        // DEPLOYMENT SUMMARY
        // ============================================================

        console.log("\n============================================================");
        console.log("       MAINNET DEPLOYMENT COMPLETED");
        console.log("============================================================");
        console.log("\n=== SAVE THESE ADDRESSES ===");
        console.log("TOKEN0 (Native/EUR):", address(token0));
        console.log("TOKEN1 (USDT):", address(tokenUSDT));
        console.log("");
        console.log("POOL_ETH_USDT=", address(poolETH_USDT));
        console.log("POOL_EURC_USDT=", address(poolEURC_USDT));
        console.log("POOL_ETH_EURC=", address(poolETH_EURC));
        console.log("\n============================================================");
        console.log("\nNEXT STEPS:");
        console.log("1. Verify contracts on block explorer");
        console.log("2. Add liquidity to pools");
        console.log("3. Test with small amounts");
        console.log("4. Update frontend configuration");
        console.log("============================================================");
    }

    /**
     * @notice Deploy pool with CREATE2 for deterministic address
     */
    function deployPool(
        IERC20 _token0,
        IERC20 _token1,
        bytes32 salt
    ) internal returns (CrossChainPool) {
        require(address(_token0) < address(_token1), "Invalid token order");

        bytes memory bytecode = abi.encodePacked(
            type(CrossChainPool).creationCode,
            abi.encode(_token0, _token1)
        );

        address poolAddress;
        assembly {
            poolAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        return CrossChainPool(poolAddress);
    }
}
