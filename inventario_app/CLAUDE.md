# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter run -d ios          # iOS simulator
flutter run -d android      # Android emulator
flutter analyze             # must stay at 0 issues
flutter test                # all green
flutter pub get
```

No codegen: no `build_runner`, Freezed, json_serializable or Isar. Models are hand-written.

## Architecture

**OmniBiz Automation** is an offline Flutter POS/inventory app for small businesses (retail, F&B, generic). Multi-store (sucursales) on one device. Light + dark themes (user-selectable in Ajustes: Sistema/Claro/Oscuro), Spanish UI and comments, Material 3 + Outfit font (bundled in `assets/fonts/outfit/`, OFL — no runtime font fetching).

### Pattern: Clean Architecture + Feature-First

```
lib/
├── main.dart                      # AppDatabaseOpener (encrypted DB) → ensureStoresMigrated → ProviderScope; DatabaseErrorApp if locked
├── app/router/                    # GoRouter + auth redirect guard, AppRoutes constants
├── core/
│   ├── database/                  # app_database (open/encrypt/migrate), database_encryption (AES-GCM codec + key),
│   │                              # money_migration (schema v2), store_migration, database_error_app
│   ├── design_system/             # tokens, theme, atomic components (barrel: design_system.dart)
│   ├── error/                     # sealed Failure hierarchy + ErrorMapper (Failure → user message)
│   ├── security/pin_hasher.dart   # PBKDF2-HMAC-SHA256 PIN hashing
│   ├── utils/                     # AppResult, AppConstants, AppLogger, Money, formatters, validators
│   └── receipt_service.dart       # PDF receipt (pdf/printing)
├── shared/
│   ├── providers/                 # databaseProvider + repository DI, currentStore, currency, businessType, themeMode
│   └── widgets/                   # SalesChart, BarcodeScannerButton
└── features/
    ├── auth/          # PIN + biometrics, LockScreen, SplashScreen, AuthNotifier
    ├── onboarding/    # business type selection
    ├── dashboard/     # KPI overview
    ├── inventory/     # products + categories CRUD
    ├── sales/         # POS (pos/), cart, checkout, history/
    ├── customers/     # customers + debt (fiado) management
    ├── analytics/     # KPIs, top products, debt summary
    ├── stores/        # sucursales CRUD
    └── settings/      # currency, store switcher
