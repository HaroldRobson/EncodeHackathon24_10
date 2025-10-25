import { useState, useEffect } from 'react';
import { getMusicNFTContract, getMyNFTs, formatUSDC } from '../utils/web3';
import { fetchFromIPFS, ipfsToHttp } from '../utils/ipfs';

function ListNFT({ signer, account }) {
  const [myNFTs, setMyNFTs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(null);
  const [prices, setPrices] = useState({});
  const [bulkMode, setBulkMode] = useState(false);
  const [bulkStart, setBulkStart] = useState('');
  const [bulkEnd, setBulkEnd] = useState('');
  const [bulkPrice, setBulkPrice] = useState('');

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
            const currentPrice = isForSale ? await contract.priceInUSDC(tokenId) : null;
            
            // Fetch metadata from IPFS
            const metadata = await fetchFromIPFS(uri);
            
            return {
              tokenId,
              title: metadata.name,
              imageUrl: ipfsToHttp(metadata.image),
              isForSale,
              currentPrice: currentPrice ? (currentPrice.toNumber() / 1000000).toString() : null
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

  const handleList = async (tokenId) => {
    const price = prices[tokenId];
    if (!price || parseFloat(price) <= 0) {
      alert('Please enter a valid price!');
      return;
    }

    try {
      setProcessing(tokenId);
      const contract = getMusicNFTContract(signer);
      
      // Convert price to USDC units (6 decimals)
      const priceInUSDC = formatUSDC(price);
      
      const tx = await contract.listForSale(tokenId, priceInUSDC);
      await tx.wait();
      
      alert('[ SUCCESS! NFT LISTED! ]');
      loadMyNFTs();
    } catch (error) {
      console.error('List error:', error);
      alert('[ ERROR: ' + error.message + ' ]');
    } finally {
      setProcessing(null);
    }
  };

  const handleUnlist = async (tokenId) => {
    try {
      setProcessing(tokenId);
      const contract = getMusicNFTContract(signer);
      
      const tx = await contract.unlist(tokenId);
      await tx.wait();
      
      alert('[ SUCCESS! NFT UNLISTED! ]');
      loadMyNFTs();
    } catch (error) {
      console.error('Unlist error:', error);
      alert('[ ERROR: ' + error.message + ' ]');
    } finally {
      setProcessing(null);
    }
  };

  const handleBulkList = async () => {
    if (!bulkStart || !bulkEnd || !bulkPrice) {
      alert('Please fill all fields!');
      return;
    }

    const start = parseInt(bulkStart);
    const end = parseInt(bulkEnd);
    const price = parseFloat(bulkPrice);

    if (start > end) {
      alert('Start ID must be less than or equal to End ID!');
      return;
    }

    if (price <= 0) {
      alert('Please enter a valid price!');
      return;
    }

    try {
      setProcessing('bulk');
      const contract = getMusicNFTContract(signer);
      
      const priceInUSDC = formatUSDC(price);
      
      const tx = await contract.listManyForSale(start, end, priceInUSDC);
      await tx.wait();
      
      alert(`[ SUCCESS! NFTs ${start}-${end} LISTED! ]`);
      setBulkStart('');
      setBulkEnd('');
      setBulkPrice('');
      loadMyNFTs();
    } catch (error) {
      console.error('Bulk list error:', error);
      alert('[ ERROR: ' + error.message + ' ]');
    } finally {
      setProcessing(null);
    }
  };

  if (loading) {
    return <div className="loading">[ LOADING YOUR NFTs... ]</div>;
  }

  if (myNFTs.length === 0) {
    return (
      <div className="empty-state">
        <p>[ YOU DON'T OWN ANY NFTs TO LIST ]</p>
        <p>MINT SOME FIRST!</p>
      </div>
    );
  }

  return (
    <div className="list-nft">
      <h2 className="section-title">[ LIST NFTs FOR SALE ]</h2>
      
      <div style={{ marginBottom: '30px' }}>
        <button onClick={() => setBulkMode(!bulkMode)}>
          {bulkMode ? '[ SWITCH TO SINGLE MODE ]' : '[ SWITCH TO BULK MODE ]'}
        </button>
      </div>

      {bulkMode && (
        <div style={{ 
          border: '2px solid var(--green)', 
          padding: '20px', 
          marginBottom: '30px',
          background: 'var(--grey)'
        }}>
          <h3 style={{ marginBottom: '15px', letterSpacing: '2px' }}>[ BULK LIST MODE ]</h3>
          <p style={{ opacity: 0.8, marginBottom: '20px', fontSize: '13px' }}>
            List multiple NFTs with consecutive IDs at the same price
          </p>
          
          <div className="form-group">
            <label>START TOKEN ID:</label>
            <input
              type="number"
              value={bulkStart}
              onChange={(e) => setBulkStart(e.target.value)}
              placeholder="e.g., 5"
              disabled={processing}
            />
          </div>

          <div className="form-group">
            <label>END TOKEN ID:</label>
            <input
              type="number"
              value={bulkEnd}
              onChange={(e) => setBulkEnd(e.target.value)}
              placeholder="e.g., 10"
              disabled={processing}
            />
          </div>

          <div className="form-group">
            <label>PRICE (USDC):</label>
            <input
              type="number"
              step="0.01"
              value={bulkPrice}
              onChange={(e) => setBulkPrice(e.target.value)}
              placeholder="e.g., 5.00"
              disabled={processing}
            />
          </div>

          <button onClick={handleBulkList} disabled={processing}>
            {processing === 'bulk' ? '[ LISTING... ]' : '[ LIST MANY NFTs ]'}
          </button>
        </div>
      )}

      <div className="nft-grid">
        {myNFTs.map((nft) => (
          <div key={nft.tokenId} className="nft-card">
            <img src={nft.imageUrl} alt={nft.title} className="nft-image" />
            <h3 className="nft-title">{nft.title}</h3>
            <p className="nft-info">TOKEN ID: #{nft.tokenId}</p>
            
            {nft.isForSale ? (
              <>
                <p className="nft-price">LISTED: {nft.currentPrice} USDC</p>
                <button 
                  onClick={() => handleUnlist(nft.tokenId)}
                  disabled={processing === nft.tokenId}
                >
                  {processing === nft.tokenId ? '[ UNLISTING... ]' : '[ UNLIST ]'}
                </button>
              </>
            ) : (
              <>
                <div className="form-group">
                  <label>PRICE (USDC):</label>
                  <input
                    type="number"
                    step="0.01"
                    value={prices[nft.tokenId] || ''}
                    onChange={(e) => setPrices({...prices, [nft.tokenId]: e.target.value})}
                    placeholder="e.g., 5.00"
                    disabled={processing === nft.tokenId}
                  />
                </div>
                <button 
                  onClick={() => handleList(nft.tokenId)}
                  disabled={processing === nft.tokenId}
                >
                  {processing === nft.tokenId ? '[ LISTING... ]' : '[ LIST FOR SALE ]'}
                </button>
              </>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

export default ListNFT;
