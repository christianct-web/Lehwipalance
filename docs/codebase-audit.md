# Codebase audit: original customer app

Audited 18 Oct 2026. The source is the client's `lehwipalancecustomerv1` Flutter
project, now in `apps/customer`.

## Verdict

A well-structured front-end prototype, not a near-finished product. The UI is
polished and the code is clean (`flutter analyze`: 0 errors, 0 warnings), but
everything runs on in-memory mock data. There is no backend, no real auth and
no real payments.

## What it has

- About 74k lines of Dart across discovery (home, categories, map), media feed,
  cart and checkout, receipts, orders, inquiries, wallet, favourites, follows,
  filter profiles and settings.
- One data interface, `lib/core/base/api_service.dart` (`ApiService`), composing
  ~17 endpoint groups. It is the contract the real backend replaces.
- `MockApiService` (~4,900 lines) implementing that contract in memory, with
  T&T demo content.
- Routing with `go_router`, state with `provider` + `get_it`.

## Blocking issues found

| # | Issue | Status |
| --- | --- | --- |
| 1 | No backend: only `MockApiService` implements `ApiService` | Open: `services/api` is the replacement |
| 2 | Fake auth: email-only sign-in, "optional" password, `mock_jwt_token_*` | Open: real auth exists in the API; app must switch to it |
| 3 | Card number and CVV captured and stored in `CreditCardModel` (PCI violation) | Open: remove forms, use WiPay hosted checkout |
| 4 | Stored wallet with top-up/withdraw (e-money licensing risk) | Open: cut from v1 |
| 5 | Placeholder IDs `com.example.lehwipalancecustomerv1`; release signed with debug key | Open: needs client's chosen bundle ID and keystore |
| 6 | No location, camera or photo permissions declared on Android or iOS | **Fixed** |
| 7 | Build failed: wrong asset path `cover_image1.jpg` in `pubspec.yaml` | **Fixed** |
| 8 | Splash screen throws `Bad state: No element` (PageController animated before attach) | **Fixed** |
| 9 | Empty test file; `flutter test` failed | **Fixed**: starter tests added |
| 10 | Dead scratch files (`test_inqury.dart`, `paste_file.dart`, `reels/test.dart`, `testauth.dart`) | **Removed** (none were imported) |
| 11 | ~20 `UnimplementedError` stubs and "coming soon" placeholders | Open |
| 12 | Public OpenStreetMap tile and Nominatim servers used directly (usage policy forbids app traffic at scale) | Open: move to a paid tile provider |
| 13 | IDE files and a developer's local SDK paths committed (`.idea`, `local.properties`) | **Removed** |

## Changes made in this repo

- `pubspec.yaml`: asset path fixed.
- `AndroidManifest.xml`: internet, location, camera and media permissions;
  `url_launcher` queries; app label "Lehwi Palance".
- `ios/Runner/Info.plist`: location, camera and photo usage descriptions;
  URL schemes for maps/phone/email; display name "Lehwi Palance".
- `lib/customer_splash_filter.dart`: guard `animateToPage` with `hasClients`
  and `mounted`.
- `test/widget_test.dart`: starter tests for `ValidationUtils`.

## Migration path for the app

1. Write `RealApiService implements ApiService` against `services/api`, one
   endpoint group at a time. Switch the one line in
   `lib/core/base/service_locator.dart` that constructs `MockApiService`.
2. Replace `MockAuthService` with token auth against `/v1/auth/*`; store the
   token in secure storage.
3. Delete the card, bank and wallet forms; checkout opens WiPay's hosted page.
4. Trim modules deferred by the market analysis (hotels, stores, services,
   vacations, reels) behind feature flags rather than deleting them.
