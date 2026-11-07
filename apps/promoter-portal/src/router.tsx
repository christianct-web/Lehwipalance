// A minimal history router: the app has a handful of routes, so this avoids a
// dependency. Paths are matched in order; ":name" segments become params.
import { useEffect, useState, type AnchorHTMLAttributes, type MouseEvent } from "react";

export function navigate(to: string, replace = false) {
  if (replace) history.replaceState(null, "", to);
  else history.pushState(null, "", to);
  window.dispatchEvent(new Event("lp:navigate"));
  if (!replace) window.scrollTo(0, 0);
}

export function useLocation() {
  const [loc, setLoc] = useState(() => ({ path: location.pathname, search: location.search }));
  useEffect(() => {
    const update = () => setLoc({ path: location.pathname, search: location.search });
    window.addEventListener("popstate", update);
    window.addEventListener("lp:navigate", update);
    return () => {
      window.removeEventListener("popstate", update);
      window.removeEventListener("lp:navigate", update);
    };
  }, []);
  return loc;
}

export function match(pattern: string, path: string): Record<string, string> | null {
  const p = pattern.split("/").filter(Boolean);
  const s = path.split("/").filter(Boolean);
  if (p.length !== s.length) return null;
  const params: Record<string, string> = {};
  for (let i = 0; i < p.length; i++) {
    if (p[i].startsWith(":")) params[p[i].slice(1)] = decodeURIComponent(s[i]);
    else if (p[i] !== s[i]) return null;
  }
  return params;
}

export function useQuery(): URLSearchParams {
  const { search } = useLocation();
  return new URLSearchParams(search);
}

export function Link({ href, onClick, ...rest }: AnchorHTMLAttributes<HTMLAnchorElement> & { href: string }) {
  const handle = (e: MouseEvent<HTMLAnchorElement>) => {
    onClick?.(e);
    if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
    if (href.startsWith("http")) return;
    e.preventDefault();
    navigate(href);
  };
  return <a href={href} onClick={handle} {...rest} />;
}
