abstract final class AppConstants {
  // ── Auth / Seguridad ─────────────────────────────────────────────────────────
  static const lockAfter     = Duration(minutes: 5);
  static const maxPinAttempts = 5;

  // ── Inventario ───────────────────────────────────────────────────────────────
  static const lowStockThreshold = 5;
  static const skuPrefix         = 'SKU-';

  // ── Base de datos ────────────────────────────────────────────────────────────
  static const dbName       = 'omnibiz.db';
  static const receiptFolder = 'OmniBiz';

  // ── UI / UX ──────────────────────────────────────────────────────────────────
  static const snackBarDuration = Duration(seconds: 4);
  static const listPageSize     = 50;
  static const animDuration     = Duration(milliseconds: 200);
}
