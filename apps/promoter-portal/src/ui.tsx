import QRCode from "qrcode";
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { api, getToken, setToken, type User } from "./api";
import { Link } from "./router";

// ---------- Data loading ----------

export function useLoad<T>(load: () => Promise<T>, deps: unknown[]) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const seq = useRef(0);
  const reload = useCallback(() => {
    const n = ++seq.current;
    setLoading(true);
    load()
      .then((d) => {
        if (n === seq.current) {
          setData(d);
          setError(null);
        }
      })
      .catch((e: Error) => n === seq.current && setError(e.message))
      .finally(() => n === seq.current && setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);
  useEffect(reload, [reload]);
  return { data, setData, error, loading, reload };
}

/** Wrap an async action: tracks busy state and the last error message. */
export function useAction() {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const run = useCallback(async <T,>(fn: () => Promise<T>): Promise<T | undefined> => {
    setBusy(true);
    setError(null);
    try {
      return await fn();
    } catch (e) {
      setError((e as Error).message);
      return undefined;
    } finally {
      setBusy(false);
    }
  }, []);
  return { busy, error, setError, run };
}

// ---------- Session ----------

type Session = { user: User | null; ready: boolean; signIn: (token: string) => Promise<void>; signOut: () => void };
const SessionContext = createContext<Session>({ user: null, ready: false, signIn: async () => {}, signOut: () => {} });

export function SessionProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (!getToken()) {
      setReady(true);
      return;
    }
    api
      .me()
      .then(setUser)
      .catch(() => setToken(null))
      .finally(() => setReady(true));
    const out = () => setUser(null);
    window.addEventListener("lp:signed-out", out);
    return () => window.removeEventListener("lp:signed-out", out);
  }, []);

  const signIn = useCallback(async (token: string) => {
    setToken(token);
    setUser(await api.me());
  }, []);
  const signOut = useCallback(() => {
    setToken(null);
    setUser(null);
  }, []);

  return <SessionContext.Provider value={{ user, ready, signIn, signOut }}>{children}</SessionContext.Provider>;
}

export const useSession = () => useContext(SessionContext);

// ---------- Site config (test-mode banner) ----------

const ConfigContext = createContext<{ testPayments: boolean }>({ testPayments: false });

export function ConfigProvider({ children }: { children: ReactNode }) {
  const [testPayments, setTestPayments] = useState(false);
  useEffect(() => {
    api
      .config()
      .then((c) => setTestPayments(c.test_payments))
      .catch(() => {});
  }, []);
  return <ConfigContext.Provider value={{ testPayments }}>{children}</ConfigContext.Provider>;
}

export const useConfig = () => useContext(ConfigContext);

// ---------- Layout ----------

export function Shell({ children, wide, nav }: { children: ReactNode; wide?: boolean; nav?: ReactNode }) {
  const { testPayments } = useConfig();
  return (
    <>
      {testPayments && (
        <div className="test-banner" role="status">
          Test mode: payments are simulated and no money is charged.
        </div>
      )}
      <header className="site-header">
        <div className={wide ? "wrap wide" : "wrap"}>
          <Link href="/" className="brand">
            Lehwi <span>Palance</span>
          </Link>
          <nav className="site-nav">{nav}</nav>
        </div>
      </header>
      <main className={wide ? "wrap wide" : "wrap"}>{children}</main>
      <footer className="site-footer">
        <div className={wide ? "wrap wide" : "wrap"}>
          <span>Lehwi Palance · Trinidad &amp; Tobago</span>
          <Link href="/promoter">For promoters</Link>
        </div>
      </footer>
    </>
  );
}

export function Notice({ kind = "error", children }: { kind?: "error" | "ok" | "info"; children: ReactNode }) {
  if (!children) return null;
  return (
    <p className={`notice notice-${kind}`} role={kind === "error" ? "alert" : "status"}>
      {children}
    </p>
  );
}

export function Loading({ label = "Loading…" }: { label?: string }) {
  return <p className="muted loading">{label}</p>;
}

export function Field({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: ReactNode;
  children: ReactNode;
}) {
  return (
    <label className="field">
      <span className="field-label">{label}</span>
      {children}
      {hint && <span className="field-hint">{hint}</span>}
    </label>
  );
}

export function Badge({ children, tone = "neutral" }: { children: ReactNode; tone?: "neutral" | "good" | "warn" | "bad" }) {
  return <span className={`badge badge-${tone}`}>{children}</span>;
}

export function QR({ value, size = 220 }: { value: string; size?: number }) {
  const [src, setSrc] = useState<string>("");
  useEffect(() => {
    QRCode.toDataURL(value, { width: size * 2, margin: 1, errorCorrectionLevel: "M" })
      .then(setSrc)
      .catch(() => setSrc(""));
  }, [value, size]);
  return src ? (
    <img className="qr" src={src} width={size} height={size} alt="Ticket QR code" />
  ) : (
    <div className="qr qr-empty" style={{ width: size, height: size }} />
  );
}

export function CopyButton({ text, label = "Copy link" }: { text: string; label?: string }) {
  const [done, setDone] = useState(false);
  return (
    <button
      type="button"
      className="btn btn-ghost btn-sm"
      onClick={async () => {
        try {
          await navigator.clipboard.writeText(text);
          setDone(true);
          setTimeout(() => setDone(false), 1500);
        } catch {
          window.prompt("Copy this link", text);
        }
      }}
    >
      {done ? "Copied" : label}
    </button>
  );
}

export function whatsappLink(text: string): string {
  return `https://wa.me/?text=${encodeURIComponent(text)}`;
}
