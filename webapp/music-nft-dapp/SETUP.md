# BAROQUE MUSIC NFT MARKETPLACE

Retro Atari-styled decentralized music NFT marketplace on Polygon Amoy testnet.

## 🎵 FEATURES

1. **MINT NFT** - Upload music, artwork, and mint NFTs
2. **BUY NFT** - Browse and purchase music NFTs with USDC
3. **LIST NFT** - List your NFTs for sale (single or bulk)
4. **MY NFTs** - View your collection

## 🚀 SETUP

### Prerequisites
- Node.js installed
- MetaMask browser extension
- Polygon Amoy testnet MATIC (for gas)
- Testnet USDC tokens

### Installation

1. Navigate to project folder:
```bash
cd music-nft-dapp
```

2. Install dependencies (already done if you see node_modules):
```bash
npm install
```

3. **IMPORTANT: Update Pinata API Key**
   
   Open `src/config.js` and replace the PINATA_JWT with your FULL JWT token from Pinata:
   
   ```javascript
   export const PINATA_JWT = "YOUR_FULL_PINATA_JWT_HERE";
   ```
   
   To get your Pinata JWT:
   - Go to https://app.pinata.cloud
   - Sign in/up
   - Go to API Keys
   - Create a new key with pinning permissions
   - Copy the JWT token

4. Start the development server:
```bash
npm run dev
```

5. Open your browser to the URL shown (usually http://localhost:5173)

## 📝 CONTRACT ADDRESSES

- **MusicNFT Contract**: `0x7422e5ed784705497a9b5EF8C4FebEc689083Ed7`
- **USDC Contract**: `0x41e94eb019c0762f9bfcf9fb1e58725bfb0e7582`
- **Network**: Polygon Amoy Testnet (Chain ID: 80002)

## 🎮 USAGE

### Connect Wallet
1. Click "CONNECT WALLET" button
2. MetaMask will pop up - approve the connection
3. Make sure you're on Polygon Amoy testnet (app will prompt to switch)

### Mint an NFT
1. Go to "MINT NFT" tab
2. Enter song title
3. Upload music file (MP3, WAV, etc.)
4. Upload album artwork (JPG, PNG, etc.)
5. Set number of copies (1-100)
6. Click "MINT NFT" - costs 0.1 MATIC
7. Wait for IPFS upload and blockchain confirmation

### Buy an NFT
1. Go to "BUY MUSIC" tab
2. Browse available NFTs
3. Play audio previews
4. Click "BUY NFT" on one you like
5. Approve USDC spending (first transaction)
6. Confirm purchase (second transaction)

### List NFT for Sale
1. Go to "LIST FOR SALE" tab
2. See all your NFTs
3. **Single mode**: Enter price for individual NFT and click "LIST FOR SALE"
4. **Bulk mode**: Enter start/end token IDs and price to list many at once
5. To unlist: Click "UNLIST" button

### View Your Collection
1. Go to "MY COLLECTION" tab
2. See all NFTs you own
3. Play your music
4. Check which are listed for sale

## 🔧 TROUBLESHOOTING

### "MetaMask not installed"
- Install MetaMask browser extension from https://metamask.io

### "Please switch to Polygon Amoy testnet"
- The app will try to switch automatically
- Or manually add Polygon Amoy in MetaMask:
  - Network Name: Polygon Amoy
  - RPC URL: https://rpc-amoy.polygon.technology
  - Chain ID: 80002
  - Currency: MATIC

### "Insufficient funds"
- Get testnet MATIC from: https://faucet.polygon.technology
- Get testnet USDC: You'll need to find an Amoy USDC faucet or have someone send you some

### IPFS upload fails
- Check your Pinata JWT is correct in `src/config.js`
- Make sure your Pinata API key has pinning permissions

### Transaction fails
- Make sure you have enough MATIC for gas
- For buying: Make sure you have enough USDC
- Check MetaMask for error details

## 📁 PROJECT STRUCTURE

```
music-nft-dapp/
├── src/
│   ├── components/         # React components
│   │   ├── MintNFT.jsx    # Minting interface
│   │   ├── BuyNFT.jsx     # Marketplace browse/buy
│   │   ├── ListNFT.jsx    # List NFTs for sale
│   │   └── MyNFTs.jsx     # User's collection
│   ├── contracts/         
│   │   └── MusicNFT.json  # Contract ABI
│   ├── utils/
│   │   ├── ipfs.js        # IPFS/Pinata functions
│   │   └── web3.js        # Blockchain functions
│   ├── config.js          # Contract addresses & config
│   ├── App.jsx            # Main app component
│   ├── App.css            # Retro Atari styling
│   └── main.jsx           # Entry point
├── package.json
└── vite.config.js
```

## 🎨 TECH STACK

- **Frontend**: React + Vite
- **Blockchain**: ethers.js v5
- **Storage**: IPFS via Pinata
- **Styling**: Custom CSS (Retro Atari theme)
- **Network**: Polygon Amoy Testnet

## 💡 NOTES

- Minting costs 0.1 MATIC minimum
- USDC has 6 decimal places
- NFT marketplace takes 5% fee on sales
- All music/artwork stored on IPFS (permanent & decentralized)
- Uses "Option A" for finding user's NFTs (loops through all tokens)

## 📞 SMART CONTRACT FUNCTIONS

The app uses these main contract functions:
- `newSong(uri, amount)` - Mint NFTs
- `whatIsForSale()` - Get NFTs for sale
- `getPrice(id)` - Get NFT price with fee
- `buy(id)` - Purchase NFT
- `listForSale(id, price)` - List single NFT
- `listManyForSale(start, end, price)` - Bulk list
- `unlist(id)` - Remove from sale
- `ownerOf(id)` - Check NFT owner
- `tokenURI(id)` - Get metadata URI

Enjoy your retro music NFT marketplace! 🎵
