import type { ReactNode } from "react";
import { api, type MyOrg, type Role } from "../../api";
import { Link } from "../../router";
import { Shell, useLoad, useSession } from "../../ui";

export const ROLE_LABEL: Record<Role, string> = {
  owner: "Owner",
  manager: "Manager",
  seller: "Seller",
  scanner: "Gate scanner",
};

export const isAdmin = (role?: Role) => role === "owner" || role === "manager";

export function PromoterShell({ children, crumbs }: { children: ReactNode; crumbs?: ReactNode }) {
  const { user, signOut } = useSession();
  return (
    <Shell
      wide
      nav={
        user && (
          <>
            <Link href="/promoter">My organisations</Link>
            <button className="link-btn" onClick={signOut}>
              Sign out
            </button>
          </>
        )
      }
    >
      {crumbs && <nav className="crumbs">{crumbs}</nav>}
      {children}
    </Shell>
  );
}

/** The signed-in user's organisation, with their role in it. */
export function useOrg(orgId: string) {
  const res = useLoad(() => api.orgs(), [orgId]);
  const org: MyOrg | undefined = res.data?.find((o) => o.id === orgId);
  return { ...res, org };
}
