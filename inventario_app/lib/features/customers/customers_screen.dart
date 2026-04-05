import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:inventario_app/features/customers/customers_provider.dart';
import 'package:inventario_app/models/customer_model.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(title: const Text('Gestión de Clientes'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildCustomerSearch(),
            const SizedBox(height: 24),
            Expanded(
              child: customers.isEmpty
                  ? const _NoCustomersPlaceholder()
                  : ListView.builder(
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return _CustomerListItem(customer: customer);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context, ref),
        child: const Icon(LucideIcons.userPlus),
      ),
    );
  }

  Widget _buildCustomerSearch() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o celular...',
        prefixIcon: const Icon(LucideIcons.search),
        filled: true,
        fillColor: Colors.white.withAlpha(5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Nuevo Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre Completo'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Celular/WhatsApp'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final customer = Customer()
                  ..name = nameController.text
                  ..phone = phoneController.text
                  ..totalDebt = 0.0;
                ref.read(customersProvider.notifier).addCustomer(customer);
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _CustomerListItem extends StatelessWidget {
  final Customer customer;
  const _CustomerListItem({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigoAccent.withAlpha(20),
            child: Text(
              customer.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.indigoAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  customer.phone ?? 'Sin teléfono',
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${customer.totalDebt.toStringAsFixed(2)}',
                style: TextStyle(
                  color: customer.totalDebt > 0
                      ? Colors.redAccent
                      : Colors.greenAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Text(
                'Deuda Actual',
                style: TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoCustomersPlaceholder extends StatelessWidget {
  const _NoCustomersPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.users, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          const Text(
            'No hay clientes registrados',
            style: TextStyle(color: Colors.white24),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
