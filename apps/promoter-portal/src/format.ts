// Trinidad & Tobago is UTC-4 all year; show every time in local fete time.
const TZ = "America/Port_of_Spain";

export function money(minor: number, currency = "TTD"): string {
  const amount = minor / 100;
  const prefix = currency === "TTD" ? "TT$" : `${currency} `;
  return `${prefix}${amount.toLocaleString("en-TT", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

export function dateLong(iso: string): string {
  return new Date(iso).toLocaleString("en-TT", {
    timeZone: TZ,
    weekday: "short",
    day: "numeric",
    month: "short",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
}

export function dateShort(iso: string): string {
  return new Date(iso).toLocaleDateString("en-TT", { timeZone: TZ, day: "numeric", month: "short" });
}

export function timeOnly(iso: string): string {
  // en-TT separates the meridiem with U+202F (narrow no-break space), which
  // reads as a gap in a tabular column. Normalise it to a plain space.
  return new Date(iso)
    .toLocaleTimeString("en-TT", { timeZone: TZ, hour: "numeric", minute: "2-digit" })
    .replace(/[\u202f\u00a0]/g, " ");
}

// <input type="datetime-local"> works in the browser's zone; convert to and
// from T&T time explicitly so a promoter abroad still sets fete time.
export function toLocalInput(iso: string | null): string {
  if (!iso) return "";
  const t = new Date(new Date(iso).getTime() - 4 * 3600_000);
  return t.toISOString().slice(0, 16);
}

export function fromLocalInput(value: string): string | null {
  if (!value) return null;
  return new Date(`${value}:00-04:00`).toISOString();
}

export function dollarsToMinor(value: string): number {
  const n = Number(value.replace(/[^0-9.]/g, ""));
  return Number.isFinite(n) ? Math.round(n * 100) : NaN;
}

// --- Season grouping. The fete guide is read by day, so a day is the unit. ---

/** Stable key for the T&T calendar day an instant falls on. */
export function dayKey(iso: string): string {
  return new Date(iso).toLocaleDateString("en-CA", { timeZone: TZ });
}

/** "FRI 6 FEB" — the dateline that heads a day's listing. */
export function dayHeading(iso: string): string {
  return new Date(iso)
    .toLocaleDateString("en-TT", { timeZone: TZ, weekday: "short", day: "numeric", month: "short" })
    .replace(/,/g, "")
    .toUpperCase();
}

/** "Today" and "Tomorrow" are what people actually say; dates after that. */
export function relativeDay(iso: string): string | null {
  const today = new Date().toLocaleDateString("en-CA", { timeZone: TZ });
  const target = dayKey(iso);
  if (target === today) return "Today";
  const t = new Date(`${today}T12:00:00Z`);
  t.setUTCDate(t.getUTCDate() + 1);
  if (target === t.toISOString().slice(0, 10)) return "Tomorrow";
  return null;
}
