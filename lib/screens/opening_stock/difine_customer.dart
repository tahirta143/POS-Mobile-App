import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer_model.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_app_bar.dart';

class DefineCustomerScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const DefineCustomerScreen({super.key, this.onMenuPressed});

  @override
  State<DefineCustomerScreen> createState() => _DefineCustomerScreenState();
}

class _DefineCustomerScreenState extends State<DefineCustomerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers();
    });
  }

  void _openDialog({CustomerModel? customer}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CustomerDialog(customer: customer),
    ).then((_) => context.read<CustomerProvider>().fetchCustomers());
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Delete this customer?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true && mounted) {
      final success =
          await context.read<CustomerProvider>().deleteCustomer(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Customer deleted successfully.'
              : 'Failed to delete customer.'),
          backgroundColor: success ? AppConstants.primaryTeal : Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Define Customer',
        leading: IconButton(
            icon: const Icon(Icons.menu), onPressed: widget.onMenuPressed),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<CustomerProvider>().fetchCustomers(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        backgroundColor: AppConstants.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Customer',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.customers.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppConstants.primaryTeal));
          }
          if (provider.customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline,
                      size: 64,
                      color: isDark
                          ? AppConstants.darkTextSecondary
                          : AppConstants.lightTextSecondary),
                  const SizedBox(height: 12),
                  Text('No customers found yet.',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(
                left: 16, right: 16, top: 16, bottom: 80),
            itemCount: provider.customers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final c = provider.customers[index];
              return _CustomerCard(
                customer: c,
                isDark: isDark,
                onEdit: () => _openDialog(customer: c),
                onDelete: () => _confirmDelete(c.id!),
              );
            },
          );
        },
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard(
      {required this.customer,
      required this.isDark,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = isDark ? AppConstants.darkCard : AppConstants.lightCard;
    final borderColor =
        isDark ? AppConstants.darkBorder : AppConstants.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppConstants.primaryTeal.withOpacity(0.15),
                child: Text(
                  customer.customerName.isEmpty
                      ? '?'
                      : customer.customerName[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppConstants.primaryTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.customerName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontSize: 14)),
                    if (customer.mobileNumber.isNotEmpty)
                      Text(customer.mobileNumber,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PKR ${customer.previousBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: customer.previousBalance > 0
                            ? AppConstants.primaryTeal
                            : (isDark
                                ? AppConstants.darkTextPrimary
                                : AppConstants.lightTextPrimary),
                        fontFamily: 'monospace'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      customer.paymentMethod.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryTeal,
                          letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (customer.address.isNotEmpty || customer.nearby.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 13,
                    color: isDark
                        ? AppConstants.darkTextSecondary
                        : AppConstants.lightTextSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    [
                      if (customer.address.isNotEmpty) customer.address,
                      if (customer.nearby.isNotEmpty)
                        'Near: ${customer.nearby}',
                    ].join(' • '),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionBtn(
                  label: 'Edit',
                  color: AppConstants.primaryTeal,
                  onTap: onEdit),
              const SizedBox(width: 8),
              _ActionBtn(
                  label: 'Delete', color: Colors.red, onTap: onDelete),
            ],
          )
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: color.withOpacity(0.3))),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

// ─── Customer Dialog ──────────────────────────────────────────────────────────
class _CustomerDialog extends StatefulWidget {
  final CustomerModel? customer;
  const _CustomerDialog({this.customer});

  @override
  State<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<_CustomerDialog> {
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _nearbyCtrl = TextEditingController();
  String _paymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    if (c != null) {
      _nameCtrl.text = c.customerName;
      _mobileCtrl.text = c.mobileNumber;
      _addressCtrl.text = c.address;
      _balanceCtrl.text =
          c.previousBalance == 0 ? '' : c.previousBalance.toString();
      _nearbyCtrl.text = c.nearby;
      _paymentMethod = c.paymentMethod;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _balanceCtrl.dispose();
    _nearbyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Customer name is required.');
      return;
    }
    final customer = CustomerModel(
      customerName: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      mobileNumber: _mobileCtrl.text.trim(),
      previousBalance: double.tryParse(_balanceCtrl.text) ?? 0,
      nearby: _nearbyCtrl.text.trim(),
      paymentMethod: _paymentMethod,
    );
    final provider = context.read<CustomerProvider>();
    final ok = await provider.saveCustomer(customer,
        editId: widget.customer?.id);
    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.customer != null
              ? 'Customer updated successfully.'
              : 'Customer created successfully.'),
          backgroundColor: AppConstants.primaryTeal,
        ));
        Navigator.of(context).pop();
      }
    } else {
      _snack(provider.error ?? 'Unable to save customer.');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppConstants.darkCard : Colors.white;
    final borderColor =
        isDark ? AppConstants.darkBorder : AppConstants.lightBorder;
    final provider = context.watch<CustomerProvider>();

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.borderRadiusMedium)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      color: AppConstants.primaryTeal, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.customer != null
                          ? 'Edit Customer'
                          : 'Customer Registration',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Personal Details
              _SectionLabel(label: 'Personal Details'),
              const SizedBox(height: 10),

              _FormField(
                  label: 'Customer Name',
                  required: true,
                  controller: _nameCtrl,
                  hint: 'Full name',
                  isDark: isDark,
                  borderColor: borderColor),
              const SizedBox(height: 10),
              _FormField(
                  label: 'Mobile No / WhatsApp',
                  controller: _mobileCtrl,
                  hint: 'e.g. 0300-1234567',
                  keyboardType: TextInputType.phone,
                  isDark: isDark,
                  borderColor: borderColor),
              const SizedBox(height: 10),
              _FormField(
                  label: 'Address',
                  controller: _addressCtrl,
                  hint: 'Residential or billing address',
                  maxLines: 3,
                  isDark: isDark,
                  borderColor: borderColor),
              const SizedBox(height: 14),

              // Accounting & Area
              _SectionLabel(label: 'Accounting & Area'),
              const SizedBox(height: 10),
              _FormField(
                  label: 'Opening Balance',
                  controller: _balanceCtrl,
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  borderColor: borderColor),
              const SizedBox(height: 10),
              _FormField(
                  label: 'Nearby Landmark',
                  controller: _nearbyCtrl,
                  hint: 'e.g. Near Metro Station',
                  isDark: isDark,
                  borderColor: borderColor),
              const SizedBox(height: 10),

              // Payment Method
              _FieldLabel(label: 'Preferred Payment'),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: _inputDecoration(
                    isDark: isDark, borderColor: borderColor),
                items: ['Cash', 'Credit', 'Gift']
                    .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(
                            m == 'Cash'
                                ? 'Cash Basis'
                                : m == 'Credit'
                                    ? 'Credit / Ledger'
                                    : 'Gift Card',
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppConstants.darkTextPrimary
                                    : AppConstants.lightTextPrimary))))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _paymentMethod = val ?? 'Cash'),
                dropdownColor: cardColor,
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: provider.submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: provider.submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: provider.submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            widget.customer != null ? 'Update' : 'Save',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared local helpers ──────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
              color: AppConstants.primaryTeal,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 6),
      Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppConstants.primaryTeal
                  : AppConstants.lightTextPrimary,
              letterSpacing: 0.5)),
    ]);
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, this.required = false});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppConstants.darkTextSecondary
                  : AppConstants.lightTextPrimary)),
      if (required)
        const Text(' *',
            style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
    ]);
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool required;
  final TextInputType keyboardType;
  final int maxLines;
  final bool isDark;
  final Color borderColor;

  const _FormField({
    required this.label,
    required this.controller,
    this.hint,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, required: required),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppConstants.darkTextPrimary
                  : AppConstants.lightTextPrimary),
          decoration: _inputDecoration(
              isDark: isDark, borderColor: borderColor, hint: hint),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(
    {required bool isDark, required Color borderColor, String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true,
    fillColor: isDark ? AppConstants.darkBg : Colors.white,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: AppConstants.primaryTeal, width: 1.5)),
  );
}
