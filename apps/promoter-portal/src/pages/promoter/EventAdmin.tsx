import { useEffect, useState, type FormEvent } from "react";
import { api, type PromoterEvent, type PromoterTier, type Role, type TierFields } from "../../api";
import { dateLong, dollarsToMinor, fromLocalInput, money, toLocalInput } from "../../format";
import { Link, navigate, useQuery } from "../../router";
import { Badge, CopyButton, Field, Loading, Notice, useAction, useLoad, whatsappLink } from "../../ui";
import { isAdmin, PromoterShell, useOrg } from "./common";
import SellPanel from "./SellPanel";

type Tab = "overview" | "details" | "tickets" | "sellers" | "orders" | "sell";
const ADMIN_TABS: [Tab, string][] = [
  ["overview", "Overview"],
  ["details", "Details"],
  ["tickets", "Tickets"],
  ["sellers", "Sellers"],
  ["orders", "Orders"],
  ["sell", "Record sale"],
];

const CATEGORIES = ["fete", "concert", "festival", "sport", "community", "other"];

export default function EventAdmin({ orgId, eventId }: { orgId: string; eventId: string }) {
  const { org } = useOrg(orgId);
  const { data: event, setData: setEvent, error } = useLoad(() => api.orgEvent(orgId, eventId), [orgId, eventId]);
  const query = useQuery();
  const role = org?.role;
  const admin = isAdmin(role);
  const tab = (query.get("tab") as Tab) || (admin ? "overview" : "sell");
  const setTab = (t: Tab) => navigate(`/promoter/orgs/${orgId}/events/${eventId}?tab=${t}`, true);

  const crumbs = (
    <>
      <Link href="/promoter">Organisations</Link> / <Link href={`/promoter/orgs/${orgId}`}>{org?.name ?? "…"}</Link>
    </>
  );
  if (error)
    return (
      <PromoterShell crumbs={crumbs}>
        <Notice>{error}</Notice>
      </PromoterShell>
    );
  if (!event || !role)
    return (
      <PromoterShell crumbs={crumbs}>
        <Loading />
      </PromoterShell>
    );

  const canScan = role !== "seller";
  const publicUrl = `${location.origin}/e/${event.slug}`;

  return (
    <PromoterShell crumbs={crumbs}>
      <div className="page-head">
        <div>
          <h1>{event.title}</h1>
          <p className="muted">
            {dateLong(event.starts_at)}
            {event.venue_name ? ` · ${event.venue_name}` : ""}
          </p>
        </div>
        <div className="row">
          <Badge tone={event.status === "published" ? "good" : event.status === "cancelled" ? "bad" : "neutral"}>
            {event.status}
          </Badge>
          {canScan && event.status === "published" && (
            <Link className="btn btn-primary btn-sm" href={`/promoter/orgs/${orgId}/events/${eventId}/scan`}>
              Open gate scanner
            </Link>
          )}
        </div>
      </div>

      {admin && (
        <div className="tabs" role="tablist">
          {ADMIN_TABS.map(([t, label]) => (
            <button key={t} role="tab" aria-selected={tab === t} className={tab === t ? "tab active" : "tab"} onClick={() => setTab(t)}>
              {label}
            </button>
          ))}
        </div>
      )}

      {admin && tab === "overview" && <Overview orgId={orgId} event={event} setEvent={setEvent} publicUrl={publicUrl} />}
      {admin && tab === "details" && <Details orgId={orgId} event={event} setEvent={setEvent} />}
      {admin && tab === "tickets" && <Tiers orgId={orgId} event={event} setEvent={setEvent} />}
      {admin && tab === "sellers" && <Sellers orgId={orgId} event={event} />}
      {admin && tab === "orders" && <Orders orgId={orgId} eventId={event.id} />}
      {(tab === "sell" || !admin) && <SellerArea orgId={orgId} event={event} role={role} />}
    </PromoterShell>
  );
}

// ---------- Overview ----------

