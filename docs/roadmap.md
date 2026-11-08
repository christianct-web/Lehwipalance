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

The `Offer`/booking generalisation (A3) was deferred out of Phase A on purpose
and **landed with accommodation on 2026-11-08** (migration 0013), once there was
a second real shape to generalise against. `orders.event_id` became
`listing_id`, and `Booking` now sits beside `Ticket`.

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
- [x] **Rating filter** (2026-11-08): `min_rating`, over the review rollup
- [ ] Full-text search; the current filter is `LIKE` over title, description
      and venue
- [ ] True distance ordering (needs PostGIS, which Supabase would bring); the
      radius filter is a bounding-box approximation today
- [x] **Filter profiles per country or city, and the "For You" feed**
      (2026-11-08): create, edit, switch, delete; category interests, keyword
      interests, price band (any/free/paid/custom) and date preference
      (upcoming/this weekend/this month/custom), resolved against the market's
      local clock on every read. Migration 0008
- [x] **Followings and favourites** (2026-11-08): follow an organisation,
      save a listing, and a feed of what followed organisations have on.
      Migration 0009
- [x] **Collaborators and public organisation profiles** (2026-11-08):
      credits on a listing, the Owned vs Collabs split, and organisation search
      that includes organisations discoverable only by being credited.
      Migration 0011
- [ ] Collaborator **consent**: crediting currently needs no agreement from the
      organisation being credited, though it shows on their public profile
- [ ] Whether an organisation profile publishes contact details, which the
      vendor directory's booking flow will need decided
- [x] **Reviews with section ratings and the verified-attendee badge**
      (2026-11-08): proved from a real, checked-in, non-simulated ticket and
      settled once at write time. Rating rollup on listings. Migration 0010
- [ ] **Review moderation** — no way to hide or report a review, and no admin
      tooling. A launch blocker for a public review system, not an extra
- [ ] Agenda and push reminders (FCM)
- [ ] Offline: cached tickets and agenda. Not offline check-in sync, which is
      a separate and harder job

## Phase C: the four new categories, in cost order

- [x] **Services** (2026-11-08) — the vendor directory plus the inquiry flow
      that books it, with its own management endpoints, price models including
      quote-only, and a generic `GET /v1/listings/{slug}` carrying each
      category's own fields. Migration 0012
- [ ] A full inquiry thread, if one reply each way turns out not to be enough
- [x] **Accommodation** (2026-11-08) — properties, room types, per-night
      availability, and stays with guest checkout, holds and settlement.
      Migrations 0013 (the `Offer` base) and 0014
- [ ] **Confirm the booking fee**: the fixed part of the buyer fee is charged
      once per booking, not per night. The fee model was written per ticket, so
      this is a commercial decision, not an implementation detail
- [ ] **One payment callback that dispatches on listing type.** Stays currently
      settle through their own endpoint so the revenue-critical ticket path was
      not disturbed; the real WiPay callback is a single URL and must dispatch
- [ ] Gate-equivalent for stays: check-in and check-out on arrival, and a
      no-show policy
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
- [ ] Review moderation: reporting, hiding, and the admin tooling behind it
- [x] **A committed demo seed script** (2026-11-08):
      `app/scripts/seed_demo.py`, idempotent, with `--reset` that removes only
      what it owns. Run it after the Supabase cutover, which does not copy rows
- [ ] Store listings, screenshots, review notes
