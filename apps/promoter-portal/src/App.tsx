import { useEffect, useState } from "react";
import { listEvents, type EventSummary } from "./api";

// Starter shell only. The real portal (event setup, ticket tiers, committee
// sellers, sales and payouts) is designed in the product & design phase.
export default function App() {
  const [events, setEvents] = useState<EventSummary[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    listEvents().then(setEvents).catch((e: Error) => setError(e.message));
  }, []);

  return (
    <main>
      <h1>Lehwi Palance for promoters</h1>
      <p className="muted">Starter shell: connected to the API's public events list.</p>
      {error && <p role="alert">Could not reach the API ({error}). Is it running on :8000?</p>}
      {events === null && !error && <p>Loading…</p>}
      {events?.length === 0 && <p>No published events yet.</p>}
      <ul>
        {events?.map((e) => (
          <li key={e.id}>
            <strong>{e.title}</strong> · {new Date(e.starts_at).toLocaleDateString("en-TT")}
            {e.venue_name ? ` · ${e.venue_name}` : ""}
          </li>
        ))}
      </ul>
    </main>
  );
}
