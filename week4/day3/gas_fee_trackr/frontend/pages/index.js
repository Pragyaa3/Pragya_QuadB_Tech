import { useEffect, useState } from 'react';
import { AptosClient, AptosAccount, TokenClient } from 'aptos';

export default function Home() {
  const [gasFees, setGasFees] = useState(null);
  const [error, setError] = useState(null);
  const [walletAddress, setWalletAddress] = useState(null);

  useEffect(() => {
    const fetchGasFees = async () => {
      try {
        const response = await fetch('/api/gas-fees');
        const data = await response.json();
        setGasFees(data);
      } catch (err) {
        setError('Failed to load gas fees');
      }
    };

    fetchGasFees();
  }, []);

  useEffect(() => {
    const connectWallet = async () => {
      if (window.aptos) {
        const aptos = window.aptos; // Assuming you're using Petra wallet extension

        try {
          const account = await aptos.connect(); // Connect to Petra
          setWalletAddress(account.address);
        } catch (error) {
          console.error("Failed to connect wallet:", error);
        }
      } else {
        alert("Petra wallet is not installed.");
      }
    };

    connectWallet();
  }, []);

  return (
    <div>
      <h1>Welcome to the Homepage</h1>
      <p>This is some additional content.</p>

      {error && <p>{error}</p>}

      {walletAddress ? (
        <div>
          <p><strong>Connected Wallet Address:</strong> {walletAddress}</p>
        </div>
      ) : (
        <div>
          <p>Connecting to wallet...</p>
        </div>
      )}

      {gasFees ? (
        <div>
          <h2>Gas Fee Data</h2>

          <div>
            <p><strong>Gas Used:</strong> {gasFees.gas_used}</p>
            <p><strong>Gas Unit Price:</strong> {gasFees.gas_unit_price} Octas</p>
            <p><strong>Sender:</strong> {gasFees.sender}</p>
            <p><strong>Transaction Type:</strong> {gasFees.transaction_type}</p>
            <p><strong>Success:</strong> {gasFees.success ? 'Yes' : 'No'}</p>
          </div>

          <div>
            <h3>State Operations</h3>
            <p><strong>Gas used for creating state:</strong> {gasFees.create_state_gas_used || 'N/A'}</p>
            <p><strong>Gas used for refunding state:</strong> {gasFees.refund_state_gas_used || 'N/A'}</p>
          </div>
        </div>
      ) : (
        <p>Loading gas fee data...</p>
      )}
    </div>
  );
}
