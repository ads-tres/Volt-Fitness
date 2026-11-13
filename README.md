# Volt apps

Flutter clients for the Gym Management System, two apps from one codebase:
the **member app** (`lib/main.dart`) and the **front desk app**, Volt Desk
(`lib/main_staff.dart`), which staff use to let members in. Both share
`lib/core/`. The Laravel API
([azabla/gym-platform](https://github.com/azabla/gym-platform)) is the source
of truth for memberships, prices, payments and access; the apps present,
request, cache and sync. Android first. It follows the API's members-app
contract, `docs/api/members-app.md` in that repository: every gym call has the
gym's slug in its path (`/me/gyms/{slug}/…` for members,
`/organizations/{slug}/…` for staff).

## Run the member app

Every build needs a flavor. Each one installs as its own app, so all three can
sit on one phone side by side:

| Flavor    | App ID                | API                                  |
| --------- | --------------------- | ------------------------------------ |
| `dev`     | `com.volt.member.dev` | `http://10.0.2.2:8080/api/v1`        |
| `staging` | `com.volt.member.stg` | `https://gym-platform.onrender.com/api/v1` |
| `prod`    | `com.volt.member`     | placeholder until deployed           |

```sh
flutter run --flavor dev
```

`10.0.2.2` is your computer as the Android emulator sees it, so it reaches
the gym platform's Docker setup (`make up`, on port 8080) there. To use a
phone on the same Wi-Fi, override the URL:

```sh
flutter run --flavor dev --dart-define=API_BASE_URL=http://192.168.1.20:8080/api/v1
```

Staging is the gym platform on Render's free plan. It sleeps when nobody
uses it, so the first call after a while takes up to a minute. Its SMS go to
Render's logs: sign in as a member the gym registered (the demo gym's Tigist
is `0922 34 56 78`) and read the code there.

Android Studio and VS Code have run configurations for all three flavors. iOS
flavors aren't set up yet; an iOS build without a flavor uses dev.

### Fake backend

Dev builds answer every call from an in-app fake
(`lib/core/network/fake_backend.dart`) that uses the same paths and JSON as
the API's members-app contract, so the app can be tried offline. Pass
`--dart-define=FAKE_BACKEND=false` to use the real API instead. Prod builds
never use the fake.

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
| Wrong or expired code          | any             | anything else |
| Too many wrong codes           | any             | 5 wrong codes, then 429 |

Dates in the fake are built around today, and the fake forgets everything
when the app restarts. Payments open a built-in test checkout instead of
Chapa's page; paying there settles the payment on the next check, as Chapa
would, and a bought plan really extends the fake membership. The signed-in
devices list (Profile) exists only in the fake: the API has no list of
phones yet.

Each number also starts with a few notifications that fit its plan. Profile →
Notifications → **Send a test notification** makes a new one and delivers it
two seconds later through a fake push, so the in-app banner and the deep
links can be tried without Firebase. It cycles through gym news, a plan
reminder and an invoice.

### Payments

What a member owes is the balance on their membership; they pay it through a
payment link (`POST /me/gyms/{gym}/memberships/{id}/payment-link`), and buy a
plan with `POST /me/gyms/{gym}/plans/{id}/purchase`. The API starts each
payment with Chapa and returns its checkout URL. The app opens it in a web
view and hands payment-app links (telebirr, CBE Birr) to those apps, and
closes it when Chapa sends the member to the link's `return_url`. Reaching it
proves nothing, so the result screen then has the API ask Chapa
(`POST …/payment-links/{id}/check`, ten a minute) until the payment is in.
Paid receipts come from `GET /me/gyms/{gym}/payments`. Amounts are always
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

## Run the front desk app

The front desk app has its own flavors, so it installs next to the member
app. It talks to the same API per flavor:

| Flavor         | App ID               | Name              |
| -------------- | -------------------- | ----------------- |
| `staffDev`     | `com.volt.staff.dev` | Volt Desk Dev     |
| `staffStaging` | `com.volt.staff.stg` | Volt Desk Staging |
| `staffProd`    | `com.volt.staff`     | Volt Desk         |

```sh
flutter run --flavor staffDev -t lib/main_staff.dart
```

Without `-t` the member app is built into the staff flavor, so always pass
both. VS Code has run configurations for all six.

Staff sign in with their phone and password (`POST /auth/tokens`). The app
picks the gym and branch when there is only one and asks otherwise, then
opens on the scanner. Three tabs:

- **Scan** reads a member's QR code (only `GQ1:` codes; others are ignored)
  and sends it once to `check-ins/scan` with a new `Idempotency-Key`. The
  answer fills the screen, green to let in and red with the reason to turn
  away, with what the member owes either way, and goes back to the camera
  after five seconds or a tap.
- **Desk** finds a member who came without their phone by name or phone
  number and checks them in at the branch, with the same answer.
- **Today** lists the branch's check-ins for the day, newest first.

The menu at the top changes the branch or signs out.

**The camera.** Scanning needs a phone or tablet with a back camera; the
app asks for the camera permission the first time and says so if it was
refused (allow it in the phone's settings). An emulator's virtual camera
works for trying it. Only the staff flavors ask for the camera: the member
flavors' manifests remove the permission, and CI checks both APKs for it.
On iOS, `Info.plist` has the camera description.

### Fake front desk

Dev builds answer the staff calls from `lib/staff/fake_front_desk.dart`, in
the API's shapes, as the member app's fake does
(`--dart-define=FAKE_BACKEND=false` uses the real API).

| To try                          | Phone           | Password   |
| ------------------------------- | --------------- | ---------- |
| Demo Gym, both branches         | `0911 00 00 01` | `password` |
| Two gyms (Demo Gym, Bole Fitness) | `0911 00 00 02` | `password` |
| Wrong password                  | either          | anything else |

| Scanned code                    | Answer                                  |
| ------------------------------- | --------------------------------------- |
| any `GQ1:` code                 | Hana Girma let in                       |
| a `GQ1:` code containing `EXPIRED` | Tigist Haile turned away, plan ended |
| a `GQ1:` code containing `OWES` | Abebe Kebede let in, owing 1,000 ETB    |
| the same code twice             | turned away, code already used          |

At the desk, search finds Abebe (owes 1,000 ETB), Tigist (turned away, plan
ended) and Hana. Today starts with two earlier check-ins at Main Branch and
lists every one made since; the fake forgets them when the app restarts.

To scan for real, run a staging build of each app and point the desk at the
member app's QR, signed in as a staff member of the demo gym.

## Test

```sh
flutter analyze
flutter test
```

## Structure

```
lib/
  main.dart     the member app
  main_staff.dart the front desk app
  app/          the member app's widget, router, startup
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
  staff/        the front desk app, laid out the same way
    app/          app widget, router, tabs
    core/         the desk's session: who is signed in, at which gym and branch
    features/     auth, gym (gym and branch), scan, desk (search), today
    fake_front_desk.dart
  l10n/         English and Amharic strings (ARB) and generated code
```

## Conventions

These follow the team's mobile architecture doc, with three deliberate changes:

- **Two apps, one package.** The front desk app lives in `lib/staff/` with its
  own entry point and flavors, and shares `core/` with the member app. Keep
  `core/` free of feature and staff imports, so it can move into a shared
  package later without changes.
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
