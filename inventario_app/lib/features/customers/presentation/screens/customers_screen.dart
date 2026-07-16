import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/error/error_mapper.dart';
import 'package:inventario_app/core/error/failures.dart';
import 'package:inventario_app/core/utils/currency_formatter.dart';
import 'package:inventario_app/core/utils/form_validators.dart';
import 'package:inventario_app/features/customers/domain/entities/customer_entity.dart';
import 'package:inventario_app/features/customers/presentation/providers/customers_notifier.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';

final _searchProvider = StateProvider.autoDispose<String>((ref) => '');

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final search         = ref.watch(_searchProvider);
    final customers      = customersAsync.valueOrNull ?? [];
    final filtered       = _filterCustomers(customers, search);
    final totalDebt      = customers.fold(0.0, (s, c) => s + c.totalDebt);

    return Scaffold(
      backgroundColor: OmniColors.bg,
      appBar: AppBar(
        backgroundColor: OmniColors.bg,
        elevation: 0,
        title: Text('Clientes', style: OmniTypography.headingMd),
      ),
      floatingActionButton: _NewCustomerFab(onTap: _showAddDialog),
      body: Column(
        children: [
          if (totalDebt > 0) _DebtSummaryBanner(totalDebt: totalDebt),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: OmniSpacing.lg),
            child: OmniSearchBar(
              controller: _searchCtrl,
              hint: 'Buscar por nombre o teléfono',
              onChanged: (v) =>
                  ref.read(_searchProvider.notifier).state = v,
            ),
          ),
          const SizedBox(height: OmniSpacing.base),
          Expanded(
            child: customersAsync.when(
              loading: () => const OmniSkeletonList(),
              error: (e, _) => OmniErrorState(
                message: e is Failure
                    ? ErrorMapper.toMessage(e)
                    : 'Error al cargar los clientes.',
                onRetry: () => ref.invalidate(customersProvider),
              ),
              data: (_) => RefreshIndicator(
                onRefresh: () => ref.refresh(customersProvider.future),
                color: OmniColors.primary,
                backgroundColor: OmniColors.bgSurface,
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _EmptyCustomers(hasSearch: search.isNotEmpty),
                        ],
                      )
                    : _CustomersList(customers: filtered),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<CustomerEntity> _filterCustomers(
      List<CustomerEntity> all, String search) {
    if (search.isEmpty) return all;
    final q = search.toLowerCase();
    return all.where((c) =>
        c.name.toLowerCase().contains(q) ||
        (c.phone?.contains(search) ?? false)).toList();
  }

  Future<void> _showAddDialog() async {
    await showDialog(
      context: context,
      builder: (_) => _AddCustomerDialog(ref: ref),
    );
  }
}

// ── List ───────────────────────────────────────────────────────────────────────
class _CustomersList extends StatelessWidget {
  const _CustomersList({required this.customers});
  final List<CustomerEntity> customers;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: OmniSpacing.lg),
      itemCount: customers.length,
      itemBuilder: (_, i) => _CustomerTile(customers[i]),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyCustomers extends StatelessWidget {
  const _EmptyCustomers({required this.hasSearch});
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return OmniEmptyState(
      icon: LucideIcons.users,
      title: hasSearch ? 'Sin resultados' : 'Sin clientes aún',
      subtitle: hasSearch
          ? 'Intenta con otro término'
          : 'Agrega tu primer cliente',
    );
  }
}

// ── Debt summary banner ────────────────────────────────────────────────────────
class _DebtSummaryBanner extends ConsumerWidget {
  const _DebtSummaryBanner({required this.totalDebt});
  final double totalDebt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        OmniSpacing.lg, 0, OmniSpacing.lg, OmniSpacing.base),
      padding: const EdgeInsets.all(OmniSpacing.base),
      decoration: BoxDecoration(
        color: OmniColors.dangerBg,
        borderRadius: OmniRadius.lgAll,
        border: Border.all(color: OmniColors.danger.withAlpha(40)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle,
              color: OmniColors.danger, size: 18),
          const SizedBox(width: OmniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deuda total pendiente',
                    style: OmniTypography.caption),
                const SizedBox(height: OmniSpacing.xs),
                Text(
                  ref.formatMoney(totalDebt),
                  style: OmniTypography.headingMd.copyWith(
                    color: OmniColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── FAB ────────────────────────────────────────────────────────────────────────
class _NewCustomerFab extends StatelessWidget {
  const _NewCustomerFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      icon: const Icon(LucideIcons.userPlus),
      label: const Text('Nuevo cliente'),
      backgroundColor: OmniColors.primary,
      foregroundColor: Colors.white,
    );
  }
}

// ── Customer tile ──────────────────────────────────────────────────────────────
class _CustomerTile extends ConsumerWidget {
  const _CustomerTile(this.customer);
  final CustomerEntity customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: OmniSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: OmniSpacing.base,
        vertical: OmniSpacing.md,
      ),
      decoration: BoxDecoration(
        color: OmniColors.bgSurface,
        borderRadius: OmniRadius.lgAll,
        border: Border.all(color: OmniColors.borderSubtle),
      ),
      child: Row(
        children: [
          OmniAvatar(name: customer.name),
          const SizedBox(width: OmniSpacing.md),
          Expanded(child: _CustomerInfo(customer: customer)),
          _DebtBadge(customer: customer),
          const SizedBox(width: OmniSpacing.xs),
          _CustomerMenu(customer: customer),
        ],
      ),
    );
  }
}

