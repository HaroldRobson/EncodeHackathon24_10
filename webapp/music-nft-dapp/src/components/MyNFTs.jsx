import { useState, useEffect } from 'react';
import { getMusicNFTContract, getMyNFTs } from '../utils/web3';
import { fetchFromIPFS, ipfsToHttp } from '../utils/ipfs';

function MyNFTs({ signer, account }) {
  const [myNFTs, setMyNFTs] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadMyNFTs();
  }, [signer, account]);

  const loadMyNFTs = async () => {
    try {
      setLoading(true);
      const contract = getMusicNFTContract(signer);
      
      // Get my token IDs
      const tokenIds = await getMyNFTs(contract, account);
      
      // Fetch metadata for each
      const nftData = await Promise.all(
        tokenIds.map(async (tokenId) => {
          try {
            const uri = await contract.tokenURI(tokenId);
            const isForSale = await contract.isForSale(tokenId);
            const price = isForSale ? await contract.priceInUSDC(tokenId) : null;
            
            // Fetch metadata from IPFS
            const metadata = await fetchFromIPFS(uri);
            
            return {
              tokenId,
              title: metadata.name,
              imageUrl: ipfsToHttp(metadata.image),
              audioUrl: ipfsToHttp(metadata.audio),
              isForSale,
              price: price ? price.toString() : null
            };
          } catch (error) {
            console.error(`Error loading NFT ${tokenId}:`, error);
            return null;
          }
        })
      );
      
      setMyNFTs(nftData.filter(nft => nft !== null));
    } catch (error) {
      console.error('Error loading my NFTs:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="loading">[ LOADING YOUR COLLECTION... ]</div>;
  }

  if (myNFTs.length === 0) {
    return (
      <div className="empty-state">
        <p>[ YOU DON'T OWN ANY NFTs YET ]</p>
        <p>MINT OR BUY SOME!</p>
      </div>
    );
  }

  return (
    <div className="my-nfts">
      <h2 className="section-title">[ MY MUSIC COLLECTION ]</h2>
      <p style={{ marginBottom: '20px', opacity: 0.8 }}>
        You own {myNFTs.length} NFT{myNFTs.length !== 1 ? 's' : ''}
      </p>
      
      <div className="nft-grid">
        {myNFTs.map((nft) => (
          <div key={nft.tokenId} className="nft-card">
            <img src={nft.imageUrl} alt={nft.title} className="nft-image" />
            <h3 className="nft-title">{nft.title}</h3>
            <p className="nft-info">TOKEN ID: #{nft.tokenId}</p>
            <p className="nft-info">
              STATUS: {nft.isForSale ? 
                `LISTED FOR ${nft.price / 1000000} USDC` : 
                'NOT LISTED'}
            </p>
            
            <audio controls className="audio-player" src={nft.audioUrl}>
              Your browser does not support audio.
            </audio>
          </div>
        ))}
      </div>
    </div>
  );
}

export default MyNFTs;
