import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BarcodeScannerButton extends StatelessWidget {
  final Function(String) onResult;

  const BarcodeScannerButton({super.key, required this.onResult});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.scan),
      tooltip: 'Escanear código',
      onPressed: () async {
        final String? result = await showDialog<String>(
          context: context,
          barrierDismissible: true,
          builder: (_) => const _ScannerDialog(),
        );
        if (result != null && result.isNotEmpty) {
          onResult(result);
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ScannerDialog extends StatefulWidget {
  const _ScannerDialog();

  @override
  State<_ScannerDialog> createState() => _ScannerDialogState();
}

class _ScannerDialogState extends State<_ScannerDialog> {
  bool _showCamera = false;
  String? _cameraError;
  final _textCtrl = TextEditingController();

  // Controller is created lazily when user requests camera
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
      backgroundColor: const Color(0xFF1A1A1A),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
            child: Row(
              children: [
                const Icon(LucideIcons.scan, color: Colors.indigoAccent, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Escanear Código',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white54, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ── Camera view (optional) ──────────────────────────────────────
          if (_showCamera) ...[
            _CameraView(
              controller: _ctrl!,
              onDetected: (code) => Navigator.pop(context, code),
              onError: (msg) => setState(() {
                _showCamera = false;
                _cameraError = msg;
              }),
              onClose: _closeCamera,
            ),
          ],

          // ── Manual input ────────────────────────────────────────────────
          if (!_showCamera)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Camera error banner (if any)
                  if (_cameraError != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amberAccent.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertTriangle,
                              color: Colors.amberAccent, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _cameraError!,
                              style: const TextStyle(
                                  color: Colors.amberAccent, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Try camera button
                  OutlinedButton.icon(
                    icon: const Icon(LucideIcons.camera, size: 16),
                    label: const Text('Usar cámara para escanear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigoAccent,
                      side: const BorderSide(color: Colors.indigoAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _openCamera,
                  ),

                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white12)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('o escribe el código',
                            style: TextStyle(color: Colors.white24, fontSize: 11)),
                      ),
                      Expanded(child: Divider(color: Colors.white12)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _textCtrl,
                    autofocus: !_showCamera,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      hintText: 'Código de barras o SKU',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withAlpha(8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _confirm,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _confirm(_textCtrl.text),
                    child: const Text('Confirmar',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CameraView extends StatelessWidget {
  final MobileScannerController controller;
  final void Function(String code) onDetected;
  final void Function(String error) onError;
  final VoidCallback onClose;

  const _CameraView({
    required this.controller,
    required this.onDetected,
    required this.onError,
    required this.onClose,
  });

  String _errorMessage(MobileScannerException e) {
    switch (e.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Permiso de cámara denegado. Actívalo en Ajustes > Privacidad > Cámara.';
      case MobileScannerErrorCode.unsupported:
        return 'Este dispositivo no tiene cámara disponible para escaneo.';
      default:
        return 'No se pudo iniciar la cámara.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 260,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final code = capture.barcodes.firstOrNull?.rawValue;
                    if (code != null) onDetected(code);
                  },
                  errorBuilder: (context, error) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      onError(_errorMessage(error));
                    });
                    return const ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: Icon(LucideIcons.cameraOff,
                            color: Colors.white24, size: 48),
                      ),
                    );
                  },
                ),
                // Reticle
                Center(
                  child: Container(
                    width: 220,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.indigoAccent, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.focus, size: 13, color: Colors.white38),
            const SizedBox(width: 6),
            const Text('Apunta al código',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(LucideIcons.keyboard, size: 13),
              label: const Text('Manual'),
              style: TextButton.styleFrom(foregroundColor: Colors.white38),
              onPressed: onClose,
            ),
          ],
        ),
      ],
    );
  }
}
