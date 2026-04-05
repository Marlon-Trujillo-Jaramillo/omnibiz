import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BarcodeScannerDialog extends StatelessWidget {
  const BarcodeScannerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código'),
        backgroundColor: Colors.black,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            Navigator.pop(context, barcodes.first.rawValue);
          }
        },
      ),
    );
  }
}

class BarcodeScannerButton extends StatelessWidget {
  final Function(String) onResult;

  const BarcodeScannerButton({super.key, required this.onResult});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.scan),
      onPressed: () async {
        final String? result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const BarcodeScannerDialog()),
        );
        if (result != null) {
          onResult(result);
        }
      },
    );
  }
}
