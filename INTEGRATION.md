# CrossChain AMM Integration Guide

## Deployed Contract Addresses

### Tokens (same on all chains)
| Token | Address | Symbol |
|-------|---------|--------|
| ETH | `0xd33B31e46A8546a34Bd51403C39529fDD1d32334` | WETH |
| USDT | `0x85C805b1f1179cb41B41Fc900A74d2329b52a6D5` | USDT |
| EURC | `0x04f97dc5AE8b1CC5182cfF9F3d0aB2b172C07E42` | EURC |

### Pools (same on all chains)
| Pool | Address | Pair |
|------|---------|------|
| ETH/USDT | `0x9ebeE6de9CcBf810313c73F21E3c448068BbB4FD` | WETH/USDT |
| EURC/USDT | `0x178D446bFCd5F01423Cbe2860131834a6d1F9979` | EURC/USDT |
| ETH/EURC | `0xb8E46b55979d36ea33FDE5acf455021b25E50d8C` | WETH/EURC |

### Chain IDs
| Chain | Chain ID |
|-------|----------|
| Sepolia | `11155111` |
| Arbitrum Sepolia | `421614` |
| Polygon Amoy | `80002` |

---

## Contract ABIs

### MockToken ABI
```json
[
  {
    "inputs": [
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "amount", "type": "uint256"}
    ],
    "name": "faucet",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "uint256", "name": "amount", "type": "uint256"}],
    "name": "mint",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "spender", "type": "address"},
      {"internalType": "uint256", "name": "amount", "type": "uint256"}
    ],
    "name": "approve",
    "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "address", "name": "account", "type": "address"}
    ],
    "name": "balanceOf",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  }
]
```

### CrossChainPool ABI
```json
[
  {
    "inputs": [
      {"internalType": "uint256", "name": "amount0In", "type": "uint256"},
      {"internalType": "uint256", "name": "amount1In", "type": "uint256"},
      {"internalType": "uint256", "name": "amount0OutMinimum", "type": "uint256"},
      {"internalType": "uint256", "name": "amount1OutMinimum", "type": "uint256"},
      {"internalType": "address", "name": "to", "type": "address"}
    ],
    "name": "swap",
    "outputs": [
      {"internalType": "uint256", "name": "amount0Out", "type": "uint256"},
      {"internalType": "uint256", "name": "amount1Out", "type": "uint256"}
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "destChainId", "type": "uint256"},
      {"internalType": "address", "name": "recipient", "type": "address"},
      {"internalType": "uint256", "name": "amount", "type": "uint256"},
      {"internalType": "uint256", "name": "amountOther", "type": "uint256"}
    ],
    "name": "crossChainTransfer",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "uint256", "name": "destChainId", "type": "uint256"},
      {"internalType": "uint256", "name": "amountIn", "type": "uint256"},
      {"internalType": "uint256", "name": "amount0OutMinimum", "type": "uint256"}
    ],
    "name": "crossChainSwap",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"components": [
        {"internalType": "uint256", "name": "sourceChainId", "type": "uint256"},
        {"internalType": "uint256", "name": "destChainId", "type": "uint256"},
        {"internalType": "address", "name": "sender", "type": "address"},
        {"internalType": "address", "name": "recipient", "type": "address"},
        {"internalType": "uint256", "name": "amount0", "type": "uint256"},
        {"internalType": "uint256", "name": "amount1", "type": "uint256"},
        {"internalType": "uint256", "name": "nonce", "type": "uint256"},
        {"internalType": "bytes", "name": "data", "type": "bytes"}
      ]},
      {"internalType": "bytes", "name": "signature", "type": "bytes"}
    ],
    "name": "receiveMessage",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "", "type": "address"}],
    "name": "nonces",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "reserve0",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "reserve1",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  }
]
```

---

## JavaScript/TypeScript Integration (ethers.js v6)

