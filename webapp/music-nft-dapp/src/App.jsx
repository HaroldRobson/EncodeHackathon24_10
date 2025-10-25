import { useState, useEffect } from 'react'
import './App.css'
import MintNFT from './components/MintNFT'
import BuyNFT from './components/BuyNFT'
import ListNFT from './components/ListNFT'
import MyNFTs from './components/MyNFTs'
import { connectWallet } from './utils/web3'

function App() {
  const [account, setAccount] = useState(null);
  const [signer, setSigner] = useState(null);
  const [currentTab, setCurrentTab] = useState('buy'); // buy, mint, list, my
  const [loading, setLoading] = useState(false);

  const handleConnectWallet = async () => {
    try {
      setLoading(true);
      const { signer, address } = await connectWallet();
      setAccount(address);
      setSigner(signer);
    } catch (error) {
      alert(error.message);
    } finally {
      setLoading(false);
    }
  };

  // Auto-connect if already connected
  useEffect(() => {
    if (window.ethereum) {
      window.ethereum.request({ method: 'eth_accounts' }).then((accounts) => {
        if (accounts.length > 0) {
          handleConnectWallet();
        }
      });
    }
  }, []);

  const renderTabContent = () => {
    if (!account) {
      return (
        <div className="connect-prompt">
          <p>[ CONNECT METAMASK TO BEGIN ]</p>
        </div>
      );
    }

    switch (currentTab) {
      case 'mint':
        return <MintNFT signer={signer} />;
      case 'buy':
        return <BuyNFT signer={signer} account={account} />;
      case 'list':
        return <ListNFT signer={signer} account={account} />;
      case 'my':
        return <MyNFTs signer={signer} account={account} />;
      default:
        return <BuyNFT signer={signer} account={account} />;
    }
  };

  return (
    <div className="App">
      <header className="retro-header">
        <h1 className="title">♫ BAROQUE MUSIC NFT ♫</h1>
        <div className="wallet-info">
          {account ? (
            <span className="address">WALLET: {account.slice(0, 6)}...{account.slice(-4)}</span>
          ) : (
            <button onClick={handleConnectWallet} disabled={loading} className="connect-btn">
              {loading ? '[ CONNECTING... ]' : '[ CONNECT WALLET ]'}
            </button>
          )}
        </div>
      </header>

      <nav className="nav-tabs">
        <button 
          className={`nav-btn ${currentTab === 'buy' ? 'active' : ''}`}
          onClick={() => setCurrentTab('buy')}
        >
          [ BUY MUSIC ]
        </button>
        <button 
          className={`nav-btn ${currentTab === 'mint' ? 'active' : ''}`}
          onClick={() => setCurrentTab('mint')}
        >
          [ MINT NFT ]
        </button>
        <button 
          className={`nav-btn ${currentTab === 'list' ? 'active' : ''}`}
          onClick={() => setCurrentTab('list')}
        >
          [ LIST FOR SALE ]
        </button>
        <button 
          className={`nav-btn ${currentTab === 'my' ? 'active' : ''}`}
          onClick={() => setCurrentTab('my')}
        >
          [ MY COLLECTION ]
        </button>
      </nav>

      <main className="main-content">
        {renderTabContent()}
      </main>

      <footer className="retro-footer">
        <p>POLYGON AMOY TESTNET | CONTRACT: 0x7422...3Ed7</p>
      </footer>
    </div>
  )
}

export default App
