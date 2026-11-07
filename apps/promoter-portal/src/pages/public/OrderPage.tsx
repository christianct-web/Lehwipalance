import { useEffect } from "react";
import { api } from "../../api";
import { dateLong, money, timeOnly } from "../../format";
import { Link, useQuery } from "../../router";
import { Badge, CopyButton, Loading, Notice, QR, Shell, useLoad, whatsappLink } from "../../ui";
import { saveOrder } from "./saved";

export default function OrderPage({ orderId }: { orderId: string }) {
  const token = useQuery().get("token") ?? "";
  const { data: order, error, reload } = useLoad(() => api.order(orderId, token), [orderId, token]);

  // A pending order settles when the provider calls back; check every few seconds.
  useEffect(() => {
    if (order?.status !== "pending") return;
    const t = setInterval(reload, 4000);
    return () => clearInterval(t);
  }, [order?.status, reload]);

  useEffect(() => {
    if (order) saveOrder({ id: order.id, token, title: order.event.title, startsAt: order.event.starts_at });
  }, [order, token]);

  if (error) {
    return (
      <Shell>
        <Notice>{error === "Order not found" ? "We couldn't find this order. Check the link." : error}</Notice>
      </Shell>
    );
  }
  if (!order) {
    return (
      <Shell>
        <Loading />
      </Shell>
    );
  }

  const share = `${location.origin}/orders/${order.id}?token=${encodeURIComponent(token)}`;

  return (
    <Shell>
      <div className="order">
        <p className="eyebrow">Order for {order.buyer_name}</p>
        <h1>{order.event.title}</h1>
        <p className="event-meta">
          <strong>{dateLong(order.event.starts_at)}</strong>
          {order.event.venue_name && <span>{order.event.venue_name}</span>}
        </p>

        {order.status === "pending" && (
          <Notice kind="info">
            Waiting for your payment to be confirmed. This page updates by itself.
            {order.expires_at && ` Your tickets are held until ${timeOnly(order.expires_at)}.`}
          </Notice>
        )}
        {order.status === "expired" && (
          <Notice>
            Your reservation expired before payment came through.{" "}
            <Link href={`/e/${order.event.slug}`}>Try again</Link>
          </Notice>
        )}
        {order.status === "failed" && (
          <Notice>
            The payment didn't go through. If you were charged, contact the promoter with this order link.{" "}
            <Link href={`/e/${order.event.slug}`}>Back to the event</Link>
          </Notice>
        )}
        {order.status === "refunded" && <Notice>This order was refunded.</Notice>}
        {order.status === "cancelled" && (
          <Notice>
            This order was cancelled, so no tickets were issued. If you were charged, contact the promoter with this
            order link for a refund.
          </Notice>
        )}
        {order.is_test && (
          <Notice kind="info">
            Test order: the payment was simulated. These tickets are for trying things out and won't be accepted at the
            gate.
          </Notice>
        )}

        {order.status === "paid" && (
          <>
            <Notice kind="ok">
              You're going! Show a QR code at the gate. Each code gets one person in.
            </Notice>
            <div className="share-row">
              <CopyButton text={share} label="Copy ticket link" />
              <a className="btn btn-ghost btn-sm" href={whatsappLink(`My tickets for ${order.event.title}: ${share}`)} target="_blank" rel="noreferrer">
                Send on WhatsApp
              </a>
            </div>
            <p className="muted small">Anyone with this link can use these tickets. Only share it with your crew.</p>
            <ol className="tickets">
              {order.tickets.map((t, i) => (
                <li key={t.code} className={t.status === "valid" ? "ticket" : "ticket used"}>
                  <div className="ticket-head">
                    <strong>{t.tier_name}</strong>
                    <span className="muted">
                      Ticket {i + 1} of {order.tickets.length}
                    </span>
                  </div>
                  <QR value={t.code} />
                  {t.status === "checked_in" && (
                    <Badge tone="warn">Scanned {t.checked_in_at ? timeOnly(t.checked_in_at) : ""}</Badge>
                  )}
                  {t.status === "void" && <Badge tone="bad">Void</Badge>}
                  <code className="ticket-code">{t.code}</code>
                </li>
              ))}
            </ol>
          </>
        )}

        <dl className="totals card">
          {order.items.map((i) => (
            <div className="totals-row" key={i.tier_name}>
              <dt>
                {i.quantity} × {i.tier_name}
              </dt>
              <dd>{money(i.quantity * i.unit_price_minor, order.currency)}</dd>
            </div>
          ))}
          {order.buyer_fee_minor > 0 && (
            <>
              <dt>Booking fee</dt>
              <dd>{money(order.buyer_fee_minor, order.currency)}</dd>
            </>
          )}
          <dt className="total">Total</dt>
          <dd className="total">{money(order.total_minor, order.currency)}</dd>
        </dl>
      </div>
    </Shell>
  );
}
