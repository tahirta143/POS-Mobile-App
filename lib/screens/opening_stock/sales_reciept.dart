import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sales_invoice_provider.dart';
import '../../models/sale_invoice_model.dart';
import '../../models/item.dart';
import '../../models/lookup_data.dart';
import '../../models/customer_model.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_loader.dart';

class SalesReceiptScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const SalesReceiptScreen({super.key, this.onMenuPressed});

  @override
  State<SalesReceiptScreen> createState() => _SalesReceiptScreenState();
}

class _SalesReceiptScreenState extends State<SalesReceiptScreen> {
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isInitialLoading = true;
      });
    }
    final p = context.read<SalesInvoiceProvider>();
    await Future.wait([
      p.fetchInitialData(),
      p.fetchInvoices(),
    ]);
    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await context.read<SalesInvoiceProvider>().fetchInvoices();
  }

  void _openDialog({SaleInvoiceListModel? editRecord}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SalesInvoiceDialog(editRecord: editRecord),
    ).then((_) => context.read<SalesInvoiceProvider>().fetchInvoices());
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Sale Record'),
        content: const Text('Delete this sale record?'),
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
          await context.read<SalesInvoiceProvider>().deleteInvoice(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Sale deleted successfully.'
              : 'Failed to delete sale.'),
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
        title: 'Sales Receipt',
        leading: IconButton(
            icon: const Icon(Icons.menu), onPressed: widget.onMenuPressed),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<SalesInvoiceProvider>().fetchInvoices(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        backgroundColor: AppConstants.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.receipt_long),
        label: const Text('New Invoice',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshData();
        },
        color: AppConstants.primaryTeal,
        child: Consumer<SalesInvoiceProvider>(
          builder: (context, provider, _) {
            if (_isInitialLoading) {
              return const CustomLoader();
            }
            if (provider.invoices.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 64,
                          color: isDark
                              ? AppConstants.darkTextSecondary
                              : AppConstants.lightTextSecondary),
                      const SizedBox(height: 12),
                      Text('No invoices found.',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 80),
              itemCount: provider.invoices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final inv = provider.invoices[index];
                return _InvoiceCard(
                  inv: inv,
                  isDark: isDark,
                  onEdit: () => _openDialog(editRecord: inv),
                  onDelete: () => _confirmDelete(inv.id),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final SaleInvoiceListModel inv;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InvoiceCard(
      {required this.inv,
      required this.isDark,
      required this.onEdit,
      required this.onDelete});

  Color get _statusColor {
    switch (inv.paymentStatus) {
      case 'Paid':
        return Colors.green;
      case 'Partial':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppConstants.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long,
                    color: AppConstants.primaryTeal, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv.displayRef,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontSize: 13, fontFamily: 'monospace')),
                    if (inv.customerName != null)
                      Text(inv.customerName!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PKR ${inv.payable.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppConstants.primaryTeal,
                        fontFamily: 'monospace'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      inv.paymentStatus.toUpperCase(),
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _statusColor,
                          letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              if (inv.mobileNumber != null && inv.mobileNumber!.isNotEmpty)
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 12,
                          color: isDark
                              ? AppConstants.darkTextSecondary
                              : AppConstants.lightTextSecondary),
                      const SizedBox(width: 4),
                      Text(inv.mobileNumber!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
              Text('Sub: PKR ${inv.subTotal.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
            ],
          ),
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
          ),
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

// ─── Sales Invoice Dialog ─────────────────────────────────────────────────────
class _SalesInvoiceDialog extends StatefulWidget {
  final SaleInvoiceListModel? editRecord;
  const _SalesInvoiceDialog({this.editRecord});

  @override
  State<_SalesInvoiceDialog> createState() => _SalesInvoiceDialogState();
}

class _SalesInvoiceDialogState extends State<_SalesInvoiceDialog> {
  final _mobileCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _givenCtrl = TextEditingController();
  late String _receiptNo;

  int? _customerId;
  List<CartRowModel> _cartRows = [];
  List<CustomerModel> _filteredCustomers = [];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _receiptNo = _generateReceiptNo();
    _cartRows = [_newRow()];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.editRecord != null) _prefillEdit();
    });
  }

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _discountCtrl.dispose();
    _givenCtrl.dispose();
    super.dispose();
  }

  CartRowModel _newRow() => CartRowModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
      );

  String _generateReceiptNo() {
    final d = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    final rand = (d.microsecond % 1000).toString().padLeft(3, '0');
    return 'RCP-${d.year}${pad(d.month)}${pad(d.day)}-${pad(d.hour)}${pad(d.minute)}${pad(d.second)}-$rand';
  }

  void _prefillEdit() {
    final rec = widget.editRecord!;
    setState(() {
      _mobileCtrl.text = rec.mobileNumber ?? '';
      _nameCtrl.text = rec.customerName ?? '';
      _customerId = rec.customerId;
      _descCtrl.text = rec.description ?? '';
      _discountCtrl.text =
          rec.discount == 0 ? '' : rec.discount.toString();
      _givenCtrl.text =
          rec.givenAmount == 0 ? '' : rec.givenAmount.toString();

      if (rec.items.isNotEmpty) {
        _cartRows = rec.items
            .map((item) => CartRowModel(
                  id: item.itemId.toString() + '_edit',
                  categoryId: item.categoryId,
                  itemId: item.itemId,
                  price: item.salePrice,
                  quantity: item.qty,
                )..recalculate())
            .toList();
      }
    });
  }

  void _onMobileChanged(String val) {
    final provider = context.read<SalesInvoiceProvider>();
    setState(() {
      _customerId = null;
      if (val.length >= 4) {
        _filteredCustomers = provider.customers
            .where((c) =>
                c.mobileNumber.toLowerCase().contains(val.toLowerCase()) ||
                c.customerName.toLowerCase().contains(val.toLowerCase()))
            .toList();
        _showDropdown = _filteredCustomers.isNotEmpty;
      } else {
        _filteredCustomers = [];
        _showDropdown = false;
      }
    });
  }

  void _selectCustomer(CustomerModel c) {
    setState(() {
      _mobileCtrl.text = c.mobileNumber;
      _nameCtrl.text = c.customerName;
      _customerId = c.id;
      _showDropdown = false;
    });
  }

  void _updateRow(String rowId,
      {int? categoryId, int? itemId, double? price, int? quantity}) {
    final provider = context.read<SalesInvoiceProvider>();
    setState(() {
      _cartRows = _cartRows.map((row) {
        if (row.id != rowId) return row;
        final updated = row.copyWith(
          categoryId: categoryId ?? (categoryId == null && itemId == null ? row.categoryId : categoryId),
          itemId: itemId ?? (categoryId != null ? null : row.itemId),
          price: price ?? row.price,
          quantity: quantity ?? row.quantity,
        );

        // Auto-fill price when item selected
        if (itemId != null) {
          final item = provider.items
              .where((i) => i.id == itemId)
              .firstOrNull;
          if (item != null) {
            return updated.copyWith(price: item.salePrice);
          }
        }
        return updated;
      }).toList();
    });
  }

  double get _subTotal =>
      _cartRows.fold(0, (sum, r) => sum + r.total);
  double get _payable =>
      (_subTotal - (double.tryParse(_discountCtrl.text) ?? 0)).clamp(0, double.infinity);
  double get _remaining =>
      (_payable - (double.tryParse(_givenCtrl.text) ?? 0)).clamp(0, double.infinity);

  Future<void> _submit() async {
    final validRows =
        _cartRows.where((r) => r.itemId != null && r.quantity > 0).toList();
    if (validRows.isEmpty) {
      _snack('Please add at least one valid item.');
      return;
    }

    final itemsPayload = validRows
        .map((r) => {
              'itemId': r.itemId,
              'quantity': r.quantity,
              'price': r.price,
              'total': r.total,
            })
        .toList();

    final payload = <String, dynamic>{
      'customerId': _customerId,
      'customerName': _nameCtrl.text.trim(),
      'mobileNumber': _mobileCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'discount': double.tryParse(_discountCtrl.text) ?? 0,
      'givenAmount': double.tryParse(_givenCtrl.text) ?? 0,
      'subTotal': _subTotal,
      'payable': _payable,
      'toBePaid': _remaining,
      'returnAmount': 0,
      'returnDescription': null,
      'items': itemsPayload,
    };

    if (widget.editRecord == null) {
      payload['receiptNo'] = _receiptNo;
    }

    final provider = context.read<SalesInvoiceProvider>();
    final ok =
        await provider.saveInvoice(payload, editId: widget.editRecord?.id);

    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.editRecord != null
              ? 'Invoice updated successfully!'
              : 'Invoice saved successfully!'),
          backgroundColor: AppConstants.primaryTeal,
        ));
        Navigator.of(context).pop();
      }
    } else {
      _snack(provider.error ?? 'Failed to save invoice.');
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
    final provider = context.watch<SalesInvoiceProvider>();

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.borderRadiusMedium)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.receipt_long,
                      color: AppConstants.primaryTeal, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.editRecord != null
                          ? 'Edit Invoice'
                          : 'New Sales Invoice',
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
              const SizedBox(height: 14),

              // Customer + Receipt row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mobile search
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(
                            label: 'Mobile / Search', required: true),
                        const SizedBox(height: 4),
                        Stack(
                          children: [
                            TextFormField(
                              controller: _mobileCtrl,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppConstants.darkTextPrimary
                                      : AppConstants.lightTextPrimary),
                              decoration: _inputDecoration(
                                      isDark: isDark,
                                      borderColor: borderColor,
                                      hint: 'Enter mobile...')
                                  .copyWith(
                                      suffixIcon: const Icon(Icons.search,
                                          size: 18, color: Colors.grey)),
                              onChanged: _onMobileChanged,
                            ),
                            if (_showDropdown)
                              Positioned(
                                top: 48,
                                left: 0,
                                right: 0,
                                child: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(10),
                                  color: cardColor,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxHeight: 150),
                                    child: ListView(
                                      shrinkWrap: true,
                                      children: _filteredCustomers
                                          .map((c) => ListTile(
                                                dense: true,
                                                title: Text(c.customerName,
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                subtitle: Text(
                                                    c.mobileNumber,
                                                    style: const TextStyle(
                                                        fontSize: 11)),
                                                onTap: () =>
                                                    _selectCustomer(c),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Customer Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(label: 'Customer Name'),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _nameCtrl,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: _customerId != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _customerId != null
                                  ? const Color(0xFF00897B)
                                  : (isDark
                                      ? AppConstants.darkTextPrimary
                                      : AppConstants.lightTextPrimary)),
                          decoration: _inputDecoration(
                              isDark: isDark,
                              borderColor: _customerId != null
                                  ? const Color(0xFF00897B)
                                  : borderColor,
                              hint: 'Walk-in Customer'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Receipt No + Description
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(label: 'Receipt No'),
                        const SizedBox(height: 4),
                        Container(
                          height: 44,
                          alignment: Alignment.centerLeft,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppConstants.darkCardHover
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(_receiptNo,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: isDark
                                      ? AppConstants.darkTextSecondary
                                      : AppConstants.lightTextSecondary)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(label: 'Description / Note'),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _descCtrl,
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppConstants.darkTextPrimary
                                  : AppConstants.lightTextPrimary),
                          decoration: _inputDecoration(
                              isDark: isDark,
                              borderColor: borderColor,
                              hint: 'Internal remarks...'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Cart Items
              _SectionLabel(label: 'Cart Items'),
              const SizedBox(height: 8),

              ..._cartRows.map((row) => _CartRowWidget(
                    key: ValueKey(row.id),
                    row: row,
                    categories: provider.categories,
                    allItems: provider.items,
                    isDark: isDark,
                    borderColor: borderColor,
                    canRemove: _cartRows.length > 1,
                    onUpdate: ({categoryId, itemId, price, quantity}) {
                      _updateRow(row.id,
                          categoryId: categoryId,
                          itemId: itemId,
                          price: price,
                          quantity: quantity);
                    },
                    onRemove: () => setState(
                        () => _cartRows.removeWhere((r) => r.id == row.id)),
                  )),

              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _cartRows.add(_newRow())),
                icon: const Icon(Icons.add,
                    size: 16, color: AppConstants.primaryTeal),
                label: const Text('Add Line',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryTeal)),
                style: TextButton.styleFrom(
                  backgroundColor:
                      AppConstants.primaryTeal.withOpacity(0.07),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: AppConstants.primaryTeal.withOpacity(0.2))),
                ),
              ),
              const SizedBox(height: 16),

              // Financial Summary + Settlement — responsive layout
              Builder(builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                // Use side-by-side only on wide screens (≥ 500 dp)
                final isWide = screenWidth >= 500;

                // ── Financial Summary panel ──────────────────────────────
                final summaryPanel = Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppConstants.darkCardHover
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: 'Financial Summary'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text('Gross Total',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PKR ${_subTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text('Discount',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              controller: _discountCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12),
                              decoration: _inputDecoration(
                                  isDark: isDark,
                                  borderColor: borderColor,
                                  hint: '0.00'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text('TOTAL PAYABLE',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PKR ${_payable.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppConstants.primaryTeal,
                                fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                // ── Settlement panel ─────────────────────────────────────
                final settlementPanel = Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppConstants.darkCardHover
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: 'Settlement'),
                      const SizedBox(height: 10),
                      _FieldLabel(label: 'Payment Received'),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _givenCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                        decoration: _inputDecoration(
                            isDark: isDark,
                            borderColor: borderColor,
                            hint: '0.00'),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _remaining <= 0
                              ? Colors.green.withOpacity(0.08)
                              : Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _remaining <= 0
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                _remaining <= 0 ? 'Fully Paid' : 'Remaining',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _remaining <= 0
                                        ? Colors.green
                                        : Colors.red),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PKR ${_remaining.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: _remaining <= 0
                                      ? Colors.green
                                      : Colors.red,
                                  fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: summaryPanel),
                      const SizedBox(width: 10),
                      Expanded(child: settlementPanel),
                    ],
                  );
                }
                // Narrow screen: stack vertically
                return Column(
                  children: [
                    summaryPanel,
                    const SizedBox(height: 10),
                    settlementPanel,
                  ],
                );
              }),

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
                  ElevatedButton.icon(
                    onPressed: provider.submitting ? null : _submit,
                    icon: provider.submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                        provider.submitting
                            ? 'Saving...'
                            : widget.editRecord != null
                                ? 'Update Invoice'
                                : 'Save Invoice',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
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

// ─── Cart Row Widget ───────────────────────────────────────────────────────────
class _CartRowWidget extends StatelessWidget {
  final CartRowModel row;
  final List<CategoryModel> categories;
  final List<ItemModel> allItems;
  final bool isDark;
  final Color borderColor;
  final bool canRemove;
  final void Function(
      {int? categoryId, int? itemId, double? price, int? quantity}) onUpdate;
  final VoidCallback onRemove;

  const _CartRowWidget({
    required super.key,
    required this.row,
    required this.categories,
    required this.allItems,
    required this.isDark,
    required this.borderColor,
    required this.canRemove,
    required this.onUpdate,
    required this.onRemove,
  });

  List<ItemModel> get _filteredItems => row.categoryId == null
      ? []
      : allItems
          .where((i) => i.itemCategoryId == row.categoryId)
          .toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.darkCardHover : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Category + Item
          Row(
            children: [
              // Category
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: row.categoryId,
                  isExpanded: true,
                  decoration: _inputDecoration(
                      isDark: isDark, borderColor: borderColor),
                  hint: const Text('Category',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  items: categories
                      .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.categoryName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppConstants.darkTextPrimary
                                      : AppConstants.lightTextPrimary))))
                      .toList(),
                  onChanged: (val) => onUpdate(categoryId: val),
                  dropdownColor:
                      isDark ? AppConstants.darkCard : Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              // Item
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: row.itemId,
                  isExpanded: true,
                  decoration: _inputDecoration(
                      isDark: isDark, borderColor: borderColor),
                  hint: Text(
                      row.categoryId == null
                          ? 'Select Category First'
                          : 'Select Item',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                  disabledHint: const Text('Select Category First',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  items: _filteredItems
                      .map((i) => DropdownMenuItem(
                          value: i.id,
                          child: Text(i.itemName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppConstants.darkTextPrimary
                                      : AppConstants.lightTextPrimary))))
                      .toList(),
                  onChanged: row.categoryId == null
                      ? null
                      : (val) => onUpdate(itemId: val),
                  dropdownColor:
                      isDark ? AppConstants.darkCard : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: Price + Qty + Total + Delete
          Row(
            children: [
              // Price label + field
              Expanded(
                flex: 3,
                child: TextFormField(
                  key: ValueKey('price_${row.id}_${row.price}'),
                  initialValue:
                      row.price == 0 ? '' : row.price.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppConstants.darkTextPrimary
                          : AppConstants.lightTextPrimary),
                  decoration: _inputDecoration(
                      isDark: isDark,
                      borderColor: borderColor,
                      hint: 'Price'),
                  onChanged: (val) =>
                      onUpdate(price: double.tryParse(val) ?? 0),
                ),
              ),
              const SizedBox(width: 6),
              // Qty
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: row.quantity.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppConstants.darkTextPrimary
                          : AppConstants.lightTextPrimary),
                  decoration: _inputDecoration(
                      isDark: isDark,
                      borderColor: borderColor,
                      hint: 'Qty'),
                  onChanged: (val) =>
                      onUpdate(quantity: int.tryParse(val) ?? 1),
                ),
              ),
              const SizedBox(width: 6),
              // Total (read-only badge)
              Expanded(
                flex: 3,
                child: Container(
                  height: 44,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryTeal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppConstants.primaryTeal.withOpacity(0.2)),
                  ),
                  child: Text(
                    'PKR ${row.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryTeal,
                        fontFamily: 'monospace'),
                  ),
                ),
              ),
              // Remove button
              IconButton(
                onPressed: canRemove ? onRemove : null,
                icon: Icon(Icons.delete_outline,
                    size: 18,
                    color: canRemove ? Colors.red : Colors.grey),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.only(left: 4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
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

InputDecoration _inputDecoration(
    {required bool isDark, required Color borderColor, String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
