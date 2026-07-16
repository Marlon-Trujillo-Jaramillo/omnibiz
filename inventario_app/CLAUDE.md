# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app (iOS simulator)
flutter run -d ios

# Run the app (Android emulator)
flutter run -d android

# Analyze code (must stay at 0 issues)
flutter analyze

# Run tests
flutter test

# Regenerate Isar schema files (*.g.dart) after modifying any @collection model
dart run build_runner build --delete-conflicting-outputs

# Get dependencies
flutter pub get
```

## Architecture

**OmniBiz Automation** is a Flutter POS/inventory app for small businesses (retail, F&B, generic). Single-tenant. Dark-only UI, Spanish language, Material 3 + Outfit font (via GoogleFonts).

### Pattern: Clean Architecture + Feature-First

```
lib/
├── app/router/app_router.dart     # GoRouter + auth redirect guard
├── core/
│   ├── design_system/             # Tokens, theme, atomic components
│   ├── error/failures.dart        # sealed class Failure hierarchy
│   └── utils/                     # CurrencyFormatter, DateFormatter, FormValidators
├── shared/
│   ├── providers/database_provider.dart  # isarProvider + repository DI
│   └── widgets/                          # SalesChart, BarcodeScannerButton
└── features/
    ├── auth/          # PIN + biometric auth (LockScreen, AuthNotifier)
    ├── onboarding/    # Business type selection
    ├── dashboard/     # KPI overview (OmniStatCard grid)
    ├── inventory/     # Products + Categories CRUD
    ├── sales/         # POS (pos/ split), cart, checkout, history/
    ├── customers/     # Customer + debt management
    └── analytics/     # KPI cards, top products, debt summary
```

Each feature follows: `domain/entities/` → `domain/repositories/` (abstract interface) → `domain/usecases/` → `data/models/` (Isar @collection) → `data/mappers/` → `data/repositories/` (Isar impl) → `presentation/providers/` (Riverpod AsyncNotifier) → `presentation/screens/`.

### State Management: Riverpod AsyncNotifier

All providers expose `AsyncValue<T>` (loading/error/data). Use `.when()` in widgets.

| Provider | Manages |
|---|---|
| `isarProvider` | Isar DB instance (overridden in main.dart ProviderScope) |
| `productRepositoryProvider` | ProductRepository impl |
| `saleRepositoryProvider` | SaleRepository impl |
| `customerRepositoryProvider` | CustomerRepository impl |
| `processSaleUseCaseProvider` | Checkout + stock deduction use case |
| `productsProvider` | List<ProductEntity> |
| `categoriesProvider` | List<CategoryEntity> |
| `salesProvider` | List<SaleEntity> |
| `cartProvider` | List<CartItemEntity> (in-memory) |
| `customersProvider` | List<CustomerEntity> |
| `authProvider` | AuthState (initial/noPinSet/locked/authenticated) |

### Design System

All UI must use `lib/core/design_system/design_system.dart` (barrel import). Never hardcode colors or text styles inline.

- **Colors**: `OmniColors.bg`, `OmniColors.bgSurface`, `OmniColors.primary`, `OmniColors.danger`, etc.
- **Spacing**: `OmniSpacing.xs/sm/md/base/lg/xl/xxl/xxxl` (4px scale)
- **Radius**: `OmniRadius.smAll / mdAll / lgAll / fullAll` (BorderRadius getters) or raw `OmniRadius.sm/md/lg/xl`
- **Typography**: `OmniTypography.headingLg/Md/Sm`, `.bodyLg/Md/Sm`, `.caption`, `.priceHero`
- **Atoms**: `OmniButton`, `OmniTextField`, `OmniBadge`, `OmniAvatar`, `OmniIconAvatar`, `OmniSelectableChip`, `OmniInputChip`
- **Molecules**: `OmniSearchBar`, `OmniStatCard`, `OmniEmptyState`, `OmniConfirmDialog.show(context, title:, body:, confirmLabel:, destructive:)`

### Navigation

GoRouter with named routes. Auth guard redirects based on `authProvider.status`. Routes:

```
/onboarding → OnboardingScreen
/auth       → LockScreen
/auth/setup → LockScreen(setupMode: true)
/dashboard  → DashboardScreen (query: ?type=retail|fnb|generic)
  /dashboard/inventory/add     → AddProductScreen
  /dashboard/inventory/:id     → AddProductScreen (edit mode)
  /dashboard/categories        → CategoriesScreen
  /dashboard/pos               → POSScreen (query: ?type=...)
  /dashboard/customers         → CustomersScreen
  /dashboard/sales/history     → SalesHistoryScreen
  /dashboard/analytics         → AnalyticsScreen
```

### Data Layer: Isar (local NoSQL)

Isar models live in `features/*/data/models/`. Each has a generated `*.g.dart` — never edit manually. Re-run `build_runner` after schema changes. Mappers convert between Isar models and domain entities via extension methods in `features/*/data/mappers/`.

Models: `ProductModel`, `CategoryModel` (`inventory/`), `SaleModel` + embedded `SaleItemModel` (`sales/`), `CustomerModel` (`customers/`).

Add new collection: create model in `features/<feature>/data/models/`, run `build_runner`, add schema to `Isar.open([...])` in `main.dart`.

### Auth

PIN is SHA-256 hashed and stored in `FlutterSecureStorage`. Biometric via `local_auth`. `AuthNotifier` exposes `setupPin / unlockWithPin / unlockWithBiometrics / lock`. The GoRouter redirect guard reads `authProvider.status` on every navigation event.

### Critical: ProcessSaleUseCase

`features/sales/domain/usecases/process_sale_usecase.dart` validates stock before deduction and handles Fiado (debt) payments. Always use this use case for checkout — never manipulate stock directly from the UI.

### Error Handling

Use the `sealed class Failure` hierarchy (`core/error/failures.dart`): `DatabaseFailure`, `ValidationFailure`, `StockFailure`, `NotFoundFailure`, `NetworkFailure`, `UnauthorizedFailure`, `UnexpectedFailure`. Use cases return `({SaleEntity sale, Failure? failure})` records.