### Setup
```typescript
import { ethers } from 'ethers';

// Contract addresses
const TOKENS = {
  ETH: '0xd33B31e46A8546a34Bd51403C39529fDD1d32334',
  USDT: '0x85C805b1f1179cb41B41Fc900A74d2329b52a6D5',
  EURC: '0x04f97dc5AE8b1CC5182cfF9F3d0aB2b172C07E42'
};

const POOLS = {
  ETH_USDT: '0x9ebeE6de9CcBf810313c73F21E3c448068BbB4FD',
  EURC_USDT: '0x178D446bFCd5F01423Cbe2860131834a6d1F9979',
  ETH_EURC: '0xb8E46b55979d36ea33FDE5acf455021b25E50d8C'
};

const CHAIN_IDS = {
  SEPOLIA: 11155111,
  ARB_SEPOLIA: 421614,
  AMOY: 80002
};

// ABIs (use the JSON above)
const TOKEN_ABI = [...]; // from above
const POOL_ABI = [...];  // from above

// Initialize provider and signer
const provider = new ethers.JsonRpcProvider('YOUR_RPC_URL');
const signer = await ethers.getSigner();
```

---

## Action 1: Swap (Different Currency, Same Chain)

**Description:** Swap ETH for USDT on the same chain

```typescript
async function swapEthForUsdt(ethAmount: string) {
  // 1. Get token and pool contracts
  const ethToken = new ethers.Contract(TOKENS.ETH, TOKEN_ABI, signer);
  const usdtToken = new ethers.Contract(TOKENS.USDT, TOKEN_ABI, signer);
  const pool = new ethers.Contract(POOLS.ETH_USDT, POOL_ABI, signer);

  // 2. Check balances before swap
  const ethBalanceBefore = await ethToken.balanceOf(await signer.getAddress());
  const usdtBalanceBefore = await usdtToken.balanceOf(await signer.getAddress());
  console.log('ETH Balance Before:', ethers.formatEther(ethBalanceBefore));
  console.log('USDT Balance Before:', ethers.formatEther(usdtBalanceBefore));

  // 3. Approve pool to spend ETH
  const amountIn = ethers.parseEther(ethAmount);
  const approveTx = await ethToken.approve(POOLS.ETH_USDT, amountIn);
  await approveTx.wait();
  console.log('Approved', ethAmount, 'ETH');

  // 4. Execute swap
  // Note: In ETH/USDT pool, ETH is token1, USDT is token0
  // So we pass 0 for amount0In and amountIn for amount1In
  const swapTx = await pool.swap(
    0,                              // amount0In (no USDT input)
    amountIn,                       // amount1In (ETH input)
    0,                              // amount0OutMinimum (none)
    0,                              // amount1OutMinimum (none)
    await signer.getAddress()       // recipient
  );
  const receipt = await swapTx.wait();
  console.log('Swap completed!');
  console.log('Transaction Hash:', receipt.hash);

  // 5. Check balances after swap
  const ethBalanceAfter = await ethToken.balanceOf(await signer.getAddress());
  const usdtBalanceAfter = await usdtToken.balanceOf(await signer.getAddress());
  console.log('ETH Balance After:', ethers.formatEther(ethBalanceAfter));
  console.log('USDT Balance After:', ethers.formatEther(usdtBalanceAfter));
  console.log('USDT Received:', ethers.formatEther(usdtBalanceAfter - usdtBalanceBefore));

  return receipt.hash;
}

// Usage
const txHash = await swapEthForUsdt('10'); // Swap 10 ETH for USDT
```

**Example Output:**
```
ETH Balance Before: 599790.0
USDT Balance Before: 1742628.0
Approved 10 ETH
Swap completed!
Transaction Hash: 0x35ced392e9443a69c67b4bab195407c4c91d081bbd499bd66d6dda7e4c3ca0f7
ETH Balance After: 599780.0
USDT Balance After: 1767404.0
USDT Received: 24776.0
```

---

## Action 2: Bridge (Same Currency, Different Chain)

**Description:** Bridge ETH from Sepolia to Arbitrum Sepolia

