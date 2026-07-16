import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/error/error_mapper.dart';
import 'package:inventario_app/core/error/failures.dart';
import 'package:inventario_app/core/utils/app_constants.dart';
import 'package:inventario_app/core/utils/form_validators.dart';
import 'package:inventario_app/features/inventory/domain/entities/product_entity.dart';
import 'package:inventario_app/features/inventory/presentation/providers/products_notifier.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';
import 'package:inventario_app/shared/widgets/barcode_scanner_button.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key, this.product});
  final ProductEntity? product;

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _priceCtrl    = TextEditingController();
  final _costCtrl     = TextEditingController();
  final _stockCtrl    = TextEditingController();
  final _barcodeCtrl  = TextEditingController();
  final _variantCtrl  = TextEditingController();
  final List<String> _variants = [];
  String _category = 'General';
  bool _loading = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameCtrl.text    = p.name;
      _priceCtrl.text   = p.price.toString();
      _costCtrl.text    = p.costPrice.toString();
      _stockCtrl.text   = p.stock.toString();
      _barcodeCtrl.text = p.barcode ?? '';
      _category         = p.category;
      _variants.addAll(p.variants);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose(); _costCtrl.dispose();
    _stockCtrl.dispose(); _barcodeCtrl.dispose(); _variantCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final p   = widget.product;

      final product = ProductEntity(
        id:        p?.id ?? 0,
        name:      _nameCtrl.text.trim(),
        category:  _category,
        price:     double.parse(_priceCtrl.text.trim()),
        costPrice: double.parse(_costCtrl.text.trim()),
        stock:     int.parse(_stockCtrl.text.trim()),
        sku:       p?.sku ?? '${AppConstants.skuPrefix}${now.millisecondsSinceEpoch}',
        variants:  List.from(_variants),
        barcode:   _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
        createdAt: p?.createdAt ?? now,
        updatedAt: now,
        storeId:   p?.storeId ?? ref.read(currentStoreProvider) ?? 0,
      );

      if (_isEdit) {
        await ref.read(productsProvider.notifier).edit(product);
      } else {
        await ref.read(productsProvider.notifier).add(product);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e is Failure
          ? ErrorMapper.toMessage(e)
          : 'Error al guardar el producto. Intenta de nuevo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: OmniColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addVariant() {
    final v = _variantCtrl.text.trim();
    if (v.isEmpty || _variants.contains(v)) return;
    setState(() { _variants.add(v); _variantCtrl.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final raw        = categoriesAsync.valueOrNull?.map((c) => c.name).toList() ?? [];
    final categories = raw.isEmpty ? ['General'] : raw;
    if (!categories.contains(_category)) _category = categories.first;

    return Scaffold(
      backgroundColor: OmniColors.bg,
      appBar: AppBar(
        backgroundColor: OmniColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: OmniColors.textSecondary),
          onPressed: _loading ? null : () => context.pop(),
        ),
        title: Text(
          _isEdit ? 'Editar Producto' : 'Nuevo Producto',
          style: OmniTypography.headingSm,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: OmniSpacing.base),
            child: OmniButton(
              label: 'Guardar',
              onPressed: _loading ? null : _save,
              loading: _loading,
              size: OmniButtonSize.sm,
            ),
          ),
        ],
      ),
      body: OmniLoadingOverlay(
        isLoading: _loading,
        label: 'Guardando...',
        child: OmniResponsiveCenter(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (_, constraints) {
              final wide = constraints.maxWidth >= OmniBreakpoints.tablet;
              return ListView(
                padding: const EdgeInsets.all(OmniSpacing.lg),
                children: [
                  _sectionTitle('Información básica'),
                  OmniTextField(
                    controller: _nameCtrl,
                    label: 'Nombre del producto',
                    prefixIcon: LucideIcons.package,
                    validator: (v) => FormValidators.required(v, 'Nombre'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: OmniSpacing.md),
                  if (wide)
                    _ThreeFieldRow(
                      priceCtrl: _priceCtrl,
                      costCtrl: _costCtrl,
                      stockCtrl: _stockCtrl,
                    )
                  else ...[
                    Row(children: [
                      Expanded(child: _PriceField(ctrl: _priceCtrl)),
                      const SizedBox(width: OmniSpacing.md),
                      Expanded(child: _CostField(ctrl: _costCtrl)),
                    ]),
                    const SizedBox(height: OmniSpacing.md),
                    _StockField(ctrl: _stockCtrl),
                  ],
                  const SizedBox(height: OmniSpacing.xxl),
                  _sectionTitle('Categoría'),
                  _CategoryDropdown(
                    value: _category,
                    categories: categories,
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: OmniSpacing.xxl),
                  _sectionTitle('Código de barras'),
                  OmniTextField(
                    controller: _barcodeCtrl,
                    label: 'Código de barras (opcional)',
                    prefixIcon: LucideIcons.scan,
                    suffixWidget: BarcodeScannerButton(
                      onResult: (code) =>
                          setState(() => _barcodeCtrl.text = code),
                    ),
                    keyboardType: TextInputType.visiblePassword,
                  ),
                  const SizedBox(height: OmniSpacing.xxl),
                  _sectionTitle('Variantes'),
                  _VariantInput(
                    controller: _variantCtrl,
                    onAdd: _addVariant,
                  ),
                  if (_variants.isNotEmpty) ...[
                    const SizedBox(height: OmniSpacing.md),
                    Wrap(
                      spacing: OmniSpacing.sm,
                      runSpacing: OmniSpacing.sm,
                      children: _variants
                          .map((v) => OmniInputChip(
                                label: v,
                                onDelete: () =>
                                    setState(() => _variants.remove(v)),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: OmniSpacing.xxl),
                  OmniButton(
                    label: _isEdit ? 'Guardar cambios' : 'Crear Producto',
                    onPressed: _loading ? null : _save,
                    loading: _loading,
                    fullWidth: true,
                    size: OmniButtonSize.lg,
                  ),
                  const SizedBox(height: OmniSpacing.xl),
                ],
              );
            },
          ),
        ),
      ),
    ),
    );
  }

  Widget _sectionTitle(String label) => Padding(
        padding: const EdgeInsets.only(bottom: OmniSpacing.md),
        child: Text(label, style: OmniTypography.headingMd),
      );
}

