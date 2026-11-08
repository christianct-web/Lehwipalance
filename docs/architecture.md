# Architecture

```
 Fete-goer (web app, later Flutter) ──┐            Caddy (HTTPS)
 Promoter, sellers (web portal) ──────┼──► /api ──► services/api (FastAPI) ──► Postgres (Supabase)
 Gate staff (web scanner) ────────────┘                  │                └──► Supabase Storage (flyers)
                                                         ├──► Payment provider: test now, WiPay next
                                                         └──► SMTP ticket emails (optional)
```

## Services

- **API** (`services/api`): the single source of truth. JWT bearer auth,
  argon2 password hashes, role-based access per organisation
  (`owner`, `manager`, `seller`, `scanner`). Alembic migrations run on start.
- **Web app** (`apps/promoter-portal`): static SPA served by Caddy on the same
  domain as the API (`/api` is proxied), so no CORS in production. Public pages
  (`/`, `/e/{slug}`, `/orders/{id}`), the promoter portal (`/promoter`) and the gate
  scanner (`/promoter/orgs/{org}/events/{event}/scan`, camera QR via jsQR).
- **Customer app** (`apps/customer`): Flutter; talks to the API through the
  `ApiService` interface. Still on mock data; the web app is the launch channel.
- **Gate scanner**: the web scanner checks tickets online. An offline mode with a
  pre-downloaded ticket list is still planned.
- **Supabase**: managed Postgres and, optionally, Storage for flyers. Only the API
  talks to it; the apps never hold Supabase keys. See docs/deploy-vps.md.

## Domain model

| Table | Purpose |
| --- | --- |
| `countries` | A market: currency, timezone, fee rates, which categories it shows, the delivery gate. T&T only |
| `users` | Everyone: fete-goers, promoter staff, sellers, scanners |
| `organisations`, `org_members` | Promoters and who can act for them |
| `listings` | Anything published, of any category; `draft` → `published` → (`cancelled`) |
| `listing_tags` | Keywords on a listing; what a filter profile's interests match |
| `filter_profiles` | A customer's saved discovery preferences, one per country or city |
| `follows`, `favourites` | Organisations someone follows; listings they saved |
| `reviews`, `review_section_ratings` | A verdict on a listing, overall and per section |
| `listing_collaborators` | Organisations credited on a listing they do not own |
| `event_details` | The event category of a listing whose `type` is `event` |
| `ticket_tiers` | Early bird, Tier 1, VIP; price in minor units, inventory, sales window |
| `sellers` | Committee members with a personal code for attributed sales |
| `orders`, `order_items` | A purchase; channel `online`, `seller_cash` or `box_office` |
| `tickets` | One admission; random `code` encoded in the QR; check-in state |

### Listings (joined-table inheritance)

Discovery, the map, search, filter profiles, follows, favourites, reviews, the
media feed and collaborators all have to work across the five categories in
`docs/original-concept.md`. Rather than a union over five sibling tables,
everything discovery touches lives on one indexed `listings` base — organisation,
`type`, title, globally unique slug, status, country, city, venue, location,
cover, `starts_at`/`ends_at`, tags — with a detail table per category keyed by
the same id. `event_details` is the first; adding a category means adding a
subclass and its detail table, not touching the base.

- `starts_at` is nullable on the base, because accommodation has no single start
  (availability will live in its rate plans). The invariant events need is kept
  by a check constraint: `type <> 'event' OR starts_at IS NOT NULL`.
- `ticket_tiers`, `sellers` and `orders` point at `event_details`, not
  `listings` — a tighter constraint, since all three can only belong to an event.
- The event row lock is taken on the `listings` row, the one every category
  shares. See `lock_event` in `app/services/orders.py`.
- `price_min_minor`/`price_max_minor` are a rollup of the listing's own
  sellable inventory, so discovery can filter and sort on price without knowing
  how each category stores it. For an event it is the span of its tiers — all of
  them, not just the ones on sale, so a sales window opening or closing never
  needs a background job to keep discovery honest. Maintained by
  `app/services/listings.py:refresh_price_range`, called from all three tier
  mutations.
- Tags are a table, not a JSON column: they are a first-class filter, and this
  shape is indexable and identical on Postgres and on the SQLite test database,
  where JSON containment would need `JSONB`. Stored already normalised —
  lowercased, whitespace-collapsed — so matching is plain equality.
- Still to come (Phase C, when accommodation lands): an `Offer` base over ticket
  tiers, rate plans and tour departures, at which point `orders.event_id`
  becomes `listing_id` and `Ticket` becomes one fulfilment type beside `Booking`.

