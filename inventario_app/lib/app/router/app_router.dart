import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/error/error_mapper.dart';
import 'package:inventario_app/core/error/failures.dart';
import 'package:inventario_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inventario_app/shared/providers/business_type_provider.dart';
import 'package:inventario_app/features/auth/presentation/screens/lock_screen.dart';
import 'package:inventario_app/features/customers/presentation/screens/customers_screen.dart';
import 'package:inventario_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:inventario_app/features/inventory/presentation/providers/products_notifier.dart';
import 'package:inventario_app/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:inventario_app/features/inventory/presentation/screens/add_product_screen.dart';
import 'package:inventario_app/features/inventory/presentation/screens/categories_screen.dart';
import 'package:inventario_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:inventario_app/features/sales/presentation/screens/history/sales_history_screen.dart';
import 'package:inventario_app/features/sales/presentation/screens/pos/pos_screen.dart';
import 'package:inventario_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:inventario_app/features/stores/presentation/screens/stores_screen.dart';
import 'app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = ref.watch(_authListenableProvider);

  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc  = state.matchedLocation;

      switch (auth.status) {
        case AuthStatus.initial:
          return null;
        case AuthStatus.noPinSet:
          if (loc == AppRoutes.authSetup) return null;
          return AppRoutes.authSetup;
        case AuthStatus.locked:
          if (loc == AppRoutes.auth) return null;
          return AppRoutes.auth;
        case AuthStatus.authenticated:
          if (loc == AppRoutes.auth || loc == AppRoutes.authSetup) {
            final type = ref.read(businessTypeProvider);
            return type != null
                ? AppRoutes.dashboardTyped(type)
                : AppRoutes.onboarding;
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.auth,
        builder: (_, __) => const LockScreen(),
      ),
      GoRoute(
        path: AppRoutes.authSetup,
        builder: (_, __) => const LockScreen(setupMode: true),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (_, state) {
          final type = state.uri.queryParameters['type'] ?? 'generic';
          return DashboardScreen(businessType: type);
        },
        routes: [
          GoRoute(
            path: AppRoutes.inventoryAdd,
            builder: (_, __) => const AddProductScreen(),
          ),
          GoRoute(
            path: AppRoutes.inventoryEdit,
            builder: (_, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              return _EditProductScreen(productId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.categories,
            builder: (_, __) => const CategoriesScreen(),
          ),
          GoRoute(
            path: AppRoutes.pos,
            builder: (_, state) {
              final type = state.uri.queryParameters['type'] ?? 'generic';
              return POSScreen(businessContext: type);
            },
          ),
          GoRoute(
            path: AppRoutes.customers,
            builder: (_, __) => const CustomersScreen(),
          ),
          GoRoute(
            path: AppRoutes.salesHistory,
            builder: (_, __) => const SalesHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            builder: (_, __) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.stores,
            builder: (_, __) => const StoresScreen(),
          ),
        ],
      ),
    ],
  );
});

// ── Listenable wrapper ─────────────────────────────────────────────────────────
final _authListenableProvider = Provider<_AuthListenable>((ref) {
  return _AuthListenable(ref);
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    _ref.listen<String?>(businessTypeProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

// Loads the product by id and passes it to AddProductScreen for editing
class _EditProductScreen extends ConsumerWidget {
  const _EditProductScreen({this.productId});
  final int? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (productId == null) return const AddProductScreen();
    final productsAsync = ref.watch(productsProvider);
    return productsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: OmniColors.bg,
        body: Center(child: CircularProgressIndicator(color: OmniColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: OmniColors.bg,
        body: OmniErrorState(
          message: e is Failure
              ? ErrorMapper.toMessage(e)
              : 'No se pudo cargar el producto.',
          onRetry: () => ref.invalidate(productsProvider),
        ),
      ),
      data: (products) {
        final product = products.where((p) => p.id == productId).firstOrNull;
        return AddProductScreen(product: product);
      },
    );
  }
}
