// Typed client for the Lehwi Palance API. Same-origin in production (Caddy
// proxies /api to the API); the Vite dev server proxies /api to :8000.
const BASE = import.meta.env.VITE_API_URL ?? "/api";
const TOKEN_KEY = "lp_token";

export function getToken(): string | null {
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

export function setToken(token: string | null) {
  try {
    if (token) localStorage.setItem(TOKEN_KEY, token);
    else localStorage.removeItem(TOKEN_KEY);
  } catch {
    /* private mode: stay signed in for this tab only */
  }
}

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
  }
}

function messageFrom(body: unknown, status: number): string {
  const detail = (body as { detail?: unknown })?.detail;
  if (typeof detail === "string") return detail;
  if (Array.isArray(detail) && detail[0]?.msg) {
    const d = detail[0];
    const field = Array.isArray(d.loc) ? d.loc[d.loc.length - 1] : "";
    return field ? `${field}: ${d.msg}` : d.msg;
  }
  return `Something went wrong (${status})`;
}

async function request<T>(method: string, path: string, body?: unknown): Promise<T> {
  const headers: Record<string, string> = {};
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;
  let payload: BodyInit | undefined;
  if (body instanceof FormData) payload = body;
  else if (body !== undefined) {
    headers["Content-Type"] = "application/json";
    payload = JSON.stringify(body);
  }
  const res = await fetch(`${BASE}${path}`, { method, headers, body: payload });
  if (res.status === 204) return undefined as T;
  const data = await res.json().catch(() => null);
  if (!res.ok) {
    if (res.status === 401 && token && !path.startsWith("/v1/auth/")) {
      setToken(null);
      window.dispatchEvent(new Event("lp:signed-out"));
    }
    throw new ApiError(res.status, messageFrom(data, res.status));
  }
  return data as T;
}

const get = <T>(p: string) => request<T>("GET", p);
const post = <T>(p: string, b?: unknown) => request<T>("POST", p, b ?? {});
const patch = <T>(p: string, b: unknown) => request<T>("PATCH", p, b);
const del = (p: string) => request<void>("DELETE", p);
const qs = (params: Record<string, string | number | boolean | undefined | null>) => {
  const s = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) if (v !== undefined && v !== null && v !== "") s.set(k, String(v));
  const str = s.toString();
  return str ? `?${str}` : "";
};

// ---------- Types ----------

export type Role = "owner" | "manager" | "seller" | "scanner";
export type EventStatus = "draft" | "published" | "cancelled";
export type Channel = "online" | "seller_cash" | "box_office";

export type PublicTier = {
  id: string;
  name: string;
  price_minor: number;
  currency: string;
  remaining: number;
  max_per_order: number;
};

export type EventSummary = {
  id: string;
  slug: string;
  title: string;
  category: string;
  venue_name: string | null;
  starts_at: string;
  cover_image_url: string | null;
};

export type EventDetail = EventSummary & {
  description: string | null;
  address: string | null;
  latitude: number | null;
  longitude: number | null;
  ends_at: string | null;
  tiers: PublicTier[];
};

export type Ticket = { code: string; tier_name: string; status: string; checked_in_at: string | null };

export type Order = {
  id: string;
  status: "pending" | "paid" | "failed" | "cancelled" | "refunded" | "expired";
  channel: Channel;
  event: {
    title: string;
    slug: string;
    starts_at: string;
    venue_name: string | null;
    address: string | null;
    cover_image_url: string | null;
  };
  items: { tier_name: string; quantity: number; unit_price_minor: number }[];
  currency: string;
  subtotal_minor: number;
  buyer_fee_minor: number;
  total_minor: number;
  buyer_name: string | null;
  buyer_email: string | null;
  created_at: string;
  expires_at: string | null;
  paid_at: string | null;
  access_token: string;
  link: string;
  tickets: Ticket[];
};

export type OrderCreated = Order & { checkout_url: string | null };

export type FeeQuote = {
  subtotal_minor: number;
  buyer_fee_minor: number;
  total_minor: number;
};

