import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/error/error_mapper.dart';
import 'package:inventario_app/core/error/failures.dart';
import 'package:inventario_app/core/utils/currency_formatter.dart';
import 'package:inventario_app/core/utils/form_validators.dart';
import 'package:inventario_app/core/utils/money.dart';
import 'package:inventario_app/features/customers/domain/entities/customer_entity.dart';
import 'package:inventario_app/features/customers/domain/repositories/customer_repository.dart';
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
    final search = ref.watch(_searchProvider);
    final customers = customersAsync.valueOrNull ?? [];
    final filtered = _filterCustomers(customers, search);
    final totalDebt = customers.fold(0, (s, c) => s + c.totalDebt);

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: _NewCustomerFab(onTap: _showAddDialog),
      body: OmniResponsiveCenter(
        child: Column(
          children: [
            if (customers.isNotEmpty)
              _DebtSummaryBanner(
                totalDebt: totalDebt,
                debtors: customers.where((c) => c.hasDebt).length,
                total: customers.length,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: OmniSpacing.base),
              child: OmniSearchBar(
                controller: _searchCtrl,
                hint: 'Buscar por nombre o teléfono',
                onChanged: (v) => ref.read(_searchProvider.notifier).state = v,
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
      ),
    );
  }

  List<CustomerEntity> _filterCustomers(
    List<CustomerEntity> all,
    String search,
  ) {
    if (search.isEmpty) return all;
    final q = search.toLowerCase();
    return all
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              (c.phone?.contains(search) ?? false),
        )
        .toList();
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
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        OmniSpacing.base,
        0,
        OmniSpacing.base,
        OmniSpacing.xxxl + OmniSpacing.xxl,
      ),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: OmniSpacing.sm),
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
      icon: hasSearch ? LucideIcons.searchX : LucideIcons.users,
      title: hasSearch ? 'Sin resultados' : 'Sin clientes aún',
      subtitle: hasSearch
          ? 'Intenta con otro término'
          : 'Registra clientes para venderles fiado y llevar su saldo',
    );
  }
}

// ── Debt summary ───────────────────────────────────────────────────────────────
class _DebtSummaryBanner extends ConsumerWidget {
  const _DebtSummaryBanner({
    required this.totalDebt,
    required this.debtors,
    required this.total,
  });
  final int totalDebt;
  final int debtors;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final hasDebt = totalDebt > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OmniSpacing.base,
        OmniSpacing.xs,
        OmniSpacing.base,
        OmniSpacing.base,
      ),
      child: OmniCard(
        child: Row(
          children: [
            OmniIconAvatar(
              icon: hasDebt
                  ? LucideIcons.notebookPen
                  : LucideIcons.checkCircle2,
              color: hasDebt ? c.danger : c.success,
            ),
            const SizedBox(width: OmniSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Por cobrar (fiado)', style: context.text.label),
                  const SizedBox(height: OmniSpacing.xxs),
                  Text(
                    ref.formatMoney(totalDebt),
                    style: context.text.priceLg.copyWith(
                      color: hasDebt ? c.danger : c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            OmniTag(
              label: '$debtors de $total',
              tone: hasDebt ? OmniTone.danger : OmniTone.success,
              icon: LucideIcons.users,
            ),
          ],
        ),
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
    );
  }
}

// ── Customer tile ──────────────────────────────────────────────────────────────
class _CustomerTile extends ConsumerWidget {
  const _CustomerTile(this.customer);
  final CustomerEntity customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OmniCard(
      onTap: customer.hasDebt ? () => _openPay(context, ref, customer) : null,
      padding: const EdgeInsets.fromLTRB(
        OmniSpacing.md,
        OmniSpacing.md,
        OmniSpacing.xs,
        OmniSpacing.md,
      ),
      child: Row(
        children: [
          OmniAvatar(name: customer.name),
          const SizedBox(width: OmniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: context.text.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (customer.phone != null) ...[
                  const SizedBox(height: OmniSpacing.xxs),
                  Text(customer.phone!, style: context.text.caption.tabular),
                ],
              ],
            ),
          ),
          customer.hasDebt
              ? OmniTag(
                  label: 'Debe ${ref.formatMoney(customer.totalDebt)}',
                  tone: OmniTone.danger,
                )
              : const OmniTag(
                  label: 'Al día',
                  tone: OmniTone.success,
                  icon: LucideIcons.check,
                ),
          _CustomerMenu(customer: customer),
        ],
      ),
    );
  }
}

Future<void> _openPay(
  BuildContext context,
  WidgetRef ref,
  CustomerEntity customer,
) {
  return showDialog(
    context: context,
    builder: (_) => _PayDialog(customer: customer, ref: ref),
  );
}

