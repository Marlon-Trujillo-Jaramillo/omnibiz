import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:inventario_app/core/isar_provider.dart';
import 'package:inventario_app/models/product_model.dart';
import 'package:inventario_app/widgets/barcode_scanner_button.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String businessType;
  const AddProductScreen({super.key, required this.businessType});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();
  final _barcodeController = TextEditingController();
  final List<String> _variants = [];
  final _variantController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información General'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Nombre del Producto',
                icon: LucideIcons.tag,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
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
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Precio Venta',
                      icon: LucideIcons.dollarSign,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _costController,
                      label: 'Precio Costo',
                      icon: LucideIcons.wallet,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _stockController,
                label: 'Stock Inicial',
                icon: LucideIcons.package,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(
                widget.businessType == 'retail'
                    ? 'Tallas / Colores'
                    : 'Ingredientes / Opciones',
              ),
              const SizedBox(height: 16),
              _buildVariantInput(),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
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
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _saveProduct,
                  child: const Text(
                    'Guardar Producto',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.indigoAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white.withAlpha(5),
      ),
    );
  }

  Widget _buildVariantInput() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: _variantController,
            label: widget.businessType == 'retail'
                ? 'Ej: XL, Rojo'
                : 'Ej: Sin Cebolla',
            icon: LucideIcons.plus,
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: () {
            if (_variantController.text.isNotEmpty) {
              setState(() {
                _variants.add(_variantController.text);
                _variantController.clear();
              });
            }
          },
          icon: const Icon(LucideIcons.plus),
        ),
      ],
    );
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final product = Product()
        ..name = _nameController.text
        ..price = double.tryParse(_priceController.text) ?? 0.0
        ..costPrice = double.tryParse(_costController.text) ?? 0.0
        ..stock = int.tryParse(_stockController.text) ?? 0
        ..variants = _variants
        ..category = 'General'
        ..barcode = _barcodeController.text.isEmpty
            ? null
            : _barcodeController.text
        ..sku = 'SKU-${DateTime.now().millisecondsSinceEpoch}'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await ref.read(productsProvider.notifier).addProduct(product);
      if (mounted) Navigator.pop(context);
    }
  }
}
