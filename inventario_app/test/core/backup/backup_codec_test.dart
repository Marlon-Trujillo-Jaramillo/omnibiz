import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/core/backup/backup_codec.dart';

// Pocas iteraciones: el KDF real (210k) es lento a propósito y no cambia la lógica.
const codec = BackupCodec(iterations: 1000);
const password = 'clave-de-respaldo';
final data = <String, Object?>{
  'sembast_export': 1,
  'version': 2,
  'stores': [
    {
      'name': 'customers',
      'keys': [1],
      'values': [
        {'name': 'Ana', 'totalDebt': 2500},
      ],
    },
  ],
};

void main() {
  test('cifra y descifra el mismo contenido', () async {
    final bytes = await codec.encode(data, password, schemaVersion: 2);
    final content = await codec.decode(bytes, password);

    expect(content.data, data);
    expect(content.header['schemaVersion'], 2);
    expect(content.createdAt, isNotNull);
  });

  test('el archivo no deja ver los datos en claro', () async {
    final text = utf8.decode(await codec.encode(data, password));
    expect(text, startsWith(BackupCodec.magic));
    expect(text, isNot(contains('Ana')));
    expect(text, isNot(contains('totalDebt')));
  });

  test(
    'dos respaldos del mismo contenido son distintos (sal y nonce)',
    () async {
      final a = await codec.encode(data, password);
      final b = await codec.encode(data, password);
      expect(a, isNot(equals(b)));
    },
  );

  test('contraseña incorrecta → BackupWrongPasswordException', () async {
    final bytes = await codec.encode(data, password);
    expect(
      codec.decode(bytes, 'otra-clave-123'),
      throwsA(isA<BackupWrongPasswordException>()),
    );
  });

  test('alterar la cabecera invalida el respaldo', () async {
    final lines = utf8.decode(await codec.encode(data, password)).split('\n');
    final header = jsonDecode(lines[1]) as Map<String, Object?>;
    header['createdAt'] = '2000-01-01T00:00:00Z';
    lines[1] = jsonEncode(header);
    final tampered = Uint8List.fromList(utf8.encode(lines.join('\n')));

    expect(
      codec.decode(tampered, password),
      throwsA(isA<BackupWrongPasswordException>()),
    );
  });

  test('un archivo cualquiera → BackupFormatException', () async {
    expect(
      codec.decode(Uint8List.fromList(utf8.encode('hola\nmundo\n')), password),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      codec.decode(Uint8List.fromList([0xff, 0xfe, 0x00]), password),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('exige una contraseña de al menos 8 caracteres', () {
    expect(
      () => codec.encode(data, '1234567'),
      throwsA(isA<BackupPasswordTooShortException>()),
    );
  });
}
