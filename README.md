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

| To try                         | Phone number    | Code          |
| ------------------------------ | --------------- | ------------- |
| Monthly plan, 18 days left     | any other       | `123456`      |
| Plan ending in 3 days          | `0922 22 22 22` | `123456`      |
| Plan expired 6 days ago        | `0933 33 33 33` | `123456`      |
| Plan frozen for a week         | `0944 44 44 44` | `123456`      |
| No plan                        | `0955 55 55 55` | `123456`      |
| Payments always declined       | `0966 66 66 66` | `123456`      |
| Member of two gyms             | `0911 11 11 11` | `123456`      |
| Number with no gym             | `0900 00 00 00` | `123456`      |
| Expired code                   | any             | `000000`      |
| Wrong code (5× locks out)      | any             | anything else |

Dates in the fake are built around today, and the fake forgets everything
when the app restarts. Payments open a built-in test checkout instead of
Chapa's page; paying there settles the payment as Chapa's webhook would, and
a bought plan really extends the fake membership.

Each number also starts with a few notifications that fit its plan. Profile →
Notifications → **Send a test notification** makes a new one and delivers it
two seconds later through a fake push, so the in-app banner and the deep
links can be tried without Firebase. It cycles through gym news, a plan
reminder and an invoice.

### Payments

Laravel starts each payment with Chapa and returns Chapa's checkout URL.
The app opens it in a web view, hands payment-app links (telebirr, CBE
Birr) to those apps, and closes it when Chapa redirects to the attempt's
`return_url`. The result screen then asks the API until it has verified the
payment: reaching the return URL proves nothing. Amounts are always
`Money` in minor units.

### Notifications

The API keeps each member's inbox and pushes through Firebase Cloud
Messaging. A push only carries a type and IDs; tapping it opens that screen,
which loads fresh data, switching gym first when the push is for another of
the member's gyms. One arriving while the app is open shows as a banner.
`PushService` (`lib/core/push/`) is the only code that touches the push
provider: dev builds use `FakePushService`, and real builds get
`NoPushService` until the Firebase projects exist (dev, staging and prod,
one per flavor). The push token goes to the API after sign-in, when it
changes and when the language changes; signing out deletes it.

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
    auth/         session token, profile and session state
    config/       environment per flavor
    design/       theme, brand colours and shared widgets
    device/       app version, install ID, device name
    errors/       Failure types and their messages
    localization/ language choice
    money/        amounts in minor units and their formatting
    network/      ApiClient, interceptors, error mapping, fake backend
    push/         push provider, permission and token sync
    storage/      secure storage (secrets) and preferences (settings)
    tenant/       selected gym
    time/         clocks, server time, dates and the Ethiopian calendar
  features/     one folder per business feature: presentation/, domain/, data/
    access/       the rotating QR (GQ1) and its credential
    attendance/   visit history
    auth/         phone and SMS code sign-in
    gyms/         choosing a gym
    home/         the dashboard
    membership/   the plan
    notifications/ inbox, push handling and notification settings
    onboarding/   welcome pages
    payments/     plans, invoices, receipts and Chapa checkout
    profile/      account, settings, signed-in devices
    shell/        tabs and navigation bar
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
- **Per-member data uses keys starting with `user.`** (`userDataPrefix`), in
  either store. Signing out deletes every such key, so a new feature's cache
  or secret is cleaned up without touching the sign-out code.
- **Business dates are `LocalDate`**, never `DateTime`: a membership's end date
  is a calendar day in the gym's timezone. Show dates through `DateText`, which
  follows the member's calendar setting (Gregorian, Ethiopian or both).
- **Time-dependent code reads `clockProvider`** (or `serverClockProvider` for
  QR codes), so tests can fix the date.
- **User-facing text goes in `lib/l10n/*.arb`**, in English and Amharic.

## Design

Warm and photo-led: a cream page, white cards with large radii, charcoal
buttons and a dark, icon-only navigation bar the pages curve down into, with
the QR as a brand-coloured square in the middle. Real photos carry the
welcome pages and the main cards; icons stay for navigation and small
controls. Montserrat for Latin text, Noto Sans Ethiopic for Amharic. Light
mode only for V1.

- **Brand colours come from the gym.** Before sign-in the app is Volt red
  (`#C3203A`) with the Volt logo. After sign-in, `brandProvider` switches to
  the selected gym's `primary_color` and logo. Read colours from
  `context.brand` or the theme, never hard-code a gym's colour.
- **Neutrals are shared** (`AppColors` in `core/design/tokens.dart`): ink for
  text and dark surfaces, greys for secondary text and lines.
- **Reuse the building blocks** in `core/design/widgets/`: `SoftBackground`,
  `AppCard`, `PhotoActionCard`, `IconTile`, `HeaderButton`, `GymAvatar`,
  `PrimaryButton`, `ScreenHeader`, `SectionHeader`.
- **Navigation:** five tabs with the QR in the middle, since members open it
  at the gym door on every visit.

### Photos

`assets/photos/` holds stock photos from Pexels, under the Pexels License
(free to use, attribution not required). They are placeholders: Volt's own
photos of its gyms and members should replace them before launch. Each was
cropped and compressed to about 100 KB.

| File | Source |
| --- | --- |
| `onboarding_train.jpg` | [Black man training with dumbbells in gym](https://www.pexels.com/photo/black-man-training-with-dumbbells-in-gym-6455963/) |
| `onboarding_check_in.jpg` | [Person with headphones holding a smartphone](https://www.pexels.com/photo/person-with-headphones-holding-a-smartphone-4162581/) |
| `onboarding_renew.jpg` | [Woman in black hijab lifting dumbbells](https://www.pexels.com/photo/woman-in-black-hijab-lifting-a-dumbbells-7690849/) |
| `home_check_in.jpg` | [Man holding black barbell in the gym](https://www.pexels.com/photo/man-holding-black-barbell-in-the-gym-4720813/) |
