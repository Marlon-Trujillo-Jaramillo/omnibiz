// Selecciona la implementación de almacenamiento según la plataforma:
// archivos locales con `sembast_io` en móvil/escritorio, IndexedDB con
// `sembast_web` en el navegador. El resto de la app usa esta API sin saber
// en cuál corre.
export 'db_platform_io.dart' if (dart.library.html) 'db_platform_web.dart';
