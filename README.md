# OmniBiz

**Offline point of sale, inventory and customer credit for small businesses** (corner stores, restaurants and other shops), built with Flutter for Android and iOS.

Everything runs on the device: no backend, no accounts, no internet required. The business data lives in a local database encrypted with AES-256-GCM, and access is protected with a PIN and biometrics.

[![Flutter CI](https://github.com/Marlon-Trujillo-Jaramillo/omnibiz/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/Marlon-Trujillo-Jaramillo/omnibiz/actions/workflows/flutter-ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-Riverpod-02569B)
![Tests](https://img.shields.io/badge/tests-195%20passing-brightgreen)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-lightgrey)

## Features

- **Point of sale** with a cart, quantities, discounts and **atomic checkout**: stock, the sale and the customer's balance are written together or not at all.
- **Inventory** with products, categories, stock alerts and a **QR / barcode scanner** using the camera.
- **Customers and credit ("fiado")**: sell on credit, register payments and see each customer's balance.
- **PDF receipts** ready to print or share.
- **Sales history and analytics** with charts.
- **Multiple stores (branches)** on the same device.
- **Encrypted backup and restore**: export everything to a file protected with a backup password (PBKDF2 + AES-256-GCM), share it to Drive, mail or WhatsApp, and restore it on any phone.
- **Onboarding by business type** and light / dark themes.

## Engineering highlights

| Topic | How it's done |
|---|---|
| Architecture | Clean Architecture per feature (`domain → data → presentation`), Riverpod 2 without code generation, go_router with route guards |
| Encrypted storage | sembast database encrypted with **AES-256-GCM**; the key lives in the Keychain / Keystore through `flutter_secure_storage`; versioned, safe migrations |
| Exact money | All amounts are integers in **cents**, so totals never drift from floating-point rounding |
| Access security | PIN derived with **PBKDF2**, progressive lockout after failed attempts, biometric unlock |
| Consistency | Checkout is a single transaction: no half-written sales if the app is killed mid-operation |
| Backups | Portable `.omnibak` files: key derived from a backup password (PBKDF2-HMAC-SHA256, 210k iterations), AES-256-GCM with the header as AAD, KDF in an isolate. Restore migrates old schemas in an in-memory copy, then swaps all data in one transaction |
| Fully offline | Fonts and assets are bundled; the app never calls the network |
| Quality | **195 tests** and `flutter analyze` with no issues, enforced by GitHub Actions |

The full technical and functional analysis (architecture, data model, security flow, every feature, risks and recommendations) is in [`inventario_app/docs/ANALISIS_TECNICO.md`](inventario_app/docs/ANALISIS_TECNICO.md) (Spanish).

## Tech stack

Flutter · Dart · Riverpod · go_router · sembast · cryptography (AES-256-GCM) · crypto (PBKDF2 / HMAC) · flutter_secure_storage · local_auth · mobile_scanner · pdf / printing · fl_chart

## Project structure

```
inventario_app/lib/
├── app/           app widget and router (route guards)
├── core/          encrypted database, design system, errors, security, utilities
├── features/      analytics, auth, customers, dashboard, inventory, onboarding, sales, settings, stores
│   └── <feature>/ domain → data → presentation
└── shared/        shared providers and widgets
```

## Running it

```bash
cd inventario_app
flutter pub get
flutter run          # Android or iOS device / emulator
flutter test         # 195 tests
flutter analyze
```

## Roadmap

- Automatic backup reminders
- Stock movements with a reason (purchase, adjustment, loss) and payment history for customers
- Optional cloud sync between devices

## Author

**Marlon Trujillo Jaramillo**, Software Developer, Medellín, Colombia
[GitHub](https://github.com/Marlon-Trujillo-Jaramillo) · [LinkedIn](https://www.linkedin.com/in/marlon-trujillo-5b661734a/)
