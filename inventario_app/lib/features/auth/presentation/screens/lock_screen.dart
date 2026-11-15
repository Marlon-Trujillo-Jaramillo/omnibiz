import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import '../providers/auth_notifier.dart';

const _pinLength = 4;

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, this.setupMode = false});
  final bool setupMode;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _confirmPin = '';
  bool _confirming = false;
  bool _verifying = false;

  /// Mensaje de error bajo los puntos (se limpia al teclear).
  String? _error;
  Timer? _ticker;

  /// Duración total del bloqueo actual (para la barra de progreso).
  Duration? _lockoutTotal;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _ticker?.cancel();
    _shake.dispose();
    super.dispose();
  }

  /// Tiempo restante de bloqueo por intentos fallidos, o null si no hay.
  Duration? _remainingLockout(AuthState auth) {
    final until = auth.lockedUntil;
    if (until == null) return null;
    final left = until.difference(DateTime.now());
    return left.isNegative ? null : left;
  }

  /// Re-dibuja cada segundo mientras dure el bloqueo (cuenta regresiva).
  void _syncTicker(Duration? remaining) {
    if (remaining == null) {
      _ticker?.cancel();
      _ticker = null;
      _lockoutTotal = null;
    } else {
      if (_lockoutTotal == null || remaining > _lockoutTotal!) {
        _lockoutTotal = remaining;
      }
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  // ── PIN input handlers ─────────────────────────────────────────────────────

  bool _inputBlocked(AuthState auth) =>
      _verifying || (!widget.setupMode && _remainingLockout(auth) != null);

  void _onDigit(String d) {
    if (_pin.length >= _pinLength || _inputBlocked(ref.read(authProvider))) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == _pinLength) _submit();
  }

  void _onDelete() {
    if (_pin.isEmpty || _verifying) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (widget.setupMode) {
      _handleSetupSubmit();
    } else {
      _handleUnlockSubmit();
    }
  }

  Future<void> _handleSetupSubmit() async {
    if (!_confirming) {
      setState(() {
        _confirmPin = _pin;
        _pin = '';
        _confirming = true;
      });
      return;
    }
    if (_pin == _confirmPin) {
      try {
        await ref.read(authProvider.notifier).setupPin(_pin);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _pin = '';
          _confirmPin = '';
          _confirming = false;
        });
        _showError('No se pudo guardar el PIN. Intenta de nuevo.');
        return;
      }
      if (mounted) context.go('/onboarding');
    } else {
      setState(() {
        _pin = '';
        _confirmPin = '';
        _confirming = false;
      });
      _showError('Los PINs no coinciden. Intenta de nuevo.');
    }
  }

  Future<void> _handleUnlockSubmit() async {
    setState(() => _verifying = true);
    final ok = await ref.read(authProvider.notifier).unlockWithPin(_pin);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (!ok) {
      setState(() => _pin = '');
      _showError(ref.read(authProvider).error ?? 'PIN incorrecto.');
    }
  }

  void _showError(String msg) {
    HapticFeedback.heavyImpact();
    setState(() => _error = msg);
    _shake.forward(from: 0);
  }

  // ── Teclado físico (tablets con teclado, escritorio) ───────────────────────

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      _onDelete();
      return KeyEventResult.handled;
    }
    final char = event.character;
    if (char != null && RegExp(r'^\d$').hasMatch(char)) {
      _onDigit(char);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── Biometrics ─────────────────────────────────────────────────────────────

  Future<void> _biometric() =>
      ref.read(authProvider.notifier).unlockWithBiometrics();

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final remaining = widget.setupMode ? null : _remainingLockout(auth);
    _syncTicker(remaining);
    final blocked = remaining != null || _verifying;
    final c = context.colors;

    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -1.1),
              radius: c.isDark ? 1.1 : 0.9,
              colors: [c.primary.withAlpha(c.isDark ? 46 : 18), c.bg],
            ),
          ),
          child: SafeArea(
            child: OmniResponsiveCenter(
              maxWidth: OmniBreakpoints.tablet,
              child: LayoutBuilder(
                builder: (_, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OmniSpacing.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    // Con altura mínima y alto libre, el Column ocupa al menos
                    // la pantalla y reparte el espacio sobrante.
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: OmniSpacing.xl),
                            _BrandMark(locked: remaining != null),
                            const SizedBox(height: OmniSpacing.xl),
                            _LockTitle(
                              setupMode: widget.setupMode,
                              confirming: _confirming,
                            ),
                            const SizedBox(height: OmniSpacing.xxl),
                            _ShakeTransition(
                              animation: _shake,
                              child: _PinDots(
                                filledCount: _pin.length,
                                error: _error != null,
                                verifying: _verifying,
                              ),
                            ),
                            const SizedBox(height: OmniSpacing.lg),
                            SizedBox(
                              height: OmniSizes.controlLg + OmniSpacing.xl,
                              child: AnimatedSwitcher(
                                duration: OmniMotion.base,
                                child: remaining != null
                                    ? _LockoutNotice(
                                        key: const ValueKey('lockout'),
                                        remaining: remaining,
                                        total: _lockoutTotal ?? remaining,
                                      )
                                    : _error != null
                                    ? Text(
                                        _error!,
                                        key: ValueKey(_error),
                                        style: context.text.bodySm.copyWith(
                                          color: c.danger,
                                        ),
                                        textAlign: TextAlign.center,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: OmniSpacing.xl,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedOpacity(
                                opacity: remaining != null ? 0.35 : 1,
                                duration: OmniMotion.base,
                                child: _NumPad(
                                  maxWidth: constraints.maxWidth,
                                  enabled: !blocked,
                                  onDigit: _onDigit,
                                  onDelete: _onDelete,
                                  onBiometric:
                                      !widget.setupMode && auth.hasBiometrics
                                      ? _biometric
                                      : null,
                                ),
                              ),
                              if (!widget.setupMode)
                                TextButton(
                                  onPressed: () => _showForgotPin(context),
                                  child: const Text('¿Olvidaste tu PIN?'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.locked});
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: OmniSizes.avatarXl,
      height: OmniSizes.avatarXl,
      decoration: BoxDecoration(
        gradient: c.brandGradient,
        borderRadius: OmniRadius.xxlAll,
        boxShadow: c.glow(c.primary),
      ),
      child: AnimatedSwitcher(
        duration: OmniMotion.base,
        child: Icon(
          locked ? LucideIcons.timer : LucideIcons.lock,
          key: ValueKey(locked),
          color: c.onPrimary,
          size: OmniSizes.iconXl,
        ),
      ),
    );
  }
}

class _LockTitle extends StatelessWidget {
  const _LockTitle({required this.setupMode, required this.confirming});

  final bool setupMode;
  final bool confirming;

  String get _title {
    if (!setupMode) return 'OmniBiz';
    return confirming ? 'Confirma tu PIN' : 'Crea tu PIN';
  }

  String get _subtitle {
    if (!setupMode) return 'Ingresa tu PIN para continuar';
    return confirming
        ? 'Vuelve a ingresar los 4 dígitos'
        : 'Elige un PIN de 4 dígitos para proteger la app';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: OmniMotion.base,
      child: Column(
        key: ValueKey(_title),
        children: [
          Text(_title, style: context.text.displayMd),
          const SizedBox(height: OmniSpacing.sm),
          Text(
            _subtitle,
            style: context.text.bodyMd.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Sacude horizontalmente a [child] (seno amortiguado) cuando [animation]
/// avanza de 0 a 1.
class _ShakeTransition extends AnimatedWidget {
  const _ShakeTransition({
    required Animation<double> animation,
    required this.child,
  }) : super(listenable: animation);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    final dx = math.sin(t * math.pi * 6) * (1 - t) * OmniSpacing.base;
    return Transform.translate(offset: Offset(dx, 0), child: child);
  }
}

class _LockoutNotice extends StatelessWidget {
  const _LockoutNotice({
    super.key,
    required this.remaining,
    required this.total,
  });

  final Duration remaining;
  final Duration total;

  String get _countdown {
    final m = remaining.inMinutes;
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final progress = total.inMilliseconds == 0
        ? 0.0
        : remaining.inMilliseconds / total.inMilliseconds;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OmniSpacing.base,
        vertical: OmniSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: c.dangerBg,
        borderRadius: OmniRadius.lgAll,
        border: Border.all(color: c.danger.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: OmniSizes.iconXl,
            height: OmniSizes.iconXl,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: OmniSizes.stroke + 1,
              color: c.danger,
              backgroundColor: c.danger.withAlpha(40),
              strokeCap: StrokeCap.round,
            ),
          ),
          const SizedBox(width: OmniSpacing.md),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Demasiados intentos',
                style: context.text.label.copyWith(color: c.danger),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Intenta de nuevo en ',
                      style: context.text.bodySm.copyWith(color: c.danger),
                    ),
                    TextSpan(
                      text: _countdown,
                      style: context.text.moneySm.copyWith(color: c.danger),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({
    required this.filledCount,
    required this.error,
    required this.verifying,
  });

  final int filledCount;
  final bool error;
  final bool verifying;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$filledCount de $_pinLength dígitos ingresados',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _pinLength,
          (i) => _PinDot(
            filled: i < filledCount,
            error: error,
            pulse: verifying,
            index: i,
          ),
        ),
      ),
    );
  }
}

class _PinDot extends StatelessWidget {
  const _PinDot({
    required this.filled,
    required this.error,
    required this.pulse,
    required this.index,
  });

  final bool filled;
  final bool error;
  final bool pulse;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = error ? c.danger : c.primary;
    final dot = AnimatedContainer(
      duration: OmniMotion.base,
      curve: OmniMotion.emphasized,
      margin: const EdgeInsets.symmetric(horizontal: OmniSpacing.sm + 2),
      width: OmniSizes.pinDot,
      height: OmniSizes.pinDot,
      transform: Matrix4.diagonal3Values(
        filled ? 1.15 : 1,
        filled ? 1.15 : 1,
        1,
      ),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : OmniPalette.transparent,
        border: Border.all(
          color: filled ? color : (error ? c.danger : c.borderWeak),
          width: OmniSizes.stroke,
        ),
        boxShadow: filled ? c.glow(color) : null,
      ),
    );
    if (!pulse) return dot;
    return _Pulse(delay: index * 120, child: dot);
  }
}

/// Parpadeo suave en bucle mientras se verifica el PIN.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child, required this.delay});
  final Widget child;
  final int delay;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 1, end: 0.35).animate(_ctrl),
    child: widget.child,
  );
}

