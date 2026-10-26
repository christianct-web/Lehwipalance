# Customer app (Flutter)

The client's original Lehwi Palance app, cleaned up. It still runs on
`MockApiService` (in-memory demo data); see `../../docs/codebase-audit.md` for
the migration to the real API.

```bash
flutter pub get
flutter run            # pick a device or Chrome
flutter analyze && flutter test
```

The original product concept is in `../../docs/original-concept.md`.
