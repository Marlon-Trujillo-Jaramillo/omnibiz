import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/features/stores/domain/entities/store_entity.dart';
import 'package:inventario_app/shared/providers/database_provider.dart';

final storesProvider = AsyncNotifierProvider<StoresNotifier, List<StoreEntity>>(
  StoresNotifier.new,
);

class StoresNotifier extends AsyncNotifier<List<StoreEntity>> {
  static const _tag = 'StoresNotifier';

  @override
  Future<List<StoreEntity>> build() {
    AppLogger.d(_tag, 'build() → cargando sucursales');
    return ref.watch(storeRepositoryProvider).getAll();
  }

  Future<void> add(StoreEntity store) async {
    AppLogger.i(_tag, 'add() "${store.name}"');
    try {
      await ref.read(storeRepositoryProvider).save(store);
      ref.invalidateSelf();
      AppLogger.i(_tag, 'add() → ok');
    } catch (e, st) {
      AppLogger.e(_tag, 'add() falló', e, st);
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    AppLogger.i(_tag, 'delete($id)');
    try {
      await ref.read(storeRepositoryProvider).delete(id);
      ref.invalidateSelf();
      AppLogger.i(_tag, 'delete($id) → ok');
    } catch (e, st) {
      AppLogger.e(_tag, 'delete($id) falló', e, st);
      rethrow;
    }
  }
}
