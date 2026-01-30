// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockToken
 * @notice A mock ERC20 token with a faucet function for testing
 * @dev Uses OpenZeppelin's ERC20 implementation
 */
contract MockToken is ERC20 {
    /**
     * @notice Constructor to initialize the token
     * @param name The name of the token
     * @param symbol The symbol of the token
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * @notice Faucet function to mint tokens to any address
     * @dev Anyone can call this to get tokens (for testing purposes)
     * @param to The address to receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function faucet(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * @notice Convenience function to mint tokens to msg.sender
     * @param amount The amount of tokens to mint
     */
    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
