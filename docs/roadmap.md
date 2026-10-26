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
- [ ] Seller sales report and member invites for people without an account
- [ ] Orders with inventory holds; WiPay checkout and callbacks
- [ ] Ticket issue, QR, transfer by phone number
- [ ] Offline check-in sync
- [ ] `RealApiService` in the Flutter app; remove card, bank and wallet forms
- [ ] Promoter portal: event setup, tiers, sellers, live sales, payouts report

## Launch checklist

- [ ] Real bundle ID and release keystore (not the debug key)
- [ ] Paid map tiles and geocoding
- [ ] Privacy policy and terms linked in sign-up
- [ ] Security review: auth, payments callback verification, rate limits
- [ ] Error monitoring and uptime alerts
- [ ] Store listings, screenshots, review notes
