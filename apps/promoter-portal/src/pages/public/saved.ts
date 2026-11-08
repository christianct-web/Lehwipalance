// Two small local records, both conveniences and neither authoritative.
//
//  - orders this browser placed, so a buyer can find their tickets again;
//    the order link (also emailed) is the real record.
//  - fetes saved to the plan. The API has no follow/save endpoint yet, so a
//    plan lives in this browser only and does not travel between devices.
//
// Every access is guarded: storage throws in private mode on some browsers.

const ORDERS = "lp_orders";
const PLAN = "lp_plan";

export type SavedOrder = { id: string; token: string; title: string; startsAt?: string };

function read<T>(key: string): T[] {
  try {
    const list = JSON.parse(localStorage.getItem(key) ?? "[]");
    return Array.isArray(list) ? list : [];
  } catch {
    return [];
  }
}

function write(key: string, value: unknown) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch {
    /* storage unavailable: the feature degrades, the page does not break */
  }
}

export function savedOrders(): SavedOrder[] {
  return read<SavedOrder>(ORDERS);
}

export function saveOrder(order: SavedOrder) {
  write(ORDERS, [order, ...savedOrders().filter((o) => o.id !== order.id)].slice(0, 20));
}

/** Slugs of fetes saved to the plan. */
export function savedSlugs(): string[] {
  return read<string>(PLAN).filter((s) => typeof s === "string");
}

export function isSaved(slug: string): boolean {
  return savedSlugs().includes(slug);
}

/** Returns the new saved state so a caller can update without re-reading. */
export function toggleSaved(slug: string): boolean {
  const current = savedSlugs();
  const next = current.includes(slug) ? current.filter((s) => s !== slug) : [slug, ...current];
  write(PLAN, next.slice(0, 200));
  window.dispatchEvent(new Event("lp:plan"));
  return next.includes(slug);
}
