import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventario_app/features/inventory/presentation/providers/products_notifier.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';

final _kCategoryIcons = <String, IconData>{
  'package':    LucideIcons.package,
  'coffee':     LucideIcons.coffee,
  'shirt':      LucideIcons.shirt,
  'smartphone': LucideIcons.smartphone,
  'home':       LucideIcons.home,
  'heart':      LucideIcons.heart,
  'star':       LucideIcons.star,
  'gift':       LucideIcons.gift,
  'music':      LucideIcons.music,
  'book':       LucideIcons.book,
  'wrench':     LucideIcons.wrench,
  'leaf':       LucideIcons.leaf,
};

IconData _iconFor(String key) => _kCategoryIcons[key] ?? LucideIcons.package;

// ── Screen ─────────────────────────────────────────────────────────────────────
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: OmniColors.bg,
      appBar: AppBar(
        backgroundColor: OmniColors.bg,
        elevation: 0,
        title: Text('Categorías', style: OmniTypography.headingMd),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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
      BuildContext context, WidgetRef ref, CategoryEntity? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: OmniColors.bgModal,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(OmniRadius.xl)),
      ),
      builder: (_) => _CategorySheet(existing: existing),
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OmniSpacing.base,
        vertical: OmniSpacing.md,
      ),
      decoration: BoxDecoration(
        color: OmniColors.bgSurface,
        borderRadius: OmniRadius.mdAll,
        border: Border.all(color: OmniColors.borderSubtle),
      ),
      child: Row(
        children: [
          OmniIconAvatar(
            icon: _iconFor(category.icon),
            color: OmniColors.primary,
            size: 40,
          ),
          const SizedBox(width: OmniSpacing.md),
          Expanded(
            child: Text(category.name, style: OmniTypography.bodyMd),
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
          icon: const Icon(LucideIcons.pencil,
              size: 18, color: OmniColors.textSecondary),
          onPressed: () => CategoriesScreen._openSheet(context, ref, category),
        ),
        IconButton(
          icon: const Icon(LucideIcons.trash2,
              size: 18, color: OmniColors.danger),
          onPressed: () => _confirmDelete(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await OmniConfirmDialog.show(
      context,
      title: 'Eliminar categoría',
      body: '¿Eliminar "${category.name}"? Los productos quedarán sin categoría.',
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
    _nameCtrl     = TextEditingController(text: widget.existing?.name ?? '');
    _selectedIcon = widget.existing?.icon ?? 'package';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);

    await ref.read(categoriesProvider.notifier).add(
      CategoryEntity(
        id:      _isEdit ? widget.existing!.id : 0,
        name:    name,
        icon:    _selectedIcon,
        storeId: widget.existing?.storeId ?? ref.read(currentStoreProvider) ?? 0,
      ),
    );
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
              _isEdit ? 'Editar categoría' : 'Nueva categoría',
              style: OmniTypography.headingLg,
            ),
            const SizedBox(height: OmniSpacing.xl),
            OmniTextField(
              controller: _nameCtrl,
              label: 'Nombre',
              hint: 'Ej: Bebidas, Ropa, Electrónica',
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
              label: _isEdit ? 'Guardar cambios' : 'Crear categoría',
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
      children: _kCategoryIcons.entries
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
