import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/features/stores/domain/entities/store_entity.dart';
import 'package:inventario_app/features/stores/presentation/providers/stores_notifier.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';

final _kStoreIcons = <String, IconData>{
  'store':    LucideIcons.store,
  'building': LucideIcons.building,
  'building2': LucideIcons.building2,
  'warehouse': LucideIcons.warehouse,
  'mapPin':   LucideIcons.mapPin,
  'landmark': LucideIcons.landmark,
};

IconData _iconFor(String key) => _kStoreIcons[key] ?? LucideIcons.store;

// ── Screen ─────────────────────────────────────────────────────────────────────
class StoresScreen extends ConsumerWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storesProvider);
    final currentId   = ref.watch(currentStoreProvider);

    return Scaffold(
      backgroundColor: OmniColors.bg,
      appBar: AppBar(
        backgroundColor: OmniColors.bg,
        elevation: 0,
        title: Text('Sucursales', style: OmniTypography.headingMd),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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

  static void _openSheet(BuildContext context, WidgetRef ref, StoreEntity? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: OmniColors.bgModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(OmniRadius.xl)),
      ),
      builder: (_) => _StoreSheet(existing: existing),
    );
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
    return InkWell(
      borderRadius: OmniRadius.mdAll,
      onTap: isActive
          ? null
          : () => ref.read(currentStoreProvider.notifier).set(store.id),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: OmniSpacing.base,
          vertical: OmniSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isActive ? OmniColors.primaryBg : OmniColors.bgSurface,
          borderRadius: OmniRadius.mdAll,
          border: Border.all(
            color: isActive ? OmniColors.primary : OmniColors.borderSubtle,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            OmniIconAvatar(
              icon: _iconFor(store.icon),
              color: OmniColors.primary,
              size: 40,
            ),
            const SizedBox(width: OmniSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name, style: OmniTypography.bodyMd),
                  if (store.address != null && store.address!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      store.address!,
                      style: OmniTypography.caption
                          .copyWith(color: OmniColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (isActive)
              const Padding(
                padding: EdgeInsets.only(right: OmniSpacing.sm),
                child: Icon(LucideIcons.checkCircle,
                    color: OmniColors.primary, size: 20),
              ),
            _TileActions(store: store, canDelete: canDelete),
          ],
        ),
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
          icon: const Icon(LucideIcons.pencil,
              size: 18, color: OmniColors.textSecondary),
          onPressed: () => StoresScreen._openSheet(context, ref, store),
        ),
        IconButton(
          icon: Icon(LucideIcons.trash2,
              size: 18,
              color: canDelete ? OmniColors.danger : OmniColors.textDisabled),
          onPressed: canDelete ? () => _confirmDelete(context, ref) : null,
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await OmniConfirmDialog.show(
      context,
      title: 'Eliminar sucursal',
      body: '¿Eliminar "${store.name}"? Los productos, ventas y clientes '
          'asociados a esta sucursal no se eliminarán, pero dejarán de ser accesibles.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final wasActive = ref.read(currentStoreProvider) == store.id;
    await ref.read(storesProvider.notifier).delete(store.id);

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
    _nameCtrl     = TextEditingController(text: widget.existing?.name ?? '');
    _addressCtrl  = TextEditingController(text: widget.existing?.address ?? '');
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
      id:        _isEdit ? widget.existing!.id : 0,
      name:      name,
      icon:      _selectedIcon,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      address:   address.isEmpty ? null : address,
    );

    await ref.read(storesProvider.notifier).add(store);

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
    return OmniResponsiveCenter(
      maxWidth: OmniBreakpoints.tablet,
      child: Padding(
        padding: EdgeInsets.only(
          left: OmniSpacing.xl,
          right: OmniSpacing.xl,
          top: OmniSpacing.xl,
          bottom: OmniSpacing.xxl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OmniDragHandle(),
            const SizedBox(height: OmniSpacing.base),
            Text(
              _isEdit ? 'Editar sucursal' : 'Nueva sucursal',
              style: OmniTypography.headingLg,
            ),
            const SizedBox(height: OmniSpacing.xl),
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
            Text('Ícono', style: OmniTypography.headingMd),
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
          .map((e) => _IconOption(
                iconKey: e.key,
                iconData: e.value,
                selected: selected == e.key,
                onTap: () => onSelect(e.key),
              ))
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(OmniSpacing.md),
        decoration: BoxDecoration(
          color: selected ? OmniColors.primaryBg : OmniColors.bgSurface,
          borderRadius: OmniRadius.mdAll,
          border: Border.all(
            color: selected ? OmniColors.primary : OmniColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Icon(
          iconData,
          size: OmniSpacing.xl,
          color: selected ? OmniColors.primary : OmniColors.textSecondary,
        ),
      ),
    );
  }
}
