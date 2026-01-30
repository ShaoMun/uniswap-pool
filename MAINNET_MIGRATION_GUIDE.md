# Mainnet Migration Guide

This guide covers everything you need to migrate the CrossChain AMM from testnet to mainnet.

---

## Overview

Migration involves updating RPC URLs, Chain IDs, and replacing mock tokens with real ERC20 tokens.

---

## 1. Environment Configuration Changes

### `.env` File Changes

**Testnet Configuration:**
```bash
# Testnet RPC URLs
SEPOLIA_RPC=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
ARB_SEPOLIA_RPC=https://arb-sepolia.g.alchemy.com/v2/YOUR_KEY
AMOY_RPC=https://polygon-amoy.g.alchemy.com/v2/YOUR_KEY

# Chain IDs (Testnet)
SEPOLIA_CHAIN_ID=11155111
ARB_SEPOLIA_CHAIN_ID=421614
AMOY_CHAIN_ID=80002
```

**Mainnet Configuration:**
```bash
# Mainnet RPC URLs
ETHEREUM_RPC=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
ARBITRUM_RPC=https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY
POLYGON_RPC=https://polygon-mainnet.g.alchemy.com/v2/YOUR_KEY

# Chain IDs (Mainnet)
ETHEREUM_CHAIN_ID=1
ARBITRUM_CHAIN_ID=42161
POLYGON_CHAIN_ID=137
```

---

## 2. Contract Deployment Script Changes

### Update `script/Deploy.s.sol`

**Change the supported chains:**

```solidity
// BEFORE (Testnet)
uint256[] memory supportedChains = new uint256[](3);
supportedChains[0] = 11155111;   // Sepolia
supportedChains[1] = 421614;     // Arbitrum Sepolia
supportedChains[2] = 80002;      // Polygon Amoy

// AFTER (Mainnet)
uint256[] memory supportedChains = new uint256[](3);
supportedChains[0] = 1;         // Ethereum
supportedChains[1] = 42161;     // Arbitrum One
supportedChains[2] = 137;       // Polygon
```

### Update Deployment SALT (Optional)

If you want fresh contract addresses on mainnet:

```solidity
// BEFORE
bytes32 constant SALT = keccak256(abi.encodePacked("CrossChainAMM-v2"));

// AFTER (v3 for mainnet)
bytes32 constant SALT = keccak256(abi.encodePacked("CrossChainAMM-mainnet-v1"));
```

---

## 3. Token Migration (Most Important!)

### Using Real Tokens vs Mock Tokens

**Option A: Use Real Existing Tokens (Recommended)**

Instead of deploying mock tokens, use real tokens that already exist on each chain:

| Chain | WETH Address | USDT Address | EURC Address |
|-------|--------------|--------------|--------------|
| **Ethereum** | `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2` | `0xdAC17F958D2ee523a2206206994597C13D831ec7` | `0x1a7e4e63778B4f12a199C062f3eFdD269A9C0111` |
| **Arbitrum** | `0x82aF49447D8a07e3bd95BD0d56f35241523fBab1` | `0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9` | `0x70E8de73Ce536b4c51bE285150D25F22f5dA6e7c` |
| **Polygon** | `0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270` | `0xc2132D05D31c914a87C6611C10748AEb04B58e8F` | Check Euro Coin on Polygon |

**Option B: Deploy Your Own Tokens**

If deploying your own tokens (still ERC20 compliant):

```solidity
// Deploy new tokens on mainnet with CREATE2
MockToken tokenWETH = deployToken("Wrapped Ether", "WETH", SALT_WETH);
MockToken tokenUSDT = deployToken("Tether USD", "USDT", SALT_USDT);
MockToken tokenEURC = deployToken("Euro Coin", "EURC", SALT_EURC);
```

### Update Pool Deployment for Real Tokens

```solidity
// For WETH/USDT pool, check token addresses to ensure proper ordering
// token0 must be < token1

CrossChainPool poolWETH_USDT = deployPool(
    USDT_ADDRESS < WETH_ADDRESS ? tokenUSDT : tokenWETH,
    USDT_ADDRESS < WETH_ADDRESS ? tokenWETH : tokenUSDT,
    SALT_POOL_0
);
```

