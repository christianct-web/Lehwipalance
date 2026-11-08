// The flyer slot.
//
// Promoters upload their own artwork, so this must look deliberate with a
// portrait flyer, a landscape photo, a blurry phone snap, or nothing at all.
// Every variant renders into the same fixed aspect box; the title is always
// real text on top of the art, never baked into it, so it stays selectable,
// searchable, translatable and readable by a screen reader.

import type { EventSummary } from "./api";

/** Deterministic per event, so a fete keeps the same face between visits. */
function tone(seed: string): number {
  let h = 2166136261;
  for (let i = 0; i < seed.length; i++) h = Math.imul(h ^ seed.charCodeAt(i), 16777619);
  return (h >>> 0) % 4;
}

/** Initials for the fallback: a fete is recognised by its name first. */
function initials(title: string): string {
  const words = title.replace(/[^\p{L}\p{N} ]/gu, "").split(/\s+/).filter(Boolean);
  return (words.length === 1 ? words[0].slice(0, 2) : words.slice(0, 2).map((w) => w[0]).join("")).toUpperCase();
}

export function Flyer({
  event,
  sizes,
  priority,
}: {
  event: Pick<EventSummary, "slug" | "title" | "cover_image_url" | "category">;
  sizes: string;
  priority?: boolean;
}) {
  if (event.cover_image_url) {
    return (
      <img
        className="flyer-img"
        src={event.cover_image_url}
        sizes={sizes}
        alt=""
        /* The title sits beside this as text, so the art is decorative. */
        loading={priority ? "eager" : "lazy"}
        decoding="async"
        fetchPriority={priority ? "high" : "low"}
      />
    );
  }
  return (
    <div className={`flyer-fallback tone-${tone(event.slug)}`} aria-hidden="true">
      <span className="flyer-initials">{initials(event.title)}</span>
    </div>
  );
}
