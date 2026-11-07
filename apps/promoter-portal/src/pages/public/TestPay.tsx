// Stand-in for the payment provider's hosted checkout while the site runs with
// PAYMENT_PROVIDER=test. Nothing here takes card details.
import { api } from "../../api";
import { money } from "../../format";
import { navigate, useQuery } from "../../router";
import { Loading, Notice, Shell, useAction, useLoad } from "../../ui";

export default function TestPay({ orderId }: { orderId: string }) {
  const token = useQuery().get("token") ?? "";
  const { data: order, error } = useLoad(() => api.order(orderId, token), [orderId, token]);
  const action = useAction();
  const orderUrl = `/orders/${orderId}?token=${encodeURIComponent(token)}`;

  const pay = async (outcome: "paid" | "declined") => {
    const done = await action.run(() => api.testPay(orderId, token, outcome));
    if (done) navigate(orderUrl, true);
  };

  return (
    <Shell>
      <div className="card test-pay">
        <p className="eyebrow">Test checkout</p>
        <h1>Simulated payment</h1>
        <p className="muted">
          This page stands in for WiPay's hosted checkout until the live account is connected. No card is charged.
        </p>
        <Notice>{error}</Notice>
        {!order && !error && <Loading />}
        {order && order.status !== "pending" && (
          <Notice kind="info">
            This order is {order.status}. <a href={orderUrl}>View order</a>
          </Notice>
        )}
        {order?.status === "pending" && (
          <>
            <dl className="totals">
              <dt>{order.event.title}</dt>
              <dd />
              {order.items.map((i) => (
                <div className="totals-row" key={i.tier_name}>
                  <dt>
                    {i.quantity} × {i.tier_name}
                  </dt>
                  <dd>{money(i.quantity * i.unit_price_minor, order.currency)}</dd>
                </div>
              ))}
              <dt>Booking fee</dt>
              <dd>{money(order.buyer_fee_minor, order.currency)}</dd>
              <dt className="total">Total</dt>
              <dd className="total">{money(order.total_minor, order.currency)}</dd>
            </dl>
            <Notice>{action.error}</Notice>
            <div className="row">
              <button className="btn btn-primary" disabled={action.busy} onClick={() => pay("paid")}>
                Pay {money(order.total_minor, order.currency)} (test)
              </button>
              <button className="btn btn-ghost" disabled={action.busy} onClick={() => pay("declined")}>
                Decline
              </button>
            </div>
          </>
        )}
      </div>
    </Shell>
  );
}