---

## 4. Integration Code Changes

### Frontend/Backend Configuration

**Testnet Configuration:**
```typescript
const CONFIG = {
  chains: {
    sepolia: {
      chainId: 11155111,
      rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY',
      nativeCurrency: { name: 'Sepolia ETH', symbol: 'ETH', decimals: 18 }
    },
    arbSepolia: {
      chainId: 421614,
      rpcUrl: 'https://arb-sepolia.g.alchemy.com/v2/YOUR_KEY',
      nativeCurrency: { name: 'Sepolia ETH', symbol: 'ETH', decimals: 18 }
    },
    amoy: {
      chainId: 80002,
      rpcUrl: 'https://polygon-amoy.g.alchemy.com/v2/YOUR_KEY',
      nativeCurrency: { name: 'MATIC', symbol: 'MATIC', decimals: 18 }
    }
  },
  tokens: {
    ETH: '0xd33B31e46A8546a34Bd51403C39529fDD1d32334',  // Mock
    USDT: '0x85C805b1f1179cb41B41Fc900A74d2329b52a6D5', // Mock
    EURC: '0x04f97dc5AE8b1CC5182cfF9F3d0aB2b172C07E42'  // Mock
  }
};
```

**Mainnet Configuration:**
```typescript
const CONFIG = {
  chains: {
    ethereum: {
      chainId: 1,
      rpcUrl: 'https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY',
      nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
      blockExplorer: 'https://etherscan.io'
    },
    arbitrum: {
      chainId: 42161,
      rpcUrl: 'https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY',
      nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
      blockExplorer: 'https://arbiscan.io'
    },
    polygon: {
      chainId: 137,
      rpcUrl: 'https://polygon-mainnet.g.alchemy.com/v2/YOUR_KEY',
      nativeCurrency: { name: 'MATIC', symbol: 'MATIC', decimals: 18 },
      blockExplorer: 'https://polygonscan.com'
    }
  },
  tokens: {
    // Ethereum mainnet tokens
    ETH: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',  // WETH
    USDT: '0xdAC17F958D2ee523a2206206994597C13D831ec7', // Tether
    EURC: '0x1a7e4e63778B4f12a199C062f3eFdD269A9C0111'  // Euro Coin
  }
};
```

---

## 5. Smart Contract Security Updates

### Add Security Measures for Mainnet

**1. Implement Pause Mechanism:**
```solidity
import "@openzeppelin/contracts/security/Pausable.sol";

contract CrossChainPool is SimplePool, Pausable {
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function swap(...) external override nonReentrant whenNotPaused {
        // existing swap logic
    }
}
```

**2. Add Role-Based Access Control:**
```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CrossChainPool is SimplePool, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function setFee(uint256 newFee) external onlyRole(ADMIN_ROLE) {
        require(newFee <= 1000, "Fee too high"); // Max 10%
        fee = newFee;
    }
}
```

**3. Add Reentrancy Protection:**
```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CrossChainPool is SimplePool, ReentrancyGuard {
    function receiveMessage(...) external nonReentrant whenNotPaused {
        // existing logic
    }
}
```

**4. Add Emergency Withdraw:**
```solidity
function emergencyWithdraw(
    address token,
    uint256 amount,
    address to
) external onlyRole(ADMIN_ROLE) whenPaused {
    IERC20(token).transfer(to, amount);
    emit EmergencyWithdraw(token, amount, to);
}
```

---

## 6. Gas Optimization for Mainnet

**Gas-Saving Techniques:**

```solidity
// BEFORE: Higher gas cost
function addLiquidity(uint256 amount0, uint256 amount1) external {
    // Multiple storage reads
    require(balance0(this) >= amount0);
    require(balance1(this) >= amount1);
}

// AFTER: Optimized
function addLiquidity(uint256 amount0, uint256 amount1) external {
    // Cache in memory
    uint256 balance0Cached = balance0(this);
    uint256 balance1Cached = balance1(this);
    require(balance0Cached >= amount0);
    require(balance1Cached >= amount1);
}

// Use calldata instead of memory for read-only parameters
function receiveMessage(
    CrossChainMessage calldata message,  // calldata is cheaper
    bytes calldata signature
) external {
    // ...
}
```