```typescript
async function bridgeEth(
  amount: string,
  destChainId: number
) {
  // 1. Get contracts on SOURCE chain
  const ethToken = new ethers.Contract(TOKENS.ETH, TOKEN_ABI, signer);
  const pool = new ethers.Contract(POOLS.ETH_USDT, POOL_ABI, signer);

  // 2. Check balance before
  const balanceBefore = await ethToken.balanceOf(await signer.getAddress());
  console.log('ETH Balance Before:', ethers.formatEther(balanceBefore));

  // 3. Approve pool to spend ETH
  const amountIn = ethers.parseEther(amount);
  const approveTx = await ethToken.approve(POOLS.ETH_USDT, amountIn);
  await approveTx.wait();
  console.log('Approved', amount, 'ETH');

  // 4. Initiate bridge
  const bridgeTx = await pool.crossChainTransfer(
    destChainId,                    // destination chain ID
    await signer.getAddress(),       // recipient address
    amountIn,                       // ETH amount to bridge
    0                               // amountOther (not used)
  );
  const receipt = await bridgeTx.wait();
  console.log('Bridge initiated!');
  console.log('Transaction Hash:', receipt.hash);

  // 5. Check balance after
  const balanceAfter = await ethToken.balanceOf(await signer.getAddress());
  console.log('ETH Balance After:', ethers.formatEther(balanceAfter));
  console.log('ETH Bridged:', ethers.formatEther(balanceBefore - balanceAfter));

  // 6. Return transaction info for completing the bridge
  return {
    txHash: receipt.hash,
    sourceChain: await signer.getChainId(),
    destChain: destChainId,
    amount: amount,
    recipient: await signer.getAddress()
  };
}

// Usage
const bridgeInfo = await bridgeEth('5', CHAIN_IDS.ARB_SEPOLIA);
// Later: complete the bridge on destination chain
```

**Completing the Bridge on Destination Chain:**

```typescript
async function completeBridge(
  sourceChainId: number,
  recipientAddress: string
) {
  const pool = new ethers.Contract(POOLS.ETH_USDT, POOL_ABI, signer);
  const ethToken = new ethers.Contract(TOKENS.ETH, TOKEN_ABI, signer);

  // 1. Get current nonce
  const nonce = await pool.nonces(recipientAddress);
  console.log('Nonce:', nonce.toString());

  // 2. Check balance before
  const balanceBefore = await ethToken.balanceOf(recipientAddress);
  console.log('ETH Balance Before:', ethers.formatEther(balanceBefore));

  // 3. Create message
  const message = {
    sourceChainId: sourceChainId,
    destChainId: await signer.getChainId(),
    sender: recipientAddress,
    recipient: recipientAddress,
    amount0: ethers.parseEther('5'),  // Must match bridge amount
    amount1: 0,
    nonce: nonce,
    data: '0x'
  };

  // 4. Sign message
  const messageHash = ethers.solidityPackedKeccak256(
    ['uint256', 'uint256', 'address', 'address', 'uint256', 'uint256', 'uint256', 'bytes'],
    [
      message.sourceChainId,
      message.destChainId,
      message.sender,
      message.recipient,
      message.amount0,
      message.amount1,
      message.nonce,
      message.data
    ]
  );

  const signature = await signer.signMessage(ethers.getBytes(messageHash));

  // 5. Complete bridge
  const completeTx = await pool.receiveMessage(message, signature);
  const receipt = await completeTx.wait();
  console.log('Bridge completed!');
  console.log('Transaction Hash:', receipt.hash);

  // 6. Check balance after
  const balanceAfter = await ethToken.balanceOf(recipientAddress);
  console.log('ETH Balance After:', ethers.formatEther(balanceAfter));
  console.log('ETH Received:', ethers.formatEther(balanceAfter - balanceBefore));

  return receipt.hash;
}

// Usage on destination chain
const completeTxHash = await completeBridge(
  CHAIN_IDS.SEPOLIA,
  '0x07dab64Aa125B206D7fd6a81AaB2133A0bdEF863'
);
```

**Example Output:**
```
Source Chain (Sepolia):
ETH Balance Before: 599780.0
Approved 5 ETH
Bridge initiated!
Transaction Hash: 0xabf202454d1d016dfef593eca6a7de19417213929aa5b3e49023e6eb049ff733
ETH Balance After: 599775.0
ETH Bridged: 5.0

Destination Chain (Arbitrum Sepolia):
Nonce: 0
ETH Balance Before: 599775.0
Bridge completed!
Transaction Hash: 0x...
ETH Balance After: 599780.0
ETH Received: 5.0
```

---

## Action 3: Cross-Chain Swap (Different Currency, Different Chain)

**Description:** Swap ETH for USDT from Sepolia to Arbitrum Sepolia

