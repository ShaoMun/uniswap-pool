# Uniswap V3 Pool Deployment with Pyth Price Feeds

Deploy 3 mock tokens (EURC, USDT, ETH), create 2 Uniswap V3 pools, initialize them with prices from Pyth Network, and add liquidity.

## Overview

This project deploys a complete Uniswap V3 setup on Sepolia testnet:
- **3 Mock Tokens**: EURC, USDT, ETH (all with faucet functionality)
- **3 Trading Pools**: ETH/USDT, EURC/USDT, and ETH/EURC with 0.3% fee
- **Pyth Integration**: Real-time prices from Pyth Network for pool initialization
- **Full Liquidity**: 100,000 tokens per pool for low slippage

## Prerequisites

1. **Foundry** - Install if not already available:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   source ~/.zshenv  # or ~/.bashrc
   foundryup
   ```

2. **Sepolia ETH** - Get testnet ETH from [Sepolia Faucet](https://sepoliafaucet.com/)

3. **RPC URL** - Use Infura, Alchemy, or public endpoint

## Project Structure

```
├── src/
│   ├── MockToken.sol           # ERC20 token with faucet
│   └── PythPriceChecker.sol     # Pyth price reader helper
├── script/
│   ├── DeployTokens.s.sol        # Deploy EURC, USDT, ETH
│   ├── CreatePoolEURC_USDT.s.sol  # Create EURC/USDT pool
│   ├── CreatePoolUSDT_ETH.s.sol  # Create USDT/ETH pool
│   ├── InitializeEURC_USDT.s.sol  # Initialize with Pyth price
│   ├── InitializeUSDT_ETH.s.sol  # Initialize with Pyth price
│   ├── AddLiquidityEURC_USDT.s.sol
│   ├── AddLiquidityUSDT_ETH.s.sol
│   └── TestSwaps.s.sol           # Test swaps on both pools
├── .env.example                  # Environment variables template
└── foundry.toml                  # Foundry configuration
```

## Deployment Steps

### Step 0: Setup Environment

Create a `.env` file (copy from `.env.example`):

```bash
cp .env.example .env
```

Edit `.env` with your values:
```env
PRIVATE_KEY=your_private_key_here
RPC_URL=https://sepolia.infura.io/v3/your_project_id
PYTH_ADDRESS=0x2880aB155794e7179c9eE2e38200202909C2Db63e
```

**Security Note**: Never commit your `.env` file or share your private key!

### Step 1: Deploy Tokens

```bash
forge script script/DeployTokens.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

The script will output the 3 token addresses. Add them to your `.env`:
```env
EURC_ADDRESS=0x...
USDT_ADDRESS=0x...
ETH_ADDRESS=0x...
```

### Step 2: Create Pools

Create EURC/USDT pool:
```bash
forge script script/CreatePoolEURC_USDT.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

Create USDT/ETH pool:
```bash
forge script script/CreatePoolUSDT_ETH.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

Add pool addresses to `.env`:
```env
POOL_EURC_USDT=0x...
POOL_USDT_ETH=0x...
```

### Step 3: Initialize Pools with Pyth Prices

Initialize EURC/USDT (reads EURC/USD and USDT/USD from Pyth):
```bash
forge script script/InitializeEURC_USDT.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

Initialize USDT/ETH (reads USDT/USD and ETH/USD from Pyth):
```bash
forge script script/InitializeUSDT_ETH.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Step 4: Add Liquidity

Add liquidity to EURC/USDT:
```bash
forge script script/AddLiquidityEURC_USDT.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

Add liquidity to USDT/ETH:
```bash
forge script script/AddLiquidityUSDT_ETH.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Step 5: Test Swaps

Verify both pools work correctly:
```bash
forge script script/TestSwaps.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

This will:
- Swap 100 EURC → USDT
- Swap 100 USDT → ETH
- Swap 50 USDT → EURC (reverse)

## Contract Addresses (Sepolia)

| Contract | Address |
|----------|---------|
| Uniswap V3 Factory | `0x1F98431c8aD98523631AE4a59f267346ea31F984` |
| NonfungiblePositionManager | `0xC36442b4a4522E871399CD717aBDD847Ab11FE88` |
| SwapRouter | `0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E` |
| Pyth Network | `0x2880aB155794e7179c9eE2e38200202909C2Db63e` |

### Deployed Pool Addresses (Sepolia)

| Pool | Address | Token0 | Token1 |
|------|---------|--------|--------|
| ETH/USDT | `0xD8abab3a58b8c5F9d888dE55ab5EaCAB7C875340` | ETH | USDT |
| EURC/USDT | `0x7f8Ac573Eb95b79e422a77FD01386afbB8e265bc` | EURC | USDT |
| ETH/EURC | `0xfF0dd27e9Fa0c0DC5c02ed52822Cf7cD5F779892` | ETH | EURC |

## Pyth Price Feed IDs (Sepolia)

| Asset | Price Feed ID |
|-------|---------------|
| EURC/USD | `0x76fa85158bf14ede77087fe3ae472f66213f6ea2f5b411cb2de472794990fa5c` |
| USDT/USD | `0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b` |
| ETH/USD | `0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace` |

## Verification

### Check Token Balances
```bash
cast balance $EURC_ADDRESS <your_wallet>
cast balance $USDT_ADDRESS <your_wallet>
cast balance $ETH_ADDRESS <your_wallet>
```

### Check Pool Creation
```bash
cast call 0x1F98431c8aD98523631AE4a59f267346ea31F984 "getPool(address,address,uint24)(address)" $EURC_ADDRESS $USDT_ADDRESS 3000
cast call 0x1F98431c8aD98523631AE4a59f267346ea31F984 "getPool(address,address,uint24)(address)" $USDT_ADDRESS $ETH_ADDRESS 3000
```

### Check Pool Initialization
```bash
cast call $POOL_EURC_USDT "slot0()(uint160,uint256,int24,uint24,uint256,uint256,bool)"
cast call $POOL_USDT_ETH "slot0()(uint160,uint256,int24,uint24,uint256,uint256,bool)"
```

### Check Liquidity NFTs
```bash
cast balance 0xC36442b4a4522E871399CD717aBDD847Ab11FE88 <your_wallet> --erc721
```

## Building & Testing

Build all contracts:
```bash
forge build
```

Run tests (if you add any):
```bash
forge test
```

## Troubleshooting

### "Stack too deep" error
The scripts use efficient memory management. If you modify them and hit this error, try:
- Reducing local variables
- Splitting functions into smaller parts
- Using `--via-ir` flag: `forge build --via-ir`

### Pyth price errors
If Pyth prices fail to load:
- Check that Pyth contract is deployed on Sepolia
- Verify price feed IDs are correct
- Ensure the price feeds have been updated recently

### Out of gas
If transactions run out of gas:
- Increase gas limit in deployment script
- Check Sepolia gas prices: `cast gas-price --rpc-url $RPC_URL`
- Ensure you have enough Sepolia ETH

## Security

- **Never commit private keys** or sensitive data
- **Test thoroughly** on testnet before mainnet
- **Verify addresses** before approving large amounts
- **Use hardware wallets** for mainnet deployments

## License

MIT
