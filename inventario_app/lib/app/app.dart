import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/globals.dart';
import 'package:inventario_app/core/utils/app_constants.dart';
import 'package:inventario_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inventario_app/shared/providers/theme_mode_provider.dart';
import 'router/app_router.dart';

class OmniBizApp extends ConsumerStatefulWidget {
  const OmniBizApp({super.key});

  @override
  ConsumerState<OmniBizApp> createState() => _OmniBizAppState();
}

class _OmniBizAppState extends ConsumerState<OmniBizApp>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;

  static const _lockAfter = AppConstants.lockAfter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _pausedAt = DateTime.now();

      case AppLifecycleState.resumed:
        final paused = _pausedAt;
        _pausedAt = null;
        if (paused != null &&
            DateTime.now().difference(paused) >= _lockAfter) {
          ref.read(authProvider.notifier).lock();
        }

      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'OmniBiz Automation',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: OmniTheme.light(),
      darkTheme: OmniTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: OmniMotion.slow,
      themeAnimationCurve: OmniMotion.standard,
      routerConfig: router,
    );
  }
}