class _CustomerMenu extends ConsumerWidget {
  const _CustomerMenu({required this.customer});
  final CustomerEntity customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return PopupMenuButton<String>(
      tooltip: 'Opciones',
      icon: Icon(
        LucideIcons.moreVertical,
        size: OmniSizes.iconSm,
        color: c.textMuted,
      ),
      onSelected: (v) => _onSelected(context, ref, v),
      itemBuilder: (_) => [
        if (customer.hasDebt)
          PopupMenuItem(
            value: 'pay',
            child: _MenuRow(
              icon: LucideIcons.wallet,
              label: 'Registrar pago',
              color: c.success,
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: _MenuRow(
            icon: LucideIcons.trash2,
            label: 'Eliminar',
            color: c.danger,
          ),
        ),
      ],
    );
  }

  Future<void> _onSelected(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    if (value == 'pay') {
      await _openPay(context, ref, customer);
      return;
    }
    if (customer.totalDebt > 0) {
      ScaffoldMessenger.of(context).showOmni(
        '${customer.name} debe ${ref.formatMoney(customer.totalDebt)}. '
        'Registra el abono antes de eliminarlo.',
        tone: OmniTone.warning,
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
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(customersProvider.notifier).delete(customer.id);
    } on CustomerHasDebtException catch (e) {
      // La deuda cambió entre el aviso y el borrado: el repositorio lo impide.
      messenger.showOmni(
        '${customer.name} debe ${ref.formatMoney(e.debt)}. '
        'Registra el abono antes de eliminarlo.',
        tone: OmniTone.warning,
      );
    }
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
        Icon(icon, size: OmniSizes.iconSm, color: color),
        const SizedBox(width: OmniSpacing.md),
        Text(label, style: context.text.bodyMd.copyWith(color: color)),
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
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(int storeId) async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.ref
          .read(customersProvider.notifier)
          .add(
            CustomerEntity(
              id: 0,
              name: _nameCtrl.text.trim(),
              phone: _phoneCtrl.text.trim().isEmpty
                  ? null
                  : _phoneCtrl.text.trim(),
              totalDebt: 0,
              createdAt: DateTime.now(),
              storeId: storeId,
            ),
          );
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
      messenger.showOmni('No se pudo crear el cliente.', tone: OmniTone.danger);
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Sin sucursal cargada no se crea nada (nunca storeId 0).
    final storeId = widget.ref.read(currentStoreProvider);
    return Form(
      key: _formKey,
      child: OmniDialog(
        title: 'Nuevo cliente',
        icon: LucideIcons.userPlus,
        actions: OmniDialogActions(
          onCancel: () => Navigator.pop(context),
          onConfirm: storeId == null ? null : () => _submit(storeId),
          confirmLabel: 'Crear',
          loading: _submitting,
        ),
        child: Column(
          children: [
            OmniTextField(
              controller: _nameCtrl,
              label: 'Nombre completo',
              prefixIcon: LucideIcons.user,
              autofocus: true,
              validator: (v) => FormValidators.required(v, 'Nombre'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: OmniSpacing.md),
            OmniTextField(
              controller: _phoneCtrl,
              label: 'Teléfono (opcional)',
              prefixIcon: LucideIcons.phone,
              keyboardType: TextInputType.phone,
              tabularDigits: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: FormValidators.phone,
              textInputAction: TextInputAction.done,
            ),
          ],
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
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: Money.toInput(widget.customer.totalDebt),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String? _validateAmount(String? v) {
    final base = FormValidators.money(v, 'Monto');
    if (base != null) return base;
    final amount = Money.parse(v)!;
    if (amount > widget.customer.totalDebt) {
      return 'No puede superar la deuda '
          '(${CurrencyFormatter.format(widget.customer.totalDebt, widget.ref.read(currencyProvider))})';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final amount = Money.parse(_amountCtrl.text)!;
    final currency = widget.ref.read(currencyProvider);
    // Capturar antes de cerrar el diálogo: su context deja de ser válido.
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.ref
          .read(customersProvider.notifier)
          .registerPayment(widget.customer.id, amount);
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
      messenger.showOmni(
        e is InvalidPaymentException
            ? e.message
            : 'No se pudo registrar el pago.',
        tone: OmniTone.danger,
      );
      return;
    }
    if (mounted) Navigator.pop(context);
    messenger.showOmni(
      'Pago de ${CurrencyFormatter.format(amount, currency)} registrado',
      tone: OmniTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: OmniDialog(
        title: 'Registrar pago',
        subtitle: widget.customer.name,
        icon: LucideIcons.wallet,
        tone: OmniTone.success,
        actions: OmniDialogActions(
          onCancel: () => Navigator.pop(context),
          onConfirm: _submit,
          confirmLabel: 'Confirmar',
          loading: _submitting,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Deuda actual', style: context.text.label),
                const Spacer(),
                Text(
                  CurrencyFormatter.format(
                    widget.customer.totalDebt,
                    widget.ref.read(currencyProvider),
                  ),
                  style: context.text.moneyMd.copyWith(
                    color: context.colors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: OmniSpacing.base),
            OmniTextField(
              controller: _amountCtrl,
              label: 'Monto pagado',
              prefixIcon: LucideIcons.dollarSign,
              tabularDigits: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: _validateAmount,
            ),
          ],
        ),
      ),
    );
  }
}
