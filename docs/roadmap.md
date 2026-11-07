# Roadmap

## Open decisions (client)

- [ ] Wedge: Carnival fete ticketing + season planner, other categories deferred
- [ ] Launch target: 2027 pilot (late-season and post-Carnival events) + 2028 full season
- [ ] Fee model and whether to offer early payouts
- [ ] WiPay business account, online Linx support, payout timing
- [ ] Three to five pilot promoters, interviewed on fees, payout and committee sales
- [ ] Final app name spelling (code uses both "Lehwi" and "Lewi"), bundle ID, icon
- [ ] Owner of the Apple and Google developer accounts

## Phase 0: foundation (this repo)

- [x] Monorepo, CI, Docker Compose
- [x] Customer app cleaned; build, permission and splash fixes
- [x] API scaffold: auth, events, tiers, fee quotes, schema and first migration
- [x] Promoter portal starter

## Phase 1: product & design

- [ ] PRODUCT.md and design direction (impeccable)
- [ ] Core flows: season calendar, crew checkout, promoter tier setup, gate scanner

## Phase 2: pilot build

- [x] Promoter endpoints: organisations, members, events, tiers, sellers (role-checked)
- [x] Seller sales report
- [ ] Member invites for people without an account
- [x] Orders with inventory holds; guest checkout; test payment provider
- [ ] WiPay checkout and callbacks (`PaymentProvider` is ready for it)
- [x] Ticket issue and QR; ticket link by email (SMTP) and WhatsApp share
- [ ] Ticket transfer by phone number
- [x] Cash sales by sellers and box office
- [x] Online gate check-in (web scanner, duplicate-safe)
- [ ] Offline check-in sync
- [ ] `RealApiService` in the Flutter app; remove card, bank and wallet forms
- [x] Web app: event pages and checkout, promoter portal (event setup, flyer, tiers, sellers, live sales, orders, payout figures)
- [x] Production deploy: Docker Compose + Caddy on a VPS, Supabase Postgres and Storage

## Launch checklist

- [ ] Real bundle ID and release keystore (not the debug key)
- [ ] Paid map tiles and geocoding
- [ ] Privacy policy and terms linked in sign-up
- [ ] Security review: auth, payments callback verification (rate limits on login, sign-up and checkout are in)
- [ ] Error monitoring and uptime alerts (watch `/api/health`)
- [ ] Refund policy, and a refund flow before cancelling events with paid orders
- [ ] Switch `PAYMENT_PROVIDER` from `test` to `wipay`
- [ ] Store listings, screenshots, review notes
