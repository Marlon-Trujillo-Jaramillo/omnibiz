abstract final class AppRoutes {
  // ── Rutas raíz ───────────────────────────────────────────────────────────────
  static const splash = '/splash';
  static const auth = '/auth';
  static const authSetup = '/auth/setup';
  static const onboarding = '/onboarding';
  static const dashboard = '/dashboard';

  // ── Rutas anidadas (relativas a /dashboard) ──────────────────────────────────
  static const inventoryAdd = 'inventory/add';
  static const inventoryEdit = 'inventory/:id';
  static const categories = 'categories';
  static const pos = 'pos';
  static const customers = 'customers';
  static const salesHistory = 'sales/history';
  static const analytics = 'analytics';
  static const settings = 'settings';
  static const stores = 'stores';

  // ── Paths completos para navegación programática ─────────────────────────────
  static String dashboardTyped(String type) => '/dashboard?type=$type';
  static String posTyped(String type) => '/dashboard/pos?type=$type';
  static String inventoryEditFull(int id) => '/dashboard/inventory/$id';

  // ── Alias para path base del dashboard ───────────────────────────────────────
  static const dashboardBase = '/dashboard';
}