export type User = { id: string; email: string; full_name: string };

export type MyOrg = {
  id: string;
  name: string;
  slug: string;
  contact_email: string | null;
  contact_phone: string | null;
  instagram: string | null;
  role: Role;
};

export type Member = { user_id: string; email: string; full_name: string; role: Role };

export type PromoterTier = {
  id: string;
  name: string;
  price_minor: number;
  currency: string;
  quantity: number;
  quantity_sold: number;
  remaining: number;
  max_per_order: number;
  sort_order: number;
  sales_start_at: string | null;
  sales_end_at: string | null;
};

export type PromoterEventSummary = {
  id: string;
  slug: string;
  title: string;
  category: string;
  status: EventStatus;
  venue_name: string | null;
  starts_at: string;
};

export type PromoterEvent = PromoterEventSummary & {
  description: string | null;
  address: string | null;
  latitude: number | null;
  longitude: number | null;
  ends_at: string | null;
  cover_image_url: string | null;
  tiers: PromoterTier[];
};

export type EventFields = {
  title?: string;
  description?: string | null;
  category?: string;
  venue_name?: string | null;
  address?: string | null;
  starts_at?: string;
  ends_at?: string | null;
};

export type TierFields = {
  name?: string;
  price_minor?: number;
  quantity?: number;
  max_per_order?: number;
  sort_order?: number;
  sales_start_at?: string | null;
  sales_end_at?: string | null;
};

export type Seller = { id: string; display_name: string; code: string; user_id: string | null };

export type SalesReport = {
  currency: string;
  tickets_sold: number;
  checked_in: number;
  gross_minor: number;
  buyer_fees_minor: number;
  promoter_fees_minor: number;
  payout_minor: number;
  cash_collected_minor: number;
  tiers: {
    tier_id: string;
    name: string;
    price_minor: number;
    quantity: number;
    sold: number;
    held: number;
    remaining: number;
    gross_minor: number;
  }[];
  channels: { channel: Channel; orders: number; tickets: number; gross_minor: number }[];
  sellers: {
    seller_id: string;
    display_name: string;
    code: string;
    orders: number;
    tickets: number;
    gross_minor: number;
  }[];
};

export type PromoterOrder = {
  id: string;
  created_at: string;
  status: string;
  channel: Channel;
  buyer_name: string | null;
  buyer_email: string | null;
  buyer_phone: string | null;
  seller_name: string | null;
  tickets: number;
  checked_in: number;
  total_minor: number;
  link: string;
};

export type CheckinResult = {
  result: "ok" | "already_checked_in" | "void" | "wrong_event" | "not_found";
  tier_name: string | null;
  buyer_name: string | null;
  checked_in_at: string | null;
  checked_in: number;
  total: number;
};

export type StaffSale = {
  tier_id: string;
  quantity: number;
  buyer_name: string;
  buyer_email?: string | null;
  buyer_phone?: string | null;
  channel: "seller_cash" | "box_office";
  seller_id?: string | null;
};

// ---------- Endpoints ----------

