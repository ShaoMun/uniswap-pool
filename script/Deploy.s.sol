// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MockToken.sol";
import "../src/CrossChainPool.sol";

/**
 * @title Deploy
 * @notice Production deployment script with CREATE2 for deterministic addresses
 * @dev This deploys the same token and pool contracts across all chains
 *
 * Features:
 * - CREATE2 deployment for consistent addresses across chains
 * - Same tokens and pools on all chains
 * - Simple lock/unlock model that actually works
 *
 * Usage:
 *   # Sepolia
 *   export RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
 *   forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast
 *
 *   # Arbitrum Sepolia
 *   export RPC_URL=https://arb-sepolia.g.alchemy.com/v2/YOUR_KEY
 *   forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast
 *
 *   # Polygon Amoy
 *   export RPC_URL=https://polygon-amoy.g.alchemy.com/v2/YOUR_KEY
 *   forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast
 */
contract Deploy is Script {
    struct DeploymentConfig {
        string tokenName;
        string tokenSymbol;
    }

    // CREATE2 factory for deterministic deployment
    address immutable create2Factory;

    // Deployment salt (change this to get new addresses)
    // Updated to v2 to get fresh pools with realistic rates
    bytes32 constant SALT = keccak256(abi.encodePacked("CrossChainAMM-v2"));
    bytes32 constant SALT_ETH = SALT;
    bytes32 constant SALT_USDT = keccak256(abi.encodePacked("CrossChainAMM-v2-USDT"));
    bytes32 constant SALT_EURC = keccak256(abi.encodePacked("CrossChainAMM-v2-EURC"));
    bytes32 constant SALT_POOL_0 = keccak256(abi.encodePacked("CrossChainAMM-v2-POOL-0"));
    bytes32 constant SALT_POOL_1 = keccak256(abi.encodePacked("CrossChainAMM-v2-POOL-1"));
    bytes32 constant SALT_POOL_2 = keccak256(abi.encodePacked("CrossChainAMM-v2-POOL-2"));

    constructor() {
        // Use a simple CREATE2 factory pattern
        // In production, you might use a dedicated factory contract
        create2Factory = address(0x4e59b44847b379578588920cA78FbF26c0B4956C); // Create2Deployer
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n============================================================");
        console.log("       PRODUCTION DEPLOYMENT                                ");
        console.log("============================================================");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("SALT:", vm.toString(SALT));
        console.log("\nThis will deploy:");
        console.log("  - 3 MockToken contracts (ETH, USDT, EURC)");
        console.log("  - 3 CrossChainPool contracts");
        console.log("  - All with SAME addresses across all chains");
        console.log("\nPress Ctrl+C to cancel...");
        // Note: vm.pause() not available in all forge versions, skipping
        // vm.pause(5000);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy tokens with CREATE2
        MockToken tokenETH = deployToken(
            "Wrapped Ether",
            "WETH",
            SALT_ETH
        );
        console.log("ETH Token:", address(tokenETH));

        MockToken tokenUSDT = deployToken(
            "Tether USD",
            "USDT",
            SALT_USDT
        );
        console.log("USDT Token:", address(tokenUSDT));

        MockToken tokenEURC = deployToken(
            "Euro Coin",
            "EURC",
            SALT_EURC
        );
        console.log("EURC Token:", address(tokenEURC));

        // Deploy pools with CREATE2
        // For ETH/USDT: USDT address < ETH address, so swap order
        CrossChainPool poolETH_USDT = deployPool(
            tokenUSDT,
            tokenETH,
            SALT_POOL_0
        );
        console.log("ETH/USDT Pool:", address(poolETH_USDT));

        CrossChainPool poolEURC_USDT = deployPool(
            tokenEURC,
            tokenUSDT,
            SALT_POOL_1
        );
        console.log("EURC/USDT Pool:", address(poolEURC_USDT));

        CrossChainPool poolETH_EURC = deployPool(
            tokenEURC,  // token0 must be < token1
            tokenETH,
            SALT_POOL_2
        );
        console.log("ETH/EURC Pool:", address(poolETH_EURC));

        // Configure supported chains
        uint256[] memory supportedChains = new uint256[](3);
        supportedChains[0] = 11155111;   // Sepolia
        supportedChains[1] = 421614;     // Arbitrum Sepolia
        supportedChains[2] = 80002;      // Polygon Amoy

        // For mainnet, use:
        // supportedChains[0] = 1;         // Ethereum
        // supportedChains[1] = 42161;     // Arbitrum One
        // supportedChains[2] = 137;       // Polygon

        poolETH_USDT.setSupportedChains(supportedChains);
        poolEURC_USDT.setSupportedChains(supportedChains);
        poolETH_EURC.setSupportedChains(supportedChains);

        console.log("Supported chains configured");

        // Mint initial supply to deployer (more tokens needed for realistic rates)
        uint256 initialSupplyETH = 500_000 * 1e18;
        uint256 initialSupplyUSDT = 2_000_000 * 1e18;
        uint256 initialSupplyEURC = 500_000 * 1e18;

        tokenETH.mint(initialSupplyETH);
        tokenUSDT.mint(initialSupplyUSDT);
        tokenEURC.mint(initialSupplyEURC);
        console.log("Minted tokens to deployer");

        // Add initial liquidity with realistic rates
        // Target rates:
        // 1 ETH = 2,733.72 USDT
        // 1 ETH = 2,296.99 EUR
        // 1 USDT = 0.84 EUR

        // ETH/USDT Pool: 273,372 USDT (token0) / 100 ETH (token1)
        tokenETH.approve(address(poolETH_USDT), type(uint256).max);
        tokenUSDT.approve(address(poolETH_USDT), type(uint256).max);
        poolETH_USDT.addLiquidity(273372 * 1e18, 100 * 1e18);

        // EURC/USDT Pool: 100,000 EURC (token0) / 84,000 USDT (token1)
        tokenEURC.approve(address(poolEURC_USDT), type(uint256).max);
        tokenUSDT.approve(address(poolEURC_USDT), type(uint256).max);
        poolEURC_USDT.addLiquidity(100000 * 1e18, 84000 * 1e18);

        // ETH/EURC Pool: 229,699 EURC (token0) / 100 ETH (token1)
        tokenETH.approve(address(poolETH_EURC), type(uint256).max);
        tokenEURC.approve(address(poolETH_EURC), type(uint256).max);
        poolETH_EURC.addLiquidity(229699 * 1e18, 100 * 1e18);

        console.log("Initial liquidity added with realistic rates");

        vm.stopBroadcast();

        console.log("\n============================================================");
        console.log("       DEPLOYMENT COMPLETED                                  ");
        console.log("============================================================");
        console.log("\n=== SAVE THESE ADDRESSES ===");
        console.log("TOKEN_ETH=", address(tokenETH));
        console.log("TOKEN_USDT=", address(tokenUSDT));
        console.log("TOKEN_EURC=", address(tokenEURC));
        console.log("POOL_ETH_USDT=", address(poolETH_USDT));
        console.log("POOL_EURC_USDT=", address(poolEURC_USDT));
        console.log("POOL_ETH_EURC=", address(poolETH_EURC));
        console.log("\nNOTE: These addresses will be THE SAME on all chains!");
        console.log("============================================================");
    }

    function deployToken(
        string memory name,
        string memory symbol,
        bytes32 salt
    ) internal returns (MockToken) {
        bytes memory bytecode = abi.encodePacked(
            type(MockToken).creationCode,
            abi.encode(name, symbol)
        );

        address tokenAddress;
        assembly {
            tokenAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        return MockToken(tokenAddress);
    }

    function deployPool(
        IERC20 token0,
        IERC20 token1,
        bytes32 salt
    ) internal returns (CrossChainPool) {
        require(address(token0) < address(token1), "Invalid token order");

        bytes memory bytecode = abi.encodePacked(
            type(CrossChainPool).creationCode,
            abi.encode(token0, token1)
        );

        address poolAddress;
        assembly {
            poolAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        return CrossChainPool(poolAddress);
    }
}
