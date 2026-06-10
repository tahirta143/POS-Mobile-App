import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/daybook_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/access_denied_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_loader.dart';

class DaybookScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const DaybookScreen({super.key, this.onMenuPressed});

  @override
  State<DaybookScreen> createState() => _DaybookScreenState();
}

class _DaybookScreenState extends State<DaybookScreen> {
  late String _selectedDate;
  final _searchController = TextEditingController();
  final _obAmountController = TextEditingController();
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _obAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    const moduleName = 'Day Book';
    final hasReadPermission = auth.isAdmin || (auth.canAccess(moduleName) && auth.can(moduleName, 'read'));

    if (hasReadPermission) {
      if (mounted) {
        setState(() {
          _isInitialLoading = true;
        });
      }
      await context.read<DaybookProvider>().fetchDaybook(_selectedDate);
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

  Future<void> _fetchData() async {
    final auth = context.read<AuthProvider>();
    const moduleName = 'Day Book';
    final hasReadPermission = auth.isAdmin || (auth.canAccess(moduleName) && auth.can(moduleName, 'read'));

    if (hasReadPermission) {
      await context.read<DaybookProvider>().fetchDaybook(_selectedDate);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_selectedDate) ?? DateTime.now(),
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
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
      _loadData();
    }
  }

  void _openObDialog(BuildContext context, double currentOb) {
    _obAmountController.text = currentOb.toStringAsFixed(2);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final borderColor = isDark ? AppConstants.darkBorder : AppConstants.lightBorder;
        final textPrimaryColor = isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Set Opening Balance',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimaryColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Drawer cash at start of $_selectedDate',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _obAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Amount (PKR) *',
                  labelStyle: const TextStyle(fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: isDark ? AppConstants.darkCard : Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppConstants.primaryTeal, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final amount = double.tryParse(_obAmountController.text);
                if (amount == null || amount < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid balance amount.'), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                final success = await context.read<DaybookProvider>().setOpeningBalance(amount, _selectedDate);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Opening balance set.' : 'Failed to update opening balance.'),
                      backgroundColor: success ? AppConstants.primaryTeal : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save', style: TextStyle(color: AppConstants.primaryTeal, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    const moduleName = 'Day Book';
    final hasReadPermission = auth.isAdmin || (auth.canAccess(moduleName) && auth.can(moduleName, 'read'));
    final canUpdateOpeningBalance = auth.isAdmin || auth.can(moduleName, 'create') || auth.can(moduleName, 'update');

    if (!hasReadPermission) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Daybook',
          leading: widget.onMenuPressed != null
              ? IconButton(icon: const Icon(Icons.menu), onPressed: widget.onMenuPressed)
              : null,
        ),
        body: const AccessDeniedWidget(module: moduleName, action: 'READ'),
      );
    }

    final provider = Provider.of<DaybookProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppConstants.darkCard : Colors.white;
    final borderColor = isDark ? AppConstants.darkBorder : AppConstants.lightBorder;
    final textSecondaryColor = isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary;
    final textPrimaryColor = isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary;

    // Filtered transactions client-side
    final searchQuery = _searchController.text.toLowerCase().trim();
    final filteredTxns = provider.transactions.where((t) {
      final ref = (t.reference ?? '').toLowerCase();
      final desc = (t.description).toLowerCase();
      final type = (t.type).toLowerCase();
      return ref.contains(searchQuery) || desc.contains(searchQuery) || type.contains(searchQuery);
    }).toList();

    // Summary calculations
    final cashIn = provider.transactions.fold(0.0, (sum, t) => sum + t.cashIn);
    final cashOut = provider.transactions.fold(0.0, (sum, t) => sum + t.cashOut);
    final netFlow = cashIn - cashOut;
    final closingBalance = provider.openingBalance + netFlow;

    final formattedDateText = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.tryParse(_selectedDate) ?? DateTime.now());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Daybook',
        leading: widget.onMenuPressed != null
            ? IconButton(icon: const Icon(Icons.menu), onPressed: widget.onMenuPressed)
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.fetchDaybook(_selectedDate),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDateText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Transactions and daily log statement',
                          style: TextStyle(fontSize: 11, color: textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.calendar_month, color: AppConstants.primaryTeal),
                    onPressed: () => _selectDate(context),
                  ),
                  if (canUpdateOpeningBalance)
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('OB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _openObDialog(context, provider.openingBalance),
                      style: TextButton.styleFrom(
                        foregroundColor: AppConstants.primaryTeal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Stat Cards Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatCard('OPENING BALANCE', provider.openingBalance, isDark, Colors.grey),
                  const SizedBox(width: 8),
                  _buildStatCard('CASH IN', cashIn, isDark, Colors.teal),
                  const SizedBox(width: 8),
                  _buildStatCard('CASH OUT', cashOut, isDark, Colors.redAccent),
                  const SizedBox(width: 8),
                  _buildStatCard('NET FLOW', netFlow, isDark, netFlow >= 0 ? Colors.green : Colors.red),
                ],
              ),
            ),
          ),

          // Closing Balance Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConstants.primaryTeal, Color(0xFF10B981)], // Teal to Emerald
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CLOSING BALANCE / DRAWER CASH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'PKR ${closingBalance.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search reference, description or type...',
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
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),
            ),
          ),

          // Transactions List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await provider.fetchDaybook(_selectedDate);
              },
              color: AppConstants.primaryTeal,
              child: _isInitialLoading
                  ? const CustomLoader()
                  : filteredTxns.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.5,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_toggle_off_rounded, size: 64, color: textSecondaryColor),
                                const SizedBox(height: 12),
                                Text('No transactions for this date.', style: TextStyle(color: textSecondaryColor)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 90),
                          itemCount: filteredTxns.length,
                          itemBuilder: (context, index) {
                            final txn = filteredTxns[index];
                            final time = txn.dateTime != null
                                ? fmtTime(txn.dateTime!)
                                : '—';
                            final ref = txn.reference ?? '—';
                            final type = txn.type;
                            final desc = txn.description;
                            final cIn = txn.cashIn;
                            final cOut = txn.cashOut;

                            Color typeBadgeColor = Colors.grey;
                            if (type == 'SALE') typeBadgeColor = Colors.teal;
                            if (type == 'RECEIPT') typeBadgeColor = Colors.green;
                            if (type == 'EXPENSE') typeBadgeColor = Colors.orange;
                            if (type == 'PURCHASE') typeBadgeColor = Colors.blue;
                            if (type == 'PAYMENT') typeBadgeColor = Colors.redAccent;
                            if (type == 'RETURN') typeBadgeColor = Colors.amber;
                            if (type == 'OPENING') typeBadgeColor = Colors.grey;
                            if (type == 'MANUAL') typeBadgeColor = Colors.purple;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: cardColor,
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
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: typeBadgeColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              type,
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: typeBadgeColor,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            ref,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'monospace',
                                              color: textPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        time,
                                        style: TextStyle(fontSize: 11, color: textSecondaryColor, fontFamily: 'monospace'),
                                      ),
                                    ],
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      desc,
                                      style: TextStyle(fontSize: 12, color: textSecondaryColor),
                                    ),
                                  ],
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (cIn > 0)
                                        _buildAmountCol('CASH IN (+)', cIn, Colors.teal)
                                      else if (cOut > 0)
                                        _buildAmountCol('CASH OUT (−)', cOut, Colors.redAccent)
                                      else
                                        Text('—', style: TextStyle(color: textSecondaryColor)),
                                      Container(), // Align right balance spacer
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, double value, bool isDark, Color themeColor) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: isDark ? AppConstants.darkBorder : themeColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'PKR ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? AppConstants.darkTextPrimary : themeColor,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCol(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          'PKR ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  String fmtTime(String val) {
    if (val.isEmpty) return '—';
    try {
      final date = DateTime.tryParse(val);
      if (date != null) {
        return DateFormat.jm().format(date); // Format as e.g. 5:15 PM
      }
    } catch (_) {}
    return '—';
  }
}
