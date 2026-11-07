// Orders this browser has placed, so a buyer can find their tickets again.
// A convenience only: the order link (also emailed) is the real record.
const KEY = "lp_orders";

export type SavedOrder = { id: string; token: string; title: string; startsAt?: string };

export function savedOrders(): SavedOrder[] {
  try {
    const list = JSON.parse(localStorage.getItem(KEY) ?? "[]");
    return Array.isArray(list) ? list : [];
  } catch {
    return [];
  }
}

export function saveOrder(order: SavedOrder) {
  try {
    const rest = savedOrders().filter((o) => o.id !== order.id);
    localStorage.setItem(KEY, JSON.stringify([order, ...rest].slice(0, 20)));
  } catch {
    /* storage unavailable: nothing to do */
  }
}
