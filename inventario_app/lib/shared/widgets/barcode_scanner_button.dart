import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';

class BarcodeScannerButton extends StatelessWidget {
  const BarcodeScannerButton({super.key, required this.onResult});

  final ValueChanged<String> onResult;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.scan, color: OmniColors.textSecondary),
      tooltip: 'Escanear código',
      onPressed: () => _openScanner(context),
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _ScannerDialog(),
    );
    if (result != null && result.isNotEmpty) onResult(result);
  }
}

// ── Dialog ─────────────────────────────────────────────────────────────────────
class _ScannerDialog extends StatefulWidget {
  const _ScannerDialog();

  @override
  State<_ScannerDialog> createState() => _ScannerDialogState();
}

class _ScannerDialogState extends State<_ScannerDialog> {
  bool _showCamera = false;
  String? _cameraError;
  final _textCtrl = TextEditingController();
  MobileScannerController? _ctrl;

  @override
  void dispose() {
    _ctrl?.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _openCamera() {
    _ctrl?.dispose();
    setState(() {
      _ctrl = MobileScannerController();
      _showCamera = true;
      _cameraError = null;
    });
  }

  void _closeCamera() {
    _ctrl?.stop();
    setState(() => _showCamera = false);
  }

  void _confirm(String value) {
    final v = value.trim();
    if (v.isNotEmpty) Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: OmniColors.bgModal,
      insetPadding: const EdgeInsets.all(OmniSpacing.xl),
      shape: RoundedRectangleBorder(borderRadius: OmniRadius.xlAll),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DialogHeader(onClose: () => Navigator.pop(context)),
          if (_showCamera)
            _CameraView(
              controller: _ctrl!,
              onDetected: (code) => Navigator.pop(context, code),
              onError: (msg) => setState(() {
                _showCamera = false;
                _cameraError = msg;
              }),
              onClose: _closeCamera,
            )
          else
            _ManualInput(
              controller: _textCtrl,
              cameraError: _cameraError,
              onOpenCamera: _openCamera,
              onConfirm: _confirm,
            ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────
class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OmniSpacing.xl, OmniSpacing.md, OmniSpacing.sm, 0),
      child: Row(
        children: [
          const Icon(LucideIcons.scan, color: OmniColors.primary, size: 18),
          const SizedBox(width: OmniSpacing.sm),
          Expanded(
            child: Text('Escanear Código', style: OmniTypography.headingSm),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x,
                color: OmniColors.textSecondary, size: 18),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

// ── Manual input panel ─────────────────────────────────────────────────────────
class _ManualInput extends StatelessWidget {
  const _ManualInput({
    required this.controller,
    required this.cameraError,
    required this.onOpenCamera,
    required this.onConfirm,
  });

  final TextEditingController controller;
  final String? cameraError;
  final VoidCallback onOpenCamera;
  final ValueChanged<String> onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OmniSpacing.xl, OmniSpacing.md, OmniSpacing.xl, OmniSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cameraError != null) _ErrorBanner(message: cameraError!),
          OmniButton(
            label: 'Usar cámara para escanear',
            icon: LucideIcons.camera,
            variant: OmniButtonVariant.secondary,
            onPressed: onOpenCamera,
            fullWidth: true,
          ),
          const _OrDivider(),
          OmniTextField(
            controller: controller,
            hint: 'Código de barras o SKU',
            autofocus: true,
            onSubmitted: onConfirm,
          ),
          const SizedBox(height: OmniSpacing.md),
          OmniButton(
            label: 'Confirmar',
            onPressed: () => onConfirm(controller.text),
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

// ── Camera view ────────────────────────────────────────────────────────────────
class _CameraView extends StatelessWidget {
  const _CameraView({
    required this.controller,
    required this.onDetected,
    required this.onError,
    required this.onClose,
  });

  final MobileScannerController controller;
  final ValueChanged<String> onDetected;
  final ValueChanged<String> onError;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ScannerPreview(
          controller: controller,
          onDetected: onDetected,
          onError: onError,
        ),
        _ScannerHintRow(onClose: onClose),
      ],
    );
  }

  static String _errorMessage(MobileScannerException e) =>
      switch (e.errorCode) {
        MobileScannerErrorCode.permissionDenied =>
          'Permiso de cámara denegado. Actívalo en Ajustes > Privacidad > Cámara.',
        MobileScannerErrorCode.unsupported =>
          'Este dispositivo no tiene cámara disponible.',
        _ => 'No se pudo iniciar la cámara.',
      };
}

class _ScannerPreview extends StatelessWidget {
  const _ScannerPreview({
    required this.controller,
    required this.onDetected,
    required this.onError,
  });

  final MobileScannerController controller;
  final ValueChanged<String> onDetected;
  final ValueChanged<String> onError;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final height = (constraints.maxWidth * 0.65).clamp(160.0, 280.0);
        return ClipRRect(
          borderRadius: OmniRadius.mdAll,
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final code = capture.barcodes.firstOrNull?.rawValue;
                    if (code != null) onDetected(code);
                  },
                  errorBuilder: (_, error) {
                    WidgetsBinding.instance.addPostFrameCallback(
                        (_) => onError(_CameraView._errorMessage(error)));
                    return const ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: Icon(LucideIcons.cameraOff,
                            color: OmniColors.textDisabled, size: 48),
                      ),
                    );
                  },
                ),
                const _ScanReticle(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScanReticle extends StatelessWidget {
  const _ScanReticle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.65,
        heightFactor: 0.55,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: OmniColors.primary, width: 2),
            borderRadius: OmniRadius.mdAll,
          ),
        ),
      ),
    );
  }
}

class _ScannerHintRow extends StatelessWidget {
  const _ScannerHintRow({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OmniSpacing.base,
        vertical: OmniSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.focus,
              size: OmniSpacing.md, color: OmniColors.textMuted),
          const SizedBox(width: OmniSpacing.xs),
          Text(
            'Apunta al código',
            style: OmniTypography.caption.copyWith(
              color: OmniColors.textMuted,
            ),
          ),
          const Spacer(),
          OmniButton(
            label: 'Manual',
            icon: LucideIcons.keyboard,
            variant: OmniButtonVariant.ghost,
            size: OmniButtonSize.sm,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

// ── Small widgets ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OmniSpacing.sm),
      margin: const EdgeInsets.only(bottom: OmniSpacing.md),
      decoration: BoxDecoration(
        color: OmniColors.warningBg,
        borderRadius: OmniRadius.mdAll,
        border: Border.all(color: OmniColors.warning.withAlpha(40)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle,
              color: OmniColors.warning, size: 14),
          const SizedBox(width: OmniSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: OmniTypography.caption.copyWith(
                color: OmniColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OmniSpacing.md),
      child: Row(
        children: [
          const Expanded(child: Divider(color: OmniColors.borderSubtle)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: OmniSpacing.sm),
            child: Text(
              'o escribe el código',
              style: OmniTypography.caption.copyWith(
                color: OmniColors.textDisabled,
              ),
            ),
          ),
          const Expanded(child: Divider(color: OmniColors.borderSubtle)),
        ],
      ),
    );
  }
}
