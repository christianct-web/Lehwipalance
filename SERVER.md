# This deployment — srv1363266 (187.77.18.154)

Live at **https://lehwi.187-77-18-154.sslip.io** (buyers at `/`, promoters at
`/promoter`). Deployed 2026-11-07.

This file describes *this server*. The general guide is `docs/deploy-vps.md`.

## How it differs from docs/deploy-vps.md

The machine already ran Sookhai TMS on ports 80/443, so this stack does **not**
own them. A shared Caddy in `~/edge` terminates TLS for the whole machine and
forwards this app to `127.0.0.1:8082`. See `~/edge/README.md`.

That is why `.env` here has `DOMAIN=:80` (the internal Caddy's listen address,
not a hostname) with `HTTP_BIND`/`HTTPS_BIND` on localhost, and why the real
public address is given separately in `PUBLIC_BASE_URL` and `CORS_ORIGINS`.

`docker-compose.prod.yml` was changed from hardcoded `80:80`/`443:443` to
`${HTTP_BIND:-0.0.0.0:80}` / `${HTTPS_BIND:-0.0.0.0:443}`, matching the pattern
Sookhai already uses. Defaults are unchanged, so a stack that *does* own the
machine's web ports still works with no `.env` entries. This edit is committed.

## Current configuration

| Setting | Value | Note |
| --- | --- | --- |
| Database | Postgres 16 in the `db` container | **Temporary** — see below |
| `PAYMENT_PROVIDER` | `test` | WiPay not connected |
| `TEST_CHECKOUT` | `true` | Simulated online payments, yellow banner |
| Flyer storage | `lehwi_uploads` volume on this VPS | No Supabase Storage yet |
| Ticket emails | off (`SMTP_HOST` empty) | Buyers still get their ticket link on screen |

## Operating

```bash
cd ~/lehwipalance
C="docker compose -f docker-compose.prod.yml --profile localdb"
$C ps
$C logs -f api
$C up -d --build          # deploy; migrations run on start
```

Drop `--profile localdb` once the database is Supabase.

Backups: `backup.sh` dumps the local database nightly at 03:17 UTC via cron to
`~/backups/lehwipalance`, keeping 14 days, and verifies each dump is readable.
Remove that cron entry once Supabase takes over backups.

## Switching the database to Supabase

The database is deliberately disposable right now — it holds no real data.

1. Create the Supabase project (region US East; Pro for daily backups).
2. **Project Settings → Database → Connection string → Session pooler**
   (port 5432; the direct connection is IPv6-only and this VPS has IPv4).
3. Run `./switch-to-supabase.sh 'postgresql://postgres.REF:PASSWORD@aws-0-us-east-1.pooler.supabase.com:5432/postgres'`

It rewrites the scheme to `postgresql+psycopg`, adds `sslmode=require`,
URL-encodes the password, checks it can connect, applies the migrations, swaps
`.env`, restarts without the local Postgres, and verifies the site. It keeps a
`.env` backup and prints how to roll back.

Carrying existing data across is a separate step — ask before running it if the
pilot has by then taken real sales.

### Flyers in Supabase Storage (optional)

Create a **public** bucket named `event-media`, then set `SUPABASE_URL` and
`SUPABASE_SERVICE_KEY` (service_role, server-side only — never in the web app)
in `.env` and restart. Without them flyers stay on the VPS.

## Before taking real money

`PAYMENT_PROVIDER=test` means no card payments. See "Before taking card
payments" in `docs/deploy-vps.md`: WiPay account, `WipayProvider` in
`app/services/payments.py`, callback route. Also outstanding: privacy policy
and terms pages, refund policy, uptime monitoring on `/api/health`.

Do not leave `TEST_CHECKOUT=true` during a real event — set it `false` and
restart, or buyers may hold simulated tickets the gate will refuse.
