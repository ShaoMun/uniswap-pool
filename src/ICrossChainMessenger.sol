// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICrossChainMessenger
 * @notice Interface for cross-chain message passing
 */
interface ICrossChainMessenger {
    struct CrossChainMessage {
        uint256 sourceChainId;
        uint256 destChainId;
        address sender;
        address recipient;
        uint256 amount0;
        uint256 amount1;
        uint256 nonce;
        bytes data;
    }

    event MessageSent(
        uint256 indexed sourceChainId,
        uint256 indexed destChainId,
        address indexed sender,
        bytes message
    );

    event MessageReceived(
        uint256 indexed sourceChainId,
        address indexed sender,
        address recipient
    );

    /**
     * @notice Verify and execute a cross-chain message
     * @param message The cross-chain message
     * @param signature Signature from the authorized relayer
     */
    function receiveMessage(
        CrossChainMessage calldata message,
        bytes calldata signature
    ) external;

    /**
     * @notice Get the current nonce for a sender
     */
    function getNonce(address sender) external view returns (uint256);
}
