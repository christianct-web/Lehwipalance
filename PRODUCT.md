# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

- **Fete-goers and their crews** in Trinidad & Tobago. Mobile, often on patchy
  data, deciding socially: a crew agrees on a fete and someone buys. They share
  by WhatsApp, not email.
- **Promoters and their committees.** Create a fete, set tiers, run committee
  and box-office cash sales, watch sales live, get paid.
- **Committee sellers** — members selling for cash against a personal link.
- **Gate staff** — scanning at entry, outdoors, at night, on a phone, with a
  queue in front of them.

## Product Purpose

The Carnival season planner for you and your crew, and the ticketing desk that
pays promoters before the fete. Success is winning Trinidad Carnival fete
ticketing by being cheaper and faster for promoters than Island eTickets.

## Positioning

Promoter-first economics the incumbent cannot match without cutting its own
take: buyer pays 4.5% + TT$3 per ticket, promoter pays 3%. Island eTickets
charges promoters 8% plus buyer processing fees, pays out 5 business days after
the event, and holds discretionary reserves. Early payout — money before the
fete, not after — is the wedge. Fee model is implemented, not aspirational
(`services/api/app/services/fees.py`).

## Operating Context

- ~300 fetes per Carnival season. 2026 prices: TT$250–600 cooler fetes,
  TT$950–2,200 all-inclusive.
- Carnival 2027 is **8–9 Feb 2027**; 2027 fete sales are already open. Launch
  target is a 2027 pilot (late-season and post-Carnival events) then the full
  2028 season.
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

**Deferred by product decision:** accommodation, vacation, services, stores and
the reels/media feed from the original concept. The stored-value wallet is cut.

**Hard constraints:**
- No card data in our systems; cards are entered only on WiPay's hosted page.
- No stored-value wallet until there is a legal opinion on the Central Bank's
  E-Money Issuer Order.
- Money is integer minor units with an explicit currency. Currency is TTD.
- Simulated orders are flagged, refused at the gate, and excluded from both
  inventory and sales figures. A simulated ticket must never read as a real one.

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
- **Retired:** the tagline "FIND IT. VIBE IT. LIVE IT." (written for the old
  five-category marketplace, not the Carnival ticketing wedge) and
  `assets/cover_image1.jpg` (a stock beach-party scene; Carnival fetes are not
  beach limes, and it reads as Caribbean-from-outside).
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
  document with sources is held by Mana Labs 8 and takes precedence).
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
   real money routes. Weighted to promoters for the 2027 pilot push.
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
