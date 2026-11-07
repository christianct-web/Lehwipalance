---
version: 1
slug: "apps-promoter-portal-src"
primary_target: "apps/promoter-portal/src"
related_targets: []
---

Scope: the whole promoter-portal web app — buyer surfaces (season home, event
page, checkout, order/tickets), promoter desk (sign-in, orgs, org, event admin,
sell panel, reports) and the gate scanner. Visitor mode: Persuade on the buyer
surfaces, Operate on the desk and the gate.

Audience and job: fete-goers and their crews choosing a fete on a phone, often
in sunlight on patchy data, sharing by WhatsApp; promoters and committees
setting up a fete, selling for cash and watching money; gate staff admitting
people at night outdoors. Constraint: cash and box-office sales are
first-class, online card payment is currently off, and a simulated ticket must
never read as real.

## Direction contract

THESIS: the season is a dated public record you read down, not a feed you
scroll. This refuses the category default — a dark flyer-hero carousel over a
card grid of event tiles — and refuses its opposite, the austere white fintech
table. The fete listing itself is the hero.

OWN-WORLD: cool off-white ground (never cream), ink a purple-tinted near-black.
The inherited spectrum carries three fixed roles and never floats free:
turquoise #10E8E8 is structure and wayfinding, magenta #F010B0 is liveness and
the primary action and nothing else, purple #B030F0 is depth and the night
ground. Montserrat 700/900 for display and figures only; system sans for UI
body; system mono with tabular figures for money, codes and serials. Ruled
rows, right-aligned money columns, hairline column rules, dense agate-scale
secondary type. Recognisable with all content removed by: the dated column
strip, the money column, and one magenta mark per view.

STORY: a fete-goer understands what is on and what it costs before scrolling,
believes the price shown is the price paid, and buys or saves it. A promoter
understands what sold, in cash and online, and what they are owed.

FIRST VIEWPORT: on the buyer home, wordmark and dateline at the top-left on the
off-white ground, no hero image. Immediately below, the season as dated column
strips — FRI 6 FEB, SAT 7 FEB — each fete a ruled row: name in Montserrat 700,
venue and time in agate beneath, price right-aligned in a tabular money column.
The primary action is a single magenta control per row, right-aligned on the
money column's axis. Three days visible above the fold on a 360px phone.

FORM: candidate 5 of seven, the newspaper Carnival fete guide; seed key
e135aa41, direction scope, persuade mode. The user pinned the Flutter brand
after the roll, which binds materials only, so the assignment is kept through
topology, controls, state vocabulary and ritual and its materials are
translated: newsprint grey-tan becomes cool off-white, and the crude spot-colour
overprint becomes the single scarce magenta mark.
TRANSLATION (named): material expression moves from newsprint to the Lehwi
spectrum; topology, the ruled dated listing, is unchanged.
RAISE (from the glyph-grid challenger): one column measure governs every
surface — desk tables, checkout, scanner — nothing floats off it.
RAISE (from the chrome-console challenger): every control reads its state
physically before its label is read; sold-out flattens, it does not vanish.
RAISE (from the mezzotint challenger): the gate commits to a full saturated ink
ground, never a light page wearing a dark panel.
RAISE (from the akari challenger): exactly one colour carries liveness across
the system, kept scarce; empty states keep their ruled outline.
SIGNATURE INTERACTION: the stamp. Committing lands a decisive, slightly
off-axis stamped mark — publish, paid, and at the gate an ADMIT that fills the
screen and is legible at arm's length by shape and word, not colour alone.
MOTION GRAMMAR: things register into place like a press impression — a short
settle, no slide-and-fade; reduced-motion removes the settle, never the state.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.

Unresolved: the redrawn mark ships as SVG from this build and still wants the
client's sign-off; WiPay is not connected so paid online checkout is simulated.

## Amendment, 2026-11-07 (after a client reference mockup)

The user supplied a reference for the buyer surfaces and chose a hybrid. The
buyer register moves from a ruled text listing to **flyer-forward**: the fete's
own artwork leads, in the Trini voice ("Yuh next lime starts here", "Plenty
vibes", "Good vibes. Real tickets."). What is unchanged: the **date spine**
(day headings still run the season), the **money axis and sober register on the
promoter desk and the gate**, and **magenta reserved for the action**.

Added: search, category and saved filters; save-to-plan; a My tickets page; and
a **Feed view** — one fete per screen, flyer full-bleed, CSS vertical scroll
snap, toggled from the finder bar and remembered per browser.

The flyer is a slot, not art direction we own: promoters upload it, so every
card renders into a fixed aspect box with a deterministic brand-gradient
fallback and the title always as real text over the art, never baked in.
No stock or generated photography ships.

FIRST VIEWPORT (amended): wordmark, the headline, a dateline rule, then the
finder bar (search · category chips · Grid/Feed). Below it the season by day:
a ruled day heading, then flyer cards two-up on a phone and four-up on desktop,
each with its door time, a save ribbon, and its title and venue as text.
