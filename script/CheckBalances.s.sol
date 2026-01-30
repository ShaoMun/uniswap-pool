// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MockToken.sol";
import "../src/SimplePool.sol";

/**
 * @title CheckBalances
 * @notice Check wallet and pool balances
 */
contract CheckBalances is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        // Token addresses
        address ethToken = 0x715f70ef11A65b4c8A7CCAa32E8aAaeE5011F15e;
        address usdtToken = 0xa3750d39Fa8c377a7FB87FD1F2Be4321722E2c58;
        address eurcToken = 0x326c5d56646A513151c75DFa5923eF6875dE53d5;

        // Pool addresses
        address poolETH_USDT = 0xD8abab3a58b8c5F9d888dE55ab5EaCAB7C875340;
        address poolEURC_USDT = 0x7f8Ac573Eb95b79e422a77FD01386afbB8e265bc;
        address poolETH_EURC = 0xfF0dd27e9Fa0c0DC5c02ed52822Cf7cD5F779892;

        MockToken eth = MockToken(ethToken);
        MockToken usdt = MockToken(usdtToken);
        MockToken eurc = MockToken(eurcToken);

        SimplePool pool1 = SimplePool(poolETH_USDT);
        SimplePool pool2 = SimplePool(poolEURC_USDT);
        SimplePool pool3 = SimplePool(poolETH_EURC);

        console.log("\n=== YOUR WALLET BALANCES ===");
        console.log("Address:", deployer);
        console.log("ETH:", eth.balanceOf(deployer));
        console.log("USDT:", usdt.balanceOf(deployer));
        console.log("EURC:", eurc.balanceOf(deployer));

        console.log("\n=== POOL RESERVES ===");

        console.log("\n--- ETH/USDT Pool ---");
        console.log("ETH in pool:", eth.balanceOf(poolETH_USDT));
        console.log("USDT in pool:", usdt.balanceOf(poolETH_USDT));
        (uint256 r0_1, uint256 r1_1) = (pool1.reserve0(), pool1.reserve1());
        console.log("Reserve0:", r0_1);
        console.log("Reserve1:", r1_1);

        console.log("\n--- EURC/USDT Pool ---");
        console.log("EURC in pool:", eurc.balanceOf(poolEURC_USDT));
        console.log("USDT in pool:", usdt.balanceOf(poolEURC_USDT));
        (uint256 r0_2, uint256 r1_2) = (pool2.reserve0(), pool2.reserve1());
        console.log("Reserve0:", r0_2);
        console.log("Reserve1:", r1_2);

        console.log("\n--- ETH/EURC Pool ---");
        console.log("ETH in pool:", eth.balanceOf(poolETH_EURC));
        console.log("EURC in pool:", eurc.balanceOf(poolETH_EURC));
        (uint256 r0_3, uint256 r1_3) = (pool3.reserve0(), pool3.reserve1());
        console.log("Reserve0:", r0_3);
        console.log("Reserve1:", r1_3);

        console.log("\n=== TOTAL SUPPLY (All tokens) ===");
        console.log("ETH total:", eth.totalSupply());
        console.log("USDT total:", usdt.totalSupply());
        console.log("EURC total:", eurc.totalSupply());
    }
}
