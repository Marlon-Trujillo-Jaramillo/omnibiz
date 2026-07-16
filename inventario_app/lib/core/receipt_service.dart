import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:inventario_app/core/globals.dart';
import 'package:inventario_app/features/sales/domain/entities/sale_entity.dart';

abstract final class ReceiptService {
  /// Generates a PDF receipt, saves a copy locally, and opens the native
  /// print/share sheet (print, WhatsApp, correo, guardar donde el usuario elija).
  ///
  /// Runs as fire-and-forget — never throws to the caller.
  static Future<void> generateAndSaveReceipt(SaleEntity sale) async {
    try {
      final bytes = await _buildPdfBytes(sale);
      final file  = await _saveToFile(sale.id, bytes);
      debugPrint('[ReceiptService] PDF guardado: ${file.path}');
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'recibo_${sale.id}.pdf',
      );
    } catch (e) {
      debugPrint('[ReceiptService] Error al generar recibo: $e');
      _notify('No se pudo generar el recibo', icon: Icons.error_outline);
    }
  }

  /// Re-opens the print/share sheet for an already completed sale
  /// (e.g. from Historial de ventas), without duplicating the saved file.
  static Future<void> shareReceipt(SaleEntity sale) async {
    try {
      final bytes = await _buildPdfBytes(sale);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'recibo_${sale.id}.pdf',
      );
    } catch (e) {
      debugPrint('[ReceiptService] Error al compartir recibo: $e');
      _notify('No se pudo compartir el recibo', icon: Icons.error_outline);
    }
  }

  // ── PDF builder ──────────────────────────────────────────────────────────────

  static Future<Uint8List> _buildPdfBytes(SaleEntity sale) async {
    final doc     = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(sale.createdAt);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context ctx) => pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'OMNIBIZ AUTOMATION',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14),
                ),
              ),
              pw.Center(child: pw.Text('Sistema de Gestión Inteligente')),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 5),
              pw.Text('Fecha: $dateStr'),
              pw.Text('Ticket: #${sale.id}'),
              pw.Text('Método: ${sale.paymentMethod}'),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Producto',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Total',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 5),
              ...sale.items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${item.quantity}x ${item.productName}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Text(
                        '\$${item.totalPrice.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text(
                    '\$${sale.totalAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  '*** GRACIAS POR SU COMPRA ***',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return doc.save();
  }

  // ── File I/O ─────────────────────────────────────────────────────────────────

  static Future<File> _saveToFile(int saleId, Uint8List bytes) async {
    // App-specific external storage — no permissions needed on Android 10+.
    // Accessible via any file manager under Android/data/<package>/files/OmniBiz/
    final base = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();

    final folder = Directory('${base!.path}/OmniBiz');
    await folder.create(recursive: true);

    final ts   = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${folder.path}/recibo_${saleId}_$ts.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  // ── Notification ─────────────────────────────────────────────────────────────

  static void _notify(
    String message, {
    IconData icon = Icons.info_outline,
    Color color   = const Color(0xFF9E9E9E),
  }) {
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
