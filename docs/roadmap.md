# Roadmap

**Scope decision of 2026-11-08:** build the full original concept — all five
listing categories plus the social layer — in **Trinidad & Tobago only**. The
2027 Carnival pilot is dropped; launch target is the 2028 season. This reverses
the narrowing in `docs/market-and-economics.md`; see `PRODUCT.md` for what that
changed and what it did not.

Nothing is live until the full concept ships, so there is no production data to
protect during the build. That lets phases be sequenced by engineering sense
rather than by migration cost.

## Open decisions (client)

- [x] Scope: the full five-category concept, not the Carnival-only wedge
- [x] Market: Trinidad & Tobago only at launch
- [x] Launch target: 2028 season (2027 pilot dropped)
- [ ] **Fee model.** The concept's 2% + US$0.50 per ticket contradicts the
      implemented 4.5% + TT$3 buyer / 3% promoter, and looks loss-making against
      WiPay's 3.5% + US$0.25 unless processing is passed to the buyer separately.
      The implemented rates are seeded in `countries`; which was meant?
- [ ] Whether to offer early payouts, and the credit risk that carries
- [ ] WiPay business account, online Linx support, payout timing
- [ ] Supply for the four new categories: who signs accommodation hosts, tour
      operators, vendors and store owners
- [ ] Legal position on FaceCard biometrics under the Data Protection Act
- [ ] Legal opinion on the Central Bank's E-Money Issuer Order (gates the wallet)
- [ ] Tagline: "FIND IT. VIBE IT. LIVE IT." was retired for being written for
      the five-category marketplace. That reasoning is gone — reinstate it?
- [ ] Bundle ID, icon, and owner of the Apple and Google developer accounts
- [ ] Paid map tile and geocoding provider (now required, not optional)

## Phase 0: foundation (this repo)

- [x] Monorepo, CI, Docker Compose
- [x] Customer app cleaned; build, permission and splash fixes
- [x] API scaffold: auth, events, tiers, fee quotes, schema and first migration
- [x] Promoter portal starter

## Phase 1: ticketing (done, and still the wedge)

- [x] Promoter endpoints: organisations, members, events, tiers, sellers
- [x] Orders with inventory holds; guest checkout; test payment provider
- [x] Ticket issue and QR; ticket link by email (SMTP) and WhatsApp share
- [x] Cash sales by sellers and box office; seller sales report
- [x] Online gate check-in (web scanner, duplicate-safe)
- [x] Web app: event pages, checkout, promoter portal, payout figures
- [x] Production deploy: Docker Compose + Caddy on a VPS
- [ ] WiPay checkout and callbacks (`PaymentProvider` is ready for it)
- [ ] Member invites for people without an account
- [ ] Ticket transfer by phone number
- [ ] Offline check-in sync

## Phase A: listings foundation — **done 2026-11-08**

- [x] `countries`: currency, timezone, fee rates, per-category availability and
      the delivery gate, per market. T&T seeded and live; migration 0005
- [x] Fee rates resolve per country (`app/services/countries.py`); a fee quote
      carries its currency
- [x] `events` becomes `listings` (typed base: organisation, type, title, slug,
      status, country, city, venue, location, cover, dates, tags) plus
      `event_details`; joined-table inheritance; migration 0006
- [x] `ticket_tiers`, `sellers` and `orders` repointed at `event_details`
- [x] Slugs unique across every category; one URL space
- [x] Verified: 61 tests, lint, `alembic check` clean, data migration and
      downgrade round-trip checked on Postgres, live stack re-deployed

Deferred out of Phase A on purpose: the `Offer`/booking generalisation (A3).
`orders.py`'s inventory engine gets generalised when accommodation lands and
there is a second real shape to generalise against — not speculatively. At that
point `orders.event_id` becomes `listing_id` and `Ticket` becomes one fulfilment
type beside `Booking`.

## Phase B: discovery and the social layer

Everything here is shared machinery all five categories need, so it comes before
any new category.

- [x] **Real filters on listings** (2026-11-08): category, country, city, free
      text, tags, date window, price window, free-only, map viewport or radius,
      four sort orders, paging with a total. `GET /v1/listings`
- [x] **The central calendar** (2026-11-08): counts per day, grouped in the
      market's local timezone. `GET /v1/listings/calendar`
- [x] **Price rollup** on listings (migration 0007) so price filtering works
      across categories; tags moved to their own indexable table
- [ ] Rating filter — needs the review rollups, so it lands with reviews below
- [ ] Full-text search; the current filter is `LIKE` over title, description
      and venue
- [ ] True distance ordering (needs PostGIS, which Supabase would bring); the
      radius filter is a bounding-box approximation today
- [x] **Filter profiles per country or city, and the "For You" feed**
      (2026-11-08): create, edit, switch, delete; category interests, keyword
      interests, price band (any/free/paid/custom) and date preference
      (upcoming/this weekend/this month/custom), resolved against the market's
      local clock on every read. Migration 0008
- [ ] Followings (organisations) and saved favourites (listings)
- [ ] Collaborators: organisations attached to a listing, with the Owned vs
      Collabs split on the organisation page
- [ ] Reviews with section ratings and a **verified-attendee badge**, provable
      from `Ticket.status == checked_in` and later from completed bookings
- [ ] Agenda and push reminders (FCM)
- [ ] Offline: cached tickets and agenda. Not offline check-in sync, which is
      a separate and harder job

## Phase C: the four new categories, in cost order

- [ ] **Services** — directory plus inquiry-and-quote, no inventory engine.
      Cheapest, and its buyers are promoters who already use the product
- [ ] **Accommodation** — rooms and date-range availability. Hardest inventory
      model; this is what triggers the A3 generalisation
- [ ] **Vacation** — tours and departure slots with capacity. Reuses much of
      the ticket-tier shape
- [ ] **Stores** — catalogue, variants, stock, cart. Country-gated
- [ ] **Food delivery** — last, and blocked on courier operations

## Phase D: media feed / reels

- [ ] Upload, transcode, CDN, likes, comments, saves, shares, view tracking
- [ ] Reporting and moderation. Carries a real recurring cost and a
      moderation obligation

## Phase E: the Flutter customer app on real data

- [ ] A **narrow** `RealApiService`, written group by group, swapping the one
      line in `service_locator.dart`. Do not implement `api_service.dart` as
      written: it composes 17 interfaces and ~200 methods including chat
      streams, teams, invitations, user banning, Stripe and PayPal — prototype
      surface area nobody asked for. Trim the interface to a real contract
- [ ] Map the Flutter enum to the schema: its `hotel` is `accommodation`, its
      `place` is `vacation`
- [ ] Token auth into secure storage
- [ ] Delete the card, bank and wallet forms (audit item #3 is a live PCI
      violation)

## Launch checklist

- [ ] Real bundle ID and release keystore (not the debug key)
- [ ] Paid map tiles and geocoding (public OSM/Nominatim forbid app traffic at
      scale, and map discovery is now central — audit item #12)
- [ ] Privacy policy and terms linked in sign-up
- [ ] Security review: auth, payment callback verification (rate limits on
      login, sign-up and checkout are in)
- [ ] Error monitoring and uptime alerts (watch `/api/health`)
- [ ] Refund policy, and a refund flow before cancelling events with paid orders
- [ ] Switch `PAYMENT_PROVIDER` from `test` to `wipay`
- [ ] `is_test` propagated to bookings and store orders, refused at every point
      of fulfilment
- [ ] Store listings, screenshots, review notes
