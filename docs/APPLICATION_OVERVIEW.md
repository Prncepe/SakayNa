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

Folder: **`docs/screenshots/`** (numbered in app-flow order for PDF).

### A. Auth
| # | File | Screen |
|---|---|---|
| 01 | `01-welcome.png` | Welcome / get started |
| 02 | `02-signup.png` | Create account |
| 03 | `03-login.png` | Log in |

### B. Renter — find & book
| # | File | Screen |
|---|---|---|
| 04 | `04-renter-home.png` | Home browse |
| 05 | `05-all-vehicles.png` | All vehicles / filters |
| 06 | `06-vehicle-detail.png` | Vehicle detail |
| 07 | `07-saved-vehicles.png` | Saved / favorites |
| 08 | `08-booking.png` | Booking form |
| 09 | `09-payment.png` | Payment |
| 10 | `10-confirmation.png` | Confirmation |

### C. Renter — trip
| # | File | Screen |
|---|---|---|
| 11 | `11-my-bookings.png` | My bookings |
| 12 | `12-trip-tracking.png` | Trip tracking |
| 13 | `13-receipt.png` | Receipt |
| 14 | `14-rate-trip.png` | Rate trip |

### D. Renter — chat & alerts
| # | File | Screen |
|---|---|---|
| 15 | `15-messages.png` | Messages inbox |
| 16 | `16-chat.png` | Chat thread |
| 17 | `17-notifications.png` | Notifications |

### E. Renter — profile & settings
| # | File | Screen |
|---|---|---|
| 18 | `18-profile-renter.png` | Profile |
| 19 | `19-edit-profile.png` | Edit profile |
| 20 | `20-license-upload.png` | License / ID |
| 21 | `21-payment-methods.png` | Payment methods |
| 22 | `22-notification-settings.png` | Notification settings |
| 23 | `23-help.png` | Help |
| 24 | `24-terms.png` | Terms |
| 25 | `25-privacy.png` | Privacy |
| 26 | `26-about.png` | About |

### F. Owner flow
| # | File | Screen |
|---|---|---|
| 27 | `27-owner-dashboard.png` | Dashboard |
| 28 | `28-add-vehicle.png` | Add vehicle |
| 29 | `29-edit-vehicle.png` | Edit vehicle |
| 30 | `30-booking-requests.png` | Booking requests |
| 31 | `31-owner-messages.png` | Messages |
| 32 | `32-owner-chat.png` | Chat |
| 33 | `33-owner-notifications.png` | Notifications |
| 34 | `34-owner-profile.png` | Profile |
| 35 | `35-verify-account.png` | Verify account |
| 36 | `36-owner-payout.png` | Payout methods |

## Source code

GitHub: **https://github.com/Prncepe/SakayNa**

The repository contains the full SwiftUI app, Firebase rules/indexes, overview, screenshots, and test script.
