# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

- **Fete-goers and their crews** in Trinidad & Tobago. Mobile, often on patchy
  data, deciding socially: a crew agrees on a fete and someone buys. They share
  by WhatsApp, not email.
- **Everyone discovering anything else on the island** — somewhere to stay, a
  tour, a caterer, a store. Same person, different errand.
- **Accommodation hosts, tour operators, vendors and store owners.** Supply for
  the four non-event categories. None is signed yet.
- **Promoters and their committees.** Create a fete, set tiers, run committee
  and box-office cash sales, watch sales live, get paid.
- **Committee sellers** — members selling for cash against a personal link.
- **Gate staff** — scanning at entry, outdoors, at night, on a phone, with a
  queue in front of them.

## Product Purpose

**Scope decision of 2026-11-08: build the full original concept.** All five
listing categories — events, accommodation, vacation, services and stores —
plus the social layer around them: filter profiles, followings, reviews,
collaborators, the media feed and the agenda. This reverses the narrowing
recommended in `docs/market-and-economics.md` and previously recorded here.
The client's own vision in `docs/original-concept.md` is the governing scope.

**Market: Trinidad & Tobago only at launch** (2026-11-08). The schema is
per-country from the start — fee rates, currency and category availability all
live on the `countries` row — but T&T is the only market seeded or live. Another
market needs a payment rail that works there plus its own consumer-protection,
refund and tax position, so none is enabled by default.

Lehwi Palance is where Trinidad & Tobago finds what's happening and what it
needs — and the ticketing desk that pays promoters before the fete. Events and
Carnival fete ticketing remain the wedge that earns the audience; they are no
longer the whole product.

## Positioning

Against Trinbago Events, which already combines discovery, calendar, map and
ticketing, the answer is the social discovery layer plus categories it does not
carry. Against Island eTickets, the answer is promoter economics it cannot
match without cutting its own take: buyer pays 4.5% + TT$3 per ticket, promoter
pays 3%. Island eTickets charges promoters 8% plus buyer processing fees, pays
out 5 business days after the event, and holds discretionary reserves. Early
payout — money before the fete, not after — is the wedge. The fee model is
implemented, not aspirational (`services/api/app/services/fees.py`), and is now
per market (`app/services/countries.py`).

## Operating Context

- ~300 fetes per Carnival season. 2026 prices: TT$250–600 cooler fetes,
  TT$950–2,200 all-inclusive.
- Carnival 2027 is **8–9 Feb 2027**. **The 2027 pilot is dropped** (decision of
  2026-11-08): the full concept comes first, so the launch target is the 2028
  season. Nothing goes live until then, so there is no production data to
  protect during the build.
- **Cash is a primary channel, not an edge case.** Committee sellers and the box
  office issue real tickets; a pilot can run entirely on cash sales with online
  card payment switched off.
- Gate: QR scan on a phone camera, duplicate-safe, outdoors at night. Offline
  check-in sync is not built yet, so the gate currently assumes a connection.
- WhatsApp is the sharing channel. Low-bandwidth realities are a design input.
- Competitor Trinbago Events already combines discovery, calendar, map and
  ticketing.

## Capabilities and Constraints

**Built and working:** email/password auth; organisations with roles; events and
tiers; fee quotes; orders with inventory holds; guest checkout; ticket issue
with QR; ticket link by email (SMTP) and WhatsApp share; cash sales by sellers
and box office; online gate check-in; sales reports and payout figures; flyer
upload.

**Not built:** WiPay card checkout and callbacks (`PAYMENT_PROVIDER=test`
today), ticket transfer by phone number, offline check-in sync, member invites
for people without an account, `RealApiService` in the Flutter customer app.

**Foundation built (Phase A, 2026-11-08):** `countries` holds currency, fee
rates and per-category availability per market, with T&T seeded and live.
`events` is now `listings` (a typed base carrying everything discovery touches)
plus `event_details`, so all five categories and the whole social layer attach
to one indexed table. Migrations 0005 and 0006; fee rates resolve per country
through `app/services/countries.py`.

**Now in scope, not yet built:** the discovery and social layer (calendar, map,
filter profiles, followings, reviews, collaborators, agenda, reminders, the
media feed) and the four non-event categories, in cost order — services,
accommodation, vacation, stores.

**Blocked, and not by scope:**
- **The stored-value wallet stays cut** pending a legal opinion on the Central
  Bank's E-Money Issuer Order. Store and delivery carts pay per transaction.
- **FaceCard** needs a Data Protection Act position and a consent flow before it
  is a build task. QR ships; NFC stays read-only (iOS will not emulate a card).
- **Food delivery** needs couriers on the ground, not a flag. `countries`
  gates it and it is off.