function Overview({
  orgId,
  event,
  setEvent,
  publicUrl,
}: {
  orgId: string;
  event: PromoterEvent;
  setEvent: (e: PromoterEvent) => void;
  publicUrl: string;
}) {
  const { data: r, error, reload } = useLoad(() => api.report(orgId, event.id), [orgId, event.id]);
  const action = useAction();

  useEffect(() => {
    const t = setInterval(reload, 30_000);
    return () => clearInterval(t);
  }, [reload]);

  const publish = async () => {
    const ev = await action.run(() => api.publish(orgId, event.id));
    if (ev) setEvent(ev);
  };
  const cancel = async () => {
    if (!confirm("Cancel this event? It will be taken off sale and can't be edited again.")) return;
    const ev = await action.run(() => api.cancel(orgId, event.id));
    if (ev) setEvent(ev);
  };

  return (
    <div className="stack">
      {event.status === "draft" && (
        <div className="card callout">
          <strong>This event is a draft.</strong>
          <p className="muted">
            Add the details and at least one ticket tier, then publish to put it on sale.
          </p>
          <button className="btn btn-primary" onClick={publish} disabled={action.busy}>
            Publish and start selling
          </button>
        </div>
      )}
      {event.status === "published" && (
        <div className="card callout">
          <strong>On sale</strong>
          <p>
            <a href={publicUrl} target="_blank" rel="noreferrer">
              {publicUrl}
            </a>
          </p>
          <div className="row">
            <CopyButton text={publicUrl} />
            <a className="btn btn-ghost btn-sm" href={whatsappLink(`Tickets for ${event.title}: ${publicUrl}`)} target="_blank" rel="noreferrer">
              Share on WhatsApp
            </a>
          </div>
        </div>
      )}
      <Notice>{action.error ?? error}</Notice>

      {r && (
        <>
          <div className="stats">
            <Stat label="Tickets sold" value={String(r.tickets_sold)} />
            <Stat label="Face value sold" value={money(r.gross_minor)} />
            <Stat label="Your payout" value={money(r.payout_minor)} hint={`after ${money(r.promoter_fees_minor)} fees`} />
            <Stat label="Cash with sellers" value={money(r.cash_collected_minor)} hint="included in face value" />
            <Stat label="Checked in" value={`${r.checked_in} / ${r.tickets_sold}`} />
          </div>

          <h3>By tier</h3>
          <table className="table">
            <thead>
              <tr>
                <th>Tier</th>
                <th className="right">Price</th>
                <th className="right">Sold</th>
                <th className="right">Held</th>
                <th className="right">Left</th>
                <th className="right">Face value</th>
              </tr>
            </thead>
            <tbody>
              {r.tiers.map((t) => (
                <tr key={t.tier_id}>
                  <td>{t.name}</td>
                  <td className="right">{money(t.price_minor)}</td>
                  <td className="right">
                    {t.sold} / {t.quantity}
                  </td>
                  <td className="right">{t.held || ""}</td>
                  <td className="right">{t.remaining}</td>
                  <td className="right">{money(t.gross_minor)}</td>
                </tr>
              ))}
            </tbody>
          </table>

          {r.sellers.length > 0 && (
            <>
              <h3>By seller</h3>
              <table className="table">
                <thead>
                  <tr>
                    <th>Seller</th>
                    <th>Code</th>
                    <th className="right">Tickets</th>
                    <th className="right">Face value</th>
                  </tr>
                </thead>
                <tbody>
                  {r.sellers.map((s) => (
                    <tr key={s.seller_id}>
                      <td>{s.display_name}</td>
                      <td>
                        <code>{s.code}</code>
                      </td>
                      <td className="right">{s.tickets}</td>
                      <td className="right">{money(s.gross_minor)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </>
          )}
          <p className="muted small">"Held" tickets are in someone's checkout right now and return to sale if unpaid.</p>
        </>
      )}

      {event.status !== "cancelled" && (
        <p>
          <button className="link-btn danger" onClick={cancel} disabled={action.busy}>
            Cancel event
          </button>
        </p>
      )}
    </div>
  );
}

function Stat({ label, value, hint }: { label: string; value: string; hint?: string }) {
  return (
    <div className="stat">
      <span className="stat-label">{label}</span>
      <strong className="stat-value">{value}</strong>
      {hint && <span className="muted small">{hint}</span>}
    </div>
  );
}

// ---------- Details ----------

function Details({ orgId, event, setEvent }: { orgId: string; event: PromoterEvent; setEvent: (e: PromoterEvent) => void }) {
  const [f, setF] = useState({
    title: event.title,
    category: event.category,
    description: event.description ?? "",
    venue_name: event.venue_name ?? "",
    address: event.address ?? "",
    starts_at: toLocalInput(event.starts_at),
    ends_at: toLocalInput(event.ends_at),
  });
  const action = useAction();
  const upload = useAction();
  const [saved, setSaved] = useState(false);
  const locked = event.status === "cancelled";
  const set = (k: keyof typeof f) => (e: { target: { value: string } }) => {
    setSaved(false);
    setF({ ...f, [k]: e.target.value });
  };

  const save = async (e: FormEvent) => {
    e.preventDefault();
    const ev = await action.run(() =>
      api.updateEvent(orgId, event.id, {
        title: f.title.trim(),
        category: f.category,
        description: f.description.trim() || null,
        venue_name: f.venue_name.trim() || null,
        address: f.address.trim() || null,
        starts_at: fromLocalInput(f.starts_at) ?? undefined,
        ends_at: fromLocalInput(f.ends_at),
      }),
    );
    if (ev) {
      setEvent(ev);
      setSaved(true);
    }
  };

  const onFile = async (file: File | undefined) => {
    if (!file) return;
    const ev = await upload.run(() => api.uploadCover(orgId, event.id, file));
    if (ev) setEvent(ev);
  };

  return (
    <div className="grid-details">
      <form className="stack" onSubmit={save}>
        <fieldset disabled={locked} className="stack">
          <Field label="Title">
            <input required value={f.title} onChange={set("title")} />
          </Field>
          <Field label="Category">
            <select value={f.category} onChange={set("category")}>
              {CATEGORIES.map((c) => (
                <option key={c} value={c}>
                  {c[0].toUpperCase() + c.slice(1)}
                </option>
              ))}
            </select>
          </Field>
          <div className="grid-2">
            <Field label="Starts (Trinidad time)">
              <input required type="datetime-local" value={f.starts_at} onChange={set("starts_at")} />
            </Field>
            <Field label="Ends (optional)" hint="Online sales close at the end time, or 12 hours after the start.">
              <input type="datetime-local" value={f.ends_at} onChange={set("ends_at")} />
            </Field>
          </div>
          <Field label="Venue">
            <input value={f.venue_name} onChange={set("venue_name")} />
          </Field>
          <Field label="Address">
            <input value={f.address} onChange={set("address")} />
          </Field>
          <Field label="Description" hint="Lineup, dress code, what's included.">
            <textarea rows={6} value={f.description} onChange={set("description")} />
          </Field>
          <Notice>{action.error}</Notice>
          {saved && <Notice kind="ok">Saved.</Notice>}
          <button className="btn btn-primary" disabled={action.busy}>
            Save details
          </button>
        </fieldset>
      </form>

      <div className="stack">
        <h3>Flyer</h3>
        {event.cover_image_url ? (
          <img className="flyer-preview" src={event.cover_image_url} alt="Event flyer" />
        ) : (
          <p className="muted">No flyer yet.</p>
        )}
        {!locked && (
          <label className="btn btn-ghost">
            {upload.busy ? "Uploading…" : event.cover_image_url ? "Replace flyer" : "Upload flyer"}
            <input
              type="file"
              accept="image/jpeg,image/png,image/webp"
              hidden
              onChange={(e) => onFile(e.target.files?.[0])}
            />
          </label>
        )}
        <p className="muted small">JPEG, PNG or WebP, up to 5 MB.</p>
        <Notice>{upload.error}</Notice>
      </div>
    </div>
  );
}

// ---------- Ticket tiers ----------

function Tiers({ orgId, event, setEvent }: { orgId: string; event: PromoterEvent; setEvent: (e: PromoterEvent) => void }) {
  const [editing, setEditing] = useState<string | "new" | null>(event.tiers.length ? null : "new");
  const action = useAction();
  const locked = event.status === "cancelled";

  const remove = async (t: PromoterTier) => {
    if (!confirm(`Delete ${t.name}?`)) return;
    const ok = await action.run(() => api.deleteTier(orgId, event.id, t.id).then(() => true));
    if (ok) setEvent({ ...event, tiers: event.tiers.filter((x) => x.id !== t.id) });
  };

  return (
    <div className="stack">
      <Notice>{action.error}</Notice>
      <table className="table">
        <thead>
          <tr>
            <th>Tier</th>
            <th className="right">Price</th>
            <th className="right">Sold / available</th>
            <th className="right">Per order</th>
            <th />
          </tr>
        </thead>
        <tbody>
          {event.tiers.map((t) =>
            editing === t.id ? (
              <tr key={t.id}>
                <td colSpan={5}>
                  <TierForm
                    tier={t}
                    onCancel={() => setEditing(null)}
                    onSave={(b) => api.updateTier(orgId, event.id, t.id, b)}
                    onSaved={(ev) => {
                      setEvent(ev);
                      setEditing(null);
                    }}
                  />
                </td>
              </tr>
            ) : (
              <tr key={t.id}>
                <td>
                  <strong>{t.name}</strong>
                  {(t.sales_start_at || t.sales_end_at) && (
                    <div className="muted small">
                      {t.sales_start_at && `From ${dateLong(t.sales_start_at)}`}
                      {t.sales_start_at && t.sales_end_at && " · "}
                      {t.sales_end_at && `Until ${dateLong(t.sales_end_at)}`}
                    </div>
                  )}
                </td>
                <td className="right">{t.price_minor ? money(t.price_minor) : "Free"}</td>
                <td className="right">
                  {t.quantity_sold} / {t.quantity}
                </td>
                <td className="right">{t.max_per_order}</td>
                <td className="right nowrap">
                  {!locked && (
                    <>
                      <button className="link-btn" onClick={() => setEditing(t.id)}>
                        Edit
                      </button>
                      {t.quantity_sold === 0 && (
                        <button className="link-btn danger" onClick={() => remove(t)}>
                          Delete
                        </button>
                      )}
                    </>
                  )}
                </td>
              </tr>
            ),
          )}
        </tbody>
      </table>
      {editing === "new" ? (
        <div className="card">
          <TierForm
            onCancel={event.tiers.length ? () => setEditing(null) : undefined}
            onSave={(b) => api.createTier(orgId, event.id, { ...b, sort_order: event.tiers.length })}
            onSaved={(ev) => {
              setEvent(ev);
              setEditing(null);
            }}
          />
        </div>
      ) : (
        !locked && (
          <button className="btn btn-ghost" onClick={() => setEditing("new")}>
            + Add tier
          </button>
        )
      )}
      <p className="muted small">
        Once a tier has sales its price is fixed; add a new tier (e.g. "Tier 2") for a price change. Buyers pay a
        booking fee on top of the ticket price online; cash sales are face value.
      </p>
    </div>
  );
}

function TierForm({
  tier,
  onSave,
  onSaved,
  onCancel,
}: {
  tier?: PromoterTier;
  onSave: (b: TierFields) => Promise<PromoterEvent>;
  onSaved: (e: PromoterEvent) => void;
  onCancel?: () => void;
}) {
  const [name, setName] = useState(tier?.name ?? "");
  const [price, setPrice] = useState(tier ? (tier.price_minor / 100).toFixed(2) : "");
  const [quantity, setQuantity] = useState(String(tier?.quantity ?? ""));
  const [perOrder, setPerOrder] = useState(String(tier?.max_per_order ?? 10));
  const [start, setStart] = useState(toLocalInput(tier?.sales_start_at ?? null));
  const [end, setEnd] = useState(toLocalInput(tier?.sales_end_at ?? null));
  const action = useAction();
  const priceLocked = !!tier && tier.quantity_sold > 0;

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    const price_minor = dollarsToMinor(price || "0");
    if (Number.isNaN(price_minor)) return action.setError("Enter a price like 350 or 350.00");
    const body: TierFields = {
      name: name.trim(),
      quantity: Number(quantity),
      max_per_order: Number(perOrder),
      sales_start_at: fromLocalInput(start),
      sales_end_at: fromLocalInput(end),
    };
    if (!priceLocked) body.price_minor = price_minor;
    const ev = await action.run(() => onSave(body));
    if (ev) onSaved(ev);
  };

  return (
    <form className="stack" onSubmit={submit}>
      <div className="grid-4">
        <Field label="Name">
          <input required placeholder="Early bird" value={name} onChange={(e) => setName(e.target.value)} />
        </Field>
        <Field label="Price (TT$)" hint={priceLocked ? "Fixed: tickets sold" : "0 for free RSVP"}>
          <input required inputMode="decimal" disabled={priceLocked} value={price} onChange={(e) => setPrice(e.target.value)} />
        </Field>
        <Field label="Tickets available">
          <input required type="number" min={Math.max(1, tier?.quantity_sold ?? 1)} value={quantity} onChange={(e) => setQuantity(e.target.value)} />
        </Field>
        <Field label="Max per order">
          <input required type="number" min={1} max={50} value={perOrder} onChange={(e) => setPerOrder(e.target.value)} />
        </Field>
      </div>
      <div className="grid-2">
        <Field label="Sales open (optional)">
          <input type="datetime-local" value={start} onChange={(e) => setStart(e.target.value)} />
        </Field>
        <Field label="Sales close (optional)">
          <input type="datetime-local" value={end} onChange={(e) => setEnd(e.target.value)} />
        </Field>
      </div>
      <Notice>{action.error}</Notice>
      <div className="row">
        <button className="btn btn-primary" disabled={action.busy}>
          {tier ? "Save tier" : "Add tier"}
        </button>
        {onCancel && (
          <button type="button" className="btn btn-ghost" onClick={onCancel}>
            Cancel
          </button>
        )}
      </div>
    </form>
  );
}

// ---------- Sellers ----------

function Sellers({ orgId, event }: { orgId: string; event: PromoterEvent }) {
  const { data: sellers, error, reload } = useLoad(() => api.sellers(orgId, event.id), [orgId, event.id]);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const action = useAction();
  const locked = event.status === "cancelled";

  const add = async (e: FormEvent) => {
    e.preventDefault();
    const s = await action.run(() =>
      api.createSeller(orgId, event.id, { display_name: name.trim(), email: email.trim() || null }),
    );
    if (s) {
      setName("");
      setEmail("");
      reload();
    }
  };
  const remove = async (id: string, label: string) => {
    if (!confirm(`Remove seller ${label}?`)) return;
    const ok = await action.run(() => api.deleteSeller(orgId, event.id, id).then(() => true));
    if (ok) reload();
  };

  return (
    <div className="stack">
      <p className="muted">
        Each committee seller gets a code and a personal link. Online sales through their link are credited to them.
        Link a seller to a team member's account (same email) so they can record cash sales from their phone.
      </p>
      <Notice>{error ?? action.error}</Notice>
      <table className="table">
        <tbody>
          {sellers?.map((s) => {
            const link = `${location.origin}/e/${event.slug}?ref=${s.code}`;
            return (
              <tr key={s.id}>
                <td>
                  <strong>{s.display_name}</strong>
                  <div className="muted small">{s.user_id ? "Can record cash sales" : "Link only"}</div>
                </td>
                <td>
                  <code>{s.code}</code>
                </td>
                <td className="right nowrap">
                  <CopyButton text={link} />
                  <a className="btn btn-ghost btn-sm" href={whatsappLink(`Get your tickets for ${event.title} from me: ${link}`)} target="_blank" rel="noreferrer">
                    WhatsApp
                  </a>
                  {!locked && (
                    <button className="link-btn danger" onClick={() => remove(s.id, s.display_name)}>
                      Remove
                    </button>
                  )}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
      {sellers?.length === 0 && <p className="muted">No sellers yet.</p>}
      {!locked && (
        <form className="inline-form" onSubmit={add}>
          <input required placeholder="Seller name" value={name} onChange={(e) => setName(e.target.value)} aria-label="Seller name" />
          <input type="email" placeholder="Their account email (optional)" value={email} onChange={(e) => setEmail(e.target.value)} aria-label="Account email" />
          <button className="btn btn-primary btn-sm" disabled={action.busy}>
            Add seller
          </button>
        </form>
      )}
    </div>
  );
}

// ---------- Orders ----------

const CHANNEL_LABEL = { online: "Online", seller_cash: "Seller (cash)", box_office: "Box office" };

function Orders({ orgId, eventId }: { orgId: string; eventId: string }) {
  const [q, setQ] = useState("");
  const [search, setSearch] = useState("");
  const [all, setAll] = useState(false);
  const { data: orders, error } = useLoad(() => api.orders(orgId, eventId, search, all), [orgId, eventId, search, all]);

  return (
    <div className="stack">
      <form
        className="inline-form"
        onSubmit={(e) => {
          e.preventDefault();
          setSearch(q.trim());
        }}
      >
        <input placeholder="Search name, email or phone" value={q} onChange={(e) => setQ(e.target.value)} aria-label="Search orders" />
        <button className="btn btn-ghost btn-sm">Search</button>
        <label className="check">
          <input type="checkbox" checked={all} onChange={(e) => setAll(e.target.checked)} /> Include unpaid
        </label>
      </form>
      <Notice>{error}</Notice>
      {!orders && !error && <Loading />}
      {orders?.length === 0 && <p className="muted">No orders found.</p>}
      {orders && orders.length > 0 && (
        <div className="table-scroll">
          <table className="table">
            <thead>
              <tr>
                <th>Buyer</th>
                <th>Channel</th>
                <th className="right">Tickets</th>
                <th className="right">Total</th>
                <th>Status</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {orders.map((o) => (
                <tr key={o.id}>
                  <td>
                    <strong>{o.buyer_name}</strong>
                    <div className="muted small">{[o.buyer_email, o.buyer_phone].filter(Boolean).join(" · ")}</div>
                    <div className="muted small">{dateLong(o.created_at)}</div>
                  </td>
                  <td>
                    {CHANNEL_LABEL[o.channel]}
                    {o.seller_name && <div className="muted small">{o.seller_name}</div>}
                  </td>
                  <td className="right">
                    {o.tickets}
                    {o.checked_in > 0 && <div className="muted small">{o.checked_in} in</div>}
                  </td>
                  <td className="right">{money(o.total_minor)}</td>
                  <td>
                    <Badge tone={o.status === "paid" ? "good" : o.status === "pending" ? "warn" : "bad"}>{o.status}</Badge>
                  </td>
                  <td className="right">{o.status === "paid" && <CopyButton text={o.link} label="Ticket link" />}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      <p className="muted small">A buyer who lost their tickets: find them here and resend the ticket link.</p>
    </div>
  );
}

// ---------- Seller / scanner area ----------

function SellerArea({ orgId, event, role }: { orgId: string; event: PromoterEvent; role: Role }) {
  if (role === "scanner") {
    return (
      <div className="card callout">
        <strong>You're on the gate for this event.</strong>
        <p className="muted">Open the scanner on your phone at the event to check tickets in.</p>
        <Link className="btn btn-primary" href={`/promoter/orgs/${orgId}/events/${event.id}/scan`}>
          Open gate scanner
        </Link>
      </div>
    );
  }
  return <SellPanel orgId={orgId} event={event} admin={isAdmin(role)} />;
}
