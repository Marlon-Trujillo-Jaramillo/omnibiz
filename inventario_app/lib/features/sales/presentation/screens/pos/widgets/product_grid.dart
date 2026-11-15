import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/error/error_mapper.dart';
import 'package:inventario_app/core/error/failures.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'package:inventario_app/features/inventory/presentation/providers/products_notifier.dart';
import 'package:inventario_app/features/sales/presentation/providers/cart_notifier.dart';
import 'package:inventario_app/shared/widgets/barcode_scanner_button.dart';
import 'quantity_dialog.dart';

final _posSearchProvider = StateProvider.autoDispose<String>((ref) => '');

/// Categoría elegida en los chips (null = todas).
final _posCategoryProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Cantidad de cada producto en el carrito (para el contador de la tarjeta).
final _cartQtyProvider = Provider.autoDispose<Map<int, int>>((ref) {
  final items = ref.watch(cartProvider.select((s) => s.items));
  return {for (final i in items) i.productId: i.quantity};
});

class ProductSearchAndGrid extends ConsumerStatefulWidget {
  const ProductSearchAndGrid({super.key});

  @override
  ConsumerState<ProductSearchAndGrid> createState() =>
      _ProductSearchAndGridState();
}

class _ProductSearchAndGridState extends ConsumerState<ProductSearchAndGrid> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onBarcodeResult(String code, List<ProductEntity> products) {
    final match = products
        .where((p) => p.barcode == code || p.sku == code)
        .firstOrNull;
    if (match != null && !match.isOutOfStock) {
      ref.read(cartProvider.notifier).addProduct(match);
      ScaffoldMessenger.of(context).showOmni(
        '${match.name} agregado',
        tone: OmniTone.success,
        duration: const Duration(seconds: 1),
      );
    } else {
      _searchCtrl.text = code;
      ref.read(_posSearchProvider.notifier).state = code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final search = ref.watch(_posSearchProvider);
    final category = ref.watch(_posCategoryProvider);
    final products = productsAsync.valueOrNull ?? [];
    final filtered = _filterProducts(products, search, category);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            OmniSpacing.base,
            OmniSpacing.sm,
            OmniSpacing.base,
            0,
          ),
          child: OmniSearchBar(
            controller: _searchCtrl,
            hint: 'Buscar producto, SKU o código...',
            onChanged: (v) => ref.read(_posSearchProvider.notifier).state = v,
            trailing: BarcodeScannerButton(
              onResult: (code) => _onBarcodeResult(code, products),
            ),
          ),
        ),
        if (products.isNotEmpty)
          _CategoryChips(products: products, selected: category),
        Expanded(
          child: productsAsync.when(
            loading: () => LayoutBuilder(
              builder: (_, c) => OmniSkeletonGrid(
                crossAxisCount: _columnCount(c.maxWidth),
                childAspectRatio: _aspect,
                padding: const EdgeInsets.all(OmniSpacing.base),
              ),
            ),
            error: (e, _) => OmniErrorState(
              message: e is Failure
                  ? ErrorMapper.toMessage(e)
                  : 'No se pudieron cargar los productos.',
              onRetry: () => ref.invalidate(productsProvider),
            ),
            data: (_) => filtered.isEmpty
                ? OmniEmptyState(
                    icon: search.isNotEmpty || category != null
                        ? LucideIcons.searchX
                        : LucideIcons.packageOpen,
                    title: search.isNotEmpty || category != null
                        ? 'Sin resultados'
                        : 'Sin productos',
                    subtitle: search.isNotEmpty || category != null
                        ? 'Intenta con otro término o categoría'
                        : 'Agrega productos desde el panel principal',
                  )
                : _ProductGrid(products: filtered),
          ),
        ),
      ],
    );
  }

  List<ProductEntity> _filterProducts(
    List<ProductEntity> products,
    String search,
    String? category,
  ) {
    Iterable<ProductEntity> result = products;
    if (category != null) result = result.where((p) => p.category == category);
    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      result = result.where(
        (p) =>
            p.name.toLowerCase().contains(q) ||
            (p.barcode?.contains(search) ?? false) ||
            p.sku.contains(search),
      );
    }
    return result.toList();
  }
}

const double _aspect = 1.2;

/// Alto fijo de la tarjeta: ícono, nombre (2 líneas) y precio.
const double _tileHeight = OmniSizes.avatarXl * 2 + OmniSpacing.md;

/// Ancho máximo de una tarjeta: más columnas en tablets anchas.
const double _maxTileWidth = 200;

int _columnCount(double width) =>
    ((width - OmniSpacing.base * 2 + OmniSpacing.md) /
            (_maxTileWidth + OmniSpacing.md))
        .ceil()
        .clamp(2, 8);