- **The concept's 2% + US$0.50 ticket fee contradicts the implemented rates**
  (4.5% + TT$3 buyer, 3% promoter). At ~TT$6.80/US$ on a TT$300 ticket the
  concept's rate yields ~TT$9.40 against WiPay's ~TT$12.20 cost — loss-making
  per card sale unless processing is passed to the buyer separately. The
  implemented rates are seeded; the client must confirm which was meant.

**Hard constraints:**
- No card data in our systems; cards are entered only on WiPay's hosted page.
- No stored-value wallet until there is a legal opinion on the Central Bank's
  E-Money Issuer Order.
- Money is integer minor units with an explicit currency, taken from the
  listing's market. One order is one market and one currency; no cross-border
  baskets, so no FX in the ledger.
- Simulated orders are flagged, refused at the gate, and excluded from both
  inventory and sales figures. A simulated ticket must never read as a real one.
  As categories arrive, `is_test` must propagate to bookings and store orders
  and be refused at every point of fulfilment, not only at the gate.

**Terminology:** fete, promoter, committee, seller, cooler fete, all-inclusive,
palance, lime.

## Brand Commitments

- **Name: Lehwi Palance** (confirmed 2026-11-07). Supersedes the "Lewi Palance"
  spelling in `docs/original-concept.md`. It is Trini Creole — "leh we palance",
  let's palance — so the name states what the product is for.
- **Does not use the Mana Labs 8 house design system** (confirmed 2026-11-07).
  Mana Labs 8 is the builder, not the brand; Lehwi Palance carries its own
  identity.
- Trinidad & Tobago and Carnival are the cultural frame, not decoration.
- **Inherited from the Flutter customer app and binding** (confirmed
  2026-11-07): the brand spectrum **turquoise `#10E8E8` -> magenta `#F010B0`
  -> purple `#B030F0`**, the **map-pin + P monogram**, and **Montserrat** as
  the display face.
- **The mark is being redrawn** (approved 2026-11-07): pin and P kept, the palm
  tree, sunset and road dropped, delivered as transparent SVG with a flat
  single-colour variant for small sizes and dark surfaces. The original
  `apps/customer/assets/logo1.jpeg` is an opaque JPEG on a white box with no
  vector and cannot sit on a non-white surface.
- **Un-retired for reconsideration:** the tagline "FIND IT. VIBE IT. LIVE IT."
  was retired *because* it was written for the five-category marketplace rather
  than the ticketing wedge. That reasoning no longer holds now the five
  categories are back; the tagline is an open question again, not a decision.
- **Retired:** `assets/cover_image1.jpg` (a stock beach-party scene; Carnival
  fetes are not beach limes, and it reads as Caribbean-from-outside).
- The promoter-portal code's `#e8432e` on cream `#fbf8f4` is scaffold, not
  brand, and is replaced by the spectrum above.
- The Flutter app's `app_colors.dart` is four untouched Material 3 palettes and
  its type scale is Material's default. That is scaffold too, not identity: the
  brand lived only in the raster assets. The app has never shipped (mock data,
  no `RealApiService`, debug keystore, no store listing), so nothing public
  depends on it.

## Evidence on Hand

- Implemented fee model with a worked comparison table
  (`docs/market-and-economics.md`, `services/api/app/services/fees.py`).
- Market and economics analysis of 18 Oct 2026 (summary in repo; the full
  document with sources is held by Mana Labs 8 and takes precedence). **Its
  central recommendation to narrow the product is superseded**; its figures,
  costs and risks still stand, but the break-even calculation assumed the
  narrow build and the implemented fee rates.
- The client's own product vision (`docs/original-concept.md`).
- Live deployment at https://lehwi.187-77-18-154.sslip.io
- **Absences that must not be fabricated:** no pilot promoters signed yet (3–5
  still to be interviewed); no testimonials, case studies, client logos, press
  or download counts; no event photography, flyers or promoter artwork on hand;
  no real event data at all — the database is empty. Any fete name, lineup,
  venue, price or sales figure shown in the UI is placeholder and must read as
  such to anyone on the team.

## Product Principles

1. **Promoter trust outranks consumer polish.** This must look like somewhere
   real money routes. That now has to hold while accommodation and vacation
   listings pull hard toward the tourist-brochure register the brand rules out.
2. **Cash and committee sales are first-class.** A fete can run with online card
   payment switched off entirely; the design must not treat that as degraded.
3. **Mobile and low-bandwidth first.** WhatsApp is the share channel.
4. **Money is always legible.** Face value, fees and payout stated plainly, never
   buried or rounded away.
5. **A simulated ticket must never pass for a real one** — on screen or at the gate.

## Accessibility & Inclusion

- The gate scanner must stay readable at arm's length, outdoors, at night:
  high contrast and large type, with the admit/refuse verdict unmistakable
  without reading words.
- Manual code entry must always work; the camera needs HTTPS and permission and
  will sometimes fail.
- Touch targets stay at 44px or larger (already the floor in the incumbent CSS).
- Colour alone never carries the admit/refuse or test/real distinction.