```

Each feature: `domain/entities/` → `domain/repositories/` (abstract interface) → `domain/usecases/` (only sales today) → `data/models/` (plain classes with `toMap()` / `static fromMap(id, map)`) → `data/mappers/` (extension methods model ↔ entity) → `data/repositories/` (`Sembast*Repository`) → `presentation/providers/` → `presentation/screens/`.

### Data layer: sembast

- One sembast `Database`, **encrypted at rest** (`AppConstants.encryptedDbName`), injected via `databaseProvider` (overridden in `main.dart`). `AppDatabaseOpener` (`core/database/app_database.dart`):
  - Codec `aesGcmSembastCodec`: AES-256-GCM per record, random 12-byte nonce (package `cryptography`). The 32-byte key lives in `FlutterSecureStorage` (`DatabaseKeyStore`, key `omni_db_key_v1`), generated on first run.
  - Legacy plaintext `omnibiz.db` is migrated once: export → import into `omnibiz_enc.db.tmp` with the codec → reopen and verify per-store counts → atomic rename → delete plaintext.
  - Encrypted file present but key missing/wrong → `AppDatabaseLocked` → `DatabaseErrorApp` (Reintentar / Empezar de cero, which renames the unreadable file to `*.unreadable-<ts>`, never deletes it). Never create a new key while an encrypted file exists.
- Schema version `appDbVersion` (`core/database/money_migration.dart`), migrated in `onVersionChanged` (runs inside sembast's open transaction): **v1** doubles → **v2** int minor units + `currencyCode` per sale. Bump the version and add a step there for future data migrations.
- **Money**: every amount (`price`, `costPrice`, `unitPrice`, `totalPrice`, `totalAmount`, `taxAmount`, `discountAmount`, `totalDebt`) is an `int` in cents (fixed scale 100 for every currency). Parse user input with `Money.parse`, prefill fields with `Money.toInput`, format with `ref.formatMoney(cents)` / `CurrencyFormatter`. Never use `double` for money arithmetic.
- Each sale stores `currencyCode`; show sale amounts with `ref.formatSaleMoney(cents, sale.currencyCode)` (receipts use it too). Changing the currency in settings does not convert anything (the settings screen warns).
- Sales are never loaded in full: `salesInRangeProvider(lastDaysRange(n))` (half-open `[from, to)`, midnight boundaries → stable family key) for dashboard/analytics/chart, and `salesHistoryProvider(query)` (cursor pagination by `createdAt`, page = `AppConstants.listPageSize`, `loadMore()`) for the history. After a sale invalidate both.
- Stores (`intMapStoreFactory`): `products`, `categories`, `sales` (items embedded), `customers`, `stores`. Keys are sembast-generated ints (start at 1; `id == 0` on an entity means "new").
- Every per-store record has `storeId`. Queries filter by `storeId`; repository methods take `{required int storeId}` (fakes must keep it `required`). **Never write `storeId: 0`** — forms disable save until `currentStoreProvider` is loaded.
- New store: add it in the repository and, if legacy records need it, in `store_migration.dart`.
- Deleting a store with products/sales/customers throws `StoreInUseException`; its categories are deleted in the same transaction.

### Encrypted backup

- `core/backup/`: `BackupCodec` (`.omnibak`: PBKDF2-HMAC-SHA256 from a user backup password + AES-256-GCM, header as AAD, gzip, runs in an `Isolate`) and `BackupService` (`create` = `exportDatabase`; `restore` = decode → import into a **memory** DB → run `onAppDbVersionChanged` + `ensureStoresMigrated` → replace every store of the real DB in **one** `db.transaction`).
- The backup key never comes from the Keychain (that would tie it to one phone). Settings in secure storage (PIN, currency, business type, theme) are not in the backup.
- When you bump `appDbVersion`, older backups keep working only if the new migration step lives in `onAppDbVersionChanged`. Backups newer than the app are rejected (`BackupTooNewException`).
- UI: `features/settings/presentation/widgets/backup_section.dart`; after restoring, invalidate every data provider and set `currentStoreProvider` to `RestoreSummary.defaultStoreId`.

### Critical: atomic checkout

Always check out through `ProcessSaleUseCase` (`processSaleUseCaseProvider`) — never touch stock or debt from the UI. The use case validates (store selected, non-empty cart, quantities, **Fiado requires a customer**), recomputes totals from the lines, then calls `SaleRepository.commitSale`, which in **one `db.transaction`** reads the products, validates aggregated quantities per product and `storeId`, validates the customer (exists, same store), updates stock, adds debt for Fiado and inserts the sale, returning it with its generated id. Rejections are thrown inside the transaction (`SaleRejection` subclasses → rollback) and mapped to `StockFailure` / `NotFoundFailure` / `ValidationFailure`. Any new multi-record write must follow the same pattern. Payment methods: `PaymentMethods.cash/card/credit` (no string literals). Debt payments go through `CustomerRepository.registerPayment` (validated in a transaction: `> 0` and `<= debt`).

### State management: Riverpod (no codegen)

`Notifier` for synchronous/in-memory state, `AsyncNotifier` for repository-backed lists (use `.when()`). Per-store lists `ref.watch(currentStoreProvider)` so they reload when the store changes; the cart is cleared on store change.

| Provider | Type | Manages |
|---|---|---|
| `databaseProvider` | Provider | sembast `Database` |
| `product/sale/customer/storeRepositoryProvider` | Provider | repository impls |
| `processSaleUseCaseProvider` | Provider | atomic checkout |
| `currentStoreProvider` | Notifier<int?> | active store id (secure storage) |
| `currencyProvider` / `businessTypeProvider` / `themeModeProvider` | Notifier | settings (secure storage; theme read in `main` before `runApp`) |
| `productsProvider` / `categoriesProvider` | AsyncNotifier | per-store lists |
| `salesInRangeProvider` | FutureProvider.autoDispose.family | sales in `[from, to)` |
| `salesHistoryProvider` | AsyncNotifier.autoDispose.family | paginated history (`loadMore`) |
| `customersProvider` / `storesProvider` | AsyncNotifier | lists |
| `cartProvider` | Notifier<PosSessionState> | in-memory cart + selected customer |
| `authProvider` | Notifier<AuthState> | initial/noPinSet/locked/authenticated + lockout |

### Error handling

`sealed class Failure` (`core/error/failures.dart`): `DatabaseFailure`, `ValidationFailure`, `StockFailure`, `NotFoundFailure`. Use cases return `AppResult<T>` (`sealed`: `AppSuccess(data)` / `AppFailure(failure)`, with `.when`, `dataOrNull`, `failureOrNull`). Show messages via `ErrorMapper.toMessage`.

### Navigation

GoRouter (`app_router.dart`, paths in `AppRoutes`). The redirect guard reads `authProvider.status`: `initial` → `/splash` only (nothing else reachable), `noPinSet` → `/auth/setup`, `locked` → `/auth`, `authenticated` → leaves auth/splash for dashboard or onboarding.

```
/splash     → SplashScreen
/onboarding → OnboardingScreen
/auth       → LockScreen
/auth/setup → LockScreen(setupMode: true)
/dashboard  → DashboardScreen (?type=retail|fnb|generic)
  /dashboard/inventory/add  → AddProductScreen
  /dashboard/inventory/:id  → AddProductScreen (edit)
  /dashboard/categories     → CategoriesScreen
  /dashboard/pos            → POSScreen (?type=...)
  /dashboard/customers      → CustomersScreen
  /dashboard/sales/history  → SalesHistoryScreen
  /dashboard/analytics      → AnalyticsScreen
  /dashboard/settings       → SettingsScreen
  /dashboard/stores         → StoresScreen
