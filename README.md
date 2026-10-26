# Lehwi Palance

Event discovery and ticketing for Trinidad & Tobago, built promoter-first: a
ticketing desk that charges less and pays promoters faster than the incumbents,
plus a season planner that fete-goers and their crews actually open.

Built by [Mana Labs 8](https://manalabs8.com) for the Lehwi Palance client.

## Repository layout

| Path | What it is | Stack |
| --- | --- | --- |
| `apps/customer` | Customer mobile app (the client's original codebase, cleaned up) | Flutter |
| `apps/promoter-portal` | Promoter web portal: events, tiers, committee sellers, payouts | React + Vite + TypeScript |
| `services/api` | Backend API: auth, events, tiers, orders, tickets, check-in | FastAPI + SQLAlchemy + Postgres |
| `infra` | Production reverse-proxy template | Caddy |
| `docs` | Audit, market analysis, architecture, roadmap | Markdown |

## Quick start

```bash
# Backend + database
cp services/api/.env.example services/api/.env
docker compose up --build          # API on http://localhost:8000/docs

# Promoter portal
cd apps/promoter-portal && npm install && npm run dev   # http://localhost:5173

# Customer app (still on mock data, see docs/codebase-audit.md)
cd apps/customer && flutter pub get && flutter run
```

Without Docker, the API runs with `pip install -e ".[dev]"` and
`uvicorn app.main:app --reload` from `services/api`, pointing `DATABASE_URL` at
any Postgres 16.

## Checks

`make api-test`, `make app-check`, and `npm run build` in the portal. CI runs all
three on every push and pull request (`.github/workflows/ci.yml`).

## Non-negotiables

- **No card data in our systems.** Cards are entered only on WiPay's hosted page.
  We store the provider's reference, never a card number or CVV.
- **No stored-value wallet** until there is a legal opinion on the Central Bank's
  E-Money Issuer Order.
- **Money is integer minor units** (cents) everywhere, with an explicit currency.
- **Secrets live in `.env`**, which is git-ignored. Only `.env.example` is committed.

## Docs

- [Codebase audit](docs/codebase-audit.md): the state of the original app and what was fixed
- [Market & economics](docs/market-and-economics.md): market, competitors, fee model, break-even
- [Architecture](docs/architecture.md): how the pieces fit
- [Roadmap](docs/roadmap.md): phases, open decisions and launch checklist
- [Original concept](docs/original-concept.md): the client's product vision as received
