import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supplier_ledger_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_loader.dart';

class SupplierLedgerScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const SupplierLedgerScreen({super.key, this.onMenuPressed});

  @override
  State<SupplierLedgerScreen> createState() => _SupplierLedgerScreenState();
}

class _SupplierLedgerScreenState extends State<SupplierLedgerScreen> {
  int? _selectedSupplierId;
  final _searchController = TextEditingController();
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
    await context.read<SupplierLedgerProvider>().fetchSuppliers();
    context.read<SupplierLedgerProvider>().clearLedger();
    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    final prov = context.read<SupplierLedgerProvider>();
    await prov.fetchSuppliers();
    if (_selectedSupplierId != null) {
      await prov.fetchLedger(_selectedSupplierId!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSupplierChanged(int? id) {
    setState(() {
      _selectedSupplierId = id;
    });
    if (id != null) {
      context.read<SupplierLedgerProvider>().fetchLedger(id);
    } else {
      context.read<SupplierLedgerProvider>().clearLedger();
    }
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SupplierLedgerProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppConstants.darkCard : Colors.white;
    final borderColor = isDark ? AppConstants.darkBorder : AppConstants.lightBorder;
    final textSecondaryColor = isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary;
    final textPrimaryColor = isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary;

    final ledgerData = provider.ledgerData;
    final loadingLedger = provider.loadingLedger;

    // Filtered Transactions
    final List transactions = ledgerData?.ledger ?? [];
    final searchQuery = _searchController.text.toLowerCase().trim();
    final filteredTxns = transactions.where((t) {
      final ref = (t.reference).toLowerCase();
      final desc = (t.description).toLowerCase();
      return ref.contains(searchQuery) || desc.contains(searchQuery);
    }).toList();

    // Summary Totals
    final totalDebit = filteredTxns.fold(0.0, (sum, t) => sum + t.debit);
    final totalCredit = filteredTxns.fold(0.0, (sum, t) => sum + t.credit);
    final closingBalance = ledgerData?.closingBalance ?? 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Supplier Ledger',
        leading: widget.onMenuPressed != null
            ? IconButton(icon: const Icon(Icons.menu), onPressed: widget.onMenuPressed)
            : null,
      ),
      body: Column(
        children: [
          // Supplier Account Selector
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(14),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACCOUNT SELECTION',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppConstants.primaryTealLight : AppConstants.lightTextSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedSupplierId,
                    dropdownColor: isDark ? AppConstants.darkCard : Colors.white,
                    style: TextStyle(fontSize: 13, color: textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: 'Select Supplier...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: isDark ? AppConstants.darkCard : Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppConstants.primaryTeal, width: 1.5),
                      ),
                    ),
                    items: provider.suppliers.map((s) {
                      return DropdownMenuItem<int>(
                        value: s.id,
                        child: Text(s.supplierName, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: _onSupplierChanged,
                  ),
                ],
              ),
            ),
          ),

          // Ledger Summaries
          if (ledgerData != null && !loadingLedger)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildSummaryMiniCard('TOTAL PURCHASES (DR)', totalDebit, isDark, Colors.redAccent),
                      const SizedBox(width: 10),
                      _buildSummaryMiniCard('TOTAL PAYMENTS (CR)', totalCredit, isDark, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: closingBalance > 0
                          ? Colors.redAccent.withValues(alpha: 0.08)
                          : closingBalance < 0
                              ? Colors.green.withValues(alpha: 0.08)
                              : (isDark ? AppConstants.darkCard : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                      border: Border.all(
                        color: closingBalance > 0
                            ? Colors.redAccent.withValues(alpha: 0.2)
                            : closingBalance < 0
                                ? Colors.green.withValues(alpha: 0.2)
                                : borderColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NET OUTSTANDING BALANCE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: closingBalance > 0
                                ? Colors.redAccent
                                : closingBalance < 0
                                    ? Colors.green
                                    : textSecondaryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PKR ${closingBalance.abs().toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: closingBalance > 0
                                    ? Colors.redAccent
                                    : closingBalance < 0
                                        ? Colors.green
                                        : textPrimaryColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              closingBalance > 0
                                  ? 'DR (Owed)'
                                  : closingBalance < 0
                                      ? 'CR (Overpaid)'
                                      : 'Settled',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: closingBalance > 0
                                    ? Colors.redAccent
                                    : closingBalance < 0
                                        ? Colors.green
                                        : textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Search Header inside Ledger
          if (_selectedSupplierId != null && !loadingLedger && ledgerData != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Filter by reference or description...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.filter_list, size: 18),
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

          // Ledger Transactions
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final prov = context.read<SupplierLedgerProvider>();
                await prov.fetchSuppliers();
                if (_selectedSupplierId != null) {
                  await prov.fetchLedger(_selectedSupplierId!);
                }
              },
              color: AppConstants.primaryTeal,
              child: _selectedSupplierId == null
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.45,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_box_outlined, size: 64, color: textSecondaryColor),
                            const SizedBox(height: 12),
                            Text('Select a supplier to view statement.', style: TextStyle(color: textSecondaryColor)),
                          ],
                        ),
                      ),
                    )
                  : loadingLedger && filteredTxns.isEmpty
                      ? const CustomLoader()
                      : filteredTxns.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Container(
                                height: MediaQuery.of(context).size.height * 0.45,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.receipt_outlined, size: 64, color: textSecondaryColor),
                                    const SizedBox(height: 12),
                                    Text('No ledger entries recorded.', style: TextStyle(color: textSecondaryColor)),
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
                                final date = txn.date ?? '—';
                                final ref = txn.reference;
                                final desc = txn.description;
                                final debit = txn.debit;
                                final credit = txn.credit;
                                final balance = txn.balance;

                                final balanceType = balance > 0
                                    ? 'DR'
                                    : balance < 0
                                        ? 'CR'
                                        : '';

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
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: ref == 'OPENING'
                                                  ? Colors.amber.withValues(alpha: 0.1)
                                                  : (isDark ? AppConstants.darkBorder : Colors.grey[200]),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              ref,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'monospace',
                                                color: ref == 'OPENING' ? Colors.amber[800] : textPrimaryColor,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            date,
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
                                          Row(
                                            children: [
                                              if (debit > 0)
                                                _buildFlowAmount('DEBIT (+)', debit, Colors.redAccent)
                                              else if (credit > 0)
                                                _buildFlowAmount('CREDIT (−)', credit, Colors.green)
                                              else
                                                Text('—', style: TextStyle(color: textSecondaryColor)),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'RUNNING BALANCE',
                                                style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'PKR ${balance.abs().toStringAsFixed(2)} $balanceType',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: balance > 0
                                                      ? Colors.redAccent
                                                      : balance < 0
                                                          ? Colors.green
                                                          : Colors.grey,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
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

  Widget _buildSummaryMiniCard(String label, double value, bool isDark, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppConstants.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(color: isDark ? AppConstants.darkBorder : color.withValues(alpha: 0.15)),
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
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowAmount(String label, double value, Color color) {
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
}
