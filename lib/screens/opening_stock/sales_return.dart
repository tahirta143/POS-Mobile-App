import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sales_return_provider.dart';
import '../../models/sales_return_model.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_app_bar.dart';

class SalesReturnScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const SalesReturnScreen({super.key, this.onMenuPressed});

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<SalesReturnProvider>();
      p.fetchSaleInvoices();
      p.fetchRecentReturns();
    });
  }

  void _openDialog({SalesReturnModel? editRecord}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SalesReturnDialog(editRecord: editRecord),
    ).then((_) => context.read<SalesReturnProvider>().fetchRecentReturns());
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Return'),
        content:
            const Text('Delete this sales return? Stock will be restored.'),
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
          await context.read<SalesReturnProvider>().deleteReturn(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              success ? 'Return deleted.' : 'Failed to delete return.'),
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
        title: 'Sales Return',
        leading: IconButton(
            icon: const Icon(Icons.menu), onPressed: widget.onMenuPressed),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<SalesReturnProvider>().fetchRecentReturns(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        backgroundColor: AppConstants.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Return',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<SalesReturnProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.recentReturns.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppConstants.primaryTeal));
          }
          if (provider.recentReturns.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_return_outlined,
                      size: 64,
                      color: isDark
                          ? AppConstants.darkTextSecondary
                          : AppConstants.lightTextSecondary),
                  const SizedBox(height: 12),
                  Text('No sales returns recorded.',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(
                left: 16, right: 16, top: 16, bottom: 80),
            itemCount: provider.recentReturns.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final record = provider.recentReturns[index];
              return _ReturnCard(
                record: record,
                isDark: isDark,
                onEdit: () => _openDialog(editRecord: record),
                onDelete: () => _confirmDelete(record.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  final SalesReturnModel record;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReturnCard(
      {required this.record,
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppConstants.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assignment_return,
                    color: AppConstants.primaryTeal, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        record.customerName ?? 'Walking Customer',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontSize: 14)),
                    Text(
                        record.invoiceRef ?? '#${record.saleInvoiceId ?? record.id}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontSize: 11, fontFamily: 'monospace')),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PKR ${record.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppConstants.primaryTeal,
                        fontFamily: 'monospace'),
                  ),
                  if (record.discount > 0)
                    Text('Disc: PKR ${record.discount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.orange)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              if (record.returnDate != null)
                Text(_formatDate(record.returnDate!),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontSize: 11)),
              const Spacer(),
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

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return raw;
    }
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

// ─── Sales Return Dialog ──────────────────────────────────────────────────────
class _SalesReturnDialog extends StatefulWidget {
  final SalesReturnModel? editRecord;
  const _SalesReturnDialog({this.editRecord});

  @override
  State<_SalesReturnDialog> createState() => _SalesReturnDialogState();
}

class _SalesReturnDialogState extends State<_SalesReturnDialog> {
  String _activeTab = 'sale'; // 'sale' | 'booking'
  SaleInvoiceModel? _selectedInvoice;
  List<SaleItemModel> _returnItems = [];
  double _discount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesReturnProvider>().fetchSaleInvoices();
    });
  }

  void _onInvoiceSelected(int id, List<SaleInvoiceModel> list) {
    final inv = list.firstWhere((i) => i.id == id);
    setState(() {
      _selectedInvoice = inv;
      _discount = 0;
      _returnItems = inv.items
          .map((item) => SaleItemModel(
                itemId: item.itemId,
                itemName: item.itemName,
                price: item.price,
                total: item.total,
                qty: item.qty,
                returnQty: 0,
              ))
          .toList();
    });
  }

  void _updateQty(int itemId, double qty) {
    setState(() {
      for (var item in _returnItems) {
        if (item.itemId == itemId) {
          item.returnQty = qty.clamp(0, item.qty.toDouble());
        }
      }
    });
  }

  double get _grossReturnValue => _returnItems.fold(
      0, (sum, item) => sum + item.returnQty * item.unitRate);

  double get _discountAmt => _discount.clamp(0, _grossReturnValue);
  double get _netReturnValue => (_grossReturnValue - _discountAmt).clamp(0, double.infinity);

  Future<void> _submit() async {
    if (_selectedInvoice == null) {
      _snack('Please select an invoice.');
      return;
    }
    final itemsToReturn =
        _returnItems.where((i) => i.returnQty > 0).toList();
    if (itemsToReturn.isEmpty) {
      _snack('Add at least one item to return.');
      return;
    }

    final normalizedItems = itemsToReturn
        .map((item) => {
              'item_id': item.itemId,
              'qty': item.returnQty,
              'price': item.unitRate,
              'total': item.returnQty * item.unitRate,
            })
        .toList();

    final provider = context.read<SalesReturnProvider>();
    final ok = await provider.submitReturn(
      saleInvoiceId: _selectedInvoice!.id,
      customerId: _selectedInvoice!.customerId,
      items: normalizedItems,
      discount: _discountAmt,
      totalAmount: _netReturnValue,
      editId: widget.editRecord?.id,
    );

    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.editRecord != null
              ? 'Return updated successfully.'
              : 'Return recorded successfully.'),
          backgroundColor: AppConstants.primaryTeal,
        ));
        Navigator.of(context).pop();
      }
    } else {
      _snack(provider.error ?? 'Failed to save return.');
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
    final provider = context.watch<SalesReturnProvider>();

    final invoiceList = provider.saleInvoices;

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.borderRadiusMedium)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.keyboard_return,
                      color: AppConstants.primaryTeal, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.editRecord != null
                          ? 'Modify Return Entry'
                          : 'Process New Return',
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
              const SizedBox(height: 12),

              // Tab switcher
              Row(
                children: [
                  _TabBtn(
                    label: 'Sale Invoices',
                    icon: Icons.shopping_bag_outlined,
                    active: _activeTab == 'sale',
                    count: provider.saleInvoices.length,
                    onTap: () => setState(() {
                      _activeTab = 'sale';
                      _selectedInvoice = null;
                      _returnItems = [];
                      _discount = 0;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _TabBtn(
                    label: 'Booking Invoices',
                    icon: Icons.book_online_outlined,
                    active: _activeTab == 'booking',
                    count: 0,
                    onTap: () => setState(() {
                      _activeTab = 'booking';
                      _selectedInvoice = null;
                      _returnItems = [];
                      _discount = 0;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Invoice selector
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(label: 'Select Invoice', required: true),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<int>(
                          value: _selectedInvoice?.id,
                          isExpanded: true,
                          decoration: _inputDecoration(
                              isDark: isDark, borderColor: borderColor),
                          hint: Text(
                              _activeTab == 'sale'
                                  ? 'Search receipt / invoice ID...'
                                  : 'Search booking ID...',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey)),
                          items: invoiceList
                              .map((inv) => DropdownMenuItem(
                                    value: inv.id,
                                    child: Text(
                                      '${inv.displayRef} — ${inv.customerName ?? 'Customer'}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppConstants.darkTextPrimary
                                              : AppConstants.lightTextPrimary),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              _onInvoiceSelected(val, invoiceList);
                            }
                          },
                          dropdownColor: cardColor,
                        ),
                      ],
                    ),
                  ),
                  if (_selectedInvoice != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryTeal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppConstants.primaryTeal.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('NET CREDIT',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.primaryTeal,
                                    letterSpacing: 0.5)),
                            Text(
                              'PKR ${_netReturnValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppConstants.primaryTeal,
                                  fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Invoice info cards
              if (_selectedInvoice != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoBox(
                          icon: Icons.person_outline,
                          label: 'Customer',
                          value: _selectedInvoice!.customerName ??
                              'Walking Customer'),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _InfoBox(
                          icon: Icons.receipt_outlined,
                          label: 'Invoice Ref',
                          value: _selectedInvoice!.displayRef),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _InfoBox(
                          icon: Icons.price_check,
                          label: 'Total Paid',
                          value:
                              'PKR ${_selectedInvoice!.paid.toStringAsFixed(2)}',
                          isTeal: true),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Items Table
                _SectionLabel(label: 'Return Items'),
                const SizedBox(height: 8),
                _SalesReturnItemsTable(
                    items: _returnItems,
                    isDark: isDark,
                    borderColor: borderColor,
                    onQtyChanged: _updateQty),
                const SizedBox(height: 14),

                // Summary
                _SectionLabel(label: 'Return Summary'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppConstants.darkCardHover
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Gross Return Value',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontSize: 13)),
                          Text(
                              'PKR ${_grossReturnValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Discount on Return',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontSize: 13)),
                          SizedBox(
                            width: 110,
                            child: TextFormField(
                              initialValue: _discount == 0
                                  ? ''
                                  : _discount.toString(),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold),
                              decoration: _inputDecoration(
                                  isDark: isDark,
                                  borderColor: borderColor,
                                  hint: '0.00'),
                              onChanged: (val) => setState(() {
                                _discount = double.tryParse(val) ?? 0;
                              }),
                            ),
                          ),
                        ],
                      ),
                      Divider(color: borderColor, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Net Credit to Customer',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(
                              'PKR ${_netReturnValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppConstants.primaryTeal,
                                  fontFamily: 'monospace')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: provider.submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Discard'),
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
                            widget.editRecord != null
                                ? 'Update Credit Note'
                                : 'Authorize Return',
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

class _TabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final int count;
  final VoidCallback onTap;

  const _TabBtn(
      {required this.label,
      required this.icon,
      required this.active,
      required this.count,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppConstants.primaryTeal
              : (Theme.of(context).brightness == Brightness.dark
                  ? AppConstants.darkCardHover
                  : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 15,
                color: active ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: active ? Colors.white : Colors.grey)),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withOpacity(0.25)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: active ? Colors.white : Colors.grey)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SalesReturnItemsTable extends StatelessWidget {
  final List<SaleItemModel> items;
  final bool isDark;
  final Color borderColor;
  final void Function(int itemId, double qty) onQtyChanged;

  const _SalesReturnItemsTable(
      {required this.items,
      required this.isDark,
      required this.borderColor,
      required this.onQtyChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppConstants.darkCardHover
                  : const Color(0xFFF8FAFC),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                _TH(label: 'Item', flex: 3),
                _TH(label: 'Sold', flex: 1, align: TextAlign.right),
                _TH(label: 'Rate', flex: 2, align: TextAlign.right),
                _TH(label: 'Return', flex: 2, align: TextAlign.center),
                _TH(label: 'Credit', flex: 2, align: TextAlign.right),
              ],
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == items.length - 1;
            final credit = item.returnQty * item.unitRate;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(item.itemName,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(item.qty.toString(),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                        'PKR ${item.unitRate.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: AppConstants.primaryTeal)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: SizedBox(
                        width: 60,
                        child: TextFormField(
                          initialValue: item.returnQty == 0
                              ? ''
                              : item.returnQty.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryTeal),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: const TextStyle(fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 6),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                    color: borderColor)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                    color: borderColor)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                    color: AppConstants.primaryTeal)),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val) ?? 0;
                            onQtyChanged(item.itemId, parsed);
                          },
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                        credit > 0
                            ? 'PKR ${credit.toStringAsFixed(2)}'
                            : '—',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: credit > 0
                                ? AppConstants.primaryTeal
                                : Colors.grey,
                            fontFamily: 'monospace')),
                  ),
                ],
              ),
            );
          }),
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

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isTeal;
  const _InfoBox(
      {required this.icon,
      required this.label,
      required this.value,
      this.isTeal = false});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: isTeal
            ? const Color(0xFF00897B).withOpacity(0.07)
            : (isDark ? AppConstants.darkCardHover : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isTeal
                ? AppConstants.primaryTeal.withOpacity(0.2)
                : (isDark
                    ? AppConstants.darkBorder
                    : AppConstants.lightBorder)),
      ),
      child: Row(children: [
        Icon(icon,
            size: 13,
            color: isTeal
                ? AppConstants.primaryTeal
                : AppConstants.lightTextSecondary),
        const SizedBox(width: 5),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isTeal
                          ? AppConstants.primaryTeal
                          : AppConstants.lightTextSecondary,
                      letterSpacing: 0.5)),
              Text(value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isTeal
                          ? AppConstants.primaryTeal
                          : (isDark
                              ? AppConstants.darkTextPrimary
                              : AppConstants.lightTextPrimary))),
            ])),
      ]),
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  final int flex;
  final TextAlign align;
  const _TH(
      {required this.label,
      required this.flex,
      this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) {
    return Expanded(
        flex: flex,
        child: Text(label.toUpperCase(),
            textAlign: align,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryTeal,
                letterSpacing: 0.5)));
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
