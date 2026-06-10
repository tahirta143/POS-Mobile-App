import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_payment_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_loader.dart';

class AmountReceivableScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const AmountReceivableScreen({super.key, this.onMenuPressed});

  @override
  State<AmountReceivableScreen> createState() => _AmountReceivableScreenState();
}

class _AmountReceivableScreenState extends State<AmountReceivableScreen> {
  String _activeTab = 'all'; // 'all', 'sales', 'bookings'
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
    final provider = context.read<CustomerPaymentProvider>();
    await Future.wait([
      provider.fetchInvoices(),
      provider.fetchBookings(),
    ]);
    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    final provider = context.read<CustomerPaymentProvider>();
    await Future.wait([
      provider.fetchInvoices(),
      provider.fetchBookings(),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerPaymentProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppConstants.darkCard : Colors.white;
    final borderColor = isDark ? AppConstants.darkBorder : AppConstants.lightBorder;
    final textSecondaryColor = isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary;
    final textPrimaryColor = isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary;

    // Group Sales
    final Map<int, Map<String, dynamic>> salesMap = {};
    for (final inv in provider.invoices) {
      if (inv.toBePaid <= 0) continue;
      final id = inv.customerId ?? 0;
      if (!salesMap.containsKey(id)) {
        salesMap[id] = {
          'customer_id': id,
          'customer_name': inv.customerName ?? 'Customer #$id',
          'mobile': inv.mobileNumber ?? '—',
          'total_due': 0.0,
          'count': 0,
          'type': 'Sale',
        };
      }
      final e = salesMap[id]!;
      e['total_due'] = (e['total_due'] as double) + inv.toBePaid;
      e['count'] = (e['count'] as int) + 1;
    }

    // Group Bookings
    final Map<int, Map<String, dynamic>> bookingsMap = {};
    for (final bk in provider.bookings) {
      if (bk.toBePaid <= 0) continue;
      final id = bk.customerId;
      if (!bookingsMap.containsKey(id)) {
        bookingsMap[id] = {
          'customer_id': id,
          'customer_name': bk.customerName ?? 'Customer #$id',
          'mobile': bk.mobileNumber ?? '—',
          'total_due': 0.0,
          'count': 0,
          'type': 'Booking',
        };
      }
      final e = bookingsMap[id]!;
      e['total_due'] = (e['total_due'] as double) + bk.toBePaid;
      e['count'] = (e['count'] as int) + 1;
    }

    final salesDues = salesMap.values.toList();
    final bookingDues = bookingsMap.values.toList();

    // Summary Dues Calculations
    final salesTotal = salesDues.fold(0.0, (sum, r) => sum + (r['total_due'] as double));
    final bookingsTotal = bookingDues.fold(0.0, (sum, r) => sum + (r['total_due'] as double));
    final grandTotal = salesTotal + bookingsTotal;

    final customerIdsSet = <int>{};
    for (var r in [...salesDues, ...bookingDues]) {
      customerIdsSet.add(r['customer_id'] as int);
    }
    final customerCount = customerIdsSet.length;

    // Filter by tab
    List<Map<String, dynamic>> receivablesList = [];
    if (_activeTab == 'sales') {
      receivablesList = salesDues;
    } else if (_activeTab == 'bookings') {
      receivablesList = bookingDues;
    } else {
      // Merge
      final Map<int, Map<String, dynamic>> combined = {};
      for (final r in [...salesDues, ...bookingDues]) {
        final id = r['customer_id'] as int;
        if (!combined.containsKey(id)) {
          combined[id] = {
            'customer_id': id,
            'customer_name': r['customer_name'],
            'mobile': r['mobile'],
            'total_due': 0.0,
            'count': 0,
            'type': 'Mixed',
          };
        }
        final e = combined[id]!;
        e['total_due'] = (e['total_due'] as double) + (r['total_due'] as double);
        e['count'] = (e['count'] as int) + (r['count'] as int);
        if (e['type'] != r['type'] && e['type'] != 'Mixed') {
          e['type'] = 'Mixed';
        }
      }
      receivablesList = combined.values.toList()
        ..sort((a, b) => (b['total_due'] as double).compareTo(a['total_due'] as double));
    }

    final searchQuery = _searchController.text.toLowerCase();
    final filtered = receivablesList.where((r) {
      final name = (r['customer_name'] as String).toLowerCase();
      final mobile = (r['mobile'] as String).toLowerCase();
      return name.contains(searchQuery) || mobile.contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Amount Receivable',
        leading: widget.onMenuPressed != null
            ? IconButton(icon: const Icon(Icons.menu), onPressed: widget.onMenuPressed)
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              provider.fetchInvoices();
              provider.fetchBookings();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stat Cards Carousel / Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatCard('GRAND TOTAL', grandTotal, isDark, Colors.teal, 'PKR'),
                  const SizedBox(width: 8),
                  _buildStatCard('SALES DUES', salesTotal, isDark, Colors.blue, 'PKR'),
                  const SizedBox(width: 8),
                  _buildStatCard('BOOKING DUES', bookingsTotal, isDark, Colors.indigo, 'PKR'),
                  const SizedBox(width: 8),
                  _buildStatCard('CUSTOMERS', customerCount.toDouble(), isDark, Colors.pink, '', isInt: true),
                ],
              ),
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.darkCard : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  _buildTabButton('All', 'all', textSecondaryColor),
                  _buildTabButton('Sales', 'sales', textSecondaryColor),
                  _buildTabButton('Bookings', 'bookings', textSecondaryColor),
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
                  hintText: 'Search by name or mobile...',
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

          // Receivables List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _refreshData();
              },
              color: AppConstants.primaryTeal,
              child: _isInitialLoading
                  ? const CustomLoader()
                  : filtered.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.5,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 64, color: textSecondaryColor),
                                const SizedBox(height: 12),
                                Text('No outstanding receivables found.', style: TextStyle(color: textSecondaryColor)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 90),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final r = filtered[index];
                          final name = r['customer_name'] as String;
                          final mobile = r['mobile'] as String;
                          final due = r['total_due'] as double;
                          final count = r['count'] as int;
                          final type = r['type'] as String;

                          Color typeBadgeColor = Colors.grey;
                          if (type == 'Sale') typeBadgeColor = Colors.blue;
                          if (type == 'Booking') typeBadgeColor = Colors.indigo;
                          if (type == 'Mixed') typeBadgeColor = Colors.teal;

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
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.phone_outlined, size: 12, color: textSecondaryColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            mobile,
                                            style: TextStyle(fontSize: 11, color: textSecondaryColor),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: Colors.pink.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '$count item${count == 1 ? "" : "s"}',
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: typeBadgeColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        type.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: typeBadgeColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'PKR ${due.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.primaryTeal,
                                        fontFamily: 'monospace',
                                      ),
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

  Widget _buildStatCard(String label, double value, bool isDark, MaterialColor themeColor, String unit, {bool isInt = false}) {
    final displayValue = isInt ? value.toStringAsFixed(0) : value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
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
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isDark ? AppConstants.darkTextSecondary : themeColor[700],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${unit.isNotEmpty ? "$unit " : ""}$displayValue',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? AppConstants.darkTextPrimary : themeColor[800],
              fontFamily: unit.isNotEmpty ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String value, Color textSecondaryColor) {
    final isSelected = _activeTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
