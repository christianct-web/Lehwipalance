# Design system — Lehwi Palance

Recorded from the built result on 2026-11-07, not from intentions. The durable
product record is `PRODUCT.md`; the route strategy and direction contract are in
`.impeccable/surfaces/apps-promoter-portal-src.md`.

Implemented in `apps/promoter-portal/src/styles.css` (one file, no CSS
framework) and `src/brand.tsx`.

## The world

**The season keeps a dated spine; the fete's own artwork leads.** Two
registers off one system:

- **Buyer** (Persuade) — flyer-forward cards under ruled day headings, in the
  Trini voice. A **Feed** view shows one fete per screen, flyer full-bleed,
  with CSS scroll snap; the choice is remembered per browser. Two-up on a
  phone, four-up on desktop.
- **Promoter desk and gate** (Operate) — deliberately sober. A ruled account
  rather than stat tiles, money on a right-hand axis, and at night a committed
  ink ground. Expression never reaches the screens where money and entry are
  decided.

What it refuses: a hero carousel with no date spine (you cannot answer "what's
on Saturday?"), and its opposite, the austere white fintech table.

## Brand inheritance

The spectrum, the pin + P monogram and Montserrat come from the Flutter
customer app (`apps/customer`) and are binding. The mark was redrawn here: the
palm tree, sunset and road were removed, and it ships as vector with a flat
single-colour variant. The original `logo1.jpeg` is an opaque JPEG on a white
box with no vector and must not be used on screen.

## Colour

Three fixed roles. They never float: a colour outside its role is a bug.

| Token | Value | Role |
| --- | --- | --- |
| `--cyan` / `--cyan-deep` / `--cyan-ink` | `#10e8e8` / `#0aa6bd` / `#05616d` | Structure and wayfinding: links, the row-hover rule, the gate viewfinder |
| `--magenta-fill` / `--magenta-ink` | `#d1009a` / `#b00080` | **Liveness and the primary action, and nothing else.** One per view |
| `--purple-deep` / `--night` | `#8b1fc4` / `#170b26` | Depth, the browser theme colour, and the night ground |
| `--ground` / `--surface` | `#f7f6fa` / `#ffffff` | Cool off-white. Never cream |
| `--ink` / `--ink-2` / `--ink-3` | `#1a1026` / `#5e5470` / `#7b7190` | Purple-cast ink, so sober surfaces still sit inside the brand |

Strategy is **restrained**: neutrals plus one scarce action colour. The raw
logo values are kept for fills and the night ground only — `#f010b0` is 3.6:1
on the ground and cannot carry text, which is why `-fill` and `-ink` steps
exist. Light was chosen from the use scene (a phone in Trinidad daylight), and
the gate commits to a full ink ground because it is used outdoors at night.
Status colours never carry meaning alone; the gate states its verdict in words.

Measured on the built pages: **no text fails WCAG AA** at 360px or 1280px on
the home, event, ticket or promoter surfaces.

## Type

- **Display** — Montserrat 600–900 variable, self-hosted, latin subset, 38KB,
  one file, preloaded. Headings, the wordmark, buttons, tier and fete names,
  and ledger totals. `letter-spacing: -0.025em` on headings.
- **UI** — the system sans stack. Chosen so the interface is fully usable
  before the one webfont lands, which matters on Caribbean mobile data.
- **Figures and codes** — the system mono stack with `tabular-nums` set
  globally on `:root`, so money, counts and times never reflow as digits change.

Body measure is capped at `68ch`. `text-wrap: balance` on headings.

## Structure

- `.dayblock` / `.day-head` / `.flyers` / `.fcard` — the signature. A ruled
  day heading over a flyer grid; two columns below 640px, `minmax(240px, 1fr)`
  above.
- `.flyer-fallback` — promoters upload their own artwork, so the empty case is
  designed, not left grey: a deterministic gradient from the spectrum (four
  tones, chosen by a hash of the slug so a fete keeps its face) with the
  event's initials. A `0.18 → 0.34` dark scrim lifts those initials from
  1.89:1 to about 3.2:1 on the lightest tone. Titles are always real text
  beside the art, never baked into the image.
- `.feed` — `scroll-snap-type: y mandatory` with `scroll-snap-stop: always`.
  Sized by flexbox off `body.feed-mode`, never a guessed header height, so the
  title and buy button are always on screen whatever the banner does.
- `.finder` — search, chips and the view switch; one row that scrolls
  sideways below 720px rather than stacking.
- `.ledger` — the promoter's account, capped at `34rem` so labels and figures
  stay connected. Replaces the stat-tile grid.
- `.table.report-table` — ruled, uppercase agate headers, money right-aligned
  in mono, always inside `.table-scroll`.
- `.ticket` — a coupon: ruled, dashed cut line between the QR and its serial
  (never across the QR), and always light whatever the colour scheme, because
  it is scanned off a screen.
- `.scanner` — full night ground, verdict at `clamp(2.5rem, 12vw, 4.5rem)`.

Spacing is a 4px scale (`--s1`…`--s8`). Radius 8/12/999. Shadows always carry
both an offset and a soft blur.

## Motion

One authored moment: **the stamp**. `stamp-land` scales from 1.5 at −4° with an
exponential ease-out, used for the gate verdict and state marks. It is keyed on
a scan counter so a repeat scan re-lands it. Everything else is a 120–160ms
ease. `prefers-reduced-motion` removes the settle, never the state.

## Browser surfaces

Themed rather than left to the browser: selection, caret, `accent-color`,
scrollbars, the focus ring (`2px` magenta at `2px` offset), underline offset,
and tabular numerals.

## States

Every control carries a physical state before its label is read. Disabled
buttons go to a flat surface rather than a dimmed primary. Empty states keep a
dashed ruled outline instead of vanishing. Destructive actions live in
`.danger-zone`, never as a bare red link.

## Accessibility

- Touch targets are 44px under `@media (pointer: coarse)`; 36px compact sizes
  apply only to fine pointers.
- No horizontal page scroll at 360px on any surface (verified: `scrollWidth`
  equals the viewport). Wide tables and the tab bar scroll inside themselves.
- The gate verdict reads by word and size, not by colour.

## Known, accepted

- **The design detector flags Montserrat as an overused face.** Overridden: it
  is an inherited brand commitment, not a default reached for. Recorded rather
  than silently ignored.
- **The buyer listing has no price column.** The direction wants money on that
  axis; `GET /v1/events` returns no price, so it currently shows the door time.
  Completing it means adding a `from_price_minor` field to `EventSummaryOut`
  (`services/api/app/schemas/events.py`) — a small read-only addition that was
  deliberately out of scope for a frontend-only pass.
- Dark scheme reuses the night palette and is implemented, but was verified by
  render rather than by a full audit pass.

## Provenance

- `src/brand.tsx`, `public/mark.svg` — authored vector, redrawn from
  `apps/customer/assets/logo1.jpeg`.
- `public/fonts/montserrat-latin-var.woff2` — Montserrat variable, latin
  subset, from Google Fonts (SIL Open Font License).
- No raster assets ship with the app.
