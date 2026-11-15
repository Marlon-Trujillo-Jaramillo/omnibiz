import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/features/stores/domain/entities/store_entity.dart';
import 'package:inventario_app/features/stores/domain/repositories/store_repository.dart';
import 'package:inventario_app/features/stores/presentation/providers/stores_notifier.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';

final _kStoreIcons = <String, IconData>{
  'store': LucideIcons.store,
  'building': LucideIcons.building,
  'building2': LucideIcons.building2,
  'warehouse': LucideIcons.warehouse,
  'mapPin': LucideIcons.mapPin,
  'landmark': LucideIcons.landmark,
};

IconData _iconFor(String key) => _kStoreIcons[key] ?? LucideIcons.store;

// ── Screen ─────────────────────────────────────────────────────────────────────
class StoresScreen extends ConsumerWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesProvider);
    final currentId = ref.watch(currentStoreProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sucursales'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: OmniSpacing.base),
            child: OmniButton(
              label: 'Nueva',
              icon: LucideIcons.plus,
              size: OmniButtonSize.sm,
              onPressed: () => _openSheet(context, ref, null),
            ),
          ),
        ],
      ),
      body: storesAsync.when(
        loading: () => const OmniSkeletonList(count: 5),
        error: (_, __) => OmniErrorState(
          message: 'No se pudo cargar la lista.',
          onRetry: () => ref.invalidate(storesProvider),
        ),
        data: (stores) => stores.isEmpty
            ? OmniEmptyState(
                icon: LucideIcons.store,
                title: 'Sin sucursales',
                subtitle: 'Crea tu primera sucursal para empezar a vender',
                actionLabel: 'Crear sucursal',
                onAction: () => _openSheet(context, ref, null),
              )
            : _StoresList(stores: stores, currentId: currentId),
      ),
    );
  }

  static void _openSheet(
    BuildContext context,
    WidgetRef ref,
    StoreEntity? existing,
  ) {
    showOmniSheet(context, builder: (_) => _StoreSheet(existing: existing));
  }
}

// ── List ───────────────────────────────────────────────────────────────────────
class _StoresList extends StatelessWidget {
  const _StoresList({required this.stores, required this.currentId});
  final List<StoreEntity> stores;
  final int? currentId;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(OmniSpacing.base),
      itemCount: stores.length,
      separatorBuilder: (_, __) => const SizedBox(height: OmniSpacing.sm),
      itemBuilder: (_, i) => _StoreTile(
        store: stores[i],
        isActive: stores[i].id == currentId,
        canDelete: stores.length > 1,
      ),
    );
  }
}

// ── Tile ───────────────────────────────────────────────────────────────────────
class _StoreTile extends ConsumerWidget {
  const _StoreTile({
    required this.store,
    required this.isActive,
    required this.canDelete,
  });
  final StoreEntity store;
  final bool isActive;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OmniCard(
      selected: isActive,
      onTap: isActive
          ? null
          : () => ref.read(currentStoreProvider.notifier).set(store.id),
      padding: const EdgeInsets.fromLTRB(
        OmniSpacing.md,
        OmniSpacing.md,
        OmniSpacing.xs,
        OmniSpacing.md,
      ),
      child: Row(
        children: [
          OmniIconAvatar(icon: _iconFor(store.icon)),
          const SizedBox(width: OmniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        store.name,
                        style: context.text.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: OmniSpacing.sm),
                      const OmniTag(
                        label: 'Activa',
                        tone: OmniTone.brand,
                        dense: true,
                      ),
                    ],
                  ],
                ),
                if (store.address != null && store.address!.isNotEmpty) ...[
                  const SizedBox(height: OmniSpacing.xxs),
                  Text(store.address!, style: context.text.caption),
                ] else if (!isActive) ...[
                  const SizedBox(height: OmniSpacing.xxs),
                  Text('Toca para activar', style: context.text.caption),
                ],
              ],
            ),
          ),
          _TileActions(store: store, canDelete: canDelete),
        ],
      ),
    );
  }
}