```typescript
async function crossChainSwap(
  ethAmount: string,
  destChainId: number,
  minAmountOut: string = '0'
) {
  const ethToken = new ethers.Contract(TOKENS.ETH, TOKEN_ABI, signer);
  const usdtToken = new ethers.Contract(TOKENS.USDT, TOKEN_ABI, signer);
  const pool = new ethers.Contract(POOLS.ETH_USDT, POOL_ABI, signer);

  // 1. Check balances before
  const ethBalanceBefore = await ethToken.balanceOf(await signer.getAddress());
  const usdtBalanceBefore = await usdtToken.balanceOf(await signer.getAddress());
  console.log('Source Chain:', await signer.getChainId());
  console.log('ETH Balance Before:', ethers.formatEther(ethBalanceBefore));
  console.log('USDT Balance Before:', ethers.formatEther(usdtBalanceBefore));

  // 2. Approve pool to spend ETH
  const amountIn = ethers.parseEther(ethAmount);
  const approveTx = await ethToken.approve(POOLS.ETH_USDT, amountIn);
  await approveTx.wait();
  console.log('Approved', ethAmount, 'ETH');

  // 3. Initiate cross-chain swap
  const swapTx = await pool.crossChainSwap(
    destChainId,                      // destination chain
    amountIn,                         // ETH input amount
    ethers.parseEther(minAmountOut)   // minimum USDT out (slippage protection)
  );
  const receipt = await swapTx.wait();
  console.log('Cross-chain swap initiated!');
  console.log('Transaction Hash:', receipt.hash);

  // 4. Check balances after
  const ethBalanceAfter = await ethToken.balanceOf(await signer.getAddress());
  console.log('ETH Balance After:', ethers.formatEther(ethBalanceAfter));
  console.log('ETH Spent:', ethers.formatEther(ethBalanceBefore - ethBalanceAfter));
  console.log('\nNOTE: Complete the swap on destination chain to receive USDT');

  return {
    txHash: receipt.hash,
    sourceChain: await signer.getChainId(),
    destChain: destChainId,
    amountIn: ethAmount,
    recipient: await signer.getAddress()
  };
}

// Usage
const swapInfo = await crossChainSwap(
  '3',
  CHAIN_IDS.ARB_SEPOLIA,
  '7000'  // Minimum 7000 USDT expected (slippage protection)
);
```

**Completing Cross-Chain Swap on Destination Chain:**

```typescript
async function completeCrossChainSwap(
  sourceChainId: number,
  recipientAddress: string
) {
  const pool = new ethers.Contract(POOLS.ETH_USDT, POOL_ABI, signer);
  const usdtToken = new ethers.Contract(TOKENS.USDT, TOKEN_ABI, signer);

  // 1. Get current nonce
  const nonce = await pool.nonces(recipientAddress);
  console.log('Nonce:', nonce.toString());

  // 2. Check USDT balance before
  const usdtBalanceBefore = await usdtToken.balanceOf(recipientAddress);
  console.log('Destination Chain:', await signer.getChainId());
  console.log('USDT Balance Before:', ethers.formatEther(usdtBalanceBefore));

  // 3. Create message (amount0 is ETH input after 0.1% fee)
  const message = {
    sourceChainId: sourceChainId,
    destChainId: await signer.getChainId(),
    sender: recipientAddress,
    recipient: recipientAddress,
    amount0: ethers.parseEther('2.997'),  // 3 ETH - 0.1% fee
    amount1: 0,
    nonce: nonce,
    data: ethers.toUtf8Bytes('SWAP')
  };

  // 4. Sign message
  const domain = {
    name: 'CrossChainPool',
    version: '1',
    chainId: await signer.getChainId(),
    verifyingContract: POOLS.ETH_USDT
  };

  const types = {
    CrossChainMessage: [
      { name: 'sourceChainId', type: 'uint256' },
      { name: 'destChainId', type: 'uint256' },
      { name: 'sender', type: 'address' },
      { name: 'recipient', type: 'address' },
      { name: 'amount0', type: 'uint256' },
      { name: 'amount1', type: 'uint256' },
      { name: 'nonce', type: 'uint256' },
      { name: 'data', type: 'bytes' }
    ]
  };

  const signature = await signer.signTypedData(domain, types, message);

  // 5. Complete cross-chain swap
  const completeTx = await pool.receiveMessage(message, signature);
  const receipt = await completeTx.wait();
  console.log('Cross-chain swap completed!');
  console.log('Transaction Hash:', receipt.hash);

  // 6. Check USDT balance after
  const usdtBalanceAfter = await usdtToken.balanceOf(recipientAddress);
  console.log('USDT Balance After:', ethers.formatEther(usdtBalanceAfter));
  console.log('USDT Received:', ethers.formatEther(usdtBalanceAfter - usdtBalanceBefore));

  return receipt.hash;
}

// Usage on destination chain
const completeTxHash = await completeCrossChainSwap(
  CHAIN_IDS.SEPOLIA,
  '0x07dab64Aa125B206D7fd6a81AaB2133A0bdEF863'
);
```

