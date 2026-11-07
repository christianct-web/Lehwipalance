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
  return new Date(iso).toLocaleTimeString("en-TT", { timeZone: TZ, hour: "numeric", minute: "2-digit" });
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