export const api = {
  config: () => get<{ payment_provider: string; test_payments: boolean }>("/v1/config"),

  // Public
  events: () => get<EventSummary[]>("/v1/events"),
  event: (slug: string) => get<EventDetail>(`/v1/events/${encodeURIComponent(slug)}`),
  quote: (face: number, quantity: number) => get<FeeQuote>(`/v1/fees/quote${qs({ face_value_minor: face, quantity })}`),
  createOrder: (body: {
    event_slug: string;
    items: { tier_id: string; quantity: number }[];
    buyer_name: string;
    buyer_email: string;
    buyer_phone?: string | null;
    seller_code?: string | null;
  }) => post<OrderCreated>("/v1/orders", body),
  order: (id: string, token: string) => get<Order>(`/v1/orders/${id}${qs({ token })}`),
  testPay: (id: string, token: string, outcome: "paid" | "declined") =>
    post<Order>(`/v1/payments/test/${id}`, { token, outcome }),

  // Auth
  register: (b: { email: string; full_name: string; password: string }) =>
    post<{ access_token: string }>("/v1/auth/register", b),
  login: (b: { email: string; password: string }) => post<{ access_token: string }>("/v1/auth/login", b),
  me: () => get<User>("/v1/auth/me"),

  // Organisations
  orgs: () => get<MyOrg[]>("/v1/orgs"),
  createOrg: (b: { name: string; contact_email?: string | null; contact_phone?: string | null; instagram?: string | null }) =>
    post<MyOrg>("/v1/orgs", b),
  updateOrg: (org: string, b: Partial<Omit<MyOrg, "id" | "slug" | "role">>) => patch<MyOrg>(`/v1/orgs/${org}`, b),
  members: (org: string) => get<Member[]>(`/v1/orgs/${org}/members`),
  addMember: (org: string, b: { email: string; role: Role }) => post<Member>(`/v1/orgs/${org}/members`, b),
  removeMember: (org: string, user: string) => del(`/v1/orgs/${org}/members/${user}`),

  // Events
  orgEvents: (org: string) => get<PromoterEventSummary[]>(`/v1/orgs/${org}/events`),
  orgEvent: (org: string, ev: string) => get<PromoterEvent>(`/v1/orgs/${org}/events/${ev}`),
  createEvent: (org: string, b: EventFields) => post<PromoterEvent>(`/v1/orgs/${org}/events`, b),
  updateEvent: (org: string, ev: string, b: EventFields) => patch<PromoterEvent>(`/v1/orgs/${org}/events/${ev}`, b),
  publish: (org: string, ev: string) => post<PromoterEvent>(`/v1/orgs/${org}/events/${ev}/publish`),
  cancel: (org: string, ev: string) => post<PromoterEvent>(`/v1/orgs/${org}/events/${ev}/cancel`),
  uploadCover: (org: string, ev: string, file: File) => {
    const form = new FormData();
    form.append("file", file);
    return post<PromoterEvent>(`/v1/orgs/${org}/events/${ev}/cover`, form);
  },

  // Tiers
  createTier: (org: string, ev: string, b: TierFields) => post<PromoterEvent>(`/v1/orgs/${org}/events/${ev}/tiers`, b),
  updateTier: (org: string, ev: string, tier: string, b: TierFields) =>
    patch<PromoterEvent>(`/v1/orgs/${org}/events/${ev}/tiers/${tier}`, b),
  deleteTier: (org: string, ev: string, tier: string) => del(`/v1/orgs/${org}/events/${ev}/tiers/${tier}`),

  // Sellers and sales
  sellers: (org: string, ev: string) => get<Seller[]>(`/v1/orgs/${org}/events/${ev}/sellers`),
  mySeller: (org: string, ev: string) => get<Seller>(`/v1/orgs/${org}/events/${ev}/sellers/me`),
  createSeller: (org: string, ev: string, b: { display_name: string; email?: string | null }) =>
    post<Seller>(`/v1/orgs/${org}/events/${ev}/sellers`, b),
  deleteSeller: (org: string, ev: string, seller: string) => del(`/v1/orgs/${org}/events/${ev}/sellers/${seller}`),
  recordSale: (org: string, ev: string, b: StaffSale) => post<Order>(`/v1/orgs/${org}/events/${ev}/sales`, b),
  report: (org: string, ev: string) => get<SalesReport>(`/v1/orgs/${org}/events/${ev}/report`),
  orders: (org: string, ev: string, q?: string, includeUnpaid?: boolean) =>
    get<PromoterOrder[]>(`/v1/orgs/${org}/events/${ev}/orders${qs({ q, include_unpaid: includeUnpaid || undefined })}`),

  // Check-in
  checkinStats: (org: string, ev: string) =>
    get<{ checked_in: number; total: number }>(`/v1/orgs/${org}/events/${ev}/checkin`),
  checkIn: (org: string, ev: string, code: string) =>
    post<CheckinResult>(`/v1/orgs/${org}/events/${ev}/checkin`, { code }),
};
