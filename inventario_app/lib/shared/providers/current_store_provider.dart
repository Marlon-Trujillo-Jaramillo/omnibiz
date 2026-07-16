import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/shared/providers/database_provider.dart';

const _tag = 'CurrentStore';

final currentStoreProvider =
    NotifierProvider<CurrentStoreNotifier, int?>(CurrentStoreNotifier.new);

class CurrentStoreNotifier extends Notifier<int?> {
  final _storage = const FlutterSecureStorage();
  static const _key = 'omni_current_store_id';

  @override
  int? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final stored = await _storage.read(key: _key);
    if (stored != null) {
      AppLogger.d(_tag, '_load() → desde storage: $stored');
      state = int.parse(stored);
      return;
    }
    final stores = await ref.read(storeRepositoryProvider).getAll();
    if (stores.isNotEmpty) {
      AppLogger.d(_tag, '_load() → sin storage, usando primera sucursal id=${stores.first.id}');
      await set(stores.first.id);
    }
  }

  Future<void> set(int storeId) async {
    AppLogger.i(_tag, 'set($storeId)');
    await _storage.write(key: _key, value: storeId.toString());
    state = storeId;
  }
}
