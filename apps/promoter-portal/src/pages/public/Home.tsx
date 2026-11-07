import { useEffect, useMemo, useState } from "react";
import { api, type EventSummary } from "../../api";
import { Flyer } from "../../flyer";
import { dayHeading, dayKey, relativeDay, timeOnly } from "../../format";
import { Link } from "../../router";
import { Loading, Notice, Shell, useLoad } from "../../ui";
import { isSaved, toggleSaved } from "./saved";

type View = "grid" | "feed";
const VIEW_KEY = "lp_view";

function storedView(): View {
  try {
    return localStorage.getItem(VIEW_KEY) === "feed" ? "feed" : "grid";
  } catch {
    return "grid";
  }
}

type Day = { key: string; label: string; relative: string | null; events: EventSummary[] };

function groupByDay(events: EventSummary[]): Day[] {
  const days = new Map<string, EventSummary[]>();
  for (const e of events) {
    const k = dayKey(e.starts_at);
    const list = days.get(k);
    if (list) list.push(e);
    else days.set(k, [e]);
  }
  return [...days.entries()].map(([key, list]) => ({
    key,
    label: dayHeading(list[0].starts_at),
    relative: relativeDay(list[0].starts_at),
    events: list,
  }));
}

/** Save to plan. The whole card is a link, so this stops the navigation. */
function SaveButton({ slug, title }: { slug: string; title: string }) {
  const [on, setOn] = useState(() => isSaved(slug));
  return (
    <button
      type="button"
      className={on ? "save on" : "save"}
      aria-pressed={on}
      aria-label={on ? `Remove ${title} from your plan` : `Save ${title} to your plan`}
      onClick={(e) => {
        e.preventDefault();
        e.stopPropagation();
        setOn(toggleSaved(slug));
      }}
    >
      <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">
        <path
          d="M6 3.5h12a1 1 0 0 1 1 1v16l-7-4.2-7 4.2v-16a1 1 0 0 1 1-1Z"
          fill={on ? "currentColor" : "none"}
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinejoin="round"
        />
      </svg>
    </button>
  );
}

