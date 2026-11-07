import type { ReactNode } from "react";
import EventAdmin from "./pages/promoter/EventAdmin";
import OrgPage from "./pages/promoter/OrgPage";
import Orgs from "./pages/promoter/Orgs";
import Scan from "./pages/promoter/Scan";
import SignIn from "./pages/promoter/SignIn";
import EventPage from "./pages/public/EventPage";
import Home from "./pages/public/Home";
import MyTickets from "./pages/public/MyTickets";
import OrderPage from "./pages/public/OrderPage";
import TestPay from "./pages/public/TestPay";
import { Link, match, useLocation } from "./router";
import { ConfigProvider, Loading, SessionProvider, Shell, useSession } from "./ui";

type Route = [string, (p: Record<string, string>) => ReactNode, { auth?: boolean }?];

const ROUTES: Route[] = [
  ["/", () => <Home />],
  ["/tickets", () => <MyTickets />],
  ["/e/:slug", (p) => <EventPage slug={p.slug} />],
  ["/pay/test/:id", (p) => <TestPay orderId={p.id} />],
  ["/orders/:id", (p) => <OrderPage orderId={p.id} />],
  ["/promoter", () => <Orgs />, { auth: true }],
  ["/promoter/orgs/:org", (p) => <OrgPage orgId={p.org} />, { auth: true }],
  ["/promoter/orgs/:org/events/:ev", (p) => <EventAdmin orgId={p.org} eventId={p.ev} />, { auth: true }],
  ["/promoter/orgs/:org/events/:ev/scan", (p) => <Scan orgId={p.org} eventId={p.ev} />, { auth: true }],
];

function Router() {
  const { path } = useLocation();
  const { user, ready } = useSession();
  for (const [pattern, render, opts] of ROUTES) {
    const params = match(pattern, path);
    if (!params) continue;
    // Every branch returns the same wrapper. A bare return here would make
    // the page's own first <div> a direct child of #root, where the
    // display:contents rule below is meant for this wrapper alone.
    const wrap = (node: ReactNode) => (
      // Key by path so a page's state resets when its params change.
      <div className="route" key={path}>
        {node}
      </div>
    );
    if (opts?.auth) {
      if (!ready) return wrap(<Loading />);
      if (!user) return wrap(<SignIn />);
    }
    return wrap(render(params));
  }
  return (
    <Shell>
      <h1>Page not found</h1>
      <p>
        <Link href="/">See what's on</Link>
      </p>
    </Shell>
  );
}

export default function App() {
  return (
    <ConfigProvider>
      <SessionProvider>
        <Router />
      </SessionProvider>
    </ConfigProvider>
  );
}
