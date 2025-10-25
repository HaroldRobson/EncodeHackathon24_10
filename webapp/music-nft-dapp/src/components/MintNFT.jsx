import { useState } from 'react';
import { ethers } from 'ethers';
import { uploadFileToIPFS, uploadJSONToIPFS } from '../utils/ipfs';
import { getMusicNFTContract } from '../utils/web3';

function MintNFT({ signer }) {
  const [title, setTitle] = useState('');
  const [musicFile, setMusicFile] = useState(null);
  const [artworkFile, setArtworkFile] = useState(null);
  const [amount, setAmount] = useState(1);
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState('');

  const handleMint = async () => {
    if (!title || !musicFile || !artworkFile) {
      alert('Please fill all fields!');
      return;
    }

    if (amount < 1 || amount > 100) {
      alert('Amount must be between 1 and 100');
      return;
    }

    try {
      setLoading(true);
      setStatus('[ UPLOADING MUSIC TO IPFS... ]');
      
      // Upload music file
      const musicUri = await uploadFileToIPFS(musicFile);
      console.log('Music uploaded:', musicUri);
      
      setStatus('[ UPLOADING ARTWORK TO IPFS... ]');
      
      // Upload artwork
      const artworkUri = await uploadFileToIPFS(artworkFile);
      console.log('Artwork uploaded:', artworkUri);
      
      setStatus('[ CREATING METADATA... ]');
      
      // Create and upload metadata JSON
      const metadata = {
        name: title,
        image: artworkUri,
        audio: musicUri,
        description: `Music NFT: ${title}`
      };
      
      const metadataUri = await uploadJSONToIPFS(metadata);
      console.log('Metadata uploaded:', metadataUri);
      
      setStatus('[ MINTING NFT ON BLOCKCHAIN... ]');
      
      // Mint NFT
      const contract = getMusicNFTContract(signer);
      const tx = await contract.newSong(metadataUri, amount, {
        value: ethers.utils.parseEther('0.1001')
      });
      
      setStatus('[ WAITING FOR CONFIRMATION... ]');
      await tx.wait();
      
      setStatus('[ SUCCESS! NFT MINTED! ]');
      
      // Reset form
      setTimeout(() => {
        setTitle('');
        setMusicFile(null);
        setArtworkFile(null);
        setAmount(1);
        setStatus('');
        // Reset file inputs
        document.getElementById('music-file').value = '';
        document.getElementById('artwork-file').value = '';
      }, 3000);
      
    } catch (error) {
      console.error('Mint error:', error);
      setStatus('[ ERROR: ' + error.message + ' ]');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="mint-nft">
      <h2 className="section-title">[ MINT NEW MUSIC NFT ]</h2>
      
      <div className="form-group">
        <label>SONG TITLE:</label>
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Enter song title..."
          disabled={loading}
        />
      </div>

      <div className="form-group">
        <label>MUSIC FILE (MP3, WAV, etc):</label>
        <input
          id="music-file"
          type="file"
          accept="audio/*"
          onChange={(e) => setMusicFile(e.target.files[0])}
          disabled={loading}
        />
      </div>

      <div className="form-group">
        <label>ALBUM ARTWORK (JPG, PNG):</label>
        <input
          id="artwork-file"
          type="file"
          accept="image/*"
          onChange={(e) => setArtworkFile(e.target.files[0])}
          disabled={loading}
        />
      </div>

      <div className="form-group">
        <label>NUMBER OF COPIES TO MINT (1-100):</label>
        <input
          type="number"
          min="1"
          max="100"
          value={amount}
          onChange={(e) => setAmount(parseInt(e.target.value))}
          disabled={loading}
        />
      </div>

      <button onClick={handleMint} disabled={loading}>
        {loading ? '[ PROCESSING... ]' : '[ MINT NFT (0.1 MATIC) ]'}
      </button>

      {status && (
        <div className="status-message">
          {status}
        </div>
      )}

      <div style={{ marginTop: '30px', opacity: 0.7, fontSize: '13px' }}>
        <p>NOTE: You must pay 0.1 MATIC to mint.</p>
        <p>This will create {amount} identical NFT{amount > 1 ? 's' : ''} of this song.</p>
      </div>
    </div>
  );
}

export default MintNFT;