// ── Numpad ─────────────────────────────────────────────────────────────────────
class _NumPad extends StatelessWidget {
  const _NumPad({
    required this.maxWidth,
    required this.enabled,
    required this.onDigit,
    required this.onDelete,
    this.onBiometric,
  });

  final double maxWidth;
  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onBiometric;

  static const _digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];

  @override
  Widget build(BuildContext context) {
    final width = (maxWidth * 0.82).clamp(260.0, 320.0);
    final gap = OmniSpacing.base;
    final keySize = (width - gap * 2) / 3;
    Widget row(List<Widget> keys) => Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: keys,
      ),
    );

    return SizedBox(
      width: width,
      child: Column(
        children: [
          for (var r = 0; r < 3; r++)
            row([
              for (final d in _digits.sublist(r * 3, r * 3 + 3))
                _Key(
                  size: keySize,
                  enabled: enabled,
                  onTap: () => onDigit(d),
                  semanticLabel: d,
                  child: Text(d, style: context.text.keypad),
                ),
            ]),
          row([
            onBiometric != null
                ? _Key(
                    size: keySize,
                    enabled: enabled,
                    flat: true,
                    onTap: onBiometric!,
                    semanticLabel: 'Usar biometría',
                    child: Icon(
                      LucideIcons.fingerprint,
                      color: context.colors.primaryText,
                      size: OmniSizes.iconLg + 4,
                    ),
                  )
                : SizedBox(width: keySize, height: keySize),
            _Key(
              size: keySize,
              enabled: enabled,
              onTap: () => onDigit('0'),
              semanticLabel: '0',
              child: Text('0', style: context.text.keypad),
            ),
            _Key(
              size: keySize,
              enabled: enabled,
              flat: true,
              onTap: onDelete,
              semanticLabel: 'Borrar',
              child: Icon(
                LucideIcons.delete,
                color: context.colors.textSecondary,
                size: OmniSizes.iconLg,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

/// Tecla circular: se hunde, se tiñe de marca y vibra al presionar.
class _Key extends StatefulWidget {
  const _Key({
    required this.size,
    required this.enabled,
    required this.onTap,
    required this.child,
    required this.semanticLabel,
    this.flat = false,
  });

  final double size;
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;
  final String semanticLabel;

  /// Sin relleno (teclas de acción).
  final bool flat;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = _down
        ? c.primaryBg
        : widget.flat
        ? OmniPalette.transparent
        : c.bgSurface;
    final border = _down
        ? c.primary.withAlpha(120)
        : widget.flat
        ? OmniPalette.transparent
        : c.borderSubtle;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      enabled: widget.enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled ? (_) => _set(true) : null,
        onTapCancel: () => _set(false),
        onTapUp: widget.enabled
            ? (_) {
                _set(false);
                widget.onTap();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.92 : 1,
          duration: OmniMotion.fast,
          curve: OmniMotion.standard,
          child: AnimatedContainer(
            duration: OmniMotion.fast,
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: Border.all(color: border),
              boxShadow: widget.flat || _down ? null : c.cardShadow,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Solo explica cómo recuperarse: no borra nada desde la pantalla de bloqueo,
/// para que nadie con el teléfono en la mano pueda destruir los datos.
Future<void> _showForgotPin(BuildContext context) => showDialog<void>(
  context: context,
  builder: (dialogContext) => OmniDialog(
    title: '¿Olvidaste tu PIN?',
    icon: LucideIcons.keyRound,
    tone: OmniTone.info,
    actions: OmniDialogActions(
      onCancel: () => Navigator.pop(dialogContext),
      onConfirm: () => Navigator.pop(dialogContext),
      confirmLabel: 'Entendido',
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Por seguridad, el PIN no se puede restablecer: protege datos '
          'cifrados que solo este teléfono puede abrir.',
          style: dialogContext.text.bodyMd,
        ),
        const SizedBox(height: OmniSpacing.md),
        Text(
          'Si usas la huella o el rostro, desbloquea con ellos. Si no, '
          'reinstala la app y, en Configuración → Respaldo de datos, '
          'restaura tu último respaldo con su contraseña.',
          style: dialogContext.text.bodyMd,
        ),
      ],
    ),
  ),
);
