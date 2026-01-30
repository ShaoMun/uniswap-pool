// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SimplePool.sol";
import "./ICrossChainMessenger.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title CrossChainPool
 * @notice Extended SimplePool with cross-chain transfer and swap capabilities
 * @dev NO RELAYER REQUIRED - users sign their own messages
 */
contract CrossChainPool is SimplePool, ICrossChainMessenger {
    using SafeERC20 for IERC20;
    // Chain ID for this deployment
    uint256 public immutable chainId;

    // Mapping to track nonces for each user
    mapping(address => uint256) public nonces;

    // Registered chain IDs
    mapping(uint256 => bool) public supportedChains;

    // Minimum gas for cross-chain execution
    uint256 public constant MIN_GAS = 200000;

    // Cross-chain fee (0.1%)
    uint256 public constant CROSS_CHAIN_FEE = 1; // 1/1000 = 0.1%

    event CrossChainTransferInitiated(
        uint256 indexed destChainId,
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1
    );

    event CrossChainTransferReceived(
        uint256 indexed sourceChainId,
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1
    );

    event CrossChainSwapInitiated(
        uint256 indexed destChainId,
        address indexed sender,
        uint256 amountIn
    );

    constructor(
        IERC20 _token0,
        IERC20 _token1
    ) SimplePool(_token0, _token1) {
        chainId = block.chainid;
    }

    /**
     * @notice Register supported chains for cross-chain operations
     * @param chainIds Array of chain IDs to support
     * @dev Anyone can call this - no relayer required
     */
    function setSupportedChains(uint256[] calldata chainIds) external {
        for (uint256 i = 0; i < chainIds.length; i++) {
            supportedChains[chainIds[i]] = true;
        }
    }

    /**
     * @notice Initiate cross-chain token transfer
     * @param destChainId Target chain ID
     * @param recipient Recipient address on destination chain
     * @param amount0 Amount of token0 to transfer (0 if only token1)
     * @param amount1 Amount of token1 to transfer (0 if only token0)
     */
    function crossChainTransfer(
        uint256 destChainId,
        address recipient,
        uint256 amount0,
        uint256 amount1
    ) external nonReentrant {
        require(supportedChains[destChainId], "CrossChainPool: UNSUPPORTED_CHAIN");
        require(destChainId != chainId, "CrossChainPool: SAME_CHAIN");
        require(recipient != address(0), "CrossChainPool: INVALID_RECIPIENT");
        require(amount0 > 0 || amount1 > 0, "CrossChainPool: NO_AMOUNT");

        // Calculate cross-chain fee
        uint256 fee0 = (amount0 * CROSS_CHAIN_FEE) / 1000;
        uint256 fee1 = (amount1 * CROSS_CHAIN_FEE) / 1000;

        uint256 amount0AfterFee = amount0 - fee0;
        uint256 amount1AfterFee = amount1 - fee1;

        // Transfer tokens from sender (including fee)
        if (amount0 > 0) {
            IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        }
        if (amount1 > 0) {
            IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
        }

        // Update reserves directly (tokens are locked in pool)
        reserve0 += amount0;
        reserve1 += amount1;
        emit Sync(reserve0, reserve1);

        // Create message for relayer
        uint256 nonce = nonces[msg.sender]++;
        CrossChainMessage memory message = CrossChainMessage({
            sourceChainId: chainId,
            destChainId: destChainId,
            sender: msg.sender,
            recipient: recipient,
            amount0: amount0AfterFee,
            amount1: amount1AfterFee,
            nonce: nonce,
            data: "" // Empty for simple transfer
        });

        emit CrossChainTransferInitiated(destChainId, msg.sender, recipient, amount0AfterFee, amount1AfterFee);
        emit MessageSent(chainId, destChainId, msg.sender, abi.encode(message));
    }

    /**
     * @notice Initiate cross-chain swap
     * @param destChainId Target chain ID
     * @param amountIn Amount of token0 to swap
     * @param amount0OutMinimum Minimum token1 to receive on destination
     */
    function crossChainSwap(
        uint256 destChainId,
        uint256 amountIn,
        uint256 amount0OutMinimum
    ) external nonReentrant {
        require(supportedChains[destChainId], "CrossChainPool: UNSUPPORTED_CHAIN");
        require(destChainId != chainId, "CrossChainPool: SAME_CHAIN");
        require(amountIn > 0, "CrossChainPool: NO_AMOUNT");

        // Calculate fee and amount after fee
        uint256 fee = (amountIn * CROSS_CHAIN_FEE) / 1000;
        uint256 amountInAfterFee = amountIn - fee;

        // Transfer token0 from sender
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amountIn);

        // Update reserves directly
        reserve0 += amountIn;
        emit Sync(reserve0, reserve1);

        uint256 nonce = nonces[msg.sender]++;
        CrossChainMessage memory message = CrossChainMessage({
            sourceChainId: chainId,
            destChainId: destChainId,
            sender: msg.sender,
            recipient: msg.sender,
            amount0: amountInAfterFee,
            amount1: amount0OutMinimum,
            nonce: nonce,
            data: abi.encode("SWAP") // Mark as swap operation
        });

        emit CrossChainSwapInitiated(destChainId, msg.sender, amountInAfterFee);
        emit MessageSent(chainId, destChainId, msg.sender, abi.encode(message));
    }

    /**
     * @notice Receive and execute cross-chain message
     * @param message The cross-chain message
     * @param signature Signature from the SENDER (not a relayer)
     * @dev Anyone can call this, but the signature must match message.sender
     */
    function receiveMessage(
        CrossChainMessage calldata message,
        bytes calldata signature
    ) external override {
        require(message.destChainId == chainId, "CrossChainPool: WRONG_CHAIN");
        require(supportedChains[message.sourceChainId], "CrossChainPool: UNSUPPORTED_SOURCE");

        // Verify signature from SENDER (not relayer)
        bytes32 messageHash = keccak256(abi.encode(message));
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        address signer = recoverSigner(ethSignedHash, signature);
        require(signer == message.sender, "CrossChainPool: INVALID_SIGNATURE");

        // Check nonce
        require(message.nonce == nonces[message.sender], "CrossChainPool: INVALID_NONCE");
        nonces[message.sender]++;

        // Execute the operation
        _executeCrossChainOperation(message);

        emit MessageReceived(message.sourceChainId, message.sender, message.recipient);
    }

    /**
     * @notice Execute the cross-chain operation
     */
    function _executeCrossChainOperation(CrossChainMessage calldata message) private {
        bool isSwap = bytes(message.data).length > 0;

        if (isSwap) {
            // Cross-chain swap: swap received tokens and send to recipient
            if (message.amount0 > 0) {
                // Swap token0 for token1
                uint256 amount0In = message.amount0;
                uint256 amount0WithFee = (amount0In * 997) / 1000;
                uint256 amount1Out = (reserve0 * amount0WithFee) / (reserve1 + amount0WithFee);

                require(amount1Out >= message.amount1, "CrossChainPool: INSUFFICIENT_OUTPUT");

                // Update reserves
                reserve0 += amount0In;
                reserve1 -= amount1Out;

                // Transfer token1 to recipient
                IERC20(token1).safeTransfer(message.recipient, amount1Out);

                emit CrossChainTransferReceived(
                    message.sourceChainId,
                    message.sender,
                    message.recipient,
                    amount0In,
                    amount1Out
                );
            }
        } else {
            // Simple cross-chain transfer: mint and send tokens to recipient
            if (message.amount0 > 0) {
                // Mint token0 to recipient
                // Note: In a real implementation, you'd need actual token minting authority
                // or use wrapped tokens. For POC, we assume pool has pre-minted tokens
                IERC20(token0).safeTransfer(message.recipient, message.amount0);
            }
            if (message.amount1 > 0) {
                // Mint token1 to recipient
                IERC20(token1).safeTransfer(message.recipient, message.amount1);
            }

            // Update reserves directly
            reserve0 -= message.amount0;
            reserve1 -= message.amount1;

            emit CrossChainTransferReceived(
                message.sourceChainId,
                message.sender,
                message.recipient,
                message.amount0,
                message.amount1
            );
        }

        emit Sync(reserve0, reserve1);
    }

    /**
     * @notice Get nonce for a sender
     */
    function getNonce(address sender) external view override returns (uint256) {
        return nonces[sender];
    }

    /**
     * @notice Recover signer from signature
     */
    function recoverSigner(
        bytes32 ethSignedHash,
        bytes memory signature
    ) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedHash, v, r, s);
    }

    /**
     * @notice Split signature into r, s, v
     */
    function splitSignature(bytes memory sig)
        private
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "CrossChainPool: INVALID_SIGNATURE_LENGTH");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /**
     * @notice Estimate output amount for cross-chain swap
     */
    function estimateCrossChainSwap(
        uint256 amountIn
    ) external view returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserve1;
        uint256 denominator = (reserve0 * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
