# Volt member app

Flutter client for the Gym Management System. The Laravel API is the source of
truth for memberships, prices, payments and access; this app presents,
requests, caches and syncs. Android first.

## Run

Every build needs a flavor. Each one installs as its own app, so all three can
sit on one phone side by side:

| Flavor    | App ID                | API                                  |
| --------- | --------------------- | ------------------------------------ |
| `dev`     | `com.volt.member.dev` | `http://10.0.2.2:8000/api/v1`        |
| `staging` | `com.volt.member.stg` | placeholder until deployed           |
| `prod`    | `com.volt.member`     | placeholder until deployed           |

```sh
flutter run --flavor dev
```

`10.0.2.2` is your computer as the Android emulator sees it, so it reaches
`php artisan serve` there. To use a phone on the same Wi-Fi, override the URL:

```sh
flutter run --flavor dev --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/v1
```

Android Studio and VS Code have run configurations for all three flavors. iOS
flavors aren't set up yet; an iOS build without a flavor uses dev.

### Fake backend

Until the Laravel API runs, dev builds answer every call from an in-app fake
(`lib/core/network/fake_backend.dart`) that uses the JSON shapes from the
backend contract doc. Pass `--dart-define=FAKE_BACKEND=false` to use the real
API instead. Prod builds never use the fake.

| To try                    | Phone number    | Code     |
| ------------------------- | --------------- | -------- |
| Member of one gym         | any other       | `123456` |
| Member of two gyms        | `0911 11 11 11` | `123456` |
| Number with no gym        | `0900 00 00 00` | `123456` |
| Expired code              | any             | `000000` |
| Wrong code (5× locks out) | any             | anything else |

## Test

```sh
flutter analyze
flutter test
```

## Structure

```
lib/
  app/          app widget, router, startup
  core/         shared by all features; never imports from features/
    auth/         session token and session state
    config/       environment per flavor
    design/       theme (placeholder until the design is set)
    device/       app version, install ID
    errors/       Failure types and their messages
    localization/ language choice
    network/      ApiClient, interceptors, error mapping
    storage/      secure storage (secrets) and preferences (settings)
    tenant/       selected gym
  features/     one folder per business feature: presentation/, domain/, data/
  l10n/         English and Amharic strings (ARB) and generated code
```

## Conventions

These follow the team's mobile architecture doc, with three deliberate changes:

- **One app for now.** The staff app becomes a separate app at Phase 6, and
  `core/` moves into shared packages then. Keep `core/` free of feature
  imports so that move stays mechanical.
- **No use-case class per action.** Controllers call repositories directly.
  Add a use case only when an action coordinates several repositories.
- **No Drift yet.** SQLite arrives with the scanner's offline outbox
  (Phase 7). The member app caches recent responses as JSON until then.
- **No code generation yet.** DTOs are parsed by hand with Dart 3 patterns
  (see `core/auth/profile_json.dart`). Freezed and json_serializable can come
  in when the number of models makes hand-written parsing a burden.

Other rules:

- **Material comes from `material_ui`.** Import
  `package:material_ui/material_ui.dart`, never `package:flutter/material.dart`.
  go_router uses `material_ui`, and two Material libraries in one app don't
  share themes or localizations.
- **API calls go through `ApiClient`.** It adds the agreed headers and turns
  errors into `Failure`s. The API contract (headers, error shape, QR
  algorithm) is in the backend doc shared with the API developer.
- **Secrets go in `SecureStore`**: tokens and QR secrets. Everything else goes
  in `PreferencesStore`. Never log tokens, OTP codes or QR payloads.
- **User-facing text goes in `lib/l10n/*.arb`**, in English and Amharic.

## Design

Light, soft and rounded, after the Covera reference: a brand-tinted wash at
the top of each page, white cards with large radii, dark ink cards and buttons
for the main action, and gradient icon tiles. Montserrat for Latin text, Noto
Sans Ethiopic for Amharic. Light mode only for V1.

- **Brand colours come from the gym.** Before sign-in the app is Volt red
  (`#C3203A`) with the Volt logo. After sign-in, `brandProvider` switches to
  the selected gym's `primary_color` and logo. Read colours from
  `context.brand` or the theme, never hard-code a gym's colour.
- **Neutrals are shared** (`AppColors` in `core/design/tokens.dart`): ink for
  text and dark surfaces, greys for secondary text and lines.
- **Reuse the building blocks** in `core/design/widgets/`: `SoftBackground`,
  `AppCard`, `IconTile`, `DarkActionCard`, `CircleButton`, `GymAvatar`,
  `PrimaryButton`, `ScreenHeader`, `SectionHeader`.
- **Navigation:** five tabs with the QR raised in the middle, since members
  open it at the gym door on every visit.