**Example Output:**
```
Source Chain (Sepolia):
Source Chain: 11155111
ETH Balance Before: 599775.0
USDT Balance Before: 1767404.0
Approved 3 ETH
Cross-chain swap initiated!
Transaction Hash: 0x4ceae81f477c3e7859f67d892955938dd18fa4c9dcacc249ed29992764bf5899
ETH Balance After: 599772.0
ETH Spent: 3.0

Destination Chain (Arbitrum Sepolia):
Nonce: 0
Destination Chain: 421614
USDT Balance Before: 1767404.0
Cross-chain swap completed!
Transaction Hash: 0x...
USDT Balance After: 1773956.0
USDT Received: 6552.0
```

---

## React Integration Example

```typescript
import { ethers } from 'ethers';
import { useState } from 'react';

function CrossChainAMM() {
  const [provider, setProvider] = useState();
  const [signer, setSigner] = useState();

  // Connect wallet
  const connectWallet = async () => {
    if (window.ethereum) {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      setProvider(provider);
      setSigner(signer);
    }
  };

  // Swap ETH for USDT
  const swap = async (amount: string) => {
    const ethToken = new ethers.Contract(TOKENS.ETH, TOKEN_ABI, signer);
    const pool = new ethers.Contract(POOLS.ETH_USDT, POOL_ABI, signer);

    const amountIn = ethers.parseEther(amount);
    await ethToken.approve(POOLS.ETH_USDT, amountIn);

    const tx = await pool.swap(
      0,                              // amount0In
      amountIn,                       // amount1In
      0,                              // amount0OutMinimum
      0,                              // amount1OutMinimum
      await signer.getAddress()
    );

    await tx.wait();
    console.log('Swap completed:', tx.hash);
    return tx.hash;
  };

  // Bridge ETH to another chain
  const bridge = async (amount: string, destChain: number) => {
    const ethToken = new ethers.Contract(TOKENS.ETH, TOKEN_ABI, signer);
    const pool = new ethers.Contract(POOLS.ETH_USDT, POOL_ABI, signer);

    const amountIn = ethers.parseEther(amount);
    await ethToken.approve(POOLS.ETH_USDT, amountIn);

    const tx = await pool.crossChainTransfer(
      destChain,
      await signer.getAddress(),
      amountIn,
      0
    );

    await tx.wait();
    console.log('Bridge initiated:', tx.hash);
    return tx.hash;
  };

  return (
    <div>
      <button onClick={connectWallet}>Connect Wallet</button>
      {/* Your UI here */}
    </div>
  );
}
```

---

## Important Notes

1. **Gas Fees**: Each transaction requires gas on the source chain
2. **Bridge Fees**: Cross-chain operations have a 0.1% fee
3. **Slippage**: Always set appropriate minimum output amounts
4. **Confirmation Times**: Bridge completion requires manual transaction on destination chain
5. **Nonce Management**: Each cross-chain operation increments the sender's nonce
6. **Signature Verification**: The signature must be from the original sender

---

## Transaction Links (Sepolia Testnet)

### Swap
- [Swap Transaction](https://sepolia.etherscan.io/tx/0x35ced392e9443a69c67b4bab195407c4c91d081bbd499bd66d6dda7e4c3ca0f7)

### Bridge
- [Bridge Transaction](https://sepolia.etherscan.io/tx/0xabf202454d1d016dfef593eca6a7de19417213929aa5b3e49023e6eb049ff733)

### Cross-Chain Swap
- [Cross-Chain Swap Transaction](https://sepolia.etherscan.io/tx/0x4ceae81f477c3e7859f67d892955938dd18fa4c9dcacc249ed29992764bf5899)