// ── Form field widgets ─────────────────────────────────────────────────────────
class _PriceField extends StatelessWidget {
  const _PriceField({required this.ctrl});
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) => OmniTextField(
    controller: ctrl,
    label: 'Precio de venta',
    prefixIcon: LucideIcons.dollarSign,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    validator: (v) => FormValidators.positiveNumber(v, 'Precio'),
    textInputAction: TextInputAction.next,
  );
}

class _CostField extends StatelessWidget {
  const _CostField({required this.ctrl});
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) => OmniTextField(
    controller: ctrl,
    label: 'Precio de costo',
    prefixIcon: LucideIcons.tag,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    validator: (v) => FormValidators.positiveNumber(v, 'Costo'),
    textInputAction: TextInputAction.next,
  );
}

class _StockField extends StatelessWidget {
  const _StockField({required this.ctrl});
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) => OmniTextField(
    controller: ctrl,
    label: 'Stock inicial',
    prefixIcon: LucideIcons.boxes,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    validator: (v) => FormValidators.nonNegativeInt(v, 'Stock'),
    textInputAction: TextInputAction.next,
  );
}

class _ThreeFieldRow extends StatelessWidget {
  const _ThreeFieldRow({
    required this.priceCtrl,
    required this.costCtrl,
    required this.stockCtrl,
  });
  final TextEditingController priceCtrl;
  final TextEditingController costCtrl;
  final TextEditingController stockCtrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _PriceField(ctrl: priceCtrl)),
        const SizedBox(width: OmniSpacing.md),
        Expanded(child: _CostField(ctrl: costCtrl)),
        const SizedBox(width: OmniSpacing.md),
        Expanded(child: _StockField(ctrl: stockCtrl)),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.value,
    required this.categories,
    required this.onChanged,
  });
  final String value;
  final List<String> categories;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: OmniColors.bgModal,
      style: OmniTypography.bodyMd,
      decoration: InputDecoration(
        filled: true,
        fillColor: OmniColors.borderSubtle,
        border: OutlineInputBorder(
          borderRadius: OmniRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OmniSpacing.base,
          vertical: OmniSpacing.md,
        ),
      ),
      items: categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _VariantInput extends StatelessWidget {
  const _VariantInput({required this.controller, required this.onAdd});
  final TextEditingController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OmniTextField(
            controller: controller,
            hint: 'Ej: Talla M, Color Rojo...',
            onSubmitted: (_) => onAdd(),
            textInputAction: TextInputAction.done,
          ),
        ),
        const SizedBox(width: OmniSpacing.sm),
        OmniButton(
          label: 'Agregar',
          onPressed: onAdd,
          variant: OmniButtonVariant.secondary,
          size: OmniButtonSize.sm,
        ),
      ],
    );
  }
}
