# Application Overview — SakayNa

**SakayNa** is an iOS app for renting motorcycles and cars in the Philippines. It connects people who need a vehicle for a trip with owners who want to earn from their motorcycle or car. Prices are shown in Philippine pesos, and the app uses a yellow SakayNa theme that matches the brand.

## Purpose

The app makes peer-to-peer vehicle rental simple and safer for both sides:

- **Renters** can browse listings, check availability by date, book a vehicle, pay with GCash / Maya / QR Ph / cash, chat with the owner, track the trip, and rate the experience.
- **Owners** can list vehicles with photos and OR/CR, manage booking requests, approve pickups with a PIN, handle deposits and deductions, and get paid through their payout methods.

All live data (accounts, vehicles, bookings, chat, and notifications) is stored in **Firebase Authentication** and **Cloud Firestore**, so a renter phone and an owner phone stay in sync in real time.

## Target users

| User | Who they are |
|---|---|
| Renters | Students, travelers, and daily users who need a motorcycle or car for a short period |
| Owners | Vehicle owners who want to list a motorcycle or car and manage bookings from their phone |
| Course / demo audience | ITWM105 / mobile development evaluators reviewing the SwiftUI + Firebase implementation |

## Main features

### Accounts and profiles
- Sign up / log in with phone number (Firebase Auth)
- Separate **Renter** and **Owner** roles
- Edit profile, avatar color, theme, keep-me-signed-in
- License / government ID upload, owner verification
- Payment methods (renter) and payout methods + QR (owner)
- Terms, Privacy Policy, and delete account

### Vehicle marketplace (renter)
- Browse motorcycles and cars with photos, specs, price per day, and location
- Search, filters, sort, favorites, and “available on my dates”
- Vehicle detail with gallery, reviews, and message owner
- Slide-to-book flow with terms, license check, and payment choice

### Owner listings
- Add / edit / delete vehicles with up to 5 photos and OR/CR
- Block unavailable dates
- Activate or deactivate a listing
- Owner dashboard with earnings and listed vehicles

### Bookings and trip flow
- Pending → Approved → Ongoing → Completed (or Declined / Cancelled)
- Pickup location, time, and renter PIN verification
- Condition photos at pickup and return
- Security deposit, late fee, and optional deductions
- Rental extension requests
- Payment proof upload and owner confirmation
- Receipt view and PDF share
- Ratings for vehicle, owner, and renter

### Chat and notifications
- Real-time conversations tied to a vehicle / booking
- Unread badges on the Messages tab
- Report and block users
- In-app notification list and Dynamic Island–style drop while the app is open

### Technical stack
- **UI:** SwiftUI (MVC controllers + services)
- **Backend:** Firebase Auth + Cloud Firestore (with security rules)
- **Photos:** stored in Firestore documents (Spark-plan friendly)
- **Platform:** iOS 17+, iPhone

## Screenshots

Full feature set captured from the running SwiftUI simulator (`docs/screenshots/`):

| # | File | Feature |
|---|---|---|
| 01 | `01-welcome.png` | Welcome / brand intro |
| 02 | `02-login.png` | Login (phone + role) |
| 03 | `03-signup.png` | Create account + Terms |
| 04 | `04-renter-home.png` | Renter home browse |
| 05 | `05-all-vehicles.png` | All vehicles / filters |
| 06 | `06-vehicle-detail.png` | Vehicle detail + gallery |
| 07 | `07-booking.png` | Booking form + payment choice |
| 08 | `08-payment.png` | Payment / proof flow |
| 09 | `09-confirmation.png` | Booking confirmation |
| 10 | `10-my-bookings.png` | My bookings list |
| 11 | `11-trip-tracking.png` | Trip tracking timeline |
| 12 | `12-receipt.png` | Receipt / PDF |
| 13 | `13-rate-trip.png` | Rate trip |
| 14 | `14-messages.png` | Messages inbox |
| 15 | `15-chat.png` | Chat thread |
| 16 | `16-notifications.png` | In-app notifications |
| 17 | `17-profile-renter.png` | Renter profile |
| 18 | `18-edit-profile.png` | Edit profile |
| 19 | `19-payment-methods.png` | Payment methods |
| 20 | `20-license-upload.png` | License / ID upload |
| 21 | `21-saved-vehicles.png` | Saved / favorites |
| 22 | `22-notification-settings.png` | Notification settings |
| 23 | `23-help.png` | Help |
| 24 | `24-terms.png` | Terms of use |
| 25 | `25-privacy.png` | Privacy policy |
| 26 | `26-about.png` | About |
| 27 | `27-owner-dashboard.png` | Owner dashboard |
| 28 | `28-add-vehicle.png` | Add vehicle |
| 29 | `29-edit-vehicle.png` | Edit vehicle |
| 30 | `30-booking-requests.png` | Booking requests |
| 31 | `31-owner-messages.png` | Owner messages |
| 32 | `32-owner-chat.png` | Owner chat |
| 33 | `33-owner-profile.png` | Owner profile |
| 34 | `34-verify-account.png` | Owner verification |
| 35 | `35-owner-payout.png` | Payout methods |
| 36 | `36-owner-notifications.png` | Owner notifications |

## Source code

GitHub: **https://github.com/Prncepe/SakayNa**

The repository contains the full SwiftUI app, Firebase rules/indexes, overview, screenshots, and test script.
