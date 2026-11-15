import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventario_app/features/inventory/presentation/providers/products_notifier.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';

final _kCategoryIcons = <String, IconData>{
  'package': LucideIcons.package,
  'coffee': LucideIcons.coffee,
  'shirt': LucideIcons.shirt,
  'smartphone': LucideIcons.smartphone,
  'home': LucideIcons.home,
  'heart': LucideIcons.heart,
  'star': LucideIcons.star,
  'gift': LucideIcons.gift,
  'music': LucideIcons.music,
  'book': LucideIcons.book,
  'wrench': LucideIcons.wrench,
  'leaf': LucideIcons.leaf,
};

IconData _iconFor(String key) => _kCategoryIcons[key] ?? LucideIcons.package;

// ── Screen ─────────────────────────────────────────────────────────────────────
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
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
      body: categoriesAsync.when(
        loading: () => const OmniSkeletonList(count: 5),
        error: (_, __) => OmniErrorState(
          message: 'No se pudo cargar la lista.',
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (categories) => categories.isEmpty
            ? OmniEmptyState(
                icon: LucideIcons.tag,
                title: 'Sin categorías',
                subtitle: 'Crea categorías para organizar tu inventario',
                actionLabel: 'Crear categoría',
                onAction: () => _openSheet(context, ref, null),
              )
            : _CategoriesList(categories: categories),
      ),
    );
  }

  static void _openSheet(
    BuildContext context,
    WidgetRef ref,
    CategoryEntity? existing,
  ) {
    showOmniSheet(context, builder: (_) => _CategorySheet(existing: existing));
  }
}

// ── List ───────────────────────────────────────────────────────────────────────
class _CategoriesList extends StatelessWidget {
  const _CategoriesList({required this.categories});
  final List<CategoryEntity> categories;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(OmniSpacing.base),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: OmniSpacing.sm),
      itemBuilder: (_, i) => _CategoryTile(categories[i]),
    );
  }
}

// ── Tile ───────────────────────────────────────────────────────────────────────
class _CategoryTile extends ConsumerWidget {
  const _CategoryTile(this.category);
  final CategoryEntity category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      productsProvider.select(
        (a) =>
            a.valueOrNull?.where((p) => p.category == category.name).length ??
            0,
      ),
    );
    return OmniCard(
      onTap: () => CategoriesScreen._openSheet(context, ref, category),
      padding: const EdgeInsets.fromLTRB(
        OmniSpacing.md,
        OmniSpacing.md,
        OmniSpacing.xs,
        OmniSpacing.md,
      ),
      child: Row(
        children: [
          OmniIconAvatar(icon: _iconFor(category.icon)),
          const SizedBox(width: OmniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: context.text.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$count producto${count == 1 ? '' : 's'}',
                  style: context.text.caption.tabular,
                ),
              ],
            ),
          ),
          _TileActions(category: category),
        ],
      ),
    );
  }
}

class _TileActions extends ConsumerWidget {
  const _TileActions({required this.category});
  final CategoryEntity category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Editar',
          icon: const Icon(LucideIcons.pencil, size: OmniSizes.iconSm + 2),
          onPressed: () => CategoriesScreen._openSheet(context, ref, category),
        ),
        IconButton(
          tooltip: 'Eliminar',
          icon: Icon(
            LucideIcons.trash2,
            size: OmniSizes.iconSm + 2,
            color: context.colors.danger,
          ),
          onPressed: () => _confirmDelete(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await OmniConfirmDialog.show(
      context,
      title: 'Eliminar categoría',
      body:
          '¿Eliminar "${category.name}"? Los productos quedarán sin categoría.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (confirmed && context.mounted) {
      await ref.read(categoriesProvider.notifier).delete(category.id);
    }
  }
}

// ── Create / Edit sheet ────────────────────────────────────────────────────────
class _CategorySheet extends ConsumerStatefulWidget {
  const _CategorySheet({this.existing});
  final CategoryEntity? existing;

  @override
  ConsumerState<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<_CategorySheet> {
  late final TextEditingController _nameCtrl;
  late String _selectedIcon;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _selectedIcon = widget.existing?.icon ?? 'package';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(int storeId) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(categoriesProvider.notifier)
          .add(
            CategoryEntity(
              id: _isEdit ? widget.existing!.id : 0,
              name: name,
              icon: _selectedIcon,
              storeId: storeId,
            ),
          );
    } catch (_) {
      // Antes el botón quedaba cargando para siempre si fallaba el guardado.
      if (mounted) setState(() => _loading = false);
      messenger.showOmni(
        'No se pudo guardar la categoría.',
        tone: OmniTone.danger,
      );
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Sin sucursal cargada no se puede guardar (nunca storeId 0).
    final storeId = widget.existing?.storeId ?? ref.watch(currentStoreProvider);
    return OmniSheetBody(
      title: _isEdit ? 'Editar categoría' : 'Nueva categoría',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OmniTextField(
            controller: _nameCtrl,
            label: 'Nombre',
            hint: 'Ej: Bebidas, Ropa, Electrónica',
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
            label: _isEdit ? 'Guardar cambios' : 'Crear categoría',
            onPressed: _loading || storeId == null
                ? null
                : () => _save(storeId),
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
      children: _kCategoryIcons.entries
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
