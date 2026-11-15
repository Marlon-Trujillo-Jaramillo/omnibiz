import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/core/security/pin_hasher.dart';

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('pbkdf2HmacSha256 (vectores RFC 7914 §11)', () {
    test('1 iteración', () {
      final dk = pbkdf2HmacSha256(
        utf8.encode('password'),
        utf8.encode('salt'),
        1,
        32,
      );
      expect(
        _hex(dk),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
    });

    test('4096 iteraciones', () {
      final dk = pbkdf2HmacSha256(
        utf8.encode('password'),
        utf8.encode('salt'),
        4096,
        32,
      );
      expect(
        _hex(dk),
        'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
      );
    });
  });

  group('PinHasher', () {
    test('hash nuevo verifica el PIN correcto y rechaza otro', () async {
      final stored = await PinHasher.hash('1234', iterations: 1000);

      expect(stored, startsWith(r'pbkdf2_sha256$1000$'));
      expect(await PinHasher.verify('1234', stored), isTrue);
      expect(await PinHasher.verify('4321', stored), isFalse);
    });

    test('dos hashes del mismo PIN difieren (sal aleatoria)', () async {
      final a = await PinHasher.hash('1234', iterations: 1000);
      final b = await PinHasher.hash('1234', iterations: 1000);

      expect(a, isNot(b));
    });

    test('verifica el formato legado SHA-256 sin sal', () async {
      final legacy = sha256.convert(utf8.encode('1234')).toString();

      expect(PinHasher.isLegacy(legacy), isTrue);
      expect(await PinHasher.verify('1234', legacy), isTrue);
      expect(await PinHasher.verify('0000', legacy), isFalse);
    });

    test('needsRehash: legado o con otras iteraciones', () async {
      final legacy = sha256.convert(utf8.encode('1234')).toString();
      final current = await PinHasher.hash('1234', iterations: 1000);

      expect(PinHasher.needsRehash(legacy, iterations: 1000), isTrue);
      expect(PinHasher.needsRehash(current, iterations: 1000), isFalse);
      expect(PinHasher.needsRehash(current, iterations: 2000), isTrue);
    });

    test('valor corrupto → false, sin excepción', () async {
      expect(await PinHasher.verify('1234', 'basura'), isFalse);
    });

    test('constantTimeEquals', () {
      expect(PinHasher.constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
      expect(PinHasher.constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
      expect(PinHasher.constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
    });
  });
}
