import { api } from "../../api";
import { dateLong, dateShort } from "../../format";
import { Link } from "../../router";
import { Loading, Notice, Shell, useLoad } from "../../ui";
import { savedOrders } from "./saved";

export default function Home() {
  const { data: events, error } = useLoad(() => api.events(), []);
  const mine = savedOrders();

  return (
    <Shell>
      <section className="hero">
        <h1>Fetes, concerts and limes across T&amp;T</h1>
        <p className="muted">Buy tickets in a minute. Show the QR at the gate.</p>
      </section>

      {mine.length > 0 && (
        <section className="saved">
          <h2>Your tickets</h2>
          <ul className="list-plain">
            {mine.map((o) => (
              <li key={o.id}>
                <Link href={`/orders/${o.id}?token=${encodeURIComponent(o.token)}`}>{o.title}</Link>
                {o.startsAt && <span className="muted"> · {dateShort(o.startsAt)}</span>}
              </li>
            ))}
          </ul>
        </section>
      )}

      <h2>Upcoming</h2>
      <Notice>{error && `Couldn't load events: ${error}`}</Notice>
      {!events && !error && <Loading />}
      {events?.length === 0 && <p className="muted">No events on sale right now. Check back soon.</p>}
      <div className="event-grid">
        {events?.map((e) => (
          <Link key={e.id} href={`/e/${e.slug}`} className="event-card">
            <div className="event-card-img">
              {e.cover_image_url ? <img src={e.cover_image_url} alt="" loading="lazy" /> : <span>{e.title.slice(0, 1)}</span>}
            </div>
            <div className="event-card-body">
              <strong>{e.title}</strong>
              <span className="muted">{dateLong(e.starts_at)}</span>
              {e.venue_name && <span className="muted">{e.venue_name}</span>}
            </div>
          </Link>
        ))}
      </div>
    </Shell>
  );
}
