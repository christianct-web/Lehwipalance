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
| `users` | Everyone: fete-goers, promoter staff, sellers, scanners |
| `organisations`, `org_members` | Promoters and who can act for them |
| `events` | A fete or event; `draft` → `published` → (`cancelled`) |
| `ticket_tiers` | Early bird, Tier 1, VIP; price in minor units, inventory, sales window |
| `sellers` | Committee members with a personal code for attributed sales |
| `orders`, `order_items` | A purchase; channel `online`, `seller_cash` or `box_office` |
| `tickets` | One admission; random `code` encoded in the QR; check-in state |

## Orders and payments

Logic lives in `app/services/orders.py`; the payment boundary is
`app/services/payments.py` (`PaymentProvider`).

- **Online**: guest checkout (name, email, optional phone and seller code) creates a
  `pending` order holding its tickets for `ORDER_HOLD_MINUTES` (15). The buyer is sent
  to the provider's hosted checkout; a verified result calls `mark_paid` (tickets issued,
  `quantity_sold` committed) or `mark_failed`. Both are idempotent.
- **Availability** = quantity − sold − tickets in unexpired pending orders. Every
  write locks the tier rows first, so a tier drop can't oversell.
- **Late payment**: if a hold expired and the tickets went to someone else, the order
  is marked `failed` with the payment reference kept for a refund; otherwise it's honoured.
- **Free tiers** and **staff sales** (`seller_cash`, `box_office`) are paid at once.
  Cash buyers pay face value (no booking fee); the promoter fee applies to all sales.
- **Test provider** (`PAYMENT_PROVIDER=test`): checkout is a page in the web app with
  Pay / Decline buttons, and the site shows a test-mode banner. The WiPay provider
  should reuse Mana Labs 8's `wipay-connect` SDK and follow the same pattern.
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
| GET | `/v1/events`, `/v1/events/{slug}` | Published events and tiers |
| GET | `/v1/fees/quote` | Fee breakdown for a face value |
| GET | `/v1/config` | Payment provider and whether test mode is on |
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
- Tiers are TTD for now; the request body doesn't take a currency.

Interactive docs at `/docs` when the API is running in development (off in production).
