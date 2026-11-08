import { useEffect, useState } from "react";
import { api, type EventSummary } from "../../api";
import { Flyer } from "../../flyer";
import { dayHeading, timeOnly } from "../../format";
import { Link } from "../../router";
import { Loading, Notice, Shell, useLoad } from "../../ui";
import { savedOrders, savedSlugs, toggleSaved } from "./saved";

/** Everything this browser is holding: tickets bought, and fetes planned.
 *  Both live in local storage, so the page says so rather than implying an
 *  account that does not exist. */
export default function MyTickets() {
  const orders = savedOrders();
  const [slugs, setSlugs] = useState<string[]>(() => savedSlugs());
  const { data: events, error } = useLoad(() => api.events(), []);

  useEffect(() => {
    const sync = () => setSlugs(savedSlugs());
    window.addEventListener("lp:plan", sync);
    return () => window.removeEventListener("lp:plan", sync);
  }, []);

  const plan = (events ?? []).filter((e: EventSummary) => slugs.includes(e.slug));

  return (
    <Shell wide>
      <h1>My tickets</h1>
      <p className="muted">
        Kept on this device only. Your ticket link is the real record — it’s also in your email, and you can
        send it to yourself on WhatsApp.
      </p>

      <h2>Tickets you bought</h2>
      {orders.length === 0 ? (
        <div className="empty">
          <strong>No tickets yet</strong>
          Once you buy, your QR codes show up here on this device.
        </div>
      ) : (
        <ul className="list-plain">
          {orders.map((o) => (
            <li key={o.id}>
              <Link href={`/orders/${o.id}?token=${encodeURIComponent(o.token)}`}>{o.title}</Link>
              {o.startsAt && <span className="agate"> · {dayHeading(o.startsAt)}</span>}
            </li>
          ))}
        </ul>
      )}

      <h2>Your plan</h2>
      <Notice>{error && `Couldn’t load your saved fetes: ${error}`}</Notice>
      {!events && !error && <Loading />}
      {events && plan.length === 0 ? (
        <div className="empty">
          <strong>Nothing saved</strong>
          Tap the ribbon on any fete to keep it here.
        </div>
      ) : (
        <ul className="flyers">
          {plan.map((e) => (
            <li key={e.id}>
              <Link className="fcard" href={`/e/${e.slug}`}>
                <span className="fcard-art">
                  <Flyer event={e} sizes="(min-width: 1100px) 260px, 50vw" />
                  <span className="fcard-time">{timeOnly(e.starts_at)}</span>
                </span>
                <span className="fcard-title">{e.title}</span>
                <span className="fcard-where">{dayHeading(e.starts_at)}</span>
              </Link>
              <button
                type="button"
                className="save on"
                aria-label={`Remove ${e.title} from your plan`}
                onClick={() => {
                  toggleSaved(e.slug);
                  setSlugs(savedSlugs());
                }}
              >
                <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">
                  <path d="M6 3.5h12a1 1 0 0 1 1 1v16l-7-4.2-7 4.2v-16a1 1 0 0 1 1-1Z" fill="currentColor" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round" />
                </svg>
              </button>
            </li>
          ))}
        </ul>
      )}
    </Shell>
  );
}
