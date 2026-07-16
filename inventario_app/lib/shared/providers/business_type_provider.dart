import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final businessTypeProvider =
    NotifierProvider<BusinessTypeNotifier, String?>(BusinessTypeNotifier.new);

class BusinessTypeNotifier extends Notifier<String?> {
  final _storage = const FlutterSecureStorage();
  static const _key = 'omni_business_type';

  @override
  String? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final type = await _storage.read(key: _key);
    if (type != null) state = type;
  }

  Future<void> save(String type) async {
    await _storage.write(key: _key, value: type);
    state = type;
  }
}
