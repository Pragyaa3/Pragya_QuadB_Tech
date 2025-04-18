'use client';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';

export default function GasChart({ data }) {
  return (
    <div className="p-8">
      <h2 className="text-2xl font-semibold mb-4">Gas Usage Comparison</h2>
      <BarChart width={500} height={300} data={data}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="operation" />
        <YAxis />
        <Tooltip />
        <Legend />
        <Bar dataKey="gas_used" fill="#8884d8" />
      </BarChart>
    </div>
  );
}
