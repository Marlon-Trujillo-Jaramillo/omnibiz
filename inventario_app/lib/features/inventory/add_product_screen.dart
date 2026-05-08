import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:inventario_app/core/isar_provider.dart';
import 'package:inventario_app/models/product_model.dart';
import 'package:inventario_app/widgets/barcode_scanner_button.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String businessType;
  final Product? product; // non-null when editing
  const AddProductScreen({super.key, required this.businessType, this.product});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _costController;
  late final TextEditingController _stockController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _variantController;
  late List<String> _variants;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.toString() : '',
    );
    _costController = TextEditingController(
      text: p != null ? p.costPrice.toString() : '',
    );
    _stockController = TextEditingController(
      text: p != null ? p.stock.toString() : '',
    );
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _variantController = TextEditingController();
    _variants = List.from(p?.variants ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    _variantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Información General'),
              const SizedBox(height: 16),
              _buildField(
                controller: _nameController,
                label: 'Nombre del Producto',
                icon: LucideIcons.tag,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'El nombre es requerido' : null,
                capitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _barcodeController,
                      label: 'Código de Barras',
                      icon: LucideIcons.scan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  BarcodeScannerButton(
                    onResult: (code) =>
                        setState(() => _barcodeController.text = code),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _priceController,
                      label: 'Precio de Venta',
                      icon: LucideIcons.dollarSign,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _validatePositiveNumber,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildField(
                      controller: _costController,
                      label: 'Precio de Costo',
                      icon: LucideIcons.wallet,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _validatePositiveNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _stockController,
                label: 'Stock Inicial',
                icon: LucideIcons.package,
                keyboardType: TextInputType.number,
                validator: _validateStock,
              ),
              const SizedBox(height: 32),
              _sectionTitle(
                widget.businessType == 'retail'
                    ? 'Tallas / Colores'
                    : 'Ingredientes / Opciones',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _variantController,
                      label: widget.businessType == 'retail'
                          ? 'Ej: XL, Rojo'
                          : 'Ej: Sin Cebolla',
                      icon: LucideIcons.plus,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: _addVariant,
                    icon: const Icon(LucideIcons.plus),
                  ),
                ],
              ),
              if (_variants.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _variants
                      .map(
                        (v) => Chip(
                          label: Text(v),
                          onDeleted: () => setState(() => _variants.remove(v)),
                          backgroundColor: Colors.indigoAccent.withAlpha(20),
                          labelStyle: const TextStyle(color: Colors.indigoAccent),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing ? 'Guardar Cambios' : 'Guardar Producto',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textCapitalization: capitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.indigoAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white.withAlpha(5),
      ),
    );
  }

  String? _validatePositiveNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Número inválido';
    if (n < 0) return 'Debe ser positivo';
    return null;
  }

  String? _validateStock(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Número entero requerido';
    if (n < 0) return 'Debe ser 0 o más';
    return null;
  }

  void _addVariant() {
    final text = _variantController.text.trim();
    if (text.isNotEmpty && !_variants.contains(text)) {
      setState(() {
        _variants.add(text);
        _variantController.clear();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final isEditing = widget.product != null;
    final product = (widget.product ?? Product())
      ..name = _nameController.text.trim()
      ..price = double.parse(_priceController.text.trim())
      ..costPrice = double.parse(_costController.text.trim())
      ..stock = int.parse(_stockController.text.trim())
      ..variants = _variants
      ..category = 'General'
      ..barcode = _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim()
      ..sku = isEditing
          ? (widget.product!.sku)
          : 'SKU-${DateTime.now().millisecondsSinceEpoch}'
      ..createdAt = isEditing ? widget.product!.createdAt : DateTime.now()
      ..updatedAt = DateTime.now();

    await ref.read(productsProvider.notifier).addProduct(product);

    if (mounted) Navigator.pop(context);
  }
}
