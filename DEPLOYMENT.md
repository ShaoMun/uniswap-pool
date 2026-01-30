# Cross-Chain AMM - Production Deployment Guide

## Overview

This is a production-ready cross-chain AMM protocol using:
- **CREATE2** for deterministic addresses across chains
- **Lock/unlock model** with same token addresses
- **No relayer required** - users sign their own messages

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Same Token Address                       │
│                  (via CREATE2 deployment)                  │
│                                                             │
│  Sepolia: 0x1234...5678  │  Arbitrum: 0x1234...5678       │
│  └─ Pool: Lock 100 ETH   │  └─ Pool: Unlock 100 ETH      │
│                                                             │
│  User initiates bridge  │  User receives same tokens      │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your values
PRIVATE_KEY=0x...               # Your private key with 0x prefix
SEPOLIA_RPC=https://...         # Sepolia RPC URL
ARB_SEPOLIA_RPC=https://...     # Arbitrum Sepolia RPC URL
AMOY_RPC=https://...            # Polygon Amoy RPC URL

# For mainnet:
ETHEREUM_RPC=https://...        # Ethereum mainnet RPC
ARBITRUM_RPC=https://...        # Arbitrum One RPC
POLYGON_RPC=https://...          # Polygon mainnet RPC
```

### 2. Deploy to Testnets

```bash
# Deploy to Sepolia
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC \
  --broadcast \
  --verify

# Deploy to Arbitrum Sepolia
forge script script/Deploy.s.sol \
  --rpc-url $ARB_SEPOLIA_RPC \
  --broadcast

# Deploy to Polygon Amoy
forge script script/Deploy.s.sol \
  --rpc-url $AMOY_RPC \
  --broadcast
```

**All contracts will have THE SAME addresses on all chains!**

### 3. Update Test Script

After deployment, update `script/Test.s.sol` with the deployed addresses:
```solidity
address constant TOKEN_ETH = 0x...;  // From deployment output
address constant POOL_ETH_USDT = 0x...;  // From deployment output
// etc...
```

### 4. Test the Protocol

```bash
# Test swap on current chain
forge script script/Test.s.sol \
  --rpc-url $SEPOLIA_RPC \
  --broadcast

# Test bridge
forge script script/Test.s.sol \
  --rpc-url $SEPOLIA_RPC \
  --broadcast \
  --sig "testBridge(uint256)" 421614  # Arbitrum Sepolia

# Complete bridge on destination
forge script script/Test.s.sol \
  --rpc-url $ARB_SEPOLIA_RPC \
  --broadcast \
  --sig "completeBridge(uint256)" 11155111  # Sepolia
```

## Production (Mainnet) Deployment

### 1. Update Chain IDs

Edit `script/Deploy.s.sol` and change:
```solidity
// From testnet:
// supportedChains[0] = 11155111;   // Sepolia
// supportedChains[1] = 421614;     // Arbitrum Sepolia
// supportedChains[2] = 80002;      // Polygon Amoy

// To mainnet:
supportedChains[0] = 1;         // Ethereum
supportedChains[1] = 42161;     // Arbitrum One
supportedChains[2] = 137;       // Polygon
```

### 2. Change SALT (Optional)

To get new addresses, change the salt:
```solidity
bytes32 constant SALT = keccak256(abi.encodePacked("CrossChainAMM-v1-PROD"));
```

### 3. Deploy to Mainnet

```bash
# Deploy to Ethereum
forge script script/Deploy.s.sol \
  --rpc-url $ETHEREUM_RPC \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY

# Deploy to Arbitrum
forge script script/Deploy.s.sol \
  --rpc-url $ARBITRUM_RPC \
  --broadcast

# Deploy to Polygon
forge script script/Deploy.s.sol \
  --rpc-url $POLYGON_RPC \
  --broadcast
```

### 4. Verify Contracts

```bash
# Verify on Etherscan
forge verify-contract <ADDRESS> \
  src/MockToken.sol:MockToken \
  "Wrapped Ether" "WETH" \
  --chain-id 1 \
  --etherscan-api-key $ETHERSCAN_API_KEY

# Verify pools
forge verify-contract <ADDRESS> \
  src/CrossChainPool.sol:CrossChainPool \
  <TOKEN0> <TOKEN1> \
  --chain-id 1 \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

## File Structure

```
uniswap-pool/
├── src/
│   ├── MockToken.sol           # ERC20 token
│   ├── SimplePool.sol          # Basic AMM pool
│   ├── CrossChainPool.sol      # Cross-chain AMM pool
│   └── ICrossChainMessenger.sol # Interface
├── script/
│   ├── Deploy.s.sol            # Main deployment script
│   └── Test.s.sol              # Test script
├── script_deprecated/          # Old scripts (archived)
├── broadcast_deprecated/       # Old broadcast data (archived)
├── .env.example                # Environment template
└── DEPLOYMENT.md               # This file
```

## Security Considerations

1. **Private Key Management**: Never commit `.env` file
2. **Audit**: Have contracts audited before mainnet deployment
3. **Testing**: Thoroughly test on testnets first
4. **Gradual Rollout**: Start with small amounts on mainnet
5. **Monitoring**: Set up monitoring for all deployed contracts

## Contract Addresses

After deployment, save addresses here:

### Testnet
| Chain | ETH Token | USDT Token | EURC Token | ETH/USDT Pool |
|-------|-----------|------------|------------|---------------|
| Sepolia | `0x...` | `0x...` | `0x...` | `0x...` |
| Arb Sepolia | `0x...` | `0x...` | `0x...` | `0x...` |
| Polygon Amoy | `0x...` | `0x...` | `0x...` | `0x...` |

### Mainnet
| Chain | ETH Token | USDT Token | EURC Token | ETH/USDT Pool |
|-------|-----------|------------|------------|---------------|
| Ethereum | `0x...` | `0x...` | `0x...` | `0x...` |
| Arbitrum | `0x...` | `0x...` | `0x...` | `0x...` |
| Polygon | `0x...` | `0x...` | `0x...` | `0x...` |

## Troubleshooting

### "Address already used" error
- Change the `SALT` constant in `Deploy.s.sol`
- Redeploy to all chains

### Bridge not completing
- Ensure pools have liquidity on destination chain
- Check that both chains are in `supportedChains`
- Verify signature is from correct sender

### Different addresses on different chains
- Make sure you're using the same `SALT` on all chains
- Ensure CREATE2 deployment is working correctly

## License

MIT
