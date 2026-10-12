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