class _CustomerInfo extends StatelessWidget {
  const _CustomerInfo({required this.customer});
  final CustomerEntity customer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(customer.name, style: OmniTypography.headingSm,
            overflow: TextOverflow.ellipsis),
        if (customer.phone != null) ...[
          const SizedBox(height: 2),
          Text(customer.phone!, style: OmniTypography.caption),
        ],
      ],
    );
  }
}

class _DebtBadge extends ConsumerWidget {
  const _DebtBadge({required this.customer});
  final CustomerEntity customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          ref.formatMoney(customer.totalDebt),
          style: OmniTypography.headingSm.copyWith(
            color: customer.hasDebt ? OmniColors.danger : OmniColors.success,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text('Deuda', style: OmniTypography.caption),
      ],
    );
  }
}

class _CustomerMenu extends ConsumerWidget {
  const _CustomerMenu({required this.customer});
  final CustomerEntity customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreVertical,
          size: 16, color: OmniColors.textMuted),
      color: OmniColors.bgPopup,
      onSelected: (v) => _onSelected(context, ref, v),
      itemBuilder: (_) => [
        if (customer.hasDebt)
          const PopupMenuItem(
            value: 'pay',
            child: _MenuRow(
              icon: LucideIcons.creditCard,
              label: 'Registrar pago',
              color: OmniColors.success,
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: _MenuRow(
            icon: LucideIcons.trash2,
            label: 'Eliminar',
            color: OmniColors.danger,
          ),
        ),
      ],
    );
  }

  Future<void> _onSelected(
      BuildContext context, WidgetRef ref, String value) async {
    if (value == 'pay') {
      await showDialog(
        context: context,
        builder: (_) => _PayDialog(customer: customer, ref: ref),
      );
      return;
    }
    final ok = await OmniConfirmDialog.show(
      context,
      icon: LucideIcons.userX,
      title: 'Eliminar cliente',
      body: '¿Eliminar a "${customer.name}"?',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (ok) ref.read(customersProvider.notifier).delete(customer.id);
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: OmniSpacing.sm),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

// ── Add customer dialog ────────────────────────────────────────────────────────
class _AddCustomerDialog extends StatefulWidget {
  const _AddCustomerDialog({required this.ref});
  final WidgetRef ref;

  @override
  State<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<_AddCustomerDialog> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.ref.read(customersProvider.notifier).add(
      CustomerEntity(
        id:        0,
        name:      _nameCtrl.text.trim(),
        phone:     _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
        totalDebt: 0,
        createdAt: DateTime.now(),
        storeId:   widget.ref.read(currentStoreProvider) ?? 0,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: OmniColors.bgModal,
      shape: RoundedRectangleBorder(borderRadius: OmniRadius.xlAll),
      child: Padding(
        padding: const EdgeInsets.all(OmniSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nuevo Cliente', style: OmniTypography.headingMd),
              const SizedBox(height: OmniSpacing.xl),
              OmniTextField(
                controller: _nameCtrl,
                label: 'Nombre completo',
                prefixIcon: LucideIcons.user,
                validator: (v) => FormValidators.required(v, 'Nombre'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: OmniSpacing.md),
              OmniTextField(
                controller: _phoneCtrl,
                label: 'Teléfono (opcional)',
                prefixIcon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: FormValidators.phone,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: OmniSpacing.xl),
              _DialogActions(
                onCancel: () => Navigator.pop(context),
                onConfirm: _submit,
                confirmLabel: 'Crear',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pay dialog ─────────────────────────────────────────────────────────────────
class _PayDialog extends StatefulWidget {
  const _PayDialog({required this.customer, required this.ref});
  final CustomerEntity customer;
  final WidgetRef ref;

  @override
  State<_PayDialog> createState() => _PayDialogState();
}

class _PayDialogState extends State<_PayDialog> {
  late final TextEditingController _amountCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
        text: widget.customer.totalDebt.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text.trim());
    await widget.ref
        .read(customersProvider.notifier)
        .registerPayment(widget.customer.id, amount);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Pago de ${CurrencyFormatter.format(amount, widget.ref.read(currencyProvider))} registrado'),
        backgroundColor: OmniColors.bgPopup,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: OmniColors.bgModal,
      shape: RoundedRectangleBorder(borderRadius: OmniRadius.xlAll),
      child: Padding(
        padding: const EdgeInsets.all(OmniSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registrar Pago', style: OmniTypography.headingMd),
              const SizedBox(height: OmniSpacing.xs),
              Text('Cliente: ${widget.customer.name}',
                  style: OmniTypography.bodySm),
              const SizedBox(height: OmniSpacing.xl),
              OmniTextField(
                controller: _amountCtrl,
                label: 'Monto pagado',
                prefixIcon: LucideIcons.dollarSign,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                validator: (v) => FormValidators.positiveNumber(v, 'Monto'),
              ),
              const SizedBox(height: OmniSpacing.xl),
              _DialogActions(
                onCancel: () => Navigator.pop(context),
                onConfirm: _submit,
                confirmLabel: 'Confirmar',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared dialog actions row ──────────────────────────────────────────────────
class _DialogActions extends StatelessWidget {
  const _DialogActions({
    required this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
  });
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OmniButton(
            label: 'Cancelar',
            onPressed: onCancel,
            variant: OmniButtonVariant.ghost,
          ),
        ),
        const SizedBox(width: OmniSpacing.md),
        Expanded(
          child: OmniButton(label: confirmLabel, onPressed: onConfirm),
        ),
      ],
    );
  }
}
