const BASE = import.meta.env.VITE_API_URL ?? "/api";

export type EventSummary = {
  id: string;
  slug: string;
  title: string;
  category: string;
  venue_name: string | null;
  starts_at: string;
};

export async function listEvents(): Promise<EventSummary[]> {
  const res = await fetch(`${BASE}/v1/events`);
  if (!res.ok) throw new Error(`API ${res.status}`);
  return res.json();
}