### Discovery

`app/services/listings.py` holds one query builder for the whole filter set in
`docs/original-concept.md`, so search, the map, the central calendar and a
filter profile's "For You" feed are the same question with different arguments
rather than four code paths. Only published listings in a live market are ever
returned, and categories a market has switched off are filtered out rather than
erroring.

- Dates are grouped in the market's own timezone. "What's on Saturday" is a
  local question: a fete starting at 00:30 UTC on Sunday is Saturday night in
  Trinidad, and the calendar has to agree with the person holding the ticket.
- Location filtering is a bounding box — a map viewport (`bbox`) directly, or a
  square around a point (`near` + `radius_km`). It over-selects at the corners
  on purpose: it is what a plain B-tree index can answer on both backends. True
  distance ordering wants PostGIS, which the Supabase cutover would bring.
- `min_rating` filters on the review rollup; see **Reviews** below.
- Free text search is `LIKE` over title, description and venue. Honest for one
  island's catalogue, and it cannot use an index — full-text search is a real
  later problem, not a forgotten one.

### Filter profiles

A saved set of preferences, scoped to a market and optionally one city. Its
columns mirror `listings.Filters`, so the "For You" feed is the ordinary
discovery query with the profile's arguments rather than a second
implementation that could drift from search.

- `listing_types` and `tags` are JSON on a profile, unlike `listing_tags` on a
  listing: they are read back whole to build a query, never themselves queried,
  so there is nothing for an index to do. Profile tags are normalised the same
  way listing tags are, or the two would never match.
- The relative date preferences — upcoming, this weekend, this month — resolve
  against the market's local clock on every read, so a profile saved in January
  still means "this weekend" in March. The feed returns the window it resolved
  to, so a client can label the results honestly. A fete weekend starts Friday
  00:00 local: Friday night is the season's busiest slot, so a weekend that
  excluded it would be right for a calendar and wrong for this product.
- Exactly one profile per user is active. That is enforced in the service when
  activating, not by a partial unique index, which would have to be spelled
  differently for each backend. Deleting the active profile promotes another, so
  a customer with profiles always has a feed.
- Browsing without an account stays open (`/v1/listings`); the profile layer
  needs a token, which is the concept's rule that Profile requires login.

### Follows and favourites

People follow organisations, not listings: a listing is an event that ends, an
organisation is the promoter you keep up with. Both tables use a composite
primary key, so following or saving twice is the same as once. Following and
saving are idempotent in both directions, because a double tap on a phone
should not be an error.

One deliberate asymmetry: discovery hides anything not published, but
favourites do not. A listing you saved getting cancelled is exactly what you
want to be told about.

### Reviews and the verified-attendee badge

The badge is the point of this feature. Anyone can run a directory and collect
opinions; this platform sold the ticket and scanned it at the gate, so it can
say which reviewers actually turned up — proof a competitor cannot fabricate.

- It is settled when the review is written and then left alone. It records that
  the person was scanned in, so a ticket later being voided does not retract it,
  and editing the words does not re-evaluate it.
- A simulated (`is_test`) order never earns it. A demo ticket buys neither entry
  nor credibility, which is the same rule the gate applies.
- Guest checkout means a ticket may have no holder, so the buyer on the order
  counts as well as the ticket holder.
- Only events can be attended today; a completed booking becomes the second way
  to earn it when accommodation and tours land.
- A review is refused before the listing has happened: a verdict on a fete that
  has not started is not a review of anything. One review per person per
  listing, edited rather than duplicated.
- Section scores are a fixed enum (venue, organisation, value, food, music) so
  per-section averages are comparable. They suit an event; accommodation and
  tours will want their own, so the set grows per category rather than being
  guessed at now.
- The rollup on `listings` is a count and a sum, not an average, so the figures
  stay exact integers. `min_rating` compares `rating_sum >= min * rating_count`,
  which keeps the division out of SQL. An unreviewed listing matches no rating
  filter: no rating is not a low rating, but it is not a high one either.
- **Not built: moderation.** There is no way to hide or report a review, and no
  admin tooling behind it. That is a launch blocker for a public review system,
  not an optional extra.

### Collaborators and organisation profiles

The concept makes a collaborator an organisation, not an individual vendor, so
this reuses `organisations` rather than inventing a parallel kind of party. A
listing has one owner — the organisation that created it and gets paid — and any
number of credited collaborators, which gives an organisation page the concept's
two groups: owned listings, and shared listings or collabs.

