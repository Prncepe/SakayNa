# SakayNa two-simulator test script

Two people use the app at the same time: **Maria** rents, **Juan** owns.
Each step says who does it. "Check" lines are what should happen on the
*other* phone without refreshing.

| Account | Phone | Password | Role |
|---|---|---|---|
| Maria | 09171234567 | password | Renter |
| Juan | 09181234567 | password | Owner |

## 0. Setup (once)

1. Firebase console > Firestore Database > **Rules**: paste all of
   `firebase/firestore.rules` and click **Publish**.
2. Firebase console > Firestore Database > **Indexes** > **Single field** >
   **Add exemption**: collection group `bookedDays`, field `date`, enable
   **Ascending** with scope **Collection group**. (Same as
   `firebase/firestore.indexes.json`.) If you skip this, the first date search
   prints a link in the Xcode console that creates it for you.
3. Xcode: run on **iPhone 15** (Simulator A, Juan). Stop, pick **iPhone 15 Pro**
   (Simulator B, Maria) and run again. Re-open the app on A from its home
   screen. Both simulators now run the app.
4. If the accounts already exist from earlier tests, either log in or delete
   them in Authentication + Firestore and start fresh.

## 1. Accounts

| # | Who | Do | Check |
|---|---|---|---|
| 1.1 | Juan (A) | Sign up > **List My Vehicle**, phone 09181234567, password `password`, accept terms | Lands on Owner Dashboard |
| 1.2 | Maria (B) | Sign up > **Rent a Vehicle**, phone 09171234567, password `password` | Lands on Home, shows "No vehicles found" |
| 1.3 | Maria (B) | Sign up again with 09171234567 | Alert "This phone number is already registered." |
| 1.4 | Maria (B) | Log out, log in with wrong password | Alert about wrong phone or password |
| 1.5 | Maria (B) | Log in correctly | Spinner, then Home |

## 2. Owner profile and listing

| # | Who | Do | Check |
|---|---|---|---|
| 2.1 | Juan | Profile > Verify my account > upload any photo as ID | Verified badge appears |
| 2.2 | Juan | Profile > Payment methods: GCash 09181234567, upload a QR photo, **Save Methods** | Saved |
| 2.3 | Juan | **Add Vehicle**: name, price, city, 2+ photos, OR/CR photo, agree to owner terms, **Save Vehicle** | "Saving…" spinner, vehicle under "Your vehicles" |
| 2.4 | Maria | (no action) | The new vehicle appears on Home within a few seconds |
| 2.5 | Juan | Edit the vehicle, block 1 date next week, save | Maria: that date shows as blocked on Booking |

## 3. Chat

| # | Who | Do | Check |
|---|---|---|---|
| 3.1 | Maria | Open the vehicle > **Message Owner** > send "Hi, available?" | Juan: Messages tab badge **1**, island drop "New Message" |
| 3.2 | Juan | Open Messages > chat | Badge clears; message is there |
| 3.3 | Juan | Reply "Yes!" | Maria sees it appear live in the open chat |

## 4. Booking

| # | Who | Do | Check |
|---|---|---|---|
| 4.1 | Maria | Profile > ID / License: upload a license photo | Saved |
| 4.2 | Maria | Home > pick dates (include the blocked date) | Vehicle hidden ("Checking availability…" first) |
| 4.3 | Maria | Pick dates without the blocked day > vehicle > **Slide to Book** > choose GCash > agree to terms > slide to confirm | Confirmation screen |
| 4.4 | Juan | (no action) | Island "New Booking"; bell shows it; **Booking Requests** shows Pending with Maria's license |
| 4.5 | Maria | Try to book the **same vehicle and dates** again | Alert: dates no longer available |
| 4.6 | Juan | **Approve** > fill location and time > **Confirm Approve** | Maria: island "Booking Approved", trip shows Approved + pickup PIN |
| 4.7 | Maria | Trip > pay: upload a proof photo + reference > **Submit proof** | Juan: request card shows the proof |
| 4.8 | Juan | **Payment received** | Maria: payment status Paid |

## 5. Pickup, extension, return

| # | Who | Do | Check |
|---|---|---|---|
| 5.1 | Juan | **Mark as Picked Up** > enter a wrong PIN | Error, not accepted |
| 5.2 | Juan | Enter Maria's PIN > **Confirm PIN** > add pickup photos, fuel > confirm | Maria: status Ongoing, pickup photos visible |
| 5.3 | Maria | **Extend rental** +1 day > **Request extension** | Juan: Extension request card |
| 5.4 | Juan | **Approve** extension | Maria: end date +1 day; that day is now taken for others |
| 5.5 | Juan | **Mark as Returned** > photos > confirm > add a deduction or **Skip** | Maria: Completed, deposit card updated |
| 5.6 | Maria | Rate the trip (stars + comment) | Juan: vehicle rating/review count updates; review shows on the listing |
| 5.7 | Juan | **Rate Renter** | Maria's renter rating shows on future requests |
| 5.8 | Maria | **View Receipt** > share PDF | PDF opens |

## 6. Cancel, decline, block, report

| # | Who | Do | Check |
|---|---|---|---|
| 6.1 | Maria | Book new dates, then **Cancel Booking** | Juan: island "Booking Cancelled"; dates free again |
| 6.2 | Maria | Book again; Juan **Decline** | Maria notified; dates free again |
| 6.3 | Maria | Chat > menu > **Report** > choose a reason | "Your report was sent" (Firestore > `reports` has a doc) |
| 6.4 | Juan | Chat > menu > **Block** | Chat disappears for Juan; Maria can no longer send |

## 7. Sessions and offline

| # | Who | Do | Check |
|---|---|---|---|
| 7.1 | Maria | Close the app completely, reopen | "Signing you in…" then Home (Keep me signed in on) |
| 7.2 | Juan | Mac Wi‑Fi off, open screens | Cached data still shows |
| 7.3 | Juan | While offline edit vehicle price; turn Wi‑Fi on | Maria sees the new price |
| 7.4 | Both | Log out | Lists clear; logging in as the other account shows only their data |

## 8. Security spot checks (Firebase console > Firestore > Rules > Rules Playground)

| # | Simulate | Expected |
|---|---|---|
| 8.1 | `get /users/{mariaUid}/private/license` as Juan's uid | Denied |
| 8.2 | `get /bookings/{id}/private/pin` as Juan's uid | Denied |
| 8.3 | `get /conversations/{id}` as a third uid | Denied |
| 8.4 | `list /reports` as anyone | Denied |
| 8.5 | Unauthenticated `get /vehicles/{id}` | Denied |

## 9. Delete account (do last)

| # | Who | Do | Check |
|---|---|---|---|
| 9.1 | Maria | Profile > **Delete my account**, type DELETE (enter password if asked) | Back to Welcome; Juan's chats with Maria are gone; past bookings show "Deleted user" |
| 9.2 | Maria | Try to log in again | Wrong phone or password |

## Known limits (explain in the demo)

- No push notifications when the app is fully closed (needs APNs + Cloud Functions).
- Rating counters, prices, and notification sending are trusted from the phone; a Cloud Function would enforce them.
- Photos are stored in Firestore (≤ 700 KB each) because the free Spark plan has no Storage.
