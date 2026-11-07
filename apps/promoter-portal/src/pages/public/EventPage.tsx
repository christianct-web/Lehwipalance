import { useEffect, useMemo, useState, type FormEvent } from "react";
import { api, type FeeQuote } from "../../api";
import { dateLong, money } from "../../format";
import { navigate, useQuery } from "../../router";
import { Field, Loading, Notice, Shell, useAction, useConfig, useLoad } from "../../ui";
import { saveOrder } from "./saved";

export default function EventPage({ slug }: { slug: string }) {
  const query = useQuery();
  const { onlinePayments } = useConfig();
  // With paid online checkout closed, only free tiers can be picked here.
  const paidOnline = onlinePayments !== "off";
  const { data: event, error } = useLoad(() => api.event(slug), [slug]);
  const [qty, setQty] = useState<Record<string, number>>({});
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [sellerCode] = useState(() => query.get("ref") ?? "");
  const [quote, setQuote] = useState<FeeQuote | null>(null);
  const action = useAction();

  const lines = useMemo(
    () => Object.entries(qty).filter(([, n]) => n > 0).map(([tier_id, quantity]) => ({ tier_id, quantity })),
    [qty],
  );
  const count = lines.reduce((s, l) => s + l.quantity, 0);

  // Price the basket with the API's fee model, so what's shown is what's charged.
  useEffect(() => {
    if (!event || lines.length === 0) {
      setQuote(null);
      return;
    }
    let live = true;
    Promise.all(
      lines.map((l) => api.quote(event.tiers.find((t) => t.id === l.tier_id)!.price_minor, l.quantity)),
    )
      .then((qs) => {
        if (!live) return;
        setQuote(
          qs.reduce(
            (a, q) => ({
              subtotal_minor: a.subtotal_minor + q.subtotal_minor,
              buyer_fee_minor: a.buyer_fee_minor + q.buyer_fee_minor,
              total_minor: a.total_minor + q.total_minor,
            }),
            { subtotal_minor: 0, buyer_fee_minor: 0, total_minor: 0 },
          ),
        );
      })
      .catch(() => live && setQuote(null));
    return () => {
      live = false;
    };
  }, [event, lines]);

  if (error) {
    return (
      <Shell>
        <Notice>{error === "Event not found" ? "This event isn't on sale." : error}</Notice>
      </Shell>
    );
  }
  if (!event) {
    return (
      <Shell>
        <Loading />
      </Shell>
    );
  }

  const step = (tierId: string, delta: number, max: number) =>
    setQty((q) => ({ ...q, [tierId]: Math.max(0, Math.min(max, (q[tierId] ?? 0) + delta)) }));

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    const order = await action.run(() =>
      api.createOrder({
        event_slug: slug,
        items: lines,
        buyer_name: name.trim(),
        buyer_email: email.trim(),
        buyer_phone: phone.trim() || null,
        seller_code: sellerCode || null,
      }),
    );
    if (!order) return;
    saveOrder({ id: order.id, token: order.access_token, title: event.title, startsAt: event.starts_at });
    if (order.checkout_url) window.location.assign(order.checkout_url);
    else navigate(`/orders/${order.id}?token=${encodeURIComponent(order.access_token)}`);
  };

  const mapUrl =
    event.latitude != null && event.longitude != null
      ? `https://www.google.com/maps/search/?api=1&query=${event.latitude},${event.longitude}`
      : event.address
        ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(event.address)}`
        : null;

  return (
    <Shell wide>
      <article className="event grid-details">
        <div>
        {event.cover_image_url && <img className="event-cover" src={event.cover_image_url} alt="" />}
        <h1>{event.title}</h1>
        <p className="event-meta">
          <strong>{dateLong(event.starts_at)}</strong>
          {event.venue_name && <span>{event.venue_name}</span>}
          {event.address && (
            <span>
              {event.address}
              {mapUrl && (
                <>
                  {" · "}
                  <a href={mapUrl} target="_blank" rel="noreferrer">
                    Map
                  </a>
                </>
              )}
            </span>
          )}
        </p>
        {event.description && <p className="event-desc">{event.description}</p>}
        </div>

        <form className="card checkout" onSubmit={submit}>
          <h2>Tickets</h2>
          <ul className="tiers">
            {event.tiers.map((t) => {
              const buyable = t.price_minor === 0 || paidOnline;
              const max = buyable ? Math.min(t.remaining, t.max_per_order) : 0;
              const n = qty[t.id] ?? 0;
              return (
                <li key={t.id} className={t.remaining === 0 ? "tier sold-out" : "tier"}>
                  <span className="tier-name">{t.name}</span>
                  <span className="tier-price">
                    {t.price_minor === 0 ? "Free" : money(t.price_minor, t.currency)}
                  </span>
                  <span className="tier-meta">
                    {t.remaining === 0
                      ? "Sold out"
                      : t.remaining <= 20
                        ? `${t.remaining} left`
                        : "On sale"}
                  </span>
                  {t.remaining === 0 ? (
                    <span className="badge">Sold out</span>
                  ) : !buyable ? (
                    <span className="muted small right">From sellers &amp; at the gate</span>
                  ) : (
                    <div className="stepper" aria-label={`${t.name} quantity`}>
                      <button type="button" onClick={() => step(t.id, -1, max)} disabled={n === 0} aria-label="One fewer">
                        −
                      </button>
                      <output>{n}</output>
                      <button type="button" onClick={() => step(t.id, 1, max)} disabled={n >= max} aria-label="One more">
                        +
                      </button>
                    </div>
                  )}
                </li>
              );
            })}
          </ul>

          {!paidOnline && event.tiers.some((t) => t.price_minor > 0) && (
            <p className="muted small">
              Online payment isn't open yet. Buy paid tickets from a committee seller or at the gate.
            </p>
          )}
          {count > 0 && (
            <>
              <div className="grid-2">
                <Field label="Your name">
                  <input required value={name} onChange={(e) => setName(e.target.value)} autoComplete="name" />
                </Field>
                <Field label="Email" hint="We send your tickets here.">
                  <input
                    required
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    autoComplete="email"
                  />
                </Field>
                <Field label="Phone (optional)">
                  <input type="tel" value={phone} onChange={(e) => setPhone(e.target.value)} autoComplete="tel" />
                </Field>
              </div>
              {sellerCode && <p className="muted">Seller code {sellerCode.toUpperCase()} will be credited.</p>}

              {quote && (
                <dl className="totals">
                  <dt>Tickets ({count})</dt>
                  <dd>{money(quote.subtotal_minor)}</dd>
                  {quote.buyer_fee_minor > 0 && (
                    <>
                      <dt>Booking fee</dt>
                      <dd>{money(quote.buyer_fee_minor)}</dd>
                    </>
                  )}
                  <dt className="total">Total</dt>
                  <dd className="total">{money(quote.total_minor)}</dd>
                </dl>
              )}
              <Notice>{action.error}</Notice>
              <button className="btn btn-primary btn-block" disabled={action.busy}>
                {action.busy ? "Reserving…" : quote?.total_minor === 0 ? "Get tickets" : "Continue to payment"}
              </button>
              {quote && quote.total_minor > 0 && (
                <p className="muted small">
                  Tickets are held for 15 minutes while you pay. Card details are entered only on the payment
                  provider's secure page.
                </p>
              )}
            </>
          )}
        </form>
      </article>
    </Shell>
  );
}
