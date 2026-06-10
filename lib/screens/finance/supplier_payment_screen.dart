import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/supplier_payment_provider.dart';
import '../../models/supplier_payment_model.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_loader.dart';

class SupplierPaymentScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const SupplierPaymentScreen({super.key, this.onMenuPressed});

  @override
  State<SupplierPaymentScreen> createState() => _SupplierPaymentScreenState();
}

class _SupplierPaymentScreenState extends State<SupplierPaymentScreen> {
  final _searchController = TextEditingController();
  bool _isInitialLoading = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    await context.read<SupplierPaymentProvider>().fetchAllPageData();
    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _openPaymentDialog(BuildContext context, SupplierPaymentModel? payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: _SupplierPaymentFormDialog(editPayment: payment),
        ),
      ),
    ).then((_) => context.read<SupplierPaymentProvider>().fetchAllPageData());
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SupplierPaymentProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppConstants.darkCard : AppConstants.lightCard;
    final borderColor = isDark ? AppConstants.darkBorder : AppConstants.lightBorder;
    final textSecondaryColor = isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary;

    final totalPaid = provider.payments.fold(0.0, (sum, p) => sum + p.amount);

    final searchQuery = _searchController.text.toLowerCase();
    final filteredPayments = provider.payments.where((p) {
      final name = (p.supplierName ?? '').toLowerCase();
      final note = (p.note).toLowerCase();
      final invoice = (p.invoiceNo ?? '').toLowerCase();
      return name.contains(searchQuery) || note.contains(searchQuery) || invoice.contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Supplier Payments',
        leading: widget.onMenuPressed != null
            ? IconButton(icon: const Icon(Icons.menu), onPressed: widget.onMenuPressed)
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.fetchAllPageData(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + Add row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search by supplier name...',
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () => _openPaymentDialog(context, null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await provider.fetchAllPageData();
              },
              color: AppConstants.primaryTeal,
              child: _isInitialLoading
                  ? const CustomLoader()
                  : filteredPayments.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.6,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_toggle_off_rounded, size: 64, color: textSecondaryColor),
                                const SizedBox(height: 12),
                                Text('No payment records found.', style: TextStyle(color: textSecondaryColor)),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 90), // Spaced bottom padding to prevent hiding
                                itemCount: filteredPayments.length,
                                itemBuilder: (context, index) {
                                  final p = filteredPayments[index];
                                  return GestureDetector(
                                    onTap: () => _openPaymentDialog(context, p),
                                    child: _buildPaymentCard(p, isDark, cardColor, borderColor, index + 1),
                                  );
                                },
                              ),
                            ),
                            _buildSummaryFooter(totalPaid, isDark, cardColor, borderColor),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(SupplierPaymentModel p, bool isDark, Color cardColor, Color borderColor, int index) {
    final formattedDate = p.paymentDate.isNotEmpty
        ? DateFormat.yMMMd().format(DateTime.tryParse(p.paymentDate) ?? DateTime.now())
        : '—';
    final textSecondaryColor = isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary;
    final textPrimaryColor = isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                p.supplierName ?? 'Supplier #${p.supplierId}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimaryColor),
              ),
              Text(
                'PKR ${p.amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.primaryTeal, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (p.purchaseId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.darkBorder : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    p.invoiceNo != null && p.invoiceNo!.isNotEmpty ? 'INV-${p.invoiceNo}' : 'PO-${p.purchaseId}',
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Text('General Payment', style: TextStyle(fontSize: 11, color: textSecondaryColor, fontStyle: FontStyle.italic)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConstants.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  p.paymentMethod.toUpperCase(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppConstants.primaryTeal, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          if (p.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              p.note,
              style: TextStyle(
                fontSize: 12,
                color: textSecondaryColor,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 12, color: textSecondaryColor),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondaryColor,
                    ),
                  ),
                ],
              ),
              Icon(Icons.chevron_right, size: 16, color: textSecondaryColor.withValues(alpha: 0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryFooter(double totalPaid, bool isDark, Color cardColor, Color borderColor) {
    final textPrimaryColor = isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOTAL PAID',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimaryColor),
            ),
            Text(
              'PKR ${totalPaid.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppConstants.primaryTeal, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Supplier Payment Form Dialog ─────────────────────────────────────────────
class _SupplierPaymentFormDialog extends StatefulWidget {
  final SupplierPaymentModel? editPayment;

  const _SupplierPaymentFormDialog({this.editPayment});

  @override
  State<_SupplierPaymentFormDialog> createState() => _SupplierPaymentFormDialogState();
}

class _SupplierPaymentFormDialogState extends State<_SupplierPaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedSupplierId;
  int? _selectedPurchaseId;
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String _paymentMethod = 'Cash';
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = widget.editPayment;
    if (p != null) {
      _selectedSupplierId = p.supplierId;
      _selectedPurchaseId = p.purchaseId;
      _amountCtrl.text = p.amount.toString();
      _dateCtrl.text = p.paymentDate.split('T')[0];
      _paymentMethod = p.paymentMethod;
      _noteCtrl.text = p.note;
    } else {
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateCtrl.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppConstants.primaryTeal,
                    onPrimary: Colors.white,
                    surface: AppConstants.darkCard,
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppConstants.primaryTeal,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier.')),
      );
      return;
    }

    final double? amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount.')),
      );
      return;
    }

    final provider = context.read<SupplierPaymentProvider>();

    // Calculate due amount for the selected purchase
    if (_selectedPurchaseId != null) {
      final selectedPurchase = provider.purchases.firstWhere(
        (p) => p.id == _selectedPurchaseId,
      );
      if (amount > selectedPurchase.toBePaid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Amount exceeds the due on this purchase (PKR ${selectedPurchase.toBePaid.toStringAsFixed(2)}).'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final payment = SupplierPaymentModel(
      supplierId: _selectedSupplierId!,
      purchaseId: _selectedPurchaseId,
      amount: amount,
      paymentMethod: _paymentMethod,
      paymentDate: _dateCtrl.text,
      note: _noteCtrl.text.trim(),
    );

    final success = await provider.savePayment(payment, editId: widget.editPayment?.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editPayment != null
                ? 'Payment updated successfully.'
                : 'Payment recorded successfully.'),
            backgroundColor: AppConstants.primaryTeal,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Unable to save payment.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Delete this payment? Purchase status will be recalculated.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      final provider = context.read<SupplierPaymentProvider>();
      final success = await provider.deletePayment(widget.editPayment!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Payment deleted.' : 'Failed to delete payment.'),
            backgroundColor: success ? AppConstants.primaryTeal : Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SupplierPaymentProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppConstants.darkBorder : AppConstants.lightBorder;
    final textPrimaryColor = isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary;
    final isEdit = widget.editPayment != null;

    // Outstanding Balance Calculation for selected supplier
    double outstandingBalance = 0;
    List<SupplierPurchaseModel> supplierPurchases = [];

    if (_selectedSupplierId != null) {
      outstandingBalance = provider.purchases
          .where((p) => p.supplierId == _selectedSupplierId)
          .fold(0.0, (sum, p) => sum + p.toBePaid);

      supplierPurchases = provider.purchases
          .where((p) => p.supplierId == _selectedSupplierId && p.toBePaid > 0)
          .toList();
    }

    double? selectedPurchaseDue;
    if (_selectedPurchaseId != null && supplierPurchases.isNotEmpty) {
      // Find matching purchase
      final matches = supplierPurchases.where((p) => p.id == _selectedPurchaseId);
      if (matches.isNotEmpty) {
        selectedPurchaseDue = matches.first.toBePaid;
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.payment_rounded, color: AppConstants.primaryTeal, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Payment' : 'Record Payment',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimaryColor),
                    ),
                  ),
                  if (isEdit)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: _confirmDelete,
                      tooltip: 'Delete Payment',
                      visualDensity: VisualDensity.compact,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Supplier Dropdown
              Text('Supplier *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
              const SizedBox(height: 4),
              DropdownButtonFormField<int>(
                value: _selectedSupplierId,
                dropdownColor: isDark ? AppConstants.darkCard : Colors.white,
                decoration: _inputDecoration(isDark, borderColor, hint: 'Choose Supplier...'),
                items: provider.suppliers.map((s) {
                  return DropdownMenuItem<int>(
                    value: s.id,
                    child: Text(s.supplierName, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSupplierId = val;
                    _selectedPurchaseId = null; // Reset purchase link
                  });
                },
              ),
              const SizedBox(height: 12),

              // Outstanding Balance Display
              if (_selectedSupplierId != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstants.primaryTeal.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL OUTSTANDING',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppConstants.primaryTeal, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PKR ${outstandingBalance.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppConstants.primaryTeal, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Link to Purchase Dropdown
              if (_selectedSupplierId != null && supplierPurchases.isNotEmpty) ...[
                Text('Link to Purchase Order (optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  value: _selectedPurchaseId,
                  dropdownColor: isDark ? AppConstants.darkCard : Colors.white,
                  decoration: _inputDecoration(isDark, borderColor, hint: '— Not linked to specific order —'),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('— Not linked —', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ),
                    ...supplierPurchases.map((p) {
                      return DropdownMenuItem<int>(
                        value: p.id,
                        child: Text('${p.displayRef} — Due: PKR ${p.toBePaid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedPurchaseId = val;
                    });
                  },
                ),
                if (selectedPurchaseDue != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Due on this order: PKR ${selectedPurchaseDue.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(height: 12),
              ],

              // Amount and Date
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amount to Pay *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: _inputDecoration(isDark, borderColor, hint: '0.00'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment Date *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _dateCtrl,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          style: const TextStyle(fontSize: 13),
                          decoration: _inputDecoration(isDark, borderColor, hint: 'Select Date', suffixIcon: Icons.calendar_today),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Payment Method
              Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                dropdownColor: isDark ? AppConstants.darkCard : Colors.white,
                decoration: _inputDecoration(isDark, borderColor),
                items: ['Cash', 'Bank Transfer', 'Cheque', 'Online']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) => setState(() => _paymentMethod = val ?? 'Cash'),
              ),
              const SizedBox(height: 12),

              // Note
              Text('Remarks / Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: _inputDecoration(isDark, borderColor, hint: 'Ref no, bank details, or remarks...'),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: provider.submitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: provider.submitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: provider.submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isEdit ? 'Update Payment' : 'Confirm Payment', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark, Color borderColor, {String? hint, IconData? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: isDark ? AppConstants.darkCard : Colors.grey[50],
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 16, color: Colors.grey) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppConstants.primaryTeal, width: 1.5),
      ),
    );
  }
}
