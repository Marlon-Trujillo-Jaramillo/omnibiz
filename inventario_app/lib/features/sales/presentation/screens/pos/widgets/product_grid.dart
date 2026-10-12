import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'package:inventario_app/features/inventory/presentation/providers/products_notifier.dart';
import 'package:inventario_app/features/sales/presentation/providers/cart_notifier.dart';
import 'package:inventario_app/shared/widgets/barcode_scanner_button.dart';
import 'quantity_dialog.dart';

final _posSearchProvider = StateProvider.autoDispose<String>((ref) => '');

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
    if (match != null) {
      ref.read(cartProvider.notifier).addProduct(match);
      _showAddedSnack(match.name);
    } else {
      _searchCtrl.text = code;
      ref.read(_posSearchProvider.notifier).state = code;
    }
  }

  void _showAddedSnack(String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$name agregado'),
      backgroundColor: OmniColors.bgPopup,
      duration: const Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final search        = ref.watch(_posSearchProvider);
    final products      = productsAsync.valueOrNull ?? [];
    final filtered      = _filterProducts(products, search);

    return Column(
      children: [
        _SearchBar(
          controller: _searchCtrl,
          products: products,
          onBarcodeResult: _onBarcodeResult,
          onChanged: (v) => ref.read(_posSearchProvider.notifier).state = v,
        ),
        Expanded(
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (_) => filtered.isEmpty
                ? _EmptyProducts(hasSearch: search.isNotEmpty)
                : _ProductGrid(products: filtered),
          ),
        ),
      ],
    );
  }

  List<ProductEntity> _filterProducts(
      List<ProductEntity> products, String search) {
    if (search.isEmpty) return products;
    final q = search.toLowerCase();
    return products.where((p) =>
        p.name.toLowerCase().contains(q) ||
        (p.barcode?.contains(search) ?? false) ||
        p.sku.contains(search)).toList();
  }
}

// ── Search bar ─────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.products,
    required this.onBarcodeResult,
    required this.onChanged,
  });

  final TextEditingController controller;
  final List<ProductEntity> products;
  final void Function(String, List<ProductEntity>) onBarcodeResult;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(OmniSpacing.base),
      child: OmniSearchBar(
        controller: controller,
        hint: 'Buscar producto, SKU o código...',
        onChanged: onChanged,
        trailing: BarcodeScannerButton(
          onResult: (code) => onBarcodeResult(code, products),
        ),
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
        final cols = _columnCount(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            OmniSpacing.base, 0, OmniSpacing.base, OmniSpacing.base),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: OmniSpacing.sm,
            mainAxisSpacing: OmniSpacing.sm,
            childAspectRatio: cols >= 4 ? 0.9 : 1.1,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => _ProductGridTile(products[i]),
        );
      },
    );
  }

  int _columnCount(double width) {
    if (width >= OmniBreakpoints.desktop) return 4;
    if (width >= OmniBreakpoints.tablet) return 3;
    return 2;
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.hasSearch});
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return OmniEmptyState(
      icon: LucideIcons.packageOpen,
      title: hasSearch ? 'Sin resultados' : 'Sin productos',
      subtitle: hasSearch
          ? 'Intenta con otro término'
          : 'Agrega productos desde el dashboard',
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
    final outOfStock = product.isOutOfStock;

    return GestureDetector(
      onTap: outOfStock
          ? null
          : () => ref.read(cartProvider.notifier).addProduct(product),
      onLongPress: outOfStock ? null : () => _addWithQuantity(context, ref),
      child: Opacity(
        opacity: outOfStock ? 0.4 : 1.0,
        child: _TileCard(product: product, outOfStock: outOfStock),
      ),
    );
  }
}

class _TileCard extends StatelessWidget {
  const _TileCard({required this.product, required this.outOfStock});
  final ProductEntity product;
  final bool outOfStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OmniSpacing.md),
      decoration: BoxDecoration(
        color: OmniColors.bgSurface,
        borderRadius: OmniRadius.lgAll,
        border: Border.all(color: OmniColors.borderSubtle),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TileTopRow(product: product, outOfStock: outOfStock),
          _TileBottomInfo(product: product),
        ],
      ),
    );
  }
}

class _TileTopRow extends StatelessWidget {
  const _TileTopRow({required this.product, required this.outOfStock});
  final ProductEntity product;
  final bool outOfStock;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OmniIconAvatar(
            icon: LucideIcons.package, color: OmniColors.primary, size: 40),
        if (product.isLowStock && !outOfStock)
          const Icon(LucideIcons.alertTriangle,
              size: 14, color: OmniColors.warning),
        if (outOfStock) _OutOfStockBadge(),
      ],
    );
  }
}

class _OutOfStockBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: OmniSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: OmniColors.dangerBg,
        borderRadius: OmniRadius.fullAll,
      ),
      child: Text(
        'Agotado',
        style: OmniTypography.caption.copyWith(color: OmniColors.danger),
      ),
    );
  }
}

class _TileBottomInfo extends ConsumerWidget {
  const _TileBottomInfo({required this.product});
  final ProductEntity product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: OmniTypography.bodyMd.copyWith(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: OmniSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              ref.formatMoney(product.price),
              style: OmniTypography.headingSm.copyWith(
                color: OmniColors.primary,
              ),
            ),
            Text('${product.stock} uds', style: OmniTypography.caption),
          ],
        ),
      ],
    );
  }
}
