import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/goods_receipt_provider.dart';
import '../../models/goods_receipt_model.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_app_bar.dart';

class GoodsReceiptNoteScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;

  const GoodsReceiptNoteScreen({super.key, this.onMenuPressed});

  @override
  State<GoodsReceiptNoteScreen> createState() => _GoodsReceiptNoteScreenState();
}

class _GoodsReceiptNoteScreenState extends State<GoodsReceiptNoteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoodsReceiptProvider>().fetchPendingOrders();
    });
  }

  void _showGrnDialog({PurchaseOrderModel? preSelected}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _GrnDialog(preSelected: preSelected),
    ).then((_) {
      context.read<GoodsReceiptProvider>().fetchPendingOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Goods Receipt Note',
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onMenuPressed,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<GoodsReceiptProvider>().fetchPendingOrders(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGrnDialog,
        backgroundColor: AppConstants.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Initiate GRN',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<GoodsReceiptProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppConstants.primaryTeal),
            );
          }

          if (provider.pendingOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64,
                      color: isDark
                          ? AppConstants.darkTextSecondary
                          : AppConstants.lightTextSecondary),
                  const SizedBox(height: 12),
                  Text(
                    'No pending goods receipts found.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.pendingOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final po = provider.pendingOrders[index];
              return _PoCard(po: po, onInitiateGrn: () => _showGrnDialog(preSelected: po));
            },
          );
        },
      ),
    );
  }
}

// ─── PO List Card ─────────────────────────────────────────────────────────────
class _PoCard extends StatelessWidget {
  final PurchaseOrderModel po;
  final VoidCallback onInitiateGrn;

