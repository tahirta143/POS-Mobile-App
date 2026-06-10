import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/customer_payment_provider.dart';
import '../../models/customer_payment_model.dart';
import '../../models/sale_invoice_model.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_loader.dart';

class CustomerPaymentScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const CustomerPaymentScreen({super.key, this.onMenuPressed});

  @override
  State<CustomerPaymentScreen> createState() => _CustomerPaymentScreenState();
}

class _CustomerPaymentScreenState extends State<CustomerPaymentScreen> {
  String _historyTab = 'sales'; // 'sales' or 'bookings'
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
    await context.read<CustomerPaymentProvider>().fetchAllPageData();
    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _openPaymentDialog(BuildContext context, {CustomerPaymentModel? salesPayment, BookingPaymentModel? bookingPayment}) {
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
          child: _CustomerPaymentFormDialog(
            editSalesPayment: salesPayment,
            editBookingPayment: bookingPayment,
          ),
        ),
      ),
    ).then((_) => context.read<CustomerPaymentProvider>().fetchAllPageData());
  }

  Future<void> _confirmDeleteBookingPayment(BuildContext context, BookingPaymentModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Collection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Delete this booking payment?'),
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
      final provider = context.read<CustomerPaymentProvider>();
      final success = await provider.deleteBookingPayment(p.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Payment deleted.' : 'Failed to delete payment.'),
            backgroundColor: success ? AppConstants.primaryTeal : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerPaymentProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppConstants.darkCard : AppConstants.lightCard;
    final borderColor = isDark ? AppConstants.darkBorder : AppConstants.lightBorder;
    final textSecondaryColor = isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary;

    final totalCollected = _historyTab == 'sales'
        ? provider.payments.fold(0.0, (sum, p) => sum + p.amount)
        : provider.bookingPayments.fold(0.0, (sum, p) => sum + p.amount);

    final searchQuery = _searchController.text.toLowerCase();
    final filteredPayments = provider.payments.where((p) {
      final name = (p.customerName ?? '').toLowerCase();
      final remarks = (p.remarks).toLowerCase();
      final receiptNo = (p.receiptNo ?? '').toLowerCase();
      return name.contains(searchQuery) || remarks.contains(searchQuery) || receiptNo.contains(searchQuery);
    }).toList();

    final filteredBookingPayments = provider.bookingPayments.where((p) {
      final name = (p.customerName ?? '').toLowerCase();
      final remarks = (p.remarks).toLowerCase();
      return name.contains(searchQuery) || remarks.contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Customer Payments',
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
          // Tab Toggle for Registries
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.darkCard : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _historyTab = 'sales'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _historyTab == 'sales' ? AppConstants.primaryTeal : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Sales Payments',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _historyTab == 'sales' ? Colors.white : textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _historyTab = 'bookings'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _historyTab == 'bookings' ? AppConstants.primaryTeal : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Booking Payments',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _historyTab == 'bookings' ? Colors.white : textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search + Add row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
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
                        hintText: 'Search by customer name...',
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
                    onPressed: () => _openPaymentDialog(context),
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
                  : (_historyTab == 'sales' ? filteredPayments.isEmpty : filteredBookingPayments.isEmpty)
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
                                Text('No $_historyTab payment records found.', style: TextStyle(color: textSecondaryColor)),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 90), // Added bottom padding to prevent hiding
                                itemCount: _historyTab == 'sales' ? filteredPayments.length : filteredBookingPayments.length,
                                itemBuilder: (context, index) {
                                  if (_historyTab == 'sales') {
                                    final p = filteredPayments[index];
                                    return GestureDetector(
                                      onTap: () => _openPaymentDialog(context, salesPayment: p),
                                      child: _buildSalesPaymentCard(p, isDark, cardColor, borderColor, index + 1),
                                    );
                                  } else {
                                    final p = filteredBookingPayments[index];
                                    return GestureDetector(
                                      onTap: () => _confirmDeleteBookingPayment(context, p),
                                      child: _buildBookingPaymentCard(p, isDark, cardColor, borderColor, index + 1),
                                    );
                                  }
                                },
                              ),
                            ),
                            _buildSummaryFooter(totalCollected, isDark, cardColor, borderColor),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesPaymentCard(CustomerPaymentModel p, bool isDark, Color cardColor, Color borderColor, int index) {
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
                p.customerName ?? 'Customer #${p.customerId}',
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
              if (p.invoiceId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppConstants.darkBorder : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    p.receiptNo ?? 'INV-${p.invoiceId}',
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
          if (p.remarks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              p.remarks,
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

  Widget _buildBookingPaymentCard(BookingPaymentModel p, bool isDark, Color cardColor, Color borderColor, int index) {
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
                p.customerName ?? 'Customer',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.darkBorder : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#BK-${p.bookingId}',
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ),
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
          if (p.remarks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              p.remarks,
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

  Widget _buildSummaryFooter(double totalCollected, bool isDark, Color cardColor, Color borderColor) {
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
              _historyTab == 'sales' ? 'TOTAL COLLECTED (SALES)' : 'TOTAL COLLECTED (BOOKINGS)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimaryColor),
            ),
            Text(
              'PKR ${totalCollected.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppConstants.primaryTeal, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Customer Payment Form Dialog ─────────────────────────────────────────────
class _CustomerPaymentFormDialog extends StatefulWidget {
  final CustomerPaymentModel? editSalesPayment;
  final BookingPaymentModel? editBookingPayment;

  const _CustomerPaymentFormDialog({this.editSalesPayment, this.editBookingPayment});

  @override
  State<_CustomerPaymentFormDialog> createState() => _CustomerPaymentFormDialogState();
}

class _CustomerPaymentFormDialogState extends State<_CustomerPaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedCustomerId;
  String _linkType = 'invoice'; // 'invoice' or 'booking'
  int? _selectedInvoiceId;
  int? _selectedBookingId;
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String _paymentMethod = 'Cash';
  final _remarksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sp = widget.editSalesPayment;
    final bp = widget.editBookingPayment;

    if (sp != null) {
      _selectedCustomerId = sp.customerId;
      _selectedInvoiceId = sp.invoiceId;
      _selectedBookingId = null;
      _linkType = 'invoice';
      _amountCtrl.text = sp.amount.toString();
      _dateCtrl.text = sp.paymentDate.split('T')[0];
      _paymentMethod = sp.paymentMethod;
      _remarksCtrl.text = sp.remarks;
    } else if (bp != null) {
      _selectedCustomerId = bp.customerId;
      _selectedInvoiceId = null;
      _selectedBookingId = bp.bookingId;
      _linkType = 'booking';
      _amountCtrl.text = bp.amount.toString();
      _dateCtrl.text = bp.paymentDate.split('T')[0];
      _paymentMethod = bp.paymentMethod;
      _remarksCtrl.text = bp.remarks;
    } else {
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    _remarksCtrl.dispose();
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
    if (widget.editBookingPayment != null) {
      // Booking payments are read-only / delete-only per React rules.
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer.')),
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

    final provider = context.read<CustomerPaymentProvider>();

    // Check maximum due limit
    double? selectedDue;
    if (_linkType == 'invoice' && _selectedInvoiceId != null) {
      final matchingInvoice = provider.invoices.firstWhere((i) => i.id == _selectedInvoiceId);
      selectedDue = matchingInvoice.toBePaid;
    } else if (_linkType == 'booking' && _selectedBookingId != null) {
      final matchingBooking = provider.bookings.firstWhere((b) => b.id == _selectedBookingId);
      selectedDue = matchingBooking.toBePaid;
    }

    if (selectedDue != null && amount > selectedDue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Amount exceeds due (PKR ${selectedDue.toStringAsFixed(2)}).'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool success;
    if (_linkType == 'booking' && _selectedBookingId != null) {
      // Record booking payment
      final payload = {
        'amount': amount,
        'paymentMethod': _paymentMethod,
        'paymentDate': _dateCtrl.text,
        'remarks': _remarksCtrl.text.trim(),
      };
      success = await provider.saveBookingPayment(_selectedBookingId!, payload);
    } else {
      // Record regular invoice / customer payment
      final payment = CustomerPaymentModel(
        customerId: _selectedCustomerId!,
        invoiceId: _selectedInvoiceId,
        amount: amount,
        paymentMethod: _paymentMethod,
        paymentDate: _dateCtrl.text,
        remarks: _remarksCtrl.text.trim(),
      );
      success = await provider.saveCustomerPayment(payment, editId: widget.editSalesPayment?.id);
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editSalesPayment != null
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
    final isBooking = widget.editBookingPayment != null;
    final msg = isBooking
        ? 'Delete this booking payment?'
        : 'Delete this payment? Invoice status will be recalculated.';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Collection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(msg),
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
      final provider = context.read<CustomerPaymentProvider>();
      final id = isBooking ? widget.editBookingPayment!.id : widget.editSalesPayment!.id!;
      final success = isBooking
          ? await provider.deleteBookingPayment(id)
          : await provider.deleteCustomerPayment(id);

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

  Widget _buildLinkTypeButton(String label, String value) {
    final isSelected = _linkType == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: widget.editSalesPayment != null || widget.editBookingPayment != null
          ? null // Read-only in edit mode
          : () {
              setState(() {
                _linkType = value;
                _selectedInvoiceId = null;
                _selectedBookingId = null;
              });
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryTeal : (isDark ? AppConstants.darkBorder : Colors.grey[200]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerPaymentProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppConstants.darkBorder : AppConstants.lightBorder;
    final textPrimaryColor = isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary;
    final isEdit = widget.editSalesPayment != null || widget.editBookingPayment != null;
    final isBookingEdit = widget.editBookingPayment != null;

    // Filtered data for selected customer
    double outstandingBalance = 0;
    List<SaleInvoiceListModel> customerInvoices = [];
    List<BookingModel> customerBookings = [];

    if (_selectedCustomerId != null) {
      final invDue = provider.invoices
          .where((inv) => inv.customerId == _selectedCustomerId)
          .fold(0.0, (sum, inv) => sum + inv.toBePaid);

      final bookDue = provider.bookings
          .where((bk) => bk.customerId == _selectedCustomerId)
          .fold(0.0, (sum, bk) => sum + bk.toBePaid);

      outstandingBalance = invDue + bookDue;

      customerInvoices = provider.invoices
          .where((inv) => inv.customerId == _selectedCustomerId && inv.toBePaid > 0)
          .toList();

      customerBookings = provider.bookings
          .where((bk) => bk.customerId == _selectedCustomerId && bk.toBePaid > 0)
          .toList();
    }

    double? selectedDue;
    if (_linkType == 'invoice' && _selectedInvoiceId != null && customerInvoices.isNotEmpty) {
      final matches = customerInvoices.where((i) => i.id == _selectedInvoiceId);
      if (matches.isNotEmpty) {
        selectedDue = matches.first.toBePaid;
      }
    } else if (_linkType == 'booking' && _selectedBookingId != null && customerBookings.isNotEmpty) {
      final matches = customerBookings.where((b) => b.id == _selectedBookingId);
      if (matches.isNotEmpty) {
        selectedDue = matches.first.toBePaid;
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
                      isEdit ? 'Edit Collection' : 'New Collection Voucher',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimaryColor),
                    ),
                  ),
                  if (isEdit)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: _confirmDelete,
                      tooltip: 'Delete Receipt',
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

              // Customer Dropdown
              Text('Customer *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
              const SizedBox(height: 4),
              DropdownButtonFormField<int>(
                value: _selectedCustomerId,
                dropdownColor: isDark ? AppConstants.darkCard : Colors.white,
                decoration: _inputDecoration(isDark, borderColor, hint: 'Choose Customer...'),
                items: provider.customers.map((c) {
                  return DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(c.customerName, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: isEdit
                    ? null // Read-only in edit mode
                    : (val) {
                        setState(() {
                          _selectedCustomerId = val;
                          _selectedInvoiceId = null;
                          _selectedBookingId = null;
                        });
                      },
              ),
              const SizedBox(height: 12),

              // Outstanding Display
              if (_selectedCustomerId != null) ...[
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

                // Link Type Selector Buttons
                Row(
                  children: [
                    _buildLinkTypeButton('Invoice Link', 'invoice'),
                    const SizedBox(width: 8),
                    _buildLinkTypeButton('Booking Link', 'booking'),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Invoices Dropdown
              if (_selectedCustomerId != null && _linkType == 'invoice' && customerInvoices.isNotEmpty) ...[
                Text('Link to Sale Invoice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  value: _selectedInvoiceId,
                  dropdownColor: isDark ? AppConstants.darkCard : Colors.white,
                  decoration: _inputDecoration(isDark, borderColor, hint: '— General Payment (No Invoice Link) —'),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('— General (No Invoice) —', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ),
                    ...customerInvoices.map((inv) {
                      return DropdownMenuItem<int>(
                        value: inv.id,
                        child: Text('${inv.displayRef} — Due: PKR ${inv.toBePaid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                      );
                    }),
                  ],
                  onChanged: isEdit ? null : (val) {
                    setState(() {
                      _selectedInvoiceId = val;
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Bookings Dropdown
              if (_selectedCustomerId != null && _linkType == 'booking' && customerBookings.isNotEmpty) ...[
                Text('Link to Booking', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  value: _selectedBookingId,
                  dropdownColor: isDark ? AppConstants.darkCard : Colors.white,
                  decoration: _inputDecoration(isDark, borderColor, hint: '— Select Booking —'),
                  items: customerBookings.map((bk) {
                    return DropdownMenuItem<int>(
                      value: bk.id,
                      child: Text('#BK-${bk.id} (${bk.bookingDate.split('T')[0]}) — Due: PKR ${bk.toBePaid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: isEdit ? null : (val) {
                    setState(() {
                      _selectedBookingId = val;
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],

              if (selectedDue != null) ...[
                Text(
                  'Due on selected item: PKR ${selectedDue.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
              ],

              // Amount and Date
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amount Received *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _amountCtrl,
                          enabled: !isBookingEdit, // Booking editing is read-only
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
                        Text('Receipt Date *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _dateCtrl,
                          readOnly: true,
                          enabled: !isBookingEdit,
                          onTap: isBookingEdit ? null : () => _selectDate(context),
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
              Text('Collection Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                dropdownColor: isDark ? AppConstants.darkCard : Colors.white,
                decoration: _inputDecoration(isDark, borderColor),
                items: ['Cash', 'Card', 'Online', 'Cheque']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: isBookingEdit ? null : (val) => setState(() => _paymentMethod = val ?? 'Cash'),
              ),
              const SizedBox(height: 12),

              // Remarks
              Text('Remarks / Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _remarksCtrl,
                enabled: !isBookingEdit,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: _inputDecoration(isDark, borderColor, hint: 'Invoice details, bank details, or remarks...'),
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
                  if (!isBookingEdit) // Only show save button for non-booking payments in edit mode
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
                          : Text(isEdit ? 'Update Receipt' : 'Record Receipt', style: const TextStyle(fontWeight: FontWeight.bold)),
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