- `credit` is how the collaboration reads on the listing ("co-promoter", "sound
  by", "hosted by"), because "collaborator" alone says nothing about what
  someone did.
- Only the owning organisation's admins can credit or remove collaborators, and
  a listing's owner cannot be one of its own collaborators.
- Organisation search lists only organisations with something published, **or
  credited on something published**. That is what makes a sound crew with no
  listings of its own discoverable, which is the concept's requirement that
  collaborators are searchable alongside other organisations.
- A profile deliberately omits `contact_email`, `contact_phone` and
  `payout_reference`. Those are the promoter's own, collected for payouts and
  ticket admin; publishing them is a decision nobody has made. The vendor
  directory's "contact and booking flow" will need that decision taken.
- **Open question: consent.** Crediting takes effect without the other
  organisation agreeing, which is how the concept describes it — but a
  collaboration appears on their public profile, so an invite-and-accept step
  is worth deciding before launch.

### Markets

A listing names a country, and that row — not a constant — decides the currency
a sale is priced in, the fee rates charged on it, and whether the category is on
offer there. Resolved by `app/services/countries.py`; the Trinidad & Tobago
values in `app/services/fees.py` are the seeded defaults and the fallback where
no row is in reach. One order is one market and one currency, so there is no FX
in the ledger.

## Orders and payments

Logic lives in `app/services/orders.py`; the payment boundary is
`app/services/payments.py` (`PaymentProvider`).

- **Online**: guest checkout (name, email, optional phone and seller code) creates a
  `pending` order holding its tickets for `ORDER_HOLD_MINUTES` (15). The buyer is sent
  to the provider's hosted checkout; a verified result calls `mark_paid` (tickets issued,
  `quantity_sold` committed) or `mark_failed`. Both are idempotent.
- **Availability** = quantity − sold − tickets in unexpired pending orders. Every
  write locks the tier rows first, so a tier drop can't oversell.
- **Locking**: checkout, staff sales, settlement, tier edits and cancellation all take
  the event row lock first (then order, then tiers), so per event they run one at a
  time in a fixed order. Verified with concurrent threads on Postgres 16.
- **Capacity**: a tier's quantity can't go below sold + held, and settlement re-checks
  capacity excluding the order's own hold.
- **Late payment**: if the tickets are gone (hold expired and sold out) the order is
  marked `failed`; if the event was cancelled it stays `cancelled`. Either way the
  payment reference is kept for a refund.
- **Cancellation** closes every pending checkout (`cancelled`) under the event lock,
  and is refused while real paid orders exist (refund flow not built yet).
- **Free tiers** and **staff sales** (`seller_cash`, `box_office`) are paid at once.
  Cash buyers pay face value (no booking fee); the promoter fee applies to all sales.
- **Test provider** (`PAYMENT_PROVIDER=test`): with `TEST_CHECKOUT` on (default in
  development, off in production) checkout is a page in the web app with Pay /
  Decline buttons and a test-mode banner. Those orders are `is_test`: no holds, no
  inventory, excluded from reports, refused at check-in (`test_ticket`). With it off,
  paid online orders are refused and the public pages point buyers to sellers. The
  WiPay provider should reuse Mana Labs 8's `wipay-connect` SDK and settle through
  `mark_paid` / `mark_failed` the same way.
- **Tickets**: a random 32-character `code` per admission, shown as a QR. The order
  link (`/orders/{id}?token=…`) is the buyer's access; it's emailed when SMTP is set.
- **Check-in** is one conditional `UPDATE … WHERE status = 'valid'`, so two gates
  can't both admit the same ticket.

