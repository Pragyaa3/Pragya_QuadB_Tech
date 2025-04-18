import GasChart from "@/components/GasChart";
import { gasData } from "@/components/data";

export default function GasPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <GasChart data={gasData} />
    </div>
  );
}
