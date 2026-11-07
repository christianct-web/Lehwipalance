import { useState, type FormEvent } from "react";
import { api } from "../../api";
import { Link, navigate } from "../../router";
import { Badge, Field, Loading, Notice, useAction, useLoad, useSession } from "../../ui";
import { PromoterShell, ROLE_LABEL } from "./common";

export default function Orgs() {
  const { user } = useSession();
  const { data: orgs, error } = useLoad(() => api.orgs(), []);
  const [name, setName] = useState("");
  const [creating, setCreating] = useState(false);
  const action = useAction();

  const create = async (e: FormEvent) => {
    e.preventDefault();
    const org = await action.run(() => api.createOrg({ name: name.trim() }));
    if (org) navigate(`/promoter/orgs/${org.id}`);
  };

  return (
    <PromoterShell>
      <h1>Hi, {user?.full_name.split(" ")[0]}</h1>
      <Notice>{error}</Notice>
      {!orgs && !error && <Loading />}
      {orgs && orgs.length === 0 && (
        <p className="muted">
          You're not part of an organisation yet. If you sell or scan for a promoter, ask them to add{" "}
          <strong>{user?.email}</strong>. If you're a promoter, create your organisation below.
        </p>
      )}
      <ul className="cards">
        {orgs?.map((o) => (
          <li key={o.id}>
            <Link href={`/promoter/orgs/${o.id}`} className="card card-link">
              <strong>{o.name}</strong>
              <Badge>{ROLE_LABEL[o.role]}</Badge>
            </Link>
          </li>
        ))}
      </ul>

      {creating ? (
        <form className="card stack narrow" onSubmit={create}>
          <h2>New organisation</h2>
          <Field label="Promoter or brand name">
            <input required autoFocus value={name} onChange={(e) => setName(e.target.value)} />
          </Field>
          <Notice>{action.error}</Notice>
          <div className="row">
            <button className="btn btn-primary" disabled={action.busy}>
              Create
            </button>
            <button type="button" className="btn btn-ghost" onClick={() => setCreating(false)}>
              Cancel
            </button>
          </div>
        </form>
      ) : (
        <button className="btn btn-ghost" onClick={() => setCreating(true)}>
          + New organisation
        </button>
      )}
    </PromoterShell>
  );
}
