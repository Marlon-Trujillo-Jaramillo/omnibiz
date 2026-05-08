import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:inventario_app/features/customers/customers_provider.dart';
import 'package:inventario_app/models/customer_model.dart';

final _customerSearchProvider = StateProvider<String>((ref) => '');

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCustomers = ref.watch(customersProvider);
    final searchQuery = ref.watch(_customerSearchProvider);

    final customers = searchQuery.isEmpty
        ? allCustomers
        : allCustomers
            .where(
              (c) =>
                  c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  (c.phone?.contains(searchQuery) ?? false),
            )
            .toList();

    final totalDebt = allCustomers.fold(0.0, (s, c) => s + c.totalDebt);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(title: const Text('Gestión de Clientes'), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Debt summary card
            if (totalDebt > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deuda total pendiente',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          Text(
                            '\$${totalDebt.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Search
            TextField(
              onChanged: (v) =>
                  ref.read(_customerSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o celular...',
                prefixIcon: const Icon(LucideIcons.search),
                filled: true,
                fillColor: Colors.white.withAlpha(5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: customers.isEmpty
                  ? const _NoCustomersPlaceholder()
                  : ListView.builder(
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return _CustomerListItem(
                          customer: customer,
                          onPayDebt: customer.totalDebt > 0
                              ? () => _showPayDebtDialog(context, ref, customer)
                              : null,
                          onDelete: () =>
                              _confirmDelete(context, ref, customer),
                        );
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

  void _showPayDebtDialog(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) {
    final controller = TextEditingController(
      text: customer.totalDebt.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Cobrar a ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deuda actual: \$${customer.totalDebt.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto a cobrar',
                prefixText: '\$',
              ),
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
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                ref
                    .read(customersProvider.notifier)
                    .updateDebt(customer.id, -amount);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pago de \$${amount.toStringAsFixed(2)} registrado',
                    ),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.greenAccent),
            child: const Text(
              'Registrar pago',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Eliminar cliente'),
        content: Text('¿Eliminar a ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(customersProvider.notifier).deleteCustomer(customer.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
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
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Celular / WhatsApp'),
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
              if (nameController.text.trim().isNotEmpty) {
                final customer = Customer()
                  ..name = nameController.text.trim()
                  ..phone = phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim()
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
  final VoidCallback? onPayDebt;
  final VoidCallback onDelete;

  const _CustomerListItem({
    required this.customer,
    required this.onPayDebt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  customer.phone ?? 'Sin teléfono',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
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
                  fontSize: 15,
                ),
              ),
              const Text(
                'Deuda',
                style: TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, size: 18, color: Colors.white38),
            color: const Color(0xFF2A2A2A),
            onSelected: (v) {
              if (v == 'pay') onPayDebt?.call();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              if (onPayDebt != null)
                const PopupMenuItem(
                  value: 'pay',
                  child: Row(
                    children: [
                      Icon(LucideIcons.dollarSign, size: 16, color: Colors.greenAccent),
                      SizedBox(width: 8),
                      Text('Registrar pago'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 64, color: Colors.white10),
          SizedBox(height: 16),
          Text(
            'No hay clientes registrados',
            style: TextStyle(color: Colors.white24),
          ),
        ],
      ),
    );
  }
}
