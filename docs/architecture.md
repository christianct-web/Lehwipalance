# Architecture

```
 Fete-goer (Flutter app) ──┐
                           ├──► services/api (FastAPI) ──► Postgres
 Promoter (web portal) ────┤          │
                           │          ├──► WiPay hosted checkout + callbacks (wipay-connect)
 Gate staff (scanner) ─────┘          └──► Email / WhatsApp notifications
```

## Services

- **API** (`services/api`): the single source of truth. JWT bearer auth,
  argon2 password hashes, role-based access per organisation
  (`owner`, `manager`, `seller`, `scanner`). Alembic migrations run on start.
- **Promoter portal** (`apps/promoter-portal`): static SPA served by Caddy.
- **Customer app** (`apps/customer`): Flutter; talks to the API through the
  `ApiService` interface.
- **Gate scanner**: planned as a mode of the customer app, or a small separate
  app, working offline with a pre-downloaded ticket list and syncing check-ins.

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

## Payments

The payment boundary is `app/services/payments.py` (`PaymentProvider`). The WiPay
implementation should reuse Mana Labs 8's `wipay-connect` SDK and callback server.
Flow: create `pending` order → redirect to hosted checkout → callback verified →
order `paid` → tickets issued → inventory committed. Inventory needs a short hold
on `pending` orders so tier drops don't oversell.

## API surface today

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/health` | DB round-trip |
| POST | `/v1/auth/register`, `/v1/auth/login` | Returns a bearer token |
| GET | `/v1/auth/me` | Current user |
| GET | `/v1/events`, `/v1/events/{slug}` | Published events and tiers |
| GET | `/v1/fees/quote` | Fee breakdown for a face value |
| GET, POST | `/v1/orgs` | My organisations (with my role); create one (caller becomes owner) |
| GET, PATCH | `/v1/orgs/{org_id}` | Organisation profile |
| GET, POST, DELETE | `/v1/orgs/{org_id}/members[/{user_id}]` | Add existing accounts by email; leave or remove |
| GET, POST, PATCH | `/v1/orgs/{org_id}/events[/{event_id}]` | All of the organisation's events, any status |
| POST | `/v1/orgs/{org_id}/events/{event_id}/publish`, `/cancel` | `draft` → `published` → `cancelled` |
| POST, PATCH, DELETE | `/v1/orgs/{org_id}/events/{event_id}/tiers[/{tier_id}]` | Ticket tiers |
| GET, POST, DELETE | `/v1/orgs/{org_id}/events/{event_id}/sellers[/{seller_id}]` | Committee sellers and their codes |

### Promoter rules

Organisation routes return 404 to non-members, so IDs can't be probed, and 403
to members whose role is too low.

| | owner | manager | seller, scanner |
| --- | --- | --- | --- |
| Read the organisation and its events | ✓ | ✓ | ✓ |
| Edit the organisation, events, tiers, sellers; list members | ✓ | ✓ | |
| Add or remove sellers and scanners | ✓ | ✓ | |
| Add or remove owners and managers | ✓ | | |
| Leave the organisation | ✓ (not the last owner) | ✓ | ✓ |

- Publishing needs at least one tier and a start time in the future.
- A cancelled event is read-only. An event with paid orders can't be cancelled
  until the refund flow exists.
- Once a tier has sales, its price is fixed (add a new tier instead), its
  quantity can't drop below what's sold, and it can't be deleted.
- A seller with attributed orders can't be deleted, so the sales report stays whole.
- Tiers are TTD for now; the request body doesn't take a currency.

Interactive docs at `/docs` when the API is running.