  const _PoCard({required this.po, required this.onInitiateGrn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppConstants.darkCard : AppConstants.lightCard;
    final borderColor =
        isDark ? AppConstants.darkBorder : AppConstants.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long,
                      color: AppConstants.primaryTeal, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        po.displayRef,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${po.id}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onInitiateGrn,
                  style: TextButton.styleFrom(
                    backgroundColor: AppConstants.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('GRN',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                    icon: Icons.business_outlined,
                    label: po.supplierName,
                    flex: 2),
                const SizedBox(width: 8),
                _InfoChip(
                    icon: Icons.inventory_2_outlined,
                    label: '${po.items.length} items',
                    flex: 1),
                const SizedBox(width: 8),
                _InfoChip(
                    icon: Icons.currency_rupee,
                    label:
                        'PKR ${po.payable.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    flex: 2,
                    isTeal: true),
              ],
            ),
            if (po.createdAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Ordered: ${_formatDate(po.createdAt!)}',
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
              ),
            ]
          ],
        ),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int flex;
  final bool isTeal;

  const _InfoChip(
      {required this.icon,
      required this.label,
      required this.flex,
      this.isTeal = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isTeal
              ? AppConstants.primaryTeal.withOpacity(0.1)
              : (isDark ? AppConstants.darkCardHover : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 13,
                color: isTeal
                    ? AppConstants.primaryTeal
                    : (isDark
                        ? AppConstants.darkTextSecondary
                        : AppConstants.lightTextSecondary)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isTeal ? FontWeight.bold : FontWeight.w500,
                  color: isTeal
                      ? AppConstants.primaryTeal
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── GRN Dialog ───────────────────────────────────────────────────────────────
class _GrnDialog extends StatefulWidget {
  final PurchaseOrderModel? preSelected;
  const _GrnDialog({this.preSelected});

  @override
  State<_GrnDialog> createState() => _GrnDialogState();
}

class _GrnDialogState extends State<_GrnDialog> {
  PurchaseOrderModel? _selectedPO;
  final _grnNoCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  late String _grnDate;

  @override
  void initState() {
    super.initState();
    _selectedPO = widget.preSelected;
    final now = DateTime.now();
    _grnDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _grnNoCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
              seedColor: AppConstants.primaryTeal,
              brightness: Theme.of(ctx).brightness),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _grnDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedPO == null) {
      _showSnack('Please select a Purchase Order.');
      return;
    }
    if (_grnNoCtrl.text.trim().isEmpty) {
      _showSnack('GRN Number is required.');
      return;
    }

    final provider = context.read<GoodsReceiptProvider>();
    final ok = await provider.submitGrn(
      purchaseOrderId: _selectedPO!.id,
      grnNo: _grnNoCtrl.text.trim(),
      grnDate: _grnDate,
      remarks: _remarksCtrl.text.trim(),
    );

    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Goods Receipt Note recorded successfully!'),
          backgroundColor: AppConstants.primaryTeal,
        ));
        Navigator.of(context).pop();
      }
    } else {
      _showSnack(provider.error ?? 'Failed to record GRN.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppConstants.darkCard : Colors.white;
    final borderColor =
        isDark ? AppConstants.darkBorder : AppConstants.lightBorder;
    final provider = context.watch<GoodsReceiptProvider>();

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.borderRadiusMedium)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.assignment_turned_in,
                      color: AppConstants.primaryTeal, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Initiate GRN',
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

              // Section: Acceptance Protocol
              _SectionLabel(label: 'Acceptance Protocol'),
              const SizedBox(height: 8),

              // PO Dropdown
              _FieldLabel(label: 'Target Purchase Order', required: true),
              const SizedBox(height: 4),
              DropdownButtonFormField<int>(
                value: _selectedPO?.id,
                isExpanded: true,
                decoration: _inputDecoration(
                    isDark: isDark, borderColor: borderColor),
                hint: const Text('Select Pending Order...',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                items: provider.pendingOrders
                    .map((po) => DropdownMenuItem(
                          value: po.id,
                          child: Text(
                            '${po.displayRef} — ${po.supplierName}',
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
                  setState(() {
                    _selectedPO = provider.pendingOrders
                        .firstWhere((po) => po.id == val);
                  });
                },
                dropdownColor: cardColor,
              ),
              const SizedBox(height: 12),

              // GRN No + Date row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(label: 'GRN No', required: true),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _grnNoCtrl,
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppConstants.darkTextPrimary
                                  : AppConstants.lightTextPrimary),
                          decoration: _inputDecoration(
                              isDark: isDark,
                              borderColor: borderColor,
                              hint: 'GRN number'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(label: 'GRN Date'),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 44,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(8),
                              color: isDark
                                  ? AppConstants.darkBg
                                  : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(_grnDate,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppConstants.darkTextPrimary
                                              : AppConstants.lightTextPrimary)),
                                ),
                                Icon(Icons.calendar_today_outlined,
                                    size: 16,
                                    color: isDark
                                        ? AppConstants.darkTextSecondary
                                        : AppConstants.lightTextSecondary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Remarks
              _FieldLabel(label: 'Condition / Remarks'),
              const SizedBox(height: 4),
              TextFormField(
                controller: _remarksCtrl,
                maxLines: 3,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppConstants.darkTextPrimary
                        : AppConstants.lightTextPrimary),
                decoration: _inputDecoration(
                    isDark: isDark,
                    borderColor: borderColor,
                    hint:
                        'Notes on condition, batch expiry, damage reports...'),
              ),

              // Itemized Orders (when PO selected)
              if (_selectedPO != null) ...[
                const SizedBox(height: 16),
                _SectionLabel(label: 'Itemized Orders for Verification'),
                const SizedBox(height: 8),
                _ItemizedTable(po: _selectedPO!, isDark: isDark),
                const SizedBox(height: 8),
                // Grand total
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryTeal.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total Valuation',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryTeal)),
                      Text(
                        'PKR ${_selectedPO!.payable.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppConstants.primaryTeal,
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: provider.submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text('Cancel',
                        style: TextStyle(
                            color: isDark
                                ? AppConstants.darkTextSecondary
                                : AppConstants.lightTextSecondary)),
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
                        : const Icon(Icons.inventory_2_outlined, size: 18),
                    label: Text(
                        provider.submitting
                            ? 'Saving...'
                            : 'Confirm Goods Receipt',
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

class _ItemizedTable extends StatelessWidget {
  final PurchaseOrderModel po;
  final bool isDark;
  const _ItemizedTable({required this.po, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark ? AppConstants.darkBorder : AppConstants.lightBorder;
    final headerBg =
        isDark ? AppConstants.darkCardHover : const Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                _TH(label: 'Item', flex: 3),
                _TH(label: 'Qty', flex: 1, align: TextAlign.right),
                _TH(label: 'Rate', flex: 2, align: TextAlign.right),
                _TH(label: 'Total', flex: 2, align: TextAlign.right),
              ],
            ),
          ),
          ...po.items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == po.items.length - 1;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    child: Text(item.quantity.toString(),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w900)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                        'PKR ${item.purchasePrice.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: AppConstants.primaryTeal)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                        'PKR ${item.total.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            color: AppConstants.primaryTeal)),
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
              letterSpacing: 0.5)),
    );
  }
}

// ─── Shared helpers ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: AppConstants.primaryTeal,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppConstants.primaryTeal
                    : AppConstants.lightTextPrimary,
                letterSpacing: 0.5)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
      ],
    );
  }
}

InputDecoration _inputDecoration(
    {required bool isDark,
    required Color borderColor,
    String? hint,
    Widget? suffix}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
    suffixIcon: suffix,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true,
    fillColor: isDark ? AppConstants.darkBg : Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide:
          const BorderSide(color: AppConstants.primaryTeal, width: 1.5),
    ),
  );
}