class _TileActions extends ConsumerWidget {
  const _TileActions({required this.store, required this.canDelete});
  final StoreEntity store;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Editar',
          icon: const Icon(LucideIcons.pencil, size: OmniSizes.iconSm + 2),
          onPressed: () => StoresScreen._openSheet(context, ref, store),
        ),
        IconButton(
          tooltip: 'Eliminar',
          icon: Icon(
            LucideIcons.trash2,
            size: OmniSizes.iconSm + 2,
            color: canDelete
                ? context.colors.danger
                : context.colors.textDisabled,
          ),
          onPressed: canDelete ? () => _confirmDelete(context, ref) : null,
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await OmniConfirmDialog.show(
      context,
      title: 'Eliminar sucursal',
      body:
          '¿Eliminar "${store.name}"? Solo se puede eliminar una sucursal '
          'sin productos, ventas ni clientes.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final wasActive = ref.read(currentStoreProvider) == store.id;
    try {
      await ref.read(storesProvider.notifier).delete(store.id);
    } on StoreInUseException catch (e) {
      messenger.showOmni(e.message, tone: OmniTone.danger);
      return;
    } catch (_) {
      messenger.showOmni(
        'No se pudo eliminar la sucursal.',
        tone: OmniTone.danger,
      );
      return;
    }

    if (wasActive) {
      final remaining = await ref.read(storesProvider.future);
      if (remaining.isNotEmpty) {
        await ref.read(currentStoreProvider.notifier).set(remaining.first.id);
      }
    }
  }
}

// ── Create / Edit sheet ────────────────────────────────────────────────────────
class _StoreSheet extends ConsumerStatefulWidget {
  const _StoreSheet({this.existing});
  final StoreEntity? existing;

  @override
  ConsumerState<_StoreSheet> createState() => _StoreSheetState();
}

class _StoreSheetState extends ConsumerState<_StoreSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late String _selectedIcon;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _addressCtrl = TextEditingController(text: widget.existing?.address ?? '');
    _selectedIcon = widget.existing?.icon ?? 'store';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);

    final address = _addressCtrl.text.trim();
    final store = StoreEntity(
      id: _isEdit ? widget.existing!.id : 0,
      name: name,
      icon: _selectedIcon,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      address: address.isEmpty ? null : address,
    );

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(storesProvider.notifier).add(store);
    } catch (_) {
      // Antes el botón quedaba cargando para siempre si fallaba el guardado.
      if (mounted) setState(() => _loading = false);
      messenger.showOmni(
        'No se pudo guardar la sucursal.',
        tone: OmniTone.danger,
      );
      return;
    }

    if (!_isEdit) {
      // Primera sucursal creada en el flujo → queda activa automáticamente.
      final current = ref.read(currentStoreProvider);
      if (current == null) {
        final stores = await ref.read(storesProvider.future);
        if (stores.isNotEmpty) {
          await ref.read(currentStoreProvider.notifier).set(stores.last.id);
        }
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return OmniSheetBody(
      title: _isEdit ? 'Editar sucursal' : 'Nueva sucursal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OmniTextField(
            controller: _nameCtrl,
            label: 'Nombre',
            hint: 'Ej: Sucursal Centro, Bodega Norte',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: OmniSpacing.base),
          OmniTextField(
            controller: _addressCtrl,
            label: 'Dirección (opcional)',
            hint: 'Ej: Calle 10 # 5-20',
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: OmniSpacing.xl),
          Text('ÍCONO', style: context.text.overline),
          const SizedBox(height: OmniSpacing.md),
          _IconPicker(
            selected: _selectedIcon,
            onSelect: (k) => setState(() => _selectedIcon = k),
          ),
          const SizedBox(height: OmniSpacing.xxl),
          OmniButton(
            label: _isEdit ? 'Guardar cambios' : 'Crear sucursal',
            onPressed: _loading ? null : _save,
            loading: _loading,
            fullWidth: true,
            size: OmniButtonSize.lg,
            icon: _isEdit ? LucideIcons.save : LucideIcons.plus,
          ),
        ],
      ),
    );
  }
}

// ── Icon picker ────────────────────────────────────────────────────────────────
class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: OmniSpacing.sm,
      runSpacing: OmniSpacing.sm,
      children: _kStoreIcons.entries
          .map(
            (e) => _IconOption(
              iconKey: e.key,
              iconData: e.value,
              selected: selected == e.key,
              onTap: () => onSelect(e.key),
            ),
          )
          .toList(),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.iconKey,
    required this.iconData,
    required this.selected,
    required this.onTap,
  });
  final String iconKey;
  final IconData iconData;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      label: iconKey,
      child: OmniPressable(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: OmniMotion.base,
            width: OmniSizes.controlLg,
            height: OmniSizes.controlLg,
            decoration: BoxDecoration(
              color: selected ? c.primaryBg : c.bgRaised,
              borderRadius: OmniRadius.mdAll,
              border: Border.all(
                color: selected ? c.primary : c.borderSubtle,
                width: selected ? OmniSizes.focusRing : OmniSizes.hairline,
              ),
            ),
            child: Icon(
              iconData,
              size: OmniSizes.iconLg,
              color: selected ? c.primaryText : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
