import { useEffect, useState } from "react";

export default function PetraWalletConnect() {
  const [address, setAddress] = useState(null);

  useEffect(() => {
    if (window.aptos) {
      window.aptos.connect().then(() => {
        const connectedAddress = window.aptos.account.address;
        console.log("Connected address:", connectedAddress);
        setAddress(connectedAddress);
      }).catch(error => {
        console.error("Error connecting to Petra wallet:", error);
      });
    }
  }, []);

  return (
    <div>
      <h3>Petra Wallet Connection</h3>
      {address ? (
        <p>Connected Address: {address}</p>
      ) : (
        <p>Connecting to Petra Wallet...</p>
      )}
    </div>
  );
}
