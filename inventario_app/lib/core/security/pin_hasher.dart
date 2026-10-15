import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Hash de PIN con PBKDF2-HMAC-SHA256 + sal aleatoria.
///
/// Formato almacenado: `pbkdf2_sha256$<iteraciones>$<sal b64>$<hash b64>`.
/// También reconoce el formato legado (SHA-256 hex sin sal, 64 caracteres)
/// para poder migrar instalaciones existentes.
abstract final class PinHasher {
  static const _scheme   = 'pbkdf2_sha256';
  static const _saltLen  = 16;
  static const _keyLen   = 32;

  /// Genera el valor a almacenar para [pin] con una sal nueva.
  /// Corre en un isolate: el KDF es lento a propósito.
  static Future<String> hash(String pin, {required int iterations}) {
    final rnd  = Random.secure();
    final salt = Uint8List.fromList(List.generate(_saltLen, (_) => rnd.nextInt(256)));
    return Isolate.run(() {
      final dk = pbkdf2HmacSha256(utf8.encode(pin), salt, iterations, _keyLen);
      return '$_scheme\$$iterations\$${base64.encode(salt)}\$${base64.encode(dk)}';
    });
  }

  /// Verifica [pin] contra un valor almacenado (nuevo o legado) en tiempo constante.
  static Future<bool> verify(String pin, String stored) async {
    if (isLegacy(stored)) {
      final candidate = Uint8List.fromList(sha256.convert(utf8.encode(pin)).bytes);
      return constantTimeEquals(candidate, _hexDecode(stored));
    }
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != _scheme) return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;
    final salt     = base64.decode(parts[2]);
    final expected = base64.decode(parts[3]);
    final dk = await Isolate.run(
      () => pbkdf2HmacSha256(utf8.encode(pin), salt, iterations, expected.length),
    );
    return constantTimeEquals(dk, expected);
  }

  /// `true` si [stored] es el hash SHA-256 sin sal de versiones anteriores.
  static bool isLegacy(String stored) =>
      stored.length == 64 && RegExp(r'^[0-9a-f]{64}$').hasMatch(stored);

  /// `true` si [stored] debe re-guardarse (legado o con otro nº de iteraciones).
  static bool needsRehash(String stored, {required int iterations}) =>
      isLegacy(stored) || !stored.startsWith('$_scheme\$$iterations\$');

  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static Uint8List _hexDecode(String hex) => Uint8List.fromList([
        for (var i = 0; i < hex.length; i += 2)
          int.parse(hex.substring(i, i + 2), radix: 16),
      ]);
}

/// PBKDF2 (RFC 8018) con HMAC-SHA256, implementado sobre `package:crypto`.
Uint8List pbkdf2HmacSha256(
  List<int> password,
  List<int> salt,
  int iterations,
  int keyLength,
) {
  final hmac   = Hmac(sha256, password);
  final out    = Uint8List(keyLength);
  final blocks = (keyLength / 32).ceil();
  for (var block = 1; block <= blocks; block++) {
    final blockIndex = Uint8List(4)
      ..buffer.asByteData().setUint32(0, block);
    var u = hmac.convert([...salt, ...blockIndex]).bytes;
    final t = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    final offset = (block - 1) * 32;
    final len    = min(32, keyLength - offset);
    out.setRange(offset, offset + len, t);
  }
  return out;
}
