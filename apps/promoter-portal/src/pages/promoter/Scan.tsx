// Gate scanner: reads ticket QR codes with the phone camera (jsQR works on
// iOS Safari too) and checks them in. Needs HTTPS for camera access.
import jsQR from "jsqr";
import { useCallback, useEffect, useRef, useState, type FormEvent } from "react";
import { api, type CheckinResult } from "../../api";
import { timeOnly } from "../../format";
import { Link } from "../../router";
import { useLoad } from "../../ui";

const RESULT_TEXT: Record<CheckinResult["result"], string> = {
  ok: "Admit",
  already_checked_in: "Already scanned",
  void: "Ticket void",
  wrong_event: "Wrong event",
  not_found: "Not a valid ticket",
};

export default function Scan({ orgId, eventId }: { orgId: string; eventId: string }) {
  const { data: event } = useLoad(() => api.orgEvent(orgId, eventId), [orgId, eventId]);
  const stats = useLoad(() => api.checkinStats(orgId, eventId), [orgId, eventId]);
  const [result, setResult] = useState<CheckinResult | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [camera, setCamera] = useState<"off" | "starting" | "on" | "denied">("off");
  const [manual, setManual] = useState("");
  const video = useRef<HTMLVideoElement>(null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const busy = useRef(false);
  const last = useRef<{ code: string; at: number }>({ code: "", at: 0 });

  const submit = useCallback(
    async (code: string) => {
      const now = Date.now();
      // The camera sees the same code many times a second; ignore repeats for a few seconds.
      if (busy.current || (code === last.current.code && now - last.current.at < 4000)) return;
      busy.current = true;
      last.current = { code, at: now };
      try {
        const r = await api.checkIn(orgId, eventId, code);
        setResult(r);
        setError(null);
        stats.setData({ checked_in: r.checked_in, total: r.total });
        navigator.vibrate?.(r.result === "ok" ? 80 : [60, 60, 60]);
      } catch (e) {
        setError((e as Error).message);
      } finally {
        busy.current = false;
      }
    },
    [orgId, eventId, stats],
  );

  useEffect(() => {
    if (camera !== "starting") return;
    let stream: MediaStream | null = null;
    let frame = 0;
    let stopped = false;

    const tick = () => {
      if (stopped) return;
      const v = video.current;
      const c = canvas.current;
      if (v && c && v.readyState === v.HAVE_ENOUGH_DATA) {
        const w = v.videoWidth;
        const h = v.videoHeight;
        // Scan a centred square at modest resolution: fast on older phones.
        const side = Math.min(w, h);
        const size = Math.min(side, 480);
        c.width = size;
        c.height = size;
        const ctx = c.getContext("2d", { willReadFrequently: true });
        if (ctx) {
          ctx.drawImage(v, (w - side) / 2, (h - side) / 2, side, side, 0, 0, size, size);
          const img = ctx.getImageData(0, 0, size, size);
          const code = jsQR(img.data, size, size, { inversionAttempts: "dontInvert" });
          if (code?.data) submit(code.data);
        }
      }
      frame = requestAnimationFrame(tick);
    };

    navigator.mediaDevices
      ?.getUserMedia({ video: { facingMode: "environment" }, audio: false })
      .then((s) => {
        if (stopped) return s.getTracks().forEach((t) => t.stop());
        stream = s;
        if (video.current) {
          video.current.srcObject = s;
          video.current.play().catch(() => {});
        }
        setCamera("on");
        frame = requestAnimationFrame(tick);
      })
      .catch(() => setCamera("denied"));
    if (!navigator.mediaDevices) setCamera("denied");

    return () => {
      stopped = true;
      cancelAnimationFrame(frame);
      stream?.getTracks().forEach((t) => t.stop());
    };
    // Restart only when the user turns the camera on.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [camera === "starting"]);

  const onManual = (e: FormEvent) => {
    e.preventDefault();
    if (manual.trim()) {
      last.current = { code: "", at: 0 };
      submit(manual.trim());
      setManual("");
    }
  };

  const tone = result ? (result.result === "ok" ? "good" : result.result === "already_checked_in" ? "warn" : "bad") : "idle";

  return (
    <div className="scanner">
      <header className="scanner-head">
        <Link href={`/promoter/orgs/${orgId}/events/${eventId}`}>← Back</Link>
        <strong>{event?.title ?? "Gate"}</strong>
        <span>{stats.data ? `${stats.data.checked_in} / ${stats.data.total} in` : ""}</span>
      </header>

      <div className={`scanner-result scanner-${tone}`} aria-live="assertive">
        {result ? (
          <>
            <strong>{RESULT_TEXT[result.result]}</strong>
            {result.tier_name && <span>{result.tier_name}</span>}
            {result.buyer_name && <span>{result.buyer_name}</span>}
            {result.result === "already_checked_in" && result.checked_in_at && (
              <span>at {timeOnly(result.checked_in_at)}</span>
            )}
          </>
        ) : (
          <span>Point the camera at a ticket QR code</span>
        )}
        {error && <span>{error}</span>}
      </div>

      <div className="scanner-view">
        <video ref={video} playsInline muted hidden={camera !== "on"} />
        <canvas ref={canvas} hidden />
        {camera === "off" && (
          <button className="btn btn-primary" onClick={() => setCamera("starting")}>
            Start camera
          </button>
        )}
        {camera === "starting" && <p>Starting camera…</p>}
        {camera === "denied" && (
          <p>
            Camera unavailable. Allow camera access for this site (it must be opened over https), or type the code
            below.
          </p>
        )}
      </div>

      <form className="scanner-manual" onSubmit={onManual}>
        <input
          placeholder="Or type / paste a ticket code"
          value={manual}
          onChange={(e) => setManual(e.target.value)}
          autoCapitalize="off"
          autoCorrect="off"
          aria-label="Ticket code"
        />
        <button className="btn btn-ghost btn-sm">Check</button>
      </form>
    </div>
  );
}
