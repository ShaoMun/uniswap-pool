# Mainnet Deployment - Same as Testnet

Deploy mock tokens and pools on mainnet. Fund pools to match rates. Fund your wallets.

---

## ONLY CHANGE: Update Chain IDs

Open `script/Deploy.s.sol` and update lines 115-117:

```solidity
// BEFORE (Testnet)
supportedChains[0] = 11155111;   // Sepolia
supportedChains[1] = 421614;     // Arbitrum Sepolia
supportedChains[2] = 80002;      // Polygon Amoy

// AFTER (Mainnet)
supportedChains[0] = 1;         // Ethereum
supportedChains[1] = 42161;     // Arbitrum One
supportedChains[2] = 137;       // Polygon
```

**That's the only code change needed!**

---

## DEPLOY TO ALL 3 CHAINS

```bash
# 1. Ethereum Mainnet
export RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast

# 2. Arbitrum One
export RPC_URL=https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast

# 3. Polygon
export RPC_URL=https://polygon-mainnet.g.alchemy.com/v2/YOUR_KEY
forge script script/script/Deploy.s.sol --rpc-url $RPC_URL --broadcast
```

**Output:** Save the deployed addresses! You'll get:
```
TOKEN_ETH=0x...
TOKEN_USDT=0x...
TOKEN_EURC=0x...
POOL_ETH_USDT=0x...
POOL_EURC_USDT=0x...
POOL_ETH_EURC=0x...
```

---

## UPDATE SCRIPTS WITH DEPLOYED ADDRESSES

After deployment, update these constants with your deployed addresses:

### In `script/MintTokens.s.sol` (lines 20-26):
```solidity
address constant TOKEN_ETH = 0x...;    // Your deployed address
address constant TOKEN_USDT = 0x...;   // Your deployed address
address constant TOKEN_EURC = 0x...;   // Your deployed address

address constant POOL_ETH_USDT = 0x...;  // Your deployed address
address constant POOL_EURC_USDT = 0x...; // Your deployed address
address constant POOL_ETH_EURC = 0x...;  // Your deployed address
```

### In `script/ComprehensiveTest.s.sol` (lines 20-26):
Same updates as above.

---

## RUN ON ALL CHAINS

```bash
# Ethereum
forge script script/MintTokens.s.sol --rpc-url $ETHEREUM_RPC --broadcast
forge script script/ComprehensiveTest.s.sol --rpc-url $ETHEREUM_RPC --broadcast

# Arbitrum
forge script script/MintTokens.s.sol --rpc-url $ARBITRUM_RPC --broadcast
forge script script/ComprehensiveTest.s.sol --rpc-url $ARBITRUM_RPC --broadcast

# Polygon
forge script script/MintTokens.s.sol --rpc-url $POLYGON_RPC --broadcast
forge script script/ComprehensiveTest.s.sol --rpc-url $POLYGON_RPC --broadcast
```

---

## WHAT HAPPENS

1. **Deploy** - Mock tokens and pools deployed (same addresses on all chains)
2. **Mint** - 100k of each token to your two wallets:
   - 0x28aDCf970A21F9FE1Da1F5770670A55F76c4E995
   - 0x07dab64Aa125B206D7fd6a81AaB2133A0bdEF863
3. **Fund Pools** - Initial liquidity added with realistic rates
4. **Test** - All operations tested

---

## POOL RATES (Same on All Chains)

- **ETH/USDT:** 1 ETH = 2,733.72 USDT
- **EURC/USDT:** 1 EURC = 0.84 USDT
- **ETH/EURC:** 1 ETH = 2,296.99 EURC

---

## WALLET BALANCES AFTER MINTING

Both wallets will have:
- 100,000 ETH
- 100,000 USDT
- 100,000 EURC

---

## ESTIMATED COSTS

| Chain | Gas Cost |
|-------|----------|
| Ethereum | ~$600 |
| Arbitrum | ~$30 |
| Polygon | ~$50 |
| **Total** | **~$680** |

---

## SUMMARY

- ✅ Change 3 lines in Deploy.s.sol (chain IDs)
- ✅ Deploy to 3 chains (same addresses)
- ✅ Pools funded with mock tokens to match rates
- ✅ 100k tokens minted to each of your 2 wallets
- ✅ Same as testnet, just on mainnet!

**No real tokens needed, no real value, just like testnet!**
