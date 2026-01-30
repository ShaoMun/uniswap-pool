# SimplePool Frontend

A simple web interface for sending test tokens on Sepolia testnet.

## Features

- ✅ **Wallet Connection** - Connect your MetaMask wallet
- ✅ **Balance Display** - See your Token A and Token B balances
- ✅ **Send Tokens** - Transfer test tokens to any address
- ✅ **Quick Amounts** - Pre-filled amounts (100, 1K, 10K, 100K)
- ✅ **Transaction Status** - Real-time feedback on transactions

## How to Use

### Option 1: Open Directly in Browser
1. Open `frontend/index.html` in your browser
2. Connect your MetaMask wallet (make sure you're on Sepolia testnet)
3. Enter the recipient address
4. Select the token and amount
5. Click "Send Tokens"

### Option 2: Run with Local Server (Recommended)
```bash
cd frontend

# Python 3
python3 -m http.server 8000

# Or with Python 2
python -m SimpleHTTPServer 8000

# Or with Node.js
npx serve
```

Then open http://localhost:8000 in your browser.

## Requirements

- MetaMask browser extension
- Sepolia testnet ETH for gas fees
- Connected to Sepolia testnet in MetaMask

## Contract Addresses

The frontend is pre-configured with the deployed contracts:
- **Token A**: 0xceA2b1e6De49e1461a552eA1e46e2E6ED48d07fa
- **Token B**: 0x7272232737FC88B945Bf8Ff6a4aABB0De78F94Bf
- **Pool**: 0xe3a464438516D7408dc1c2afdAd5ddE22ACf2280

## Getting Sepolia ETH

1. Go to https://sepoliafaucet.com/
2. Enter your wallet address
3. Complete the captcha
4. Receive 0.1 Sepolia ETH

## Security Notes

⚠️ **TESTNET ONLY** - This is for testing purposes on Sepolia testnet only.

- Never use mainnet private keys
- Tokens have no real value
- Only use with testnet contracts