## API surface today

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/health` | DB round-trip |
| POST | `/v1/auth/register`, `/v1/auth/login` | Returns a bearer token (rate-limited) |
| GET | `/v1/auth/me` | Current user |
| GET | `/v1/listings` | Discovery across every category: `type`, `country`, `city`, `q`, `tag`, date window, price window, `free`, `bbox` or `near`+`radius_km`, `sort`, paging |
| GET | `/v1/listings/calendar` | Counts per local day for the central calendar |
| GET, POST | `/v1/me/filter-profiles` | My saved profiles; create one (the first is active) |
| GET, PATCH, DELETE | `/v1/me/filter-profiles/{id}` | One profile |
| POST | `/v1/me/filter-profiles/{id}/activate` | Switch the feed to this profile |
| GET | `/v1/me/filter-profiles/{id}/feed` | Preview a profile without activating it |
| GET | `/v1/me/feed` | The "For You" feed from the active profile; 404 when there is none |
| GET | `/v1/me/follows` | Organisations I follow, with follower counts |
| PUT, DELETE | `/v1/me/follows/{org_id}` | Follow or unfollow; both idempotent |
| GET | `/v1/me/follows/listings` | What the organisations I follow have on |
| GET | `/v1/me/favourites` | Listings I saved, newest first; keeps cancelled ones |
| PUT, DELETE | `/v1/me/favourites/{listing_id}` | Save or unsave a published listing |
| GET | `/v1/organisations/{slug}/followers` | Public follower count |
| GET | `/v1/organisations` | Search organisations with something published or credited |
| GET | `/v1/organisations/{slug}` | Public profile: followers, owned listings, collaborations |
| GET | `/v1/listings/{slug}/collaborators` | Who is credited on a listing |
| GET, PUT | `/v1/orgs/{org_id}/listings/{listing_id}/collaborators` | Manage credits (owner's admins) |
| DELETE | `/v1/orgs/{org_id}/listings/{listing_id}/collaborators/{id}` | Remove a credit |
| GET, POST | `/v1/listings/{slug}/reviews` | Reviews and their summary; write one (needs a token) |
| PATCH, DELETE | `/v1/reviews/{id}` | Change or remove my own review |
| GET | `/v1/events`, `/v1/events/{slug}` | Published events and tiers |
| GET | `/v1/fees/quote` | Fee breakdown for a face value; `country` picks the market |
| GET | `/v1/config` | Payment provider and `online_payments`: `live`, `test` or `off` |
| POST | `/v1/orders` | Guest checkout; returns the order and `checkout_url` (rate-limited) |
| GET | `/v1/orders/{id}?token=` | Order status and tickets |
| POST | `/v1/payments/test/{id}` | Test provider's pay/decline (only in test mode) |
| GET | `/v1/me/orders` | Orders placed while signed in |
| GET, POST | `/v1/orgs` | My organisations (with my role); create one (caller becomes owner) |
| GET, PATCH | `/v1/orgs/{org_id}` | Organisation profile |
| GET, POST, DELETE | `/v1/orgs/{org_id}/members[/{user_id}]` | Add existing accounts by email; leave or remove |
| GET, POST, PATCH | `/v1/orgs/{org_id}/events[/{event_id}]` | All of the organisation's events, any status |
| POST | `/v1/orgs/{org_id}/events/{event_id}/publish`, `/cancel` | `draft` → `published` → `cancelled` |
| POST, PATCH, DELETE | `/v1/orgs/{org_id}/events/{event_id}/tiers[/{tier_id}]` | Ticket tiers |
| GET, POST, DELETE | `/v1/orgs/{org_id}/events/{event_id}/sellers[/{seller_id}]` | Committee sellers and their codes |
| GET | `/v1/orgs/{org_id}/events/{event_id}/sellers/me` | The caller's own seller record |
| POST | `/v1/orgs/{org_id}/events/{event_id}/sales` | Record a cash or box-office sale |
| GET | `/v1/orgs/{org_id}/events/{event_id}/report` | Sales by tier, channel and seller; payout figures |
| GET | `/v1/orgs/{org_id}/events/{event_id}/orders` | Orders, searchable by buyer |
| GET, POST | `/v1/orgs/{org_id}/events/{event_id}/checkin` | Check-in counts; check a ticket in |
| POST | `/v1/orgs/{org_id}/events/{event_id}/cover` | Upload the flyer (JPEG, PNG, WebP; 5 MB) |

### Promoter rules

Organisation routes return 404 to non-members, so IDs can't be probed, and 403
to members whose role is too low.

| | owner | manager | seller, scanner |
| --- | --- | --- | --- |
| Read the organisation and its events | ✓ | ✓ | ✓ |
| Edit the organisation, events, tiers, sellers; list members | ✓ | ✓ | |
| Add or remove sellers and scanners | ✓ | ✓ | |
| Add or remove owners and managers | ✓ | | |
| Sales report, orders, flyer | ✓ | ✓ | |
| Record cash sales | ✓ (any seller) | ✓ (any seller) | sellers, credited to themselves |
| Check tickets in | ✓ | ✓ | scanners |
| Leave the organisation | ✓ (not the last owner) | ✓ | ✓ |

- Publishing needs at least one tier and a start time in the future.
- A cancelled event is read-only. An event with paid orders can't be cancelled
  until the refund flow exists.
- Once a tier has sales, its price is fixed (add a new tier instead), its
  quantity can't drop below what's sold, and it can't be deleted.
- A seller with attributed orders can't be deleted, so the sales report stays whole.
- A tier's currency comes from its listing's market, so the request body
  doesn't take one. Every listing is `TT` until a promoter can choose.

Interactive docs at `/docs` when the API is running in development (off in production).