export default function Home() {
  const { data: events, error } = useLoad(() => api.events(), []);
  const [category, setCategory] = useState("all");
  const [query, setQuery] = useState("");
  const [onlySaved, setOnlySaved] = useState(false);
  const [view, setView] = useState<View>(storedView);

  useEffect(() => {
    try {
      localStorage.setItem(VIEW_KEY, view);
    } catch {
      /* a remembered preference is a nicety, not a requirement */
    }
  }, [view]);

  // The feed owns the whole viewport: the page stops scrolling and the feed
  // scrolls instead, so one fete always fills the screen whatever the height
  // of the test banner and the header above it.
  useEffect(() => {
    document.body.classList.toggle("feed-mode", view === "feed");
    return () => document.body.classList.remove("feed-mode");
  }, [view]);

  const categories = useMemo(() => [...new Set((events ?? []).map((e) => e.category))].sort(), [events]);

  const shown = useMemo(() => {
    const q = query.trim().toLowerCase();
    return (events ?? []).filter((e) => {
      if (category !== "all" && e.category !== category) return false;
      if (onlySaved && !isSaved(e.slug)) return false;
      if (!q) return true;
      return `${e.title} ${e.venue_name ?? ""}`.toLowerCase().includes(q);
    });
  }, [events, category, query, onlySaved]);

  const days = useMemo(() => groupByDay(shown), [shown]);
  const empty = events && shown.length === 0;

  const toolbar = (
    <div className="finder">
      <div className="finder-search">
        <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
          <circle cx="11" cy="11" r="6.5" fill="none" stroke="currentColor" strokeWidth="1.9" />
          <path d="m16 16 4.5 4.5" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" />
        </svg>
        <input
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Find a fete…"
          aria-label="Search fetes by name or venue"
        />
      </div>
      <div className="chips" role="group" aria-label="Filter">
        <button type="button" className={`chip${category === "all" ? " on" : ""}`} aria-pressed={category === "all"} onClick={() => setCategory("all")}>
          Everything
        </button>
        {categories.map((c) => (
          <button key={c} type="button" className={`chip${category === c ? " on" : ""}`} aria-pressed={category === c} onClick={() => setCategory(c)}>
            {c.replace(/_/g, " ")}
          </button>
        ))}
        <button type="button" className={`chip${onlySaved ? " on" : ""}`} aria-pressed={onlySaved} onClick={() => setOnlySaved((v) => !v)}>
          Saved
        </button>
      </div>
      <div className="viewswitch" role="group" aria-label="How to view">
        <button type="button" className={view === "grid" ? "on" : ""} aria-pressed={view === "grid"} onClick={() => setView("grid")}>
          Grid
        </button>
        <button type="button" className={view === "feed" ? "on" : ""} aria-pressed={view === "feed"} onClick={() => setView("feed")}>
          Feed
        </button>
      </div>
    </div>
  );

  // ---- Feed: one fete per screen, flyer full-bleed, vertical snap. ----
  if (view === "feed") {
    return (
      <Shell flush>
        <div className="wrap wide">{toolbar}</div>
        <Notice>{error && `Couldn’t load what’s on: ${error}`}</Notice>
        {!events && !error && <Loading label="Loading the season…" />}
        {empty && <EmptyState category={category} onlySaved={onlySaved} />}
        <div className="feed" tabIndex={-1}>
          {shown.map((e, i) => (
            <article className="feed-item" key={e.id}>
              <Flyer event={e} sizes="100vw" priority={i === 0} />
              <div className="feed-body">
                <p className="feed-when">
                  {relativeDay(e.starts_at) ?? dayHeading(e.starts_at)} · {timeOnly(e.starts_at)}
                </p>
                <h2 className="feed-title">{e.title}</h2>
                <p className="feed-where">
                  {e.venue_name ?? "Trinidad & Tobago"} · {e.category.replace(/_/g, " ")}
                </p>
                <div className="feed-actions">
                  <Link className="btn btn-primary" href={`/e/${e.slug}`}>
                    Get tickets
                  </Link>
                  <SaveButton slug={e.slug} title={e.title} />
                </div>
              </div>
            </article>
          ))}
        </div>
      </Shell>
    );
  }

  // ---- Grid: the season keeps its spine, each day a heading. ----
  return (
    <Shell wide>
      <h1>
        Yuh next lime <em>starts here.</em>
      </h1>
      <p className="dateline">
        <span>Trinidad &amp; Tobago</span>
        <span>Carnival season</span>
        <span>Times are fete time</span>
      </p>
      {toolbar}

      <p className="muted">
        {shown.length === 0
          ? "Nothing matching yet."
          : `${shown.length} ${shown.length === 1 ? "fete" : "fetes"} on sale. Plenty vibes.`}
      </p>

      <Notice>{error && `Couldn’t load what’s on: ${error}`}</Notice>
      {!events && !error && <Loading label="Loading the season…" />}
      {empty && <EmptyState category={category} onlySaved={onlySaved} />}

      {days.map((day) => (
        <section className="dayblock" key={day.key}>
          <h2 className="day-head">
            <span className="day-date">{day.relative ?? day.label}</span>
            {day.relative && <span className="agate">{day.label}</span>}
            <span className="day-count">
              {day.events.length} {day.events.length === 1 ? "fete" : "fetes"}
            </span>
          </h2>
          <ul className="flyers">
            {day.events.map((e, i) => (
              <li key={e.id}>
                <Link className="fcard" href={`/e/${e.slug}`}>
                  <span className="fcard-art">
                    <Flyer event={e} sizes="(min-width: 1100px) 260px, (min-width: 700px) 33vw, 50vw" priority={i < 2} />
                    <span className="fcard-time">{timeOnly(e.starts_at)}</span>
                  </span>
                  <span className="fcard-title">{e.title}</span>
                  <span className="fcard-where">{e.venue_name ?? "Trinidad & Tobago"}</span>
                </Link>
                <SaveButton slug={e.slug} title={e.title} />
              </li>
            ))}
          </ul>
        </section>
      ))}
    </Shell>
  );
}

function EmptyState({ category, onlySaved }: { category: string; onlySaved: boolean }) {
  return (
    <div className="empty">
      <strong>Nothing on sale here yet</strong>
      {onlySaved
        ? "Nothing saved yet. Tap the ribbon on a fete to keep it in your plan."
        : category === "all"
          ? "As promoters publish their fetes they’ll show up here, by date."
          : "No fetes in this category. Try Everything."}
    </div>
  );
}
