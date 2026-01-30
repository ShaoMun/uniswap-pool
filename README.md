# Cross-Chain AMM Protocol

A production-ready cross-chain automated market maker (AMM) protocol built with Solidity and Foundry.

## Features

- ✅ **Cross-chain swaps** - Swap tokens across different chains
- ✅ **Bridge tokens** - Transfer tokens between chains
- ✅ **No relayer required** - Users sign their own messages
- ✅ **Deterministic addresses** - Same contract addresses across all chains via CREATE2
- ✅ **Simple deployment** - One script deploys to any chain

## How It Works

```
User on Ethereum          User on Arbitrum
    │                         │
    │  Lock 100 ETH          │
    ├────────────────────────>│
    │  Message emitted        │
    │                         │
    │                     Sign & Submit
    │                         │
    │                    Receive 100 ETH
    │                         │
```

## Quick Start

### 1. Installation

```bash
git clone <repo-url>
cd uniswap-pool
forge install
```

### 2. Setup Environment

```bash
cp .env.example .env
# Edit .env with your private key and RPC URLs
```

### 3. Deploy

```bash
# Deploy to any chain
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast
```

### 4. Test

```bash
# Test swap
forge script script/Test.s.sol --rpc-url $RPC_URL --broadcast

# Test cross-chain bridge
forge script script/Test.s.sol --rpc-url $RPC_URL --broadcast \
  --sig "testBridge(uint256)" <DEST_CHAIN_ID>
```

## Documentation

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment instructions.

## Architecture

### Contracts

| Contract | Description |
|----------|-------------|
| `MockToken.sol` | ERC20 token implementation |
| `SimplePool.sol` | Basic AMM pool (x * y = k) |
| `CrossChainPool.sol` | Cross-chain pool with bridge functionality |
| `ICrossChainMessenger.sol` | Interface for cross-chain messaging |

### Pool Operations

| Operation | Description |
|-----------|-------------|
| `swap()` | Swap tokens on the same chain |
| `addLiquidity()` | Add liquidity to earn LP tokens |
| `removeLiquidity()` | Remove liquidity and receive tokens |
| `crossChainTransfer()` | Bridge tokens to another chain |
| `crossChainSwap()` | Swap tokens on destination chain |
| `receiveMessage()` | Complete cross-chain operation |

## Security

⚠️ **IMPORTANT**: This is experimental software. Always:
- Audit contracts before mainnet deployment
- Test thoroughly on testnets
- Start with small amounts
- Monitor contracts after deployment

## License

MIT
