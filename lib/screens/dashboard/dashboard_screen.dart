import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/custom_app_bar.dart';
import '../../models/dashboard_data.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const DashboardScreen({super.key, this.onMenuPressed});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard stats on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStats();
    });
  }

  void _refreshStats() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<DashboardProvider>(context, listen: false).fetchDashboardStats(auth);
  }

  String _formatCurrency(double val) {
    return NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'Rs. ',
      decimalDigits: 0,
    ).format(val);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(dateTime);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final auth = Provider.of<AuthProvider>(context);
    final dashboard = Provider.of<DashboardProvider>(context);

    // Permission flags
    final showCustomers = auth.isAdmin || auth.canAccess('Customer');
    final showProducts = auth.isAdmin || auth.canAccess('Items') || auth.canAccess('Item');
    final showStaff = auth.isAdmin || auth.canAccess('Users') || auth.canAccess('Security');
    final showSales = auth.isAdmin || auth.canAccess('Sale');
    final showBookings = auth.isAdmin || auth.canAccess('Booking');
    final hasAnyAccess = showCustomers || showProducts || showStaff || showSales || showBookings;

    // Responsive grid column count for stats cards
    int crossAxisCount = 2;
    if (size.width > 1100) {
      crossAxisCount = 5;
    } else if (size.width > 700) {
      crossAxisCount = 3;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Dashboard',
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onMenuPressed,
        ),
      ),
      body: dashboard.loading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryTeal))
          : !hasAnyAccess
              ? _buildNoAccessScreen(isDark)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome text
                      Text(
                        'Welcome, ${auth.user?.name ?? "User"}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Overview of your business performance and key metrics',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Stat Cards Grid
                      GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: size.width > 1100 ? 1.7 : 1.9,
                        children: [
                          _buildStatCard(
                            label: 'Customers',
                            value: dashboard.totalCustomers.toInt().toString(),
                            icon: Icons.people_outline,
                            show: showCustomers,
                            isDark: isDark,
                          ),
                          _buildStatCard(
                            label: 'Products',
                            value: dashboard.totalProducts.toInt().toString(),
                            icon: Icons.inventory_2_outlined,
                            show: showProducts,
                            isDark: isDark,
                          ),
                          _buildStatCard(
                            label: 'Staff',
                            value: dashboard.totalStaff.toInt().toString(),
                            icon: Icons.badge_outlined,
                            show: showStaff,
                            isDark: isDark,
                          ),
                          _buildStatCard(
                            label: 'Total Sales',
                            value: _formatCurrency(dashboard.totalSales),
                            icon: Icons.monetization_on_outlined,
                            show: showSales,
                            isDark: isDark,
                          ),
                          _buildStatCard(
                            label: 'Bookings',
                            value: dashboard.totalBookings.toInt().toString(),
                            icon: Icons.calendar_month_outlined,
                            show: showBookings,
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Chart Row / Column depending on screen width
                      if (size.width > 900)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildSalesOverviewChart(isDark, showSales, dashboard),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: _buildBookingDistributionChart(isDark, showBookings, dashboard),
                            ),
                          ],
                        )
                      else ...[
                        _buildSalesOverviewChart(isDark, showSales, dashboard),
                        const SizedBox(height: 1),
                        _buildBookingDistributionChart(isDark, showBookings, dashboard),
                      ],
                      const SizedBox(height: 1),

                      // Tables Row / Column
                      if (size.width > 900)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildRecentBookingsTable(isDark, showBookings, dashboard),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildRecentSalesTable(isDark, showSales, dashboard),
                            ),
                          ],
                        )
                      else ...[
                        _buildRecentBookingsTable(isDark, showBookings, dashboard),
                        const SizedBox(height: 16),
                        _buildRecentSalesTable(isDark, showSales, dashboard),
                      ],
                    ],
                  ),
                ),
    );
  }

  // Side Drawer for Navigation
  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Drawer(
      child: Container(
        color: isDark ? AppConstants.darkCard : Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: AppConstants.primaryTeal,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  auth.user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryTeal,
                  ),
                ),
              ),
              accountName: Text(
                auth.user?.name ?? 'POS User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(auth.user?.email ?? 'user@company.com'),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              selected: true,
              selectedColor: AppConstants.primaryTeal,
              onTap: () => Navigator.of(context).pop(),
            ),
            if (auth.isAdmin || auth.canAccess('Items') || auth.canAccess('Item'))
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Items List'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/items');
                },
              ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Sign Out'),
              onTap: () async {
                await auth.logout();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Build No Access State
  Widget _buildNoAccessScreen(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 80,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Dashboard Access',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact your administrator to grant module permissions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stat Card Widget - Uses SINGLE Brand color highlight (Teal)
  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required bool show,
    required bool isDark,
  }) {
    if (!show) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppConstants.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 20,
              color: isDark ? Colors.grey[800] : Colors.grey[300],
            ),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: isDark ? Colors.grey[700] : Colors.grey[400],
              ),
            ),
            const Text(
              'No Access',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppConstants.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: isDark ? AppConstants.primaryTealLight : AppConstants.lightTextSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryTeal.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 14,
                          color: AppConstants.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_upward, color: Colors.green, size: 8),
                            Text(
                              '10%',
                              style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'vs last mo',
                        style: TextStyle(
                          fontSize: 8,
                          color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sales Overview Chart Widget
  Widget _buildSalesOverviewChart(bool isDark, bool show, DashboardProvider dashboard) {
    if (!show) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? AppConstants.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
          ),
        ),
        alignment: Alignment.center,
        child: const Text('Sales Overview — No Access', style: TextStyle(color: Colors.grey)),
      );
    }

    final chartData = dashboard.salesOverview;
    final periods = ['daily', 'weekly', 'monthly', 'yearly'];

    return Container(
      height: 350,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Sales vs Expenses performance',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Period Filter selector buttons (daily, weekly, monthly, yearly)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppConstants.darkBg : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: periods.map((p) {
                    final isSelected = dashboard.selectedPeriod == p;
                    return InkWell(
                      onTap: () {
                        dashboard.setPeriod(p, show);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? (isDark ? AppConstants.darkBorder : Colors.white) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 3,
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          p[0].toUpperCase() + p.substring(1),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppConstants.primaryTeal : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: chartData.isEmpty
                ? const Center(
                    child: Text(
                      'No sales data available',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(chartData),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => isDark ? AppConstants.darkBg : Colors.white,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final item = chartData[groupIndex];
                            final label = rodIndex == 0 ? 'Sales' : 'Expenses';
                            return BarTooltipItem(
                              '${item.periodLabel}\n$label: ${_formatCurrency(rod.toY)}',
                              TextStyle(
                                color: rodIndex == 0 ? AppConstants.primaryTeal : const Color(0xFFFB7185),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < chartData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    chartData[index].periodLabel,
                                    style: const TextStyle(color: Colors.grey, fontSize: 9),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value == 0) return const Text('0', style: TextStyle(color: Colors.grey, fontSize: 9));
                              return Text(
                                '${(value / 1000).toStringAsFixed(0)}k',
                                style: const TextStyle(color: Colors.grey, fontSize: 9),
                              );
                            },
                            reservedSize: 32,
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark ? AppConstants.darkBorder.withOpacity(0.5) : Colors.grey[200],
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(chartData.length, (index) {
                        final item = chartData[index];
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: item.sales,
                              color: AppConstants.primaryTeal,
                              width: 8,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: item.expenses,
                              color: const Color(0xFFFB7185),
                              width: 8,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendIndicator(AppConstants.primaryTeal, 'Sales'),
              const SizedBox(width: 16),
              _buildLegendIndicator(const Color(0xFFFB7185), 'Expenses'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  double _getMaxY(List<SalesPeriodChartItem> items) {
    double max = 1000.0;
    for (var item in items) {
      if (item.sales > max) max = item.sales;
      if (item.expenses > max) max = item.expenses;
    }
    return max * 1.15; // 15% padding on top
  }

  // Booking Distribution (Pie Chart) Widget
  Widget _buildBookingDistributionChart(bool isDark, bool show, DashboardProvider dashboard) {
    if (!show) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? AppConstants.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
          ),
        ),
        alignment: Alignment.center,
        child: const Text('Bookings — No Access', style: TextStyle(color: Colors.grey)),
      );
    }

    final total = dashboard.pendingBookings + dashboard.completedBookings + dashboard.rejectedBookings;

    return Container(
      height: 350,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Status breakdown of advance orders',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: total == 0
                ? const Center(child: Text('No booking status data', style: TextStyle(color: Colors.grey, fontSize: 13)))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 50,
                      sections: [
                        if (dashboard.pendingBookings > 0)
                          PieChartSectionData(
                            color: Colors.amber,
                            value: dashboard.pendingBookings.toDouble(),
                            title: '',
                            radius: 20,
                          ),
                        if (dashboard.completedBookings > 0)
                          PieChartSectionData(
                            color: const Color(0xFF10B981),
                            value: dashboard.completedBookings.toDouble(),
                            title: '',
                            radius: 20,
                          ),
                        if (dashboard.rejectedBookings > 0)
                          PieChartSectionData(
                            color: const Color(0xFFF43F5E),
                            value: dashboard.rejectedBookings.toDouble(),
                            title: '',
                            radius: 20,
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // Legend breakdown indicators matching web status card design
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPieLegendItem(
                label: 'Pending',
                count: dashboard.pendingBookings,
                color: Colors.amber,
                bgColor: Colors.amber.shade50.withOpacity(isDark ? 0.05 : 0.6),
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _buildPieLegendItem(
                label: 'Completed',
                count: dashboard.completedBookings,
                color: const Color(0xFF10B981),
                bgColor: Colors.teal.shade50.withOpacity(isDark ? 0.05 : 0.6),
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _buildPieLegendItem(
                label: 'Rejected',
                count: dashboard.rejectedBookings,
                color: const Color(0xFFF43F5E),
                bgColor: Colors.red.shade50.withOpacity(isDark ? 0.05 : 0.6),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieLegendItem({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recent Bookings Table
  Widget _buildRecentBookingsTable(bool isDark, bool show, DashboardProvider dashboard) {
    if (!show) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: isDark ? AppConstants.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
          ),
        ),
        alignment: Alignment.center,
        child: const Text('Recent Bookings — No Access', style: TextStyle(color: Colors.grey)),
      );
    }

    final list = dashboard.recentBookings;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppConstants.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Bookings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text('Latest customer bookings', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: Text('No recent bookings', style: TextStyle(color: Colors.grey, fontSize: 12))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = list[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.customerName ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                              ),
                            ),
                            Text(
                              _formatDate(item.bookingDate),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatCurrency(item.payable),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatusChip(label: item.bookingStatus),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Recent Sales Table
  Widget _buildRecentSalesTable(bool isDark, bool show, DashboardProvider dashboard) {
    if (!show) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: isDark ? AppConstants.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
          ),
        ),
        alignment: Alignment.center,
        child: const Text('Recent Sales — No Access', style: TextStyle(color: Colors.grey)),
      );
    }

    final list = dashboard.recentSales;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppConstants.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Sales',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text('Latest sales invoices', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: Text('No recent sales', style: TextStyle(color: Colors.grey, fontSize: 12))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = list[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${item.id}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryTeal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.customerName ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                              ),
                            ),
                            Text(
                              item.mobile ?? '—',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatCurrency(item.payable),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatusChip(label: item.status),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