```

### Auth

- PIN stored in `FlutterSecureStorage` as `pbkdf2_sha256$<iter>$<salt b64>$<hash b64>` (random 16-byte salt, `AppConstants.pinHashIterations` = 100k, run in an isolate, constant-time compare). Legacy unsalted SHA-256 hashes are verified once and re-stored in the new format (`PinHasher.needsRehash`).
- Failed attempts + `lockedUntil` persisted in secure storage; after `AppConstants.maxPinAttempts` failures the lockout starts at `pinLockoutBase` and doubles per extra failure (capped at `pinLockoutMax`). The lock screen shows the countdown. Biometric success clears it.
- `AuthNotifier._init` fails closed: storage errors → `locked`.
- App auto-locks after `AppConstants.lockAfter` in background.

### Design system

All UI imports `core/design_system/design_system.dart`. No inline `Color(0x…)`/`Colors.*`, `TextStyle(fontSize: …)` or magic sizes outside `tokens/`.

- **Colors** `OmniPalette` (`tokens/omni_colors.dart`, the only place with color values): a `ThemeExtension` with `OmniPalette.light` / `OmniPalette.dark` (same identity: violet-indigo brand `#5B5BF7` → `#8B5CF6`; blue-graphite dark surfaces, cool off-white light). Read it with **`context.colors`** (never static colors). Fields: `bg`, `bgSurface`, `bgRaised`, `bgPanel`, `bgModal`, `bgPopup`, `bgSunken`; `border{Subtle,Muted,Weak}`; `text{Primary,Secondary,Muted,Disabled}`; `primary` (fill), `primaryText` (brand as text, AA), `primaryBg`, `onPrimary`, `brandEnd`; `success/warning/danger/info` + `*Bg` tints (AA on their tint in both themes), `dangerFill`; accents `purple/orange/teal`; `snackBg/onSnack`, `scrim`, `shadow`; helpers `brandGradient`, `cardShadow`, `floatingShadow`, `glow(color)`, `toneFg/toneBg(OmniTone)`.
- **Typography** `OmniTypography` (colorless base scale) → use **`context.text.*`** (`displayLg/Md`, `headingLg/Md/Sm`, `bodyLg/Md/Sm`, `label`, `caption`, `overline`, `micro`, `moneySm/moneyMd`, `priceLg/priceXl/priceHero`, `keypad`). Money/quantities use tabular figures (money/price styles already do; `.tabular` extension otherwise).
- **Spacing** `OmniSpacing`; **Radius** `OmniRadius` (+ `sheetTop`); **Sizes/motion** `OmniSizes` (icons, controls, avatars), `OmniMotion` (durations/curves); **Breakpoints** `OmniBreakpoints` + `OmniResponsiveCenter`, `context.isTablet`.
- **Atoms**: `OmniButton` (primary/brand(gradient CTA)/secondary/ghost/danger; sm/md/lg/xl; `loading`, `trailing`), `OmniPressable`, `OmniTextField` (`tabularDigits`), `OmniBadge`, `OmniTag` (status pill), `OmniAvatar`, `OmniIconAvatar`, `OmniSelectableChip`, `OmniInputChip`, `OmniDragHandle`, `OmniSkeleton`/`OmniShimmer`/`OmniSkeletonTile|List|Card|Grid`.
- **Molecules**: `OmniCard`, `OmniSectionHeader`, `OmniSearchBar`, `OmniStatCard`, `OmniEmptyState`/`OmniStateIllustration`, `OmniErrorState`, `OmniLoadingOverlay`, `OmniDialog` + `OmniDialogActions`, `OmniConfirmDialog.show(...)`, `OmniBanner`, `showOmniSheet` + `OmniSheetBody`, snackbars via `ScaffoldMessenger.of(context).showOmni(msg, tone:)`.
- Theme: `OmniTheme.light()/dark()` theme every Material component from the palette; `MaterialApp.themeMode` = `themeModeProvider`. Loading states use skeletons, not spinners. PDF receipts use `pdf` package units, not these tokens.

### Tests

`test/` mirrors `lib/`. Repository and checkout tests run against `databaseFactoryMemory` (real transactions); encryption/opener tests use `databaseFactoryIo` in a temp dir; auth and key tests use `FlutterSecureStorage.setMockInitialValues` and fake `AuthRepository` + `authClockProvider`.

## App identity & release signing

- Android `applicationId`/`namespace` and iOS/macOS bundle id: `com.omnibiz.pos` (`MainActivity` in `android/app/src/main/kotlin/com/omnibiz/pos/`). Display name: OmniBiz.
- Release signing reads `android/key.properties` (gitignored, as are `*.jks`/`*.keystore`). If the file is missing, release builds fall back to the **debug** key and Gradle prints a `WARNING` — such an APK must not be published.
- Create the upload keystore once (keep it and its passwords backed up: losing it means you can no longer update the app):

```bash
keytool -genkey -v -keystore ~/omnibiz-upload.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

`android/key.properties`:

```properties
storePassword=<store password>
keyPassword=<key password>
keyAlias=upload
storeFile=/Users/<you>/omnibiz-upload.jks   # absolute, or relative to android/app
```

Then `flutter build apk --release` / `flutter build appbundle`.
