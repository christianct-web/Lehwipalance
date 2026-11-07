import { useState, type FormEvent } from "react";
import { api, type Role } from "../../api";
import { dateLong, fromLocalInput } from "../../format";
import { Link, navigate } from "../../router";
import { Badge, Field, Loading, Notice, useAction, useLoad, useSession } from "../../ui";
import { isAdmin, PromoterShell, ROLE_LABEL, useOrg } from "./common";

const STATUS_TONE = { draft: "neutral", published: "good", cancelled: "bad" } as const;

export default function OrgPage({ orgId }: { orgId: string }) {
  const { org, error: orgError, loading } = useOrg(orgId);
  const { data: events, error, reload } = useLoad(() => api.orgEvents(orgId), [orgId]);
  const [showNew, setShowNew] = useState(false);

  if (orgError || (!loading && !org)) {
    return (
      <PromoterShell>
        <Notice>{orgError ?? "Organisation not found."}</Notice>
      </PromoterShell>
    );
  }
  if (!org) {
    return (
      <PromoterShell>
        <Loading />
      </PromoterShell>
    );
  }
  const admin = isAdmin(org.role);

  return (
    <PromoterShell crumbs={<Link href="/promoter">Organisations</Link>}>
      <div className="page-head">
        <h1>{org.name}</h1>
        <Badge>{ROLE_LABEL[org.role]}</Badge>
      </div>

      <section>
        <div className="section-head">
          <h2>Events</h2>
          {admin && !showNew && (
            <button className="btn btn-primary btn-sm" onClick={() => setShowNew(true)}>
              + New event
            </button>
          )}
        </div>
        {showNew && <NewEvent orgId={orgId} onCancel={() => setShowNew(false)} />}
        <Notice>{error}</Notice>
        {!events && !error && <Loading />}
        {events?.length === 0 && <p className="muted">No events yet.</p>}
        <ul className="cards">
          {events?.map((e) => (
            <li key={e.id}>
              <Link href={`/promoter/orgs/${orgId}/events/${e.id}`} className="card card-link">
                <div>
                  <strong>{e.title}</strong>
                  <div className="muted small">
                    {dateLong(e.starts_at)}
                    {e.venue_name ? ` · ${e.venue_name}` : ""}
                  </div>
                </div>
                <Badge tone={STATUS_TONE[e.status]}>{e.status}</Badge>
              </Link>
            </li>
          ))}
        </ul>
        {events && <button className="link-btn small" onClick={reload}>Refresh</button>}
      </section>

      {admin && <Members orgId={orgId} myRole={org.role} />}
    </PromoterShell>
  );
}

function NewEvent({ orgId, onCancel }: { orgId: string; onCancel: () => void }) {
  const [title, setTitle] = useState("");
  const [startsAt, setStartsAt] = useState("");
  const [venue, setVenue] = useState("");
  const action = useAction();

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    const starts = fromLocalInput(startsAt);
    if (!starts) return;
    const ev = await action.run(() =>
      api.createEvent(orgId, { title: title.trim(), starts_at: starts, venue_name: venue.trim() || null }),
    );
    if (ev) navigate(`/promoter/orgs/${orgId}/events/${ev.id}`);
  };

  return (
    <form className="card stack narrow" onSubmit={submit}>
      <h3>New event</h3>
      <Field label="Title">
        <input required autoFocus value={title} onChange={(e) => setTitle(e.target.value)} />
      </Field>
      <Field label="Starts (Trinidad time)">
        <input required type="datetime-local" value={startsAt} onChange={(e) => setStartsAt(e.target.value)} />
      </Field>
      <Field label="Venue">
        <input value={venue} onChange={(e) => setVenue(e.target.value)} />
      </Field>
      <Notice>{action.error}</Notice>
      <div className="row">
        <button className="btn btn-primary" disabled={action.busy}>
          Create draft
        </button>
        <button type="button" className="btn btn-ghost" onClick={onCancel}>
          Cancel
        </button>
      </div>
    </form>
  );
}

function Members({ orgId, myRole }: { orgId: string; myRole: Role }) {
  const { user } = useSession();
  const { data: members, error, reload } = useLoad(() => api.members(orgId), [orgId]);
  const [email, setEmail] = useState("");
  const [role, setRole] = useState<Role>("seller");
  const action = useAction();
  const roles: Role[] = myRole === "owner" ? ["seller", "scanner", "manager", "owner"] : ["seller", "scanner"];

  const add = async (e: FormEvent) => {
    e.preventDefault();
    const m = await action.run(() => api.addMember(orgId, { email: email.trim(), role }));
    if (m) {
      setEmail("");
      reload();
    }
  };

  const remove = async (userId: string, label: string) => {
    if (!confirm(`Remove ${label} from this organisation?`)) return;
    const ok = await action.run(() => api.removeMember(orgId, userId).then(() => true));
    if (ok) reload();
  };

  return (
    <section>
      <h2>Team</h2>
      <p className="muted small">
        Sellers record cash sales and get a personal sales link. Gate scanners check tickets in. Each person needs an
        account first; add them by the email they signed up with.
      </p>
      <Notice>{error ?? action.error}</Notice>
      <table className="table">
        <tbody>
          {members?.map((m) => (
            <tr key={m.user_id}>
              <td>
                <strong>{m.full_name}</strong>
                <div className="muted small">{m.email}</div>
              </td>
              <td>{ROLE_LABEL[m.role]}</td>
              <td className="right">
                {m.user_id !== user?.id && (myRole === "owner" || !isAdmin(m.role)) && (
                  <button className="link-btn danger" onClick={() => remove(m.user_id, m.full_name)}>
                    Remove
                  </button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      <form className="inline-form" onSubmit={add}>
        <input
          required
          type="email"
          placeholder="Their account email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          aria-label="Email"
        />
        <select value={role} onChange={(e) => setRole(e.target.value as Role)} aria-label="Role">
          {roles.map((r) => (
            <option key={r} value={r}>
              {ROLE_LABEL[r]}
            </option>
          ))}
        </select>
        <button className="btn btn-primary btn-sm" disabled={action.busy}>
          Add
        </button>
      </form>
    </section>
  );
}