// ── Categorías ─────────────────────────────────────────────────────────────────
class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({required this.products, required this.selected});
  final List<ProductEntity> products;
  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = <String, int>{};
    for (final p in products) {
      counts[p.category] = (counts[p.category] ?? 0) + 1;
    }
    if (counts.length < 2) return const SizedBox(height: OmniSpacing.sm);
    final names = counts.keys.toList()..sort();
    void select(String? v) => ref.read(_posCategoryProvider.notifier).state = v;

    return SizedBox(
      height: OmniSizes.controlSm + OmniSpacing.xl,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: OmniSpacing.base,
          vertical: OmniSpacing.md,
        ),
        children: [
          OmniSelectableChip(
            label: 'Todos',
            count: products.length,
            selected: selected == null,
            onTap: () => select(null),
          ),
          for (final n in names) ...[
            const SizedBox(width: OmniSpacing.sm),
            OmniSelectableChip(
              label: n,
              count: counts[n],
              selected: selected == n,
              onTap: () => select(selected == n ? null : n),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Grid ───────────────────────────────────────────────────────────────────────
class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});
  final List<ProductEntity> products;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            OmniSpacing.base,
            0,
            OmniSpacing.base,
            OmniSpacing.xxxl,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columnCount(constraints.maxWidth),
            crossAxisSpacing: OmniSpacing.md,
            mainAxisSpacing: OmniSpacing.md,
            mainAxisExtent: _tileHeight,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => _ProductGridTile(products[i]),
        );
      },
    );
  }
}

// ── Product tile ───────────────────────────────────────────────────────────────
class _ProductGridTile extends ConsumerWidget {
  const _ProductGridTile(this.product);
  final ProductEntity product;

  Future<void> _addWithQuantity(BuildContext context, WidgetRef ref) async {
    final qty = await showQuantityDialog(
      context,
      productName: product.name,
      confirmLabel: 'Agregar',
    );
    if (qty != null) {
      ref.read(cartProvider.notifier).addProductQuantity(product, qty);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final outOfStock = product.isOutOfStock;
    final inCart = ref.watch(
      _cartQtyProvider.select((m) => m[product.id] ?? 0),
    );

    final (OmniTone tone, String stockLabel) = outOfStock
        ? (OmniTone.danger, 'Agotado')
        : product.isLowStock
        ? (OmniTone.warning, '${product.stock} uds')
        : (OmniTone.neutral, '${product.stock} uds');

    return Semantics(
      button: true,
      enabled: !outOfStock,
      label: '${product.name}, ${ref.formatMoney(product.price)}, $stockLabel',
      child: Opacity(
        opacity: outOfStock ? 0.55 : 1,
        child: OmniCard(
          selected: inCart > 0,
          padding: const EdgeInsets.all(OmniSpacing.md),
          onTap: outOfStock
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  ref.read(cartProvider.notifier).addProduct(product);
                },
          onLongPress: outOfStock ? null : () => _addWithQuantity(context, ref),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Monogram(name: product.name),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: OmniMotion.base,
                    transitionBuilder: (child, a) =>
                        ScaleTransition(scale: a, child: child),
                    child: inCart > 0
                        ? _InCartCounter(key: ValueKey(inCart), qty: inCart)
                        : OmniTag(label: stockLabel, tone: tone, dense: true),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                product.name,
                style: context.text.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: OmniSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  ref.formatMoney(product.price),
                  style: context.text.moneyMd.copyWith(
                    color: outOfStock ? c.textMuted : c.primaryText,
                    fontSize: OmniTypography.headingMd.fontSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inicial del producto sobre un tinte derivado del nombre.
class _Monogram extends StatelessWidget {
  const _Monogram({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final palette = [c.primaryText, c.purple, c.teal, c.orange, c.info];
    final color = palette[name.hashCode.abs() % palette.length];
    return Container(
      width: OmniSizes.avatarSm + OmniSpacing.xs,
      height: OmniSizes.avatarSm + OmniSpacing.xs,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withAlpha(c.isDark ? 36 : 24),
        borderRadius: OmniRadius.mdAll,
      ),
      child: Text(
        name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
        style: context.text.headingSm.copyWith(color: color),
      ),
    );
  }
}

class _InCartCounter extends StatelessWidget {
  const _InCartCounter({super.key, required this.qty});
  final int qty;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: const BoxConstraints(
        minWidth: OmniSizes.iconLg + 2,
        minHeight: OmniSizes.iconLg + 2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: OmniSpacing.sm),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: OmniRadius.fullAll,
      ),
      child: Text(
        '×$qty',
        style: context.text.label
            .copyWith(color: c.onPrimary, fontWeight: FontWeight.w700)
            .tabular,
      ),
    );
  }
}
