import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sembast/sembast.dart';

/// Codec sembast que cifra cada registro con AES-256-GCM.
///
/// Cada línea del archivo es `base64(nonce[12] ‖ ciphertext ‖ tag[16])` con un
/// nonce aleatorio por registro. Una clave incorrecta hace fallar la
/// autenticación GCM de la firma → sembast lanza
/// `DatabaseException.invalidCodec` al abrir (nunca datos basura).
SembastCodec aesGcmSembastCodec(List<int> key) {
  if (key.length != 32) {
    throw ArgumentError.value(key.length, 'key', 'se esperan 32 bytes');
  }
  return SembastCodec(signature: 'aes-gcm-256-v1', codec: _AesGcmCodec(key));
}

class _AesGcmCodec extends AsyncContentCodecBase {
  _AesGcmCodec(List<int> key) : _key = SecretKeyData(List.unmodifiable(key));

  static final _algo = AesGcm.with256bits();
  final SecretKey _key;

  @override
  Future<String> encodeAsync(Object? input) async {
    final box = await _algo.encrypt(
      utf8.encode(jsonEncode(input)),
      secretKey: _key,
      nonce: _algo.newNonce(),
    );
    return base64.encode(box.concatenation());
  }

  @override
  Future<Object?> decodeAsync(String encoded) async {
    final box = SecretBox.fromConcatenation(
      base64.decode(encoded),
      nonceLength: _algo.nonceLength,
      macLength: _algo.macAlgorithm.macLength,
      copy: false,
    );
    final clear = await _algo.decrypt(box, secretKey: _key);
    return jsonDecode(utf8.decode(clear));
  }
}

/// Clave de la BD (32 bytes aleatorios) en el almacenamiento seguro del SO
/// (Keychain / Android Keystore vía flutter_secure_storage).
class DatabaseKeyStore {
  const DatabaseKeyStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;
  static const _key = 'omni_db_key_v1';

  /// Clave existente o `null` si no hay ninguna (instalación nueva o
  /// almacenamiento seguro borrado).
  Future<Uint8List?> read() async {
    final value = await _storage.read(key: _key);
    if (value == null) return null;
    final bytes = base64.decode(value);
    if (bytes.length != 32) {
      throw const FormatException('Clave de BD con longitud inválida');
    }
    return bytes;
  }

  /// Genera y guarda una clave nueva. Sólo llamar cuando NO existe un archivo
  /// cifrado previo (si no, se perdería el acceso a él).
  Future<Uint8List> create() async {
    final rnd = Random.secure();
    final bytes = Uint8List.fromList(
      List.generate(32, (_) => rnd.nextInt(256)),
    );
    await _storage.write(key: _key, value: base64.encode(bytes));
    return bytes;
  }
}
