// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MockToken.sol";

/**
 * @title MintTokens
 * @notice Mint tokens to specific addresses
 */
contract MintTokens is Script {
    // Token addresses (same on all chains)
    address constant TOKEN_ETH = 0xd33B31e46A8546a34Bd51403C39529fDD1d32334;
    address constant TOKEN_USDT = 0x85C805b1f1179cb41B41Fc900A74d2329b52a6D5;
    address constant TOKEN_EURC = 0x04f97dc5AE8b1CC5182cfF9F3d0aB2b172C07E42;

    // Recipients
    address constant RECIPIENT_1 = 0x28aDCf970A21F9FE1Da1F5770670A55F76c4E995;
    address constant RECIPIENT_2 = 0x07dab64Aa125B206D7fd6a81AaB2133A0bdEF863;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n=== MINTING TOKENS ===");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);

        MockToken tokenETH = MockToken(TOKEN_ETH);
        MockToken tokenUSDT = MockToken(TOKEN_USDT);
        MockToken tokenEURC = MockToken(TOKEN_EURC);

        // Amount to mint to each address: 100k of each token
        uint256 amount = 100_000 * 1e18;

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n--- Minting to", RECIPIENT_1, "---");
        tokenETH.faucet(RECIPIENT_1, amount);
        console.log("Minted", amount / 1e18, "ETH");

        tokenUSDT.faucet(RECIPIENT_1, amount);
        console.log("Minted", amount / 1e18, "USDT");

        tokenEURC.faucet(RECIPIENT_1, amount);
        console.log("Minted", amount / 1e18, "EURC");

        console.log("\n--- Minting to", RECIPIENT_2, "---");
        tokenETH.faucet(RECIPIENT_2, amount);
        console.log("Minted", amount / 1e18, "ETH");

        tokenUSDT.faucet(RECIPIENT_2, amount);
        console.log("Minted", amount / 1e18, "USDT");

        tokenEURC.faucet(RECIPIENT_2, amount);
        console.log("Minted", amount / 1e18, "EURC");

        vm.stopBroadcast();

        console.log("\n=== VERIFYING BALANCES ===");

        console.log("\nRecipient 1:", RECIPIENT_1);
        console.log("  ETH:", tokenETH.balanceOf(RECIPIENT_1) / 1e18);
        console.log("  USDT:", tokenUSDT.balanceOf(RECIPIENT_1) / 1e18);
        console.log("  EURC:", tokenEURC.balanceOf(RECIPIENT_1) / 1e18);

        console.log("\nRecipient 2:", RECIPIENT_2);
        console.log("  ETH:", tokenETH.balanceOf(RECIPIENT_2) / 1e18);
        console.log("  USDT:", tokenUSDT.balanceOf(RECIPIENT_2) / 1e18);
        console.log("  EURC:", tokenEURC.balanceOf(RECIPIENT_2) / 1e18);

        console.log("\n=== MINTING COMPLETE ===");
    }
}
