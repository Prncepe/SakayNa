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

Clear screenshots of the running SwiftUI app are in `docs/screenshots/`:

1. **Welcome** — brand intro and get-started slide  
2. **Login** — phone/password auth, renter vs owner role  
3. **Owner dashboard** — earnings, listed vehicles, add vehicle  
4. **Renter home** — search, dates, city/type filters, vehicle cards  

## Source code

GitHub: **https://github.com/Prncepe/SakayNa**

The repository contains the full SwiftUI app, Firebase rules/indexes, overview, screenshots, and test script.
