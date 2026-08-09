# Dapzo — Customer App

Flutter customer app for local food + meat delivery, built to the Dapzo
master spec: brand theme, phone/OTP-only auth, Firestore-driven catalog,
Cloudinary images, COD + Cloudflare-Worker-backed online payment, live order
tracking. No Wallet, no Refer & Earn, no Google login, no static catalog.

## What's included

```
lib/
├── main.dart, firebase_options.dart (placeholder — see setup)
├── theme/            Dapzo colors, Poppins type scale, ThemeData
├── models/           Product, CartItem, Address, Order, User, Shop, Payment
├── services/         Auth, Firestore, Product, Cart, Address, Order,
│                     Payment (Cloudflare Worker client), Cloudinary,
│                     Location (delivery-radius check), Notification
├── state/            AppState (user/mode/address) via Provider
├── screens/
│   ├── auth/         splash, onboarding, phone login, OTP, profile setup
│   ├── location/     select location, add address + radius check, saved addresses
│   ├── home/         home (food/meat switch, categories, search entry), category grid
│   ├── product/      product detail (weights, qty, instructions)
│   ├── cart/         cart, checkout (coupon, COD/Online, place order)
│   ├── orders/       orders list (tabs), order tracking timeline
│   └── profile/      profile, favorites, offers, notifications
└── widgets/           product_card, search_bar
```

This is a complete, wired-up **scaffold**: every screen in the spec's flow
(splash → onboarding → phone/OTP → profile setup → home → cart → checkout →
tracking → profile) is implemented and navigable, reading live from
Firestore with no hard-coded products/categories/prices. It has **not**
been compiled here — this sandbox has no Flutter SDK on its allowed
network — so budget one pass of `flutter analyze` locally to catch any
typos before you run it.

## Setup (run locally)

1. **Get the SDKs**
   ```bash
   flutter pub get
   dart pub global activate flutterfire_cli
   flutterfire configure   # replaces lib/firebase_options.dart with real values
   ```

2. **Enable Firebase products**: Authentication → Phone; Firestore; Cloud
   Messaging. Add a test phone number + fixed OTP in the Firebase console
   while developing, so you're not burning real SMS.

3. **Cloudinary**: create an *unsigned* upload preset scoped to your
   `meet_dapzo/` folder, then put your cloud name + preset name into
   `lib/services/cloudinary_service.dart`. Never put the Cloudinary API
   *secret* in the app — signed uploads/deletes belong in a backend
   function, same as payments.

4. **Cloudflare Worker (payments)**: deploy a Worker that holds your
   payment gateway secret and exposes `/create-session` and
   `/verify-payment` (shapes assumed in `lib/services/payment_service.dart`
   — adjust to your gateway's actual API). Put its URL in that file.

5. **Firestore collections** to seed (see spec sections 26–31 for fields):
   `products`, `categories`, `shops`, `offers`, `coupons`, `delivery_zones`,
   and per-user `users/{uid}/addresses`, `/favorites`, `/notifications`.
   `products` docs should also carry a lowercase `nameLowercase` field —
   the search query in `product_service.dart` filters on it.

6. **Firestore security rules** — starter, tighten before production:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /products/{id}      { allow read: if true; allow write: if false; }
       match /categories/{id}    { allow read: if true; allow write: if false; }
       match /offers/{id}        { allow read: if true; allow write: if false; }
       match /coupons/{id}       { allow read: if true; allow write: if false; }
       match /shops/{id}         { allow read: if true; allow write: if false; }
       match /users/{uid} {
         allow read, write: if request.auth != null && request.auth.uid == uid;
         match /{sub=**} {
           allow read, write: if request.auth != null && request.auth.uid == uid;
         }
       }
       match /orders/{id} {
         allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
         allow read:   if request.auth != null && request.auth.uid == resource.data.userId;
         allow update, delete: if false; // status changes come from shop/admin backend only
       }
     }
   }
   ```

7. Run it:
   ```bash
   flutter clean && flutter pub get && flutter analyze && flutter run
   ```

## What still needs a backend

Per the spec, none of these belong in the Flutter app, and aren't included
here — they're server-side work (Cloud Functions or your own backend):

- Re-validating delivery radius and pricing when an order is *created*
  (the client-side check is UX-only, per section 29).
- The Cloudflare Worker itself (payment gateway secret + verification).
- Order status transitions (`shopAccepted` → `preparing` → … ) — those
  come from the Shop and Delivery apps, not the customer app.
- Signed/authenticated Cloudinary uploads if you ever need customer-side
  image uploads (currently only unsigned preset uploads are wired up).

## Next phases

The spec's phases 15–24 (shop/delivery-partner connection, real backend
notifications sending, favorites write-path, offers admin, hardened
security rules, testing) are natural follow-ups once this compiles clean
against your real Firebase project. Happy to build any of those next.
