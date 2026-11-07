import { useState, type FormEvent } from "react";
import { api, ApiError, type Order, type PromoterEvent } from "../../api";
import { money } from "../../format";
import { CopyButton, Field, Notice, QR, useAction, useLoad, whatsappLink } from "../../ui";

export default function SellPanel({ orgId, event, admin }: { orgId: string; event: PromoterEvent; admin: boolean }) {
  const me = useLoad(() => api.mySeller(orgId, event.id).catch((e) => (e instanceof ApiError && e.status === 404 ? null : Promise.reject(e))), [orgId, event.id]);
  const sellers = useLoad(() => (admin ? api.sellers(orgId, event.id) : Promise.resolve([])), [orgId, event.id, admin]);
  const [tierId, setTierId] = useState(event.tiers[0]?.id ?? "");
  const [quantity, setQuantity] = useState(1);
  const [buyerName, setBuyerName] = useState("");
  const [buyerEmail, setBuyerEmail] = useState("");
  const [buyerPhone, setBuyerPhone] = useState("");
  const [channel, setChannel] = useState<"seller_cash" | "box_office">("seller_cash");
  const [sellerId, setSellerId] = useState("");
  const [done, setDone] = useState<Order | null>(null);
  const action = useAction();

  if (!admin && me.data === null && !me.loading) {
    return (
      <Notice kind="info">
        You're not set up as a seller for this event yet. Ask the promoter to add you under Sellers with your account
        email.
      </Notice>
    );
  }
  if (event.status !== "published") {
    return <Notice kind="info">Sales open once the event is published.</Notice>;
  }

  const tier = event.tiers.find((t) => t.id === tierId);
  const myLink = me.data ? `${location.origin}/e/${event.slug}?ref=${me.data.code}` : null;

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    const order = await action.run(() =>
      api.recordSale(orgId, event.id, {
        tier_id: tierId,
        quantity,
        buyer_name: buyerName.trim(),
        buyer_email: buyerEmail.trim() || null,
        buyer_phone: buyerPhone.trim() || null,
        channel: admin ? channel : "seller_cash",
        seller_id: admin ? sellerId || null : undefined,
      }),
    );
    if (order) {
      setDone(order);
      setBuyerName("");
      setBuyerEmail("");
      setBuyerPhone("");
      setQuantity(1);
    }
  };

  if (done) {
    const link = `${location.origin}/orders/${done.id}?token=${encodeURIComponent(done.access_token)}`;
    return (
      <div className="stack">
        <Notice kind="ok">
          Sold {done.tickets.length} × {done.items[0]?.tier_name} to {done.buyer_name} for{" "}
          {money(done.subtotal_minor, done.currency)}. Collect the cash.
        </Notice>
        <p>Send the buyer their tickets:</p>
        <div className="row">
          <a className="btn btn-primary" href={whatsappLink(`Your tickets for ${done.event.title}: ${link}`)} target="_blank" rel="noreferrer">
            Send on WhatsApp
          </a>
          <CopyButton text={link} label="Copy ticket link" />
        </div>
        {done.buyer_email && <p className="muted small">A copy was emailed to {done.buyer_email} (if email is set up).</p>}
        <div className="ticket-strip">
          {done.tickets.map((t) => (
            <QR key={t.code} value={t.code} size={140} />
          ))}
        </div>
        <button className="btn btn-ghost" onClick={() => setDone(null)}>
          Record another sale
        </button>
      </div>
    );
  }

  return (
    <div className="grid-details">
      <form className="stack" onSubmit={submit}>
        <h2>Record a cash sale</h2>
        <div className="grid-2">
          <Field label="Tier">
            <select value={tierId} onChange={(e) => setTierId(e.target.value)}>
              {event.tiers.map((t) => (
                <option key={t.id} value={t.id} disabled={t.remaining === 0}>
                  {t.name} · {money(t.price_minor)} {t.remaining === 0 ? "(sold out)" : `(${t.remaining} left)`}
                </option>
              ))}
            </select>
          </Field>
          <Field label="How many">
            <input type="number" min={1} max={100} value={quantity} onChange={(e) => setQuantity(Number(e.target.value))} />
          </Field>
          <Field label="Buyer's name">
            <input required value={buyerName} onChange={(e) => setBuyerName(e.target.value)} />
          </Field>
          <Field label="Buyer's phone (optional)">
            <input type="tel" value={buyerPhone} onChange={(e) => setBuyerPhone(e.target.value)} />
          </Field>
          <Field label="Buyer's email (optional)" hint="Tickets are emailed if given.">
            <input type="email" value={buyerEmail} onChange={(e) => setBuyerEmail(e.target.value)} />
          </Field>
          {admin && (
            <Field label="Sold by">
              <select
                value={sellerId ? `s:${sellerId}` : channel}
                onChange={(e) => {
                  const v = e.target.value;
                  if (v.startsWith("s:")) {
                    setSellerId(v.slice(2));
                    setChannel("seller_cash");
                  } else {
                    setSellerId("");
                    setChannel(v as "seller_cash" | "box_office");
                  }
                }}
              >
                <option value="box_office">Box office</option>
                <option value="seller_cash">Promoter (cash)</option>
                {sellers.data?.map((s) => (
                  <option key={s.id} value={`s:${s.id}`}>
                    Seller: {s.display_name}
                  </option>
                ))}
              </select>
            </Field>
          )}
        </div>
        {tier && (
          <p className="total-line">
            Collect <strong>{money(tier.price_minor * quantity)}</strong>
          </p>
        )}
        <Notice>{action.error}</Notice>
        <button className="btn btn-primary btn-block" disabled={action.busy || !tierId}>
          {action.busy ? "Recording…" : "Record sale and issue tickets"}
        </button>
      </form>

      {myLink && (
        <aside className="card stack">
          <h3>Your sales link</h3>
          <p className="muted small">Online sales through this link are credited to you (code {me.data?.code}).</p>
          <code className="wrap-anywhere">{myLink}</code>
          <div className="row">
            <CopyButton text={myLink} />
            <a className="btn btn-ghost btn-sm" href={whatsappLink(`Get your tickets for ${event.title} from me: ${myLink}`)} target="_blank" rel="noreferrer">
              WhatsApp
            </a>
          </div>
        </aside>
      )}
    </div>
  );
}
