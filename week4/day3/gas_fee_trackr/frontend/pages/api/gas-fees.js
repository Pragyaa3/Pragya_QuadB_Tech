import { AptosClient } from 'aptos';

const client = new AptosClient('https://fullnode.devnet.aptoslabs.com/v1');

export default async function handler(req, res) {
  try {
    const transactionHash = '0x1e1d4bf0d7cc4a2f381ceeb73d87aa6265b7846e94bbe6a43e12fcca30d70696'; // Example hash

    const transaction = await client.getTransactionByHash(transactionHash);

    // Extract basic gas data
    const gasUsed = transaction?.gas_used || 0;
    const gasUnitPrice = transaction?.gas_unit_price || 0;
    const sender = transaction?.sender || "Unknown Sender";
    const success = transaction?.status === 'success' ? 'Yes' : 'No';

    // Transaction type and state operations
    const transactionType = transaction?.payload?.type || "Unknown Type";
    
    // Placeholder gas tracking for state creation and refund
    const createStateGasUsed = transaction?.payload?.entries?.[0]?.gas_used || 0;
    const refundStateGasUsed = transaction?.payload?.refund_gas_used || 0;

    // Respond with structured gas data
    res.status(200).json({
      gas_used: gasUsed,
      gas_unit_price: gasUnitPrice,
      sender: sender,
      transaction_type: transactionType,
      success: success,
      create_state_gas_used: createStateGasUsed,
      refund_state_gas_used: refundStateGasUsed,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Failed to fetch gas fee data" });
  }
}
