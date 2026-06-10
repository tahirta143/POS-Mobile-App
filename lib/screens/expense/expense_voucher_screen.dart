import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense_model.dart';
import '../../utils/constants.dart';
import '../../widgets/access_denied_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_loader.dart';

class ExpenseVoucherScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const ExpenseVoucherScreen({super.key, this.onMenuPressed});

  @override
  State<ExpenseVoucherScreen> createState() => _ExpenseVoucherScreenState();
}

class _ExpenseVoucherScreenState extends State<ExpenseVoucherScreen> {
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
    final auth = context.read<AuthProvider>();
    if (auth.isAdmin || auth.canAccess('Expense Voucher')) {
      if (mounted) {
        setState(() {
          _isInitialLoading = true;
        });
      }
      await _refreshData();
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    final provider = context.read<ExpenseProvider>();
    await Future.wait([
      provider.fetchHeads(),
      provider.fetchVouchers(),
    ]);
  }

  void _openVoucherDialog(BuildContext context, ExpenseVoucherModel? voucher, {bool canDelete = false}) {
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
          child: _VoucherFormDialog(
            editVoucher: voucher,
            canDelete: canDelete,
          ),
        ),
      ),
    ).then((_) => context.read<ExpenseProvider>().fetchVouchers());
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<ExpenseProvider>(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppConstants.darkCard : AppConstants.lightCard;
    final borderColor = isDark ? AppConstants.darkBorder : AppConstants.lightBorder;
    final textSecondaryColor = isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary;

    const moduleName = 'Expense Voucher';
    final canReadVoucher = auth.isAdmin || auth.can(moduleName, 'read');
    final canCreateVoucher = auth.isAdmin || auth.can(moduleName, 'create');
    final canUpdateVoucher = auth.isAdmin || auth.can(moduleName, 'update');
    final canDeleteVoucher = auth.isAdmin || auth.can(moduleName, 'delete');

    final searchQuery = _searchController.text.toLowerCase();
    final filteredVouchers = provider.vouchers.where((v) {
      final head = (v.headName ?? '').toLowerCase();
      final details = (v.details).toLowerCase();
      return head.contains(searchQuery) || details.contains(searchQuery);
    }).toList();

    if (!canReadVoucher) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Expense Vouchers',
          leading: widget.onMenuPressed != null
              ? IconButton(icon: const Icon(Icons.menu), onPressed: widget.onMenuPressed)
              : null,
        ),
        body: const AccessDeniedWidget(module: moduleName, action: 'READ'),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Expense Vouchers',
        leading: widget.onMenuPressed != null
            ? IconButton(icon: const Icon(Icons.menu), onPressed: widget.onMenuPressed)
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              provider.fetchHeads();
              provider.fetchVouchers();
            },
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
                        hintText: 'Search by head name or details...',
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
                if (canCreateVoucher)
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => _openVoucherDialog(context, null),
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
                await _refreshData();
              },
              color: AppConstants.primaryTeal,
              child: _isInitialLoading
                  ? const CustomLoader()
                  : filteredVouchers.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.6,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 64, color: textSecondaryColor),
                                const SizedBox(height: 12),
                                Text('No vouchers recorded yet.', style: TextStyle(color: textSecondaryColor)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 90), // Added bottom padding to not hide under bottom bar
                          itemCount: filteredVouchers.length,
                          itemBuilder: (context, index) {
                            final v = filteredVouchers[index];
                            return GestureDetector(
                              onTap: canUpdateVoucher ? () => _openVoucherDialog(context, v, canDelete: canDeleteVoucher) : null,
                              child: _buildVoucherCard(v, isDark, cardColor, borderColor),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(
    ExpenseVoucherModel v,
    bool isDark,
    Color cardColor,
    Color borderColor,
  ) {
    final formattedDate = v.voucherDate.isNotEmpty
        ? DateFormat.yMMMd().format(DateTime.tryParse(v.voucherDate) ?? DateTime.now())
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
                v.headName ?? 'Head #${v.headId}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimaryColor),
              ),
              Text(
                'PKR ${v.amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.redAccent, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (v.details.isNotEmpty) ...[
            Text(
              v.details,
              style: TextStyle(
                fontSize: 12,
                color: textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
          ],
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
}

// ─── Voucher Form Dialog ──────────────────────────────────────────────────────
class _VoucherFormDialog extends StatefulWidget {
  final ExpenseVoucherModel? editVoucher;
  final bool canDelete;

  const _VoucherFormDialog({this.editVoucher, this.canDelete = false});

  @override
  State<_VoucherFormDialog> createState() => _VoucherFormDialogState();
}

class _VoucherFormDialogState extends State<_VoucherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateCtrl = TextEditingController();
  int? _selectedHeadId;
  final _detailsCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final v = widget.editVoucher;
    if (v != null) {
      _dateCtrl.text = v.voucherDate.split('T')[0];
      _selectedHeadId = v.headId;
      _detailsCtrl.text = v.details;
      _amountCtrl.text = v.amount.toString();
    } else {
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _detailsCtrl.dispose();
    _amountCtrl.dispose();
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

    if (_selectedHeadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an Expense Head.')),
      );
      return;
    }

    final double? amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    final voucher = ExpenseVoucherModel(
      voucherDate: _dateCtrl.text,
      headId: _selectedHeadId!,
      details: _detailsCtrl.text.trim(),
      amount: amount,
    );

    final provider = context.read<ExpenseProvider>();
    final success = await provider.saveVoucher(voucher, editId: widget.editVoucher?.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editVoucher != null
                ? 'Voucher updated successfully.'
                : 'Expense Voucher recorded successfully.'),
            backgroundColor: AppConstants.primaryTeal,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Unable to save voucher.'),
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
        title: const Text('Delete Voucher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Are you sure you want to delete this expense voucher?'),
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
      final provider = context.read<ExpenseProvider>();
      final success = await provider.deleteVoucher(widget.editVoucher!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Voucher deleted successfully.' : 'Failed to delete voucher.'),
            backgroundColor: success ? AppConstants.primaryTeal : Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppConstants.darkBorder : AppConstants.lightBorder;
    final textPrimaryColor = isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary;
    final isEdit = widget.editVoucher != null;

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
                  const Icon(Icons.description_outlined, color: AppConstants.primaryTeal, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Voucher' : 'Voucher Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimaryColor),
                    ),
                  ),
                  if (isEdit && widget.canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: _confirmDelete,
                      tooltip: 'Delete Voucher',
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

              // Date Selector Field
              Text('Voucher Date *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                onTap: () => _selectDate(context),
                style: const TextStyle(fontSize: 13),
                decoration: _inputDecoration(isDark, borderColor, hint: 'Select Date', suffixIcon: Icons.calendar_today),
              ),
              const SizedBox(height: 12),

              // Head Selector Field
              Text('Expense Head *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
              const SizedBox(height: 4),
              DropdownButtonFormField<int>(
                value: _selectedHeadId,
                dropdownColor: isDark ? AppConstants.darkCard : Colors.white,
                decoration: _inputDecoration(isDark, borderColor, hint: provider.loadingHeads ? 'Loading...' : 'Select Head...'),
                items: provider.heads.map((h) {
                  return DropdownMenuItem<int>(
                    value: h.id,
                    child: Text(h.head, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedHeadId = val;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Details Field
              Text('Description / Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _detailsCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: _inputDecoration(isDark, borderColor, hint: 'Short description of transaction'),
              ),
              const SizedBox(height: 12),

              // Amount Field
              Text('Amount (PKR) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                decoration: _inputDecoration(isDark, borderColor, hint: '0.00'),
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
                        : Text(isEdit ? 'Update' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
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
