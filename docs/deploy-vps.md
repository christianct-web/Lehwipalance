# Deploying to a VPS

One server runs everything with Docker: **Caddy** (HTTPS and the web app) in
front of the **API**. The database is **Supabase** (managed Postgres), or
Postgres on the same server if you prefer.

```
 Browser ──HTTPS──► Caddy (web container, ports 80/443)
                      ├── /        → web app: buyer pages, /promoter portal, gate scanner
                      └── /api/*   → api container (FastAPI) ──► Supabase Postgres
                                                              └─► Supabase Storage (flyers, optional)
```

## What you need

- A VPS with Ubuntu 22.04+ (1 vCPU / 1 GB RAM is enough for a pilot), ports 80 and 443 open.
- A domain or subdomain, e.g. `tickets.lehwipalance.com`.
- A Supabase project (Pro plan recommended for daily backups), region **US East**.
- Optional: an SMTP account for ticket emails (Resend, Postmark, Brevo…).

## 1. Point the domain at the server

Create a DNS **A record** for your domain pointing to the VPS's IP address.
Caddy can't get an HTTPS certificate until this resolves.

## 2. Install Docker on the VPS

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER   # log out and back in afterwards
```

## 3. Get the code

```bash
git clone https://github.com/christianct-web/Lehwipalance.git
cd Lehwipalance
```

The repository is private, so GitHub will ask for credentials: use your GitHub
username and a [personal access token](https://github.com/settings/tokens) with
read access to this repo (or add a deploy key to the server).

## 4. Set up Supabase

1. Create a project. Save the database password.
2. **Project Settings → Database → Connection string**: choose **Session pooler**
   (it works over IPv4; the direct connection needs IPv6). Copy it. It looks like
   `postgresql://postgres.abcd:[YOUR-PASSWORD]@aws-0-us-east-1.pooler.supabase.com:5432/postgres`
3. For `DATABASE_URL`, change `postgresql://` to `postgresql+psycopg://`, put in the
   password, and add `?sslmode=require` at the end. If the password has symbols like
   `@ : / # ?`, URL-encode them (or reset to a password of letters and numbers).
4. Optional, for flyers: **Storage → New bucket** named `event-media`, set to **Public**.
   Copy **Project URL** and the **service_role** key (Project Settings → API) into
   `SUPABASE_URL` and `SUPABASE_SERVICE_KEY`. The service key stays on the server only;
   never put it in the web app. Without these, flyers are stored on the VPS.

The API creates its tables itself on start (Alembic migrations). You don't run any SQL.

## 5. Configure

```bash
cp .env.production.example .env
nano .env
```

Fill in at least `DOMAIN`, `ACME_EMAIL`, `PUBLIC_BASE_URL`, `CORS_ORIGINS`,
`JWT_SECRET` (`openssl rand -hex 32`) and `DATABASE_URL`. Leave
`PAYMENT_PROVIDER=test` until WiPay is connected, and choose `TEST_CHECKOUT`
(see "Two ways to run before WiPay" below).

## 6. Start

```bash
docker compose -f docker-compose.prod.yml up -d --build
docker compose -f docker-compose.prod.yml logs -f api    # watch migrations run; Ctrl+C to stop watching
```

Open `https://YOUR_DOMAIN`. With `TEST_CHECKOUT=true` a yellow banner confirms
test mode. `https://YOUR_DOMAIN/api/health` should return `{"status":"ok"}`.

Using Postgres on the VPS instead of Supabase: set the `localdb` lines in `.env`
and add `--profile localdb` to every `docker compose` command.

## 7. First run-through

1. Go to `/promoter`, create your account, then create the promoter's organisation.
2. New event → Details (description, flyer) → Tickets (add a tier) → Overview → **Publish**.
3. Open the public link on your phone, buy a ticket, press **Pay (test)**, see the QR codes.
4. Event → **Open gate scanner** on a phone, **Start camera**, scan the QR: green **Admit**,
   then amber **Already scanned** on a second scan.
5. Team: have sellers and gate staff create accounts, then add them by email
   (Organisation page → Team). Add sellers to an event under **Sellers** with the same
   email so they can record cash sales and get a personal link.

## Updating

```bash
cd Lehwipalance
git pull
docker compose -f docker-compose.prod.yml up -d --build
```

Migrations run automatically on start.

## Backups

- **Supabase**: daily backups on Pro, plus point-in-time recovery as an add-on.
- **Local Postgres**: back up nightly, e.g. a cron job running
  `docker compose -f docker-compose.prod.yml --profile localdb exec -T db pg_dump -U lehwi lehwi | gzip > ~/backups/lehwi-$(date +%F).sql.gz`
  and copy the files off the server.
- **Flyers on the VPS**: they live in the `lehwi_uploads` Docker volume.

## Two ways to run before WiPay

`TEST_CHECKOUT` decides whether the public can make **simulated** online payments.

| | `TEST_CHECKOUT=false` (the production default) | `TEST_CHECKOUT=true` |
| --- | --- | --- |
| Use it for | **A real pilot**: real cash sales, real gate | Demos and staff training |
| Paid tiers online | Shown, but marked "from sellers & at the gate" | Simulated checkout (Pay / Decline) |
| Free RSVP tiers online | Real tickets | Real tickets |
| Cash and box-office sales | Real tickets | Real tickets |
| Banner | None | Yellow test-mode banner |

Simulated orders are always flagged as test orders, whichever mode: they don't
use up inventory, don't appear in sales figures, and the gate scanner refuses
their tickets ("Test ticket: not valid"). So nobody gets into a real fete with a
simulated payment. Still, **don't leave `TEST_CHECKOUT=true` on while you run a
real event**: buyers could be confused by tickets that won't work.

## Before taking card payments

To take card payments online:

1. WiPay business account approved; API credentials in hand.
2. Implement `WipayProvider` in `services/api/app/services/payments.py` with
   wipay-connect, plus a callback route that verifies WiPay's payload and calls
   `orders.mark_paid` / `orders.mark_failed` (the test route shows the pattern).
3. Set `PAYMENT_PROVIDER=wipay` and the `WIPAY_*` values. `TEST_CHECKOUT` no
   longer applies and online checkout takes real payments.

Also on the launch list (docs/roadmap.md): privacy policy and terms pages, a
refund policy, uptime monitoring on `/api/health`, and error alerts.

## Troubleshooting

- **No HTTPS / certificate errors**: DNS isn't pointing at the server yet, or ports 80/443
  are blocked by the provider's firewall. `docker compose -f docker-compose.prod.yml logs web`.
- **API keeps restarting**: `docker compose -f docker-compose.prod.yml logs api`. Common causes:
  `JWT_SECRET` missing or short, `PUBLIC_BASE_URL` left as localhost, or a wrong `DATABASE_URL`
  (password not URL-encoded, missing `+psycopg`, missing `sslmode=require`).
- **Scanner camera won't start**: the page must be opened over `https://`, and the phone
  must allow camera access for the site. Typing the ticket code still works.
- **No ticket emails**: `SMTP_HOST` is empty or wrong; check `logs api`. Buyers can always
  open their tickets from the order link, and promoters can resend it from the Orders tab.
