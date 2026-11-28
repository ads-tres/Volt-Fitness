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
| Plan frozen for 8 days from today | `0944 44 44 44` | `123456`      |
| No plan                        | `0955 55 55 55` | `123456`      |
| Payments always declined       | `0966 66 66 66` | `123456`      |
| Member of two gyms             | `0911 11 11 11` | `123456`      |
| In the Student group (20% off) | `0977 77 77 77` | `123456`      |
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

### My photo

Profile's avatar opens **Take a photo**, **Choose from gallery** and
**Remove photo** (`PUT` and `DELETE /me/photo`, the gym platform's ADR 0036).
The picture comes from the phone's camera app or gallery through
image_picker, so the member app still asks for no camera permission of its
own. The photo is kept at every gym where the member's number is
registered and shows on the QR screen, so the desk can see it's them. Its
link (`photo_url` in `GET /me/gyms`) works for 10 minutes, so the app reads
it when a screen shows it and never stores it. The fake keeps the picture
as a data link.

### A paused gym

When the platform pauses a gym (the gym platform's ADR 0043), `GET
/me/gyms` marks it `paused` and its routes answer `403 GYM_PAUSED`. Home
then says "This gym is paused for now. Ask at the gym." instead of an error,
the gym list marks it **Paused**, and other screens show the API's own
message. In the fake, `0988 88 88 88` is a member of a paused gym.

Receipts name the way the member paid in their language; `brought_in`, money
paid before the gym joined the platform and recorded when it imported its
members, shows as **Paid before** (the fake's `0933 33 33 33`).

### Branches, past plans and language

Profile, then **Branches and hours** lists the gym's branches
(`GET branches`) with each one's week and whether it is open now, by the
same rule as the door: a closure (a holiday, or other hours) decides its
dates; otherwise no hours means always open, and a weekday without hours is
closed. Hours that close before they open run past midnight ("18:00 – 02:00
(next day)"). Coming closures show with their Ethiopian date, and
`branch_closed`, `branch_hours_changed` and `branch_reopened` messages open
the page. The Membership tab lists the member's other plans, coming
and past (`GET memberships`). The app tells the API the member's language
(`PUT /me/language`) after sign-in and when it changes, so texts from the
gym come in Amharic or English to match.

In the fake, Bole opens Monday to Saturday 06:00 to 22:00 and Sunday 08:00
to 14:00, closes tomorrow for Timket and keeps short hours in five days,
Megenagna is always open, and every member has last month's plan
behind the current one.

### Discounts and promo codes

Plans show what the member pays (`your_price`, the gym platform's ADR
0032): their discount group's price, such as Student, or a promo code's,
whichever is lower, with the list price struck through and a tag naming
why. **Have a promo code?** on the Payments tab applies a code to every
plan (`GET plans?promo_code=`); the API's reason shows when it can't be
used. Buying a plan the code covers sends it (`{"promo_code": …}`) and is
charged its price. The code is forgotten when the member changes gym.

In the fake, `NEWYEAR` takes 10% off Monthly and Quarterly (not Annual),
`USED` has already been used, and any other code doesn't exist.

### Freezing

Members freeze their own membership from the Membership tab, within the
freeze days their plan allows: `POST /me/gyms/{gym}/memberships/{id}/freezes`
with the first and last day (from today, never in the past) and an optional
reason. The plan's end date moves later by as many days. A freeze covering
today or coming shows as a card with **I'm back** (or **Cancel freeze** before
it starts), which calls `…/freezes/{freeze}/end`; the unused days come back.
The API checks every rule and its refusal shows under the day it is about.

Each freeze says whether the member made it in the app or the gym did
(`frozen_in_app`).

In the fake, every Monthly plan allows 7 freeze days. The frozen number has
used 8 of its 10, so it can end its freeze or add a two-day one after it.

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

The menu at the top changes the branch, opens **Numbers** or
**Notifications**, or signs out.

**Numbers.** The gym's figures from the staff dashboard
(`GET /organizations/{gym}/dashboard`), for today or the last 7 or 30 days,
at this branch or every branch: check-ins with the top reasons for turning
away, money and what is owed, members and plans sold, the busy hours, and
the members to call, with a button to call each. The API leaves money out
for roles that don't see it, so a receptionist sees no money cards.

**Staff messages.** The bell in the top bar counts unread messages and
opens the inbox (`GET /organizations/{gym}/notifications`): online
payments, refunds to make, freezes members made in the app, and the
morning's members to call. Opening one shows it in full and marks it read;
the members to call link to the gym's staff panel. The desk checks every
two minutes and when it comes back to the front. **Notifications** in the
menu sets push and SMS for each topic (`notification-preferences`).
While signed in, the desk registers the phone's push token with
`"app": "staff"`, so it gets staff pushes and never members' ones (the gym
platform's ADR 0035); signing out removes it first, for shared desk
phones. A push arriving shows a banner; a tapped one opens its message.
Real builds have no Firebase yet, so for now they only see the inbox.

**Without internet.** The desk keeps a door list from the gym platform
(`GET door-list`, its ADR 0038): today's and tomorrow's day keys for every
member's QR credential, what each membership allows each date, and each
branch's hours. The app checks the list's Ed25519 signature before using
it and keeps it in secure storage; it downloads a new one when it opens a
branch and every 15 minutes. When a scan can't reach the API, the desk
decides it from the list exactly as the server would (the code, its time,
the day key, a fresh step, the hours, the membership, the 5-minute rule)
and shows the usual green or red screen, marked **Decided offline**.
Without a list it says it can't check. The decisions are kept on the phone
and sent to `POST check-ins/offline` once online; Today marks offline
check-ins and those the server would have decided otherwise, to review in
the panel. Desk check-in by search needs the internet. Signing out wipes
the list and the queue.

Staging and prod builds need the gym platform's door list key, so they
refuse a list signed with any other:

```sh
flutter run --flavor staffStaging -t lib/main_staff.dart \
  --dart-define=DOOR_LIST_PUBLIC_KEY=<public_key> --dart-define=DOOR_LIST_KEY_ID=<key_id>
```

Both come from `GET /organizations/{gym}/door-list/public-key` once the
server has `DOOR_LIST_SIGNING_KEY`. Without them (dev builds) the app
fetches the key once and keeps it.

**Taking payments.** A member who owes shows **Take payment** in Desk
search and on their check-in result. The sheet finds the membership with
money due (`GET members/{id}/memberships`, choosing when there are
several), fills in the amount due and records it as cash, telebirr, CBE Birr
or a bank transfer (`POST memberships/{id}/payments`, at the desk's branch;
transfers need the transaction number). Owners, managers and accountants
can also date it earlier. The receipt number shows once recorded. **Text a
pay link instead** opens a Chapa link for the amount and texts it to the
member (`payment-links`, then `sms`), or texts the open one again. The
API's refusals (more than is due, no Chapa account, texted a moment ago)
show where they belong.

**Selling plans.** Every member in Desk search has **Sell a plan**, and a
member turned away for an ended plan, no plan or used-up visits gets
**Renew** on the result. The sheet lists the gym's plans (`GET plans`) with
their price, length and branches, marks the current one, and starts the new
plan on the member's first free day unless staff pick another (owners and
managers may pick a past day). A promo code applies, or owners and managers
type a discount ("500" or "10%") with a reason. Selling calls `POST
members/{id}/memberships`; the member pays the lowest of the plan's price,
their discount group's and the promo code's, which the payment sheet then
shows as due. A clashing start day, an unknown code and the other refusals
show under their field.

**New members.** Owners, managers and receptionists see **Add member** in
Desk search, and under "no member matches". The form starts from what was
typed (digits go in the phone, anything else in the name) and asks for the
full name and phone, with optional gender, date of birth, message language,
email and an emergency contact (both halves or neither). It sends `POST
members` with the desk's branch as home branch; Ethiopian mobiles go as
E.164. A phone another member has comes back with **Find them instead**.
Once added, the desk takes their photo, sells a plan and takes the payment
in one go, or does it later.

**Freezing and cancelling.** Owners, managers and receptionists see
**Membership** on each member in Desk search. It lists the memberships that
run or are still to come, with their freeze days used and any freeze now or
coming. **Freeze** asks for the first and last day (from today; a past day
only for owners and managers) and a reason, shows the new end date, and
keeps receptionists within the plan's freeze days (`POST
memberships/{id}/freezes`). **End freeze** stops one that started, and
**Remove freeze** drops one still to come (`…/freezes/{freeze}/end`).
Owners and managers can also **Cancel membership** with a reason (`…/
cancellation`); any refund is made in the staff panel. A member turned away
as frozen gets **End freeze** on the result. Accountants see none of these,
nor Sell a plan or Renew, as the API allows them none.

**A paused gym.** `GET /me` marks a gym the platform paused, and its routes
then answer `403 GYM_PAUSED`. The gym chooser marks it **Paused**, every tab
shows a banner to contact the platform, and failed calls show the API's
message. The banner follows the inbox and Today, which reload every few
minutes, so it goes once the gym is back. Scans decided offline stay on the
phone and are sent then. In dev builds the menu's **Pause the gym (demo)**
switch tries it.

**Members' photos.** The scan and desk results show the member's photo
large, so the desk can see the person is the member; desk search and Today
show it small (`photo_url`, the gym platform's ADR 0036). At the desk,
tapping a member's photo or initials in search opens **Take a photo**
(`PUT members/{id}/photo`, from the camera) and **Remove photo**
(`DELETE`); a photo the API refuses shows its reason. The photo is kept at
every gym where the member's number is registered. Its link works for 10
minutes, so the app shows it when it loads and never stores it; offline,
the door list's photos are shown.

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
| Accountant at Demo Gym (can't add members) | `0911 00 00 03` | `password` |
| Wrong password                  | any of these    | anything else |

| Scanned code                    | Answer                                  |
| ------------------------------- | --------------------------------------- |
| any `GQ1:` code                 | Hana Girma let in                       |
| a `GQ1:` code containing `EXPIRED` | Tigist Haile turned away, plan ended |
| a `GQ1:` code containing `OWES` | Abebe Kebede let in, owing 1,000 ETB    |
| the same code twice             | turned away, code already used          |

The menu's **No internet (demo)** switch makes every call fail, so the
desk decides from the fake's signed door list (Abebe let in, Tigist's plan
ended, Hana with one visit left at Main Branch); turn it off and the scans
are sent.

Each gym's inbox starts with one unread message of each kind, and the
choices start with push on and SMS off. Numbers counts the check-ins made
in the fake; the owner sees money, the two-gyms receptionist doesn't.

At the desk, search finds Abebe (owes 1,000 ETB), Tigist (turned away, plan
ended) and Hana. Nobody has a photo until one is taken; the fake keeps it
until the app restarts and refuses one over 5 MB. Abebe's 1,000 ETB can be
paid in parts, with receipts from R-000001. Demo Gym has Chapa connected, so
pay links work and a second text within 5 minutes is refused; Bole Fitness
doesn't. The plans are Monthly (1,500 ETB), 3 months (4,000 ETB) and 10
visits (1,200 ETB, Main Branch only); `VOLT10` takes 10% off. Selling
Tigist a plan lets her in again. Every plan has 7 freeze days; Hana has a
3-day freeze next week, so her plan ends on 4 November. Members added at the
desk are kept until the app restarts; Abebe's number (0911 234 567) is taken. Today starts with two earlier check-ins at Main Branch and
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
