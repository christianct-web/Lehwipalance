import { useState, type FormEvent } from "react";
import { api } from "../../api";
import { Field, Notice, useAction, useSession } from "../../ui";
import { PromoterShell } from "./common";

export default function SignIn() {
  const { signIn } = useSession();
  const [mode, setMode] = useState<"in" | "up">("in");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const action = useAction();

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    await action.run(async () => {
      const res =
        mode === "in"
          ? await api.login({ email, password })
          : await api.register({ email, password, full_name: name.trim() });
      await signIn(res.access_token);
    });
  };

  return (
    <PromoterShell>
      <div className="auth card">
        <h1>{mode === "in" ? "Sign in" : "Create your account"}</h1>
        <p className="muted">
          For promoters, their committee sellers and gate staff. Sellers and scanners: create an account, then ask
          your promoter to add you with this email.
        </p>
        <form onSubmit={submit} className="stack">
          {mode === "up" && (
            <Field label="Full name">
              <input required value={name} onChange={(e) => setName(e.target.value)} autoComplete="name" />
            </Field>
          )}
          <Field label="Email">
            <input required type="email" value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="email" />
          </Field>
          <Field label="Password" hint={mode === "up" ? "At least 8 characters." : undefined}>
            <input
              required
              type="password"
              minLength={mode === "up" ? 8 : undefined}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete={mode === "in" ? "current-password" : "new-password"}
            />
          </Field>
          <Notice>{action.error}</Notice>
          <button className="btn btn-primary btn-block" disabled={action.busy}>
            {action.busy ? "One moment…" : mode === "in" ? "Sign in" : "Create account"}
          </button>
        </form>
        <p className="muted">
          {mode === "in" ? "New here? " : "Already have an account? "}
          <button
            className="link-btn"
            onClick={() => {
              setMode(mode === "in" ? "up" : "in");
              action.setError(null);
            }}
          >
            {mode === "in" ? "Create an account" : "Sign in"}
          </button>
        </p>
      </div>
    </PromoterShell>
  );
}
