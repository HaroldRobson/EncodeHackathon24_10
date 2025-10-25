import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { getMusicNFTContract, getUSDCContract, formatUSDC } from '../utils/web3';
import { fetchFromIPFS, ipfsToHttp } from '../utils/ipfs';

function BuyNFT({ signer, account }) {
  const [nftsForSale, setNftsForSale] = useState([]);
  const [loading, setLoading] = useState(true);
  const [buying, setBuying] = useState(null);

  useEffect(() => {
    loadNFTsForSale();
  }, [signer]);

  const loadNFTsForSale = async () => {
    try {
      setLoading(true);
      const contract = getMusicNFTContract(signer);
      
      // Get all token IDs for sale
      const forSaleIds = await contract.whatIsForSale();
      
      // Fetch metadata for each
      const nftData = await Promise.all(
        forSaleIds.map(async (id) => {
          try {
            const tokenId = id.toNumber();
            const uri = await contract.tokenURI(tokenId);
            const price = await contract.getPrice(tokenId);
            const owner = await contract.ownerOf(tokenId);
            
            // Fetch metadata from IPFS
            const metadata = await fetchFromIPFS(uri);
            
            return {
              tokenId,
              title: metadata.name,
              imageUrl: ipfsToHttp(metadata.image),
              audioUrl: ipfsToHttp(metadata.audio),
              price: ethers.utils.formatUnits(price, 6),
              owner
            };
          } catch (error) {
            console.error(`Error loading NFT ${id}:`, error);
            return null;
          }
        })
      );
      
      setNftsForSale(nftData.filter(nft => nft !== null));
    } catch (error) {
      console.error('Error loading NFTs:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleBuy = async (tokenId, price) => {
    try {
      setBuying(tokenId);
      const musicContract = getMusicNFTContract(signer);
      const usdcContract = getUSDCContract(signer);
      
      // Convert price to USDC amount (6 decimals)
      const priceInUSDC = formatUSDC(price);
      
      // Step 1: Approve USDC spending
      console.log('Approving USDC...');
      const approveTx = await usdcContract.approve(musicContract.address, priceInUSDC);
      await approveTx.wait();
      
      // Step 2: Buy the NFT
      console.log('Buying NFT...');
      const buyTx = await musicContract.buy(tokenId);
      await buyTx.wait();
      
      alert('[ SUCCESS! NFT PURCHASED! ]');
      
      // Reload the list
      loadNFTsForSale();
    } catch (error) {
      console.error('Buy error:', error);
      alert('[ ERROR: ' + error.message + ' ]');
    } finally {
      setBuying(null);
    }
  };

  if (loading) {
    return <div className="loading">[ LOADING NFTs... ]</div>;
  }

  if (nftsForSale.length === 0) {
    return (
      <div className="empty-state">
        <p>[ NO NFTS FOR SALE YET ]</p>
        <p>BE THE FIRST TO MINT!</p>
      </div>
    );
  }

  return (
    <div className="buy-nft">
      <h2 className="section-title">[ MUSIC NFTs FOR SALE ]</h2>
      
      <div className="nft-grid">
        {nftsForSale.map((nft) => (
          <div key={nft.tokenId} className="nft-card">
            <img src={nft.imageUrl} alt={nft.title} className="nft-image" />
            <h3 className="nft-title">{nft.title}</h3>
            <p className="nft-info">TOKEN ID: #{nft.tokenId}</p>
            <p className="nft-info">SELLER: {nft.owner.slice(0, 6)}...{nft.owner.slice(-4)}</p>
            <p className="nft-price">{nft.price} USDC</p>
            
            <audio controls className="audio-player" src={nft.audioUrl}>
              Your browser does not support audio.
            </audio>
            
            <button 
              onClick={() => handleBuy(nft.tokenId, nft.price)}
              disabled={buying === nft.tokenId || nft.owner.toLowerCase() === account.toLowerCase()}
            >
              {buying === nft.tokenId ? '[ BUYING... ]' : 
               nft.owner.toLowerCase() === account.toLowerCase() ? '[ YOU OWN THIS ]' :
               '[ BUY NFT ]'}
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}

export default BuyNFT;
