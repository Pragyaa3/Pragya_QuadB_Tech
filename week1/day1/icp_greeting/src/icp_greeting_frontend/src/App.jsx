import { useState } from "react";
import { icp_greeting_backend } from "../../declarations/icp_greeting_backend";

function App() {
  const [greeting, setGreeting] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  async function handleSubmit(event) {
    event.preventDefault();
    const name = event.target.elements.name.value.trim();

    if (!name) {
      setError("Please enter a name.");
      return;
    }

    setLoading(true);
    setError(null); // Reset error state

    try {
      const response = await icp_greeting_backend.greet(name);
      setGreeting(response);
    } catch (err) {
      console.error("Error calling backend:", err);
      setError("Failed to fetch greeting. Please try again.");
    }

    setLoading(false);
    event.target.reset(); // Clear input field after submission
  }

  return (
    <main style={{ textAlign: "center", marginTop: "50px" }}>
      <h1>Welcome to ICP Greeting App</h1>
      <img src="/logo2.svg" alt="DFINITY logo" width="150px" />

      <form onSubmit={handleSubmit} style={{ marginTop: "20px" }}>
        <label htmlFor="name">Enter your name: &nbsp;</label>
        <input id="name" type="text" required />
        <button type="submit" disabled={loading}>
          {loading ? "Loading..." : "Greet Me!"}
        </button>
      </form>

      {error && (
        <p style={{ color: "red", marginTop: "10px" }}>{error}</p>
      )}

      {greeting && (
        <section style={{ marginTop: "20px", fontSize: "18px", fontWeight: "bold" }}>
          {greeting}
        </section>
      )}
    </main>
  );
}

export default App;
