import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/features/settings/presentation/widgets/backup_section.dart';
import 'package:inventario_app/shared/providers/database_provider.dart';

Future<void> _pump(WidgetTester tester) async {
  final db = await databaseFactoryMemory.openDatabase('backup_section.db');
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: OmniTheme.light(),
        home: const Scaffold(
          body: SingleChildScrollView(child: BackupSection()),
        ),
      ),
    ),
  );
}

Future<void> _openCreate(WidgetTester tester) async {
  await tester.tap(find.text('Crear respaldo'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra las dos acciones y el aviso', (tester) async {
    await _pump(tester);
    expect(find.text('Crear respaldo'), findsOneWidget);
    expect(find.text('Restaurar respaldo'), findsOneWidget);
    expect(
      find.textContaining('Todo vive solo en este teléfono'),
      findsOneWidget,
    );
  });

  testWidgets('exige mínimo 8 caracteres', (tester) async {
    await _pump(tester);
    await _openCreate(tester);
    await tester.enterText(find.byType(TextFormField).at(0), '1234');
    await tester.enterText(find.byType(TextFormField).at(1), '1234');
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    expect(find.text('Mínimo 8 caracteres'), findsOneWidget);
  });

  testWidgets('las dos contraseñas deben coincidir', (tester) async {
    await _pump(tester);
    await _openCreate(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'clave-segura-1');
    await tester.enterText(find.byType(TextFormField).at(1), 'clave-segura-2');
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });

  testWidgets('cancelar cierra el diálogo sin crear nada', (tester) async {
    await _pump(tester);
    await _openCreate(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Elige una contraseña para proteger el archivo'),
      findsNothing,
    );
  });
}
