import { ethers } from 'ethers';
import { MUSIC_NFT_ADDRESS, USDC_ADDRESS, ERC20_ABI, CHAIN_ID } from '../config';
import MusicNFTABI from '../contracts/MusicNFT.json';

// Connect to MetaMask and get provider/signer
export const connectWallet = async () => {
  if (!window.ethereum) {
    throw new Error('MetaMask not installed!');
  }

  try {
    // Request account access
    await window.ethereum.request({ method: 'eth_requestAccounts' });
    
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const address = await signer.getAddress();
    
    // Check if on correct network
    const network = await provider.getNetwork();
    if (network.chainId !== CHAIN_ID) {
      try {
        await window.ethereum.request({
          method: 'wallet_switchEthereumChain',
          params: [{ chainId: `0x${CHAIN_ID.toString(16)}` }],
        });
      } catch (error) {
        throw new Error('Please switch to Polygon Amoy testnet');
      }
    }
    
    return { provider, signer, address };
  } catch (error) {
    console.error('Error connecting wallet:', error);
    throw error;
  }
};

// Get MusicNFT contract instance
export const getMusicNFTContract = (signer) => {
  return new ethers.Contract(MUSIC_NFT_ADDRESS, MusicNFTABI, signer);
};

// Get USDC contract instance
export const getUSDCContract = (signer) => {
  return new ethers.Contract(USDC_ADDRESS, ERC20_ABI, signer);
};

// Get all NFTs owned by an address
export const getMyNFTs = async (contract, address) => {
  try {
    const totalSupply = await contract.tokenId();
    const myNFTs = [];
    
    for (let i = 0; i < totalSupply.toNumber(); i++) {
      try {
        const owner = await contract.ownerOf(i);
        if (owner.toLowerCase() === address.toLowerCase()) {
          myNFTs.push(i);
        }
      } catch (error) {
        // Token might not exist or be burned, skip it
        continue;
      }
    }
    
    return myNFTs;
  } catch (error) {
    console.error('Error getting my NFTs:', error);
    throw error;
  }
};

// Get all NFTs for sale with their metadata
export const getNFTsForSale = async (contract) => {
  try {
    const forSaleIds = await contract.whatIsForSale();
    return forSaleIds.map(id => id.toNumber());
  } catch (error) {
    console.error('Error getting NFTs for sale:', error);
    throw error;
  }
};

// Get NFT metadata (price, URI, etc)
export const getNFTMetadata = async (contract, tokenId) => {
  try {
    const uri = await contract.tokenURI(tokenId);
    const price = await contract.getPrice(tokenId);
    const isForSale = await contract.isForSale(tokenId);
    const owner = await contract.ownerOf(tokenId);
    
    return {
      tokenId,
      uri,
      price: ethers.utils.formatUnits(price, 6), // USDC has 6 decimals
      isForSale,
      owner
    };
  } catch (error) {
    console.error('Error getting NFT metadata:', error);
    throw error;
  }
};

// Format USDC amount (6 decimals)
export const formatUSDC = (amount) => {
  return ethers.utils.parseUnits(amount.toString(), 6);
};

// Parse USDC amount from wei
export const parseUSDC = (amount) => {
  return ethers.utils.formatUnits(amount, 6);
};
