import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Formato del archivo de respaldo (`.omnibak`), en texto:
///
/// ```
/// OMNIBIZ-BACKUP v1
/// {"kdf":"pbkdf2-hmac-sha256","iterations":210000,"salt":"…","cipher":"aes-256-gcm",…}
/// base64(nonce[12] ‖ ciphertext ‖ tag[16])
/// ```
///
/// - La clave sale de la **contraseña de respaldo** (PBKDF2-HMAC-SHA256, sal
///   aleatoria de 16 bytes). No depende del Keychain/Keystore, así que el
///   archivo se puede restaurar en otro teléfono.
/// - El contenido es el export de sembast en JSON, comprimido con gzip y
///   cifrado con AES-256-GCM.
/// - La cabecera va como datos asociados (AAD) de GCM: si alguien la altera
///   (p. ej. baja las iteraciones), el descifrado falla.
class BackupCodec {
  const BackupCodec({this.iterations = defaultIterations});

  static const magic = 'OMNIBIZ-BACKUP v1';
  static const defaultIterations = 210000;
  static const minPasswordLength = 8;

  final int iterations;

  /// Cifra [data] con [password]. Corre el KDF y el cifrado en un isolate.
  Future<Uint8List> encode(
    Map<String, Object?> data,
    String password, {
    int? schemaVersion,
  }) {
    if (password.length < minPasswordLength) {
      throw const BackupPasswordTooShortException();
    }
    final iterations = this.iterations;
    return Isolate.run(
      () => _encode(data, password, iterations, schemaVersion),
    );
  }

  /// Descifra un respaldo. Lanza [BackupFormatException] si el archivo no es
  /// un respaldo válido y [BackupWrongPasswordException] si la contraseña no
  /// corresponde (o el archivo fue modificado).
  Future<BackupContent> decode(Uint8List bytes, String password) =>
      Isolate.run(() => _decode(bytes, password));
}

class BackupContent {
  const BackupContent({required this.header, required this.data});

  final Map<String, Object?> header;

  /// Export de sembast (`exportDatabase`).
  final Map<String, Object?> data;

  DateTime? get createdAt =>
      DateTime.tryParse(header['createdAt'] as String? ?? '');
}

sealed class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class BackupFormatException extends BackupException {
  const BackupFormatException([
    super.message = 'El archivo no es un respaldo de OmniBiz.',
  ]);
}

final class BackupWrongPasswordException extends BackupException {
  const BackupWrongPasswordException()
    : super('La contraseña no corresponde a este respaldo.');
}

final class BackupPasswordTooShortException extends BackupException {
  const BackupPasswordTooShortException()
    : super(
        'La contraseña debe tener al menos '
        '${BackupCodec.minPasswordLength} caracteres.',
      );
}

final class BackupTooNewException extends BackupException {
  const BackupTooNewException()
    : super(
        'El respaldo viene de una versión más nueva de OmniBiz. '
        'Actualiza la app y vuelve a intentarlo.',
      );
}

// ---------------------------------------------------------------------------
// Implementación (funciones de nivel superior: se ejecutan en el isolate).

final _aes = AesGcm.with256bits();

Future<SecretKey> _deriveKey(String password, List<int> salt, int iterations) =>
    Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKeyFromPassword(password: password, nonce: salt);

Future<Uint8List> _encode(
  Map<String, Object?> data,
  String password,
  int iterations,
  int? schemaVersion,
) async {
  final rnd = Random.secure();
  final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
  final header = <String, Object?>{
    'kdf': 'pbkdf2-hmac-sha256',
    'iterations': iterations,
    'salt': base64.encode(salt),
    'cipher': 'aes-256-gcm',
    'compression': 'gzip',
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'schemaVersion': ?schemaVersion,
  };
  final headerLine = jsonEncode(header);

  final key = await _deriveKey(password, salt, iterations);
  final clear = gzip.encode(utf8.encode(jsonEncode(data)));
  final box = await _aes.encrypt(
    clear,
    secretKey: key,
    nonce: _aes.newNonce(),
    aad: utf8.encode(headerLine),
  );

  final out =
      '${BackupCodec.magic}\n$headerLine\n${base64.encode(box.concatenation())}\n';
  return Uint8List.fromList(utf8.encode(out));
}

Future<BackupContent> _decode(Uint8List bytes, String password) async {
  final List<String> lines;
  try {
    lines = const LineSplitter().convert(utf8.decode(bytes));
  } on FormatException {
    throw const BackupFormatException();
  }
  if (lines.length < 3 || lines[0] != BackupCodec.magic) {
    throw const BackupFormatException();
  }

  final headerLine = lines[1];
  final Map<String, Object?> header;
  final List<int> salt;
  final int iterations;
  final SecretBox box;
  try {
    header = (jsonDecode(headerLine) as Map).cast<String, Object?>();
    if (header['kdf'] != 'pbkdf2-hmac-sha256' ||
        header['cipher'] != 'aes-256-gcm') {
      throw const BackupFormatException(
        'El respaldo usa un formato que esta versión no reconoce.',
      );
    }
    salt = base64.decode(header['salt']! as String);
    iterations = header['iterations']! as int;
    box = SecretBox.fromConcatenation(
      base64.decode(lines[2]),
      nonceLength: _aes.nonceLength,
      macLength: _aes.macAlgorithm.macLength,
    );
  } on BackupException {
    rethrow;
  } catch (_) {
    throw const BackupFormatException('El respaldo está incompleto o dañado.');
  }

  final key = await _deriveKey(password, salt, iterations);
  final List<int> clear;
  try {
    clear = await _aes.decrypt(
      box,
      secretKey: key,
      aad: utf8.encode(headerLine),
    );
  } on SecretBoxAuthenticationError {
    throw const BackupWrongPasswordException();
  }

  final data = (jsonDecode(utf8.decode(gzip.decode(clear))) as Map)
      .cast<String, Object?>();
  return BackupContent(header: header, data: data);
}