---

## 7. Testing Checklist Before Mainnet Deployment

### Pre-Mainnet Testing

- [ ] **Unit Tests**: Run `forge test -vvv`
- [ ] **Integration Tests**: Test all three operations
  - [ ] Swap (same chain)
  - [ ] Bridge (cross-chain)
  - [ ] Cross-chain swap (cross-chain)
- [ ] **Fuzz Testing**: Test edge cases
- [ ] **Security Audit**: Have contracts audited
- [ ] **Testnet Deployment**: Deploy to all testnets and verify
- [ ] **Gas Estimation**: Calculate deployment and transaction costs
- [ ] **Load Testing**: Test with high transaction volumes

### Test Coverage Commands

```bash
# Run all tests
forge test

# Run with gas report
forge test --gas-report

# Run coverage report
forge coverage

# Run specific test
forge test --match-test testCrossChainSwap -vvv
```

---

## 8. Deployment Steps

### Step 1: Deploy to Ethereum Mainnet

```bash
# Set your private key
export PRIVATE_KEY=your_mainnet_private_key

# Set Ethereum RPC
export RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY

# Deploy
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast --verify
```

**Estimated Costs:**
- Deployment: ~0.05-0.1 ETH
- Liquidity provision: Variable (depends on amounts)

### Step 2: Deploy to Arbitrum One

```bash
export RPC_URL=https://arb-mainnet.g.alchemy.com/v2/YOUR_KEY

forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast --verify
```

**Estimated Costs:**
- Deployment: ~0.001 ETH
- Much cheaper than Ethereum!

### Step 3: Deploy to Polygon

```bash
export RPC_URL=https://polygon-mainnet.g.alchemy.com/v2/YOUR_KEY

forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast --verify
```

**Estimated Costs:**
- Deployment: ~0.01-0.05 MATIC
- Lowest gas costs!

---

## 9. Post-Deployment Configuration

### Verify Contracts on Etherscan

```bash
# Verify contract
forge verify-contract \
  <CONTRACT_ADDRESS> \
  src/CrossChainPool.sol:CrossChainPool \
  <CONSTRUCTOR_ARGS> \
  --chain-id 1 \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### Update Frontend Configuration

```typescript
// config/mainnet.ts
export const MAINNET_CONFIG = {
  pools: {
    ETH_USDT: '0x...', // Update after deployment
    EURC_USDT: '0x...',
    ETH_EURC: '0x...'
  },
  tokens: {
    ETH: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2', // Real WETH
    USDT: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
    EURC: '0x1a7e4e63778B4f12a199C062f3eFdD269A9C0111'
  },
  chainIds: {
    ethereum: 1,
    arbitrum: 42161,
    polygon: 137
  }
};
```

---

## 10. Monitoring & Maintenance

### Set Up Monitoring

**Key Metrics to Monitor:**
- Total Value Locked (TVL)
- Daily trading volume
- Cross-chain transaction volume
- Gas costs
- Error rates

**Monitoring Tools:**
- [Dune Analytics](https://duneanalytics.com/) - Dashboard creation
- [The Graph](https://thegraph.com/) - Subgraph indexing
- [Tenderly](https://tenderly.co/) - Transaction monitoring
- [OpenZeppelin Sentinel](https://sentinel.openzeppelin.com/) - Security monitoring

### Emergency Procedures

**If issues detected:**
1. Pause contracts: `pool.pause()`
2. Investigate logs
3. Fix issues
4. Unpause: `pool.unpause()`

---

## 11. Cost Summary

### Estimated Mainnet Deployment Costs

| Chain | Deployment | Initial Liquidity (100 ETH + 273k USDT) | Total |
|-------|------------|----------------------------------------|-------|
| Ethereum | ~0.05 ETH (~$150) | $283,000 | ~$283,150 |
| Arbitrum | ~0.001 ETH (~$3) | $283,000 | ~$283,003 |
| Polygon | ~0.01 MATIC (~$0.01) | $283,000 | ~$283,000 |

### Transaction Costs (Per Operation)

| Operation | Ethereum | Arbitrum | Polygon |
|-----------|----------|----------|---------|
| Swap | $2-10 | $0.10-0.50 | $0.01-0.10 |
| Bridge | $3-15 | $0.15-0.75 | $0.02-0.15 |
| Cross-chain swap | $5-20 | $0.20-1.00 | $0.03-0.20 |

---

## 12. Important Reminders

### Security Checklist

- [ ] ✅ Private keys stored securely (never commit to git!)
- [ ] ✅ Use hardware wallets for large transactions
- [ ] ✅ Enable multi-sig for admin functions
- [ ] ✅ Set up monitoring/alerts
- [ ] ✅ Test with small amounts first
- [ ] ✅ Have emergency pause mechanism
- [ ] ✅ Audit contracts before mainnet
- [ ] ✅ Verify all contracts on block explorers

### Real Token Considerations

**IMPORTANT:** When using real tokens:
1. **You cannot mint** real tokens like WETH, USDT, EURC
2. **You must acquire** them from exchanges or other sources
3. **Liquidity requires real funds** - no test tokens!

### Liquidity Provision

**Option A: Bootstrap with own funds**
```bash
# Transfer real WETH and USDT to deployer address
# Then add liquidity via script
```

**Option B: Community liquidity**
- Launch with minimal liquidity
- Incentivize community to provide liquidity
- Use liquidity mining/bonding programs

---

## 13. Quick Migration Command Reference

```bash
# 1. Deploy to Ethereum Mainnet
forge script script/Deploy.s.sol \
  --rpc-url $ETHEREUM_RPC \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY

