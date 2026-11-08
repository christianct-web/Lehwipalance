# Market & economics (summary)

Summary of the full analysis of 18 Oct 2026. The live document with sources,
the break-even chart and comments is shared separately by Mana Labs 8. Figures
there take precedence over this summary.

> **Superseded in part, 2026-11-08.** The client chose the full five-category
> concept in Trinidad & Tobago only, and dropped the 2027 pilot for a 2028
> launch. The recommendation below to narrow the product no longer governs; see
> `PRODUCT.md` and `docs/roadmap.md`. The facts, costs and risks still stand,
> but **the break-even figure assumed the narrow build** — it is a floor, not an
> estimate, now that four more categories and the social layer are in scope.

## Recommendation (superseded — kept for the reasoning)

Narrow the product. Win Trinidad Carnival fete ticketing first, by being cheaper
and faster for promoters than Island eTickets. Add a season planner for
fete-goers and their crews. Defer hotels, vacations, services, stores and the
reels feed; cut the wallet.

**One line:** Lehwi Palance is the Carnival season planner for you and your crew,
and the ticketing desk that pays promoters before the fete.

## Key facts

- ~300 fetes per Carnival season (NCC, 2014); 2026 tickets TT$250–600 for cooler
  fetes, TT$950–2,200 all-inclusive.
- Carnival 2026: 54,441 arrivals (1 Jan–14 Feb), up 13%; TT$15,313 spend per air visitor.
- Island eTickets: 8% promoter fee plus buyer processing fees; payout 5 business
  days after the event; discretionary reserves.
- Trinbago Events already combines discovery, calendar, map and ticketing.
- Carnival 2027 is 8–9 Feb; 2027 fete sales are already open.

## Fee model (implemented in `services/api/app/services/fees.py`)

Buyer pays 4.5% + TT$3 per ticket; promoter pays 3%. WiPay costs 3.5% + US$0.25.
Rates are now per market, held on the `countries` row and resolved by
`app/services/countries.py`; these are the seeded Trinidad & Tobago values.

**Unresolved conflict with the concept doc.** `docs/original-concept.md` states
2% + US$0.50 per paid ticket. At ~TT$6.80/US$ on a TT$300 ticket that yields
~TT$9.40 against WiPay's ~TT$12.20 cost — loss-making per card sale unless
processing is passed to the buyer separately, or unless the 2% is a promoter fee
charged alongside a separate buyer processing fee. The client has to confirm
which was meant; the implemented rates are what is seeded and charged today.

| Face value (TT$) | Buyer pays | Promoter receives | On Island eTickets (92%) | Platform net |
| --- | --- | --- | --- | --- |
| 300 | 316.50 | 291.00 | 276.00 | 12.72 |
| 500 | 525.50 | 485.00 | 460.00 | 20.41 |
| 1,000 | 1,048.00 | 970.00 | 920.00 | 39.62 |

## Economics

- Running cost ~TT$290k/year: hosting, support, marketing, legal.
- Break-even ~14,200 tickets/year, about 5% of one Carnival season — **for the
  narrow build only.** The full concept adds running cost (map tiles, media
  storage and CDN, moderation) that this figure does not carry.
- Build effort 36–49 person-weeks for the narrow build. The full five-category
  concept is roughly 40–70 person-weeks beyond the state of 2026-11-08,
  excluding delivery operations. That wider figure is an engineering estimate,
  not from the market analysis.

## Main risks

Missing the 2027 season; credit risk on early payouts; e-money rules (no wallet);
PCI (no card data); incumbent fee response; WiPay outages at tier drops; the Data
Protection Act being fully proclaimed; venue bans.
