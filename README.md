# SakayNa

SwiftUI iOS app for motorcycle and car rental in the Philippines (₱).  
Renters browse and book; owners list vehicles and manage trips. Live data uses **Firebase Auth** + **Cloud Firestore**.

## Source code

**https://github.com/Prncepe/SakayNa**

## Application overview

See [docs/APPLICATION_OVERVIEW.md](docs/APPLICATION_OVERVIEW.md).

## Screenshots

**Path:** [`docs/screenshots/`](docs/screenshots/) — insert into your PDF in filename order (`01` → `36`).

Flow: Welcome → Signup → Login → Browse → Book → Trip → Chat → Profile → Owner dashboard → Listings → Requests.

Full labeled list: [APPLICATION_OVERVIEW.md](docs/APPLICATION_OVERVIEW.md#screenshots).

| Flow step | Preview |
|---|---|
| 01 Welcome | ![Welcome](docs/screenshots/01-welcome.png) |
| 02 Signup | ![Signup](docs/screenshots/02-signup.png) |
| 03 Login | ![Login](docs/screenshots/03-login.png) |
| 04 Renter home | ![Renter](docs/screenshots/04-renter-home.png) |
| 06 Vehicle detail | ![Detail](docs/screenshots/06-vehicle-detail.png) |
| 12 Trip tracking | ![Trip](docs/screenshots/12-trip-tracking.png) |
| 16 Chat | ![Chat](docs/screenshots/16-chat.png) |
| 27 Owner dashboard | ![Owner](docs/screenshots/27-owner-dashboard.png) |
| 28 Add vehicle | ![Add](docs/screenshots/28-add-vehicle.png) |
| 30 Booking requests | ![Requests](docs/screenshots/30-booking-requests.png) |

## Demo accounts

| Role | Phone | Password |
|---|---|---|
| Owner (Juan) | `09691304673` | `123456` |
| Renter (Maria) | `09157977535` | `123456` |

## Requirements

- Xcode 15+ / iOS 17+
- Firebase project `sakayna-5741b` (plist included)
- Publish rules from `firebase/firestore.rules`

## Build

```bash
python3 generate_xcodeproj.py
open SakayNa.xcodeproj
```

Select your Development Team under **Signing & Capabilities**, then Run on a simulator or iPhone.
