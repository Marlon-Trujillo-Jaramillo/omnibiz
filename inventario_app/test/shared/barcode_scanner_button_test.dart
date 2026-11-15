import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/shared/widgets/barcode_scanner_button.dart';

void main() {
  testWidgets('dos resultados seguidos cierran solo el diálogo', (
    tester,
  ) async {
    final results = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: BarcodeScannerButton(onResult: results.add)),
        ),
      ),
    );

    await tester.tap(find.byType(BarcodeScannerButton));
    await tester.pumpAndSettle();
    // Dos envíos en el mismo frame (como las detecciones repetidas de la
    // cámara): sin el guard, el segundo `pop` cerraría la pantalla de debajo.
    final field = tester.widget<OmniTextField>(find.byType(OmniTextField));
    field.onSubmitted!('7701234');
    field.onSubmitted!('7701234');
    await tester.pumpAndSettle();

    expect(results, ['7701234']);
    expect(find.byType(BarcodeScannerButton), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });
}