# 2. Deploy to Arbitrum One
forge script script/Deploy.s.sol \
  --rpc-url $ARBITRUM_RPC \
  --broadcast \
  --verify \
  --verifier-url https://api.arbiscan.io/api \
  --etherscan-api-key $ARBISCAN_API_KEY

# 3. Deploy to Polygon
forge script script/Deploy.s.sol \
  --rpc-url $POLYGON_RPC \
  --broadcast \
  --verify \
  --verifier-url https://api.polygonscan.com/api \
  --etherscan-api-key $POLYGONSCAN_API_KEY

# 4. Test operations on mainnet (with small amounts!)
forge script script/ComprehensiveTest.s.sol \
  --rpc-url $ETHEREUM_RPC \
  --broadcast
```

---

## 14. Common Issues & Solutions

### Issue 1: Insufficient Gas
```bash
# Increase gas limit
forge script ... --gas-limit 30000000
```

### Issue 2: Transaction Stuck
```bash
# Use speedup or cancel
cast send <tx-hash> --gas-price <higher-gwei>
```

### Issue 3: Wrong Contract Address
```bash
# Double-check address before deployment
cast code <address> --rpc-url <rpc-url>
```

### Issue 4: Token Approval Issues
```solidity
// Always check allowance before swapping
uint256 allowance = token.allowance(user, pool);
require(allowance >= amount, "Insufficient allowance");
```

---

## 15. Post-Migration Checklist

- [ ] All contracts deployed and verified
- [ ] Initial liquidity added to all pools
- [ ] Cross-chain functionality tested
- [ ] Frontend updated with mainnet addresses
- [ ] Monitoring dashboards configured
- [ ] Admin keys secured in hardware wallet
- [ ] Documentation updated
- [ ] Community announcement prepared
- [ ] Liquidity mining program (if applicable)
- [ ] Customer support channels ready

---

## 16. Recommended Mainnet Addresses

When deploying to mainnet, document your addresses:

```bash
# AFTER DEPLOYMENT - UPDATE THESE
export MAINNET_TOKEN_ETH="0x..."      # From deployment output
export MAINNET_TOKEN_USDT="0x..."     # From deployment output
export MAINNET_TOKEN_EURC="0x..."     # From deployment output
export MAINNET_POOL_ETH_USDT="0x..."  # From deployment output
export MAINNET_POOL_EURC_USDT="0x..." # From deployment output
export MAINNET_POOL_ETH_EURC="0x..."  # From deployment output
```

---

## Support

For issues during migration:
- Check contract addresses match across chains
- Verify RPC URLs are correct
- Ensure sufficient ETH/MATIC for gas
- Review transaction logs on block explorers

**Remember: This is mainnet with real money. Test thoroughly and start with small amounts!** ⚠️
