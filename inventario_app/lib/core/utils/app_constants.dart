abstract final class AppConstants {
  // ── Auth / Seguridad ─────────────────────────────────────────────────────────
  static const lockAfter     = Duration(minutes: 5);
  static const maxPinAttempts = 5;
  /// Bloqueo tras [maxPinAttempts] fallos; se duplica con cada fallo extra.
  static const pinLockoutBase = Duration(seconds: 30);
  static const pinLockoutMax  = Duration(hours: 1);
  /// PBKDF2-HMAC-SHA256. ~265 ms en Apple Silicon (AOT); corre en un isolate.
  static const pinHashIterations = 100000;

  // ── Inventario ───────────────────────────────────────────────────────────────
  static const lowStockThreshold = 5;
  static const skuPrefix         = 'SKU-';

  // ── Base de datos ────────────────────────────────────────────────────────────
  /// BD legada en texto plano: sólo se lee para migrarla a [encryptedDbName].
  static const dbName          = 'omnibiz.db';
  static const encryptedDbName = 'omnibiz_enc.db';
  static const receiptFolder = 'OmniBiz';

  // ── UI / UX ──────────────────────────────────────────────────────────────────
  /// Tamaño de página del historial de ventas.
  static const listPageSize = 50;
}
