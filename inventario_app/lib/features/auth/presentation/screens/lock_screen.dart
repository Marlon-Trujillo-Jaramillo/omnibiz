import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import '../providers/auth_notifier.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, this.setupMode = false});
  final bool setupMode;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _confirming = false;

  // ── PIN input handlers ─────────────────────────────────────────────────────

  void _onDigit(String d) {
    if (_pin.length >= 4) return;
    setState(() => _pin += d);
    if (_pin.length == 4) _submit();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
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
      setState(() { _confirmPin = _pin; _pin = ''; _confirming = true; });
      return;
    }
    if (_pin == _confirmPin) {
      await ref.read(authProvider.notifier).setupPin(_pin);
      if (mounted) context.go('/onboarding');
    } else {
      setState(() { _pin = ''; _confirmPin = ''; _confirming = false; });
      _showError('Los PINs no coinciden. Intenta de nuevo.');
    }
  }

  Future<void> _handleUnlockSubmit() async {
    final ok = await ref.read(authProvider.notifier).unlockWithPin(_pin);
    if (!ok && mounted) {
      setState(() => _pin = '');
      _showError('PIN incorrecto');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: OmniColors.danger),
    );
  }

  // ── Biometrics ─────────────────────────────────────────────────────────────

  Future<void> _biometric() =>
      ref.read(authProvider.notifier).unlockWithBiometrics();

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: OmniColors.bg,
      body: SafeArea(
        child: OmniResponsiveCenter(
          maxWidth: OmniBreakpoints.tablet,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              _LockIcon(),
              const SizedBox(height: OmniSpacing.xl),
              _LockTitle(setupMode: widget.setupMode, confirming: _confirming),
              const SizedBox(height: OmniSpacing.xxl),
              _PinDots(filledCount: _pin.length),
              const Spacer(flex: 2),
              _NumPad(onDigit: _onDigit, onDelete: _onDelete),
              const SizedBox(height: OmniSpacing.xl),
              if (!widget.setupMode && auth.hasBiometrics)
                _BiometricButton(onTap: _biometric),
              const SizedBox(height: OmniSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _LockIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OmniSpacing.xl),
      decoration: const BoxDecoration(
        color: OmniColors.primaryBg,
        shape: BoxShape.circle,
      ),
      child: const Icon(LucideIcons.lock, color: OmniColors.primary, size: 36),
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
    return 'Elige un PIN de 4 dígitos para proteger la app';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_title, style: OmniTypography.displayMd),
        const SizedBox(height: OmniSpacing.sm),
        Text(
          _subtitle,
          style: OmniTypography.bodySm,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.filledCount});

  final int filledCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) => _PinDot(filled: i < filledCount)),
    );
  }
}

class _PinDot extends StatelessWidget {
  const _PinDot({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: OmniSpacing.sm),
      width: OmniSpacing.base,
      height: OmniSpacing.base,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? OmniColors.primary : OmniColors.borderWeak,
      ),
    );
  }
}

class _BiometricButton extends StatelessWidget {
  const _BiometricButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(LucideIcons.fingerprint, color: OmniColors.primary),
      label: Text(
        'Usar biometría',
        style: OmniTypography.bodyMd.copyWith(color: OmniColors.primary),
      ),
      onPressed: onTap,
    );
  }
}

// ── Numpad ─────────────────────────────────────────────────────────────────────
class _NumPad extends StatelessWidget {
  const _NumPad({required this.onDigit, required this.onDelete});

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  static const _keys = ['1','2','3','4','5','6','7','8','9','','0','⌫'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final size = (constraints.maxWidth * 0.65).clamp(240.0, 300.0);
        return SizedBox(
          width: size,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: OmniSpacing.sm,
            crossAxisSpacing: OmniSpacing.sm,
            children: _keys.map((k) => _NumKey(
              value: k,
              onDigit: onDigit,
              onDelete: onDelete,
            )).toList(),
          ),
        );
      },
    );
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({
    required this.value,
    required this.onDigit,
    required this.onDelete,
  });

  final String value;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();

    final isDelete = value == '⌫';
    return Material(
      color: OmniColors.bgSurface,
      borderRadius: OmniRadius.fullAll,
      child: InkWell(
        borderRadius: OmniRadius.fullAll,
        onTap: isDelete ? onDelete : () => onDigit(value),
        child: Center(
          child: isDelete
              ? const Icon(Icons.backspace_outlined,
                  color: OmniColors.textMuted, size: 22)
              : Text(value, style: OmniTypography.headingLg),
        ),
      ),
    );
  }
}
