import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_data.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class DashboardProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  late final ApiService _apiService;

  bool _loading = false;
  String _selectedPeriod = 'daily';

  // Stats
  double _totalCustomers = 0;
  double _totalProducts = 0;
  double _totalStaff = 0;
  double _totalSales = 0;
  double _totalBookings = 0;

  // Status breakdown (Pie Chart data)
  int _pendingBookings = 0;
  int _completedBookings = 0;
  int _rejectedBookings = 0;

  // Lists
  List<BookingItem> _recentBookings = [];
  List<SalesInvoiceItem> _recentSales = [];
  List<SalesPeriodChartItem> _salesOverview = [];

  bool get loading => _loading;
  String get selectedPeriod => _selectedPeriod;

  double get totalCustomers => _totalCustomers;
  double get totalProducts => _totalProducts;
  double get totalStaff => _totalStaff;
  double get totalSales => _totalSales;
  double get totalBookings => _totalBookings;

  int get pendingBookings => _pendingBookings;
  int get completedBookings => _completedBookings;
  int get rejectedBookings => _rejectedBookings;

  List<BookingItem> get recentBookings => _recentBookings;
  List<SalesInvoiceItem> get recentSales => _recentSales;
  List<SalesPeriodChartItem> get salesOverview => _salesOverview;

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  DashboardProvider(this._prefs) {
    _apiService = ApiService(_prefs);
  }

  // Set chart period and fetch new data
  void setPeriod(String period, bool showSales) {
    _selectedPeriod = period;
    notifyListeners();
    if (showSales) {
      fetchChartData();
    }
  }

  // Fetch all dashboard stats based on permissions
  Future<void> fetchDashboardStats(AuthProvider auth) async {
    _loading = true;
    notifyListeners();

    final showCustomers = auth.isAdmin || auth.canAccess('Customer');
    final showProducts = auth.isAdmin || auth.canAccess('Items') || auth.canAccess('Item');
    final showStaff = auth.isAdmin || auth.canAccess('Users') || auth.canAccess('Security');
    final showSales = auth.isAdmin || auth.canAccess('Sale');
    final showBookings = auth.isAdmin || auth.canAccess('Booking');

    debugPrint('DASHBOARD: showCustomers: $showCustomers, showProducts: $showProducts, showStaff: $showStaff, showSales: $showSales, showBookings: $showBookings');

    try {
      debugPrint('DASHBOARD: Starting parallel API requests...');
      
      // We use individual try-catch blocks for each future to mirror React's .catch() behavior
      // This ensures one failing API call doesn't stop others
      
      Future<dynamic> safeGet(String endpoint, bool show) async {
        if (!show) return null;
        try {
          final res = await _apiService.get(endpoint);
          return res.statusCode == 200 ? jsonDecode(res.body) : null;
        } catch (e) {
          debugPrint('DASHBOARD: Error fetching $endpoint: $e');
          return null;
        }
      }

      final results = await Future.wait([
        safeGet('/customers/count', showCustomers),
        safeGet('/item-details/count', showProducts),
        safeGet('/staff/count', showStaff),
        safeGet('/bookings', showBookings),
        safeGet('/sale-invoices/revenue', showSales),
      ]);

      debugPrint('DASHBOARD: API requests finished.');

      // 1. Process Customers
      final customersData = results[0];
      if (customersData != null) {
        _totalCustomers = _parseDouble(customersData['totalCustomers'] ?? customersData['count'] ?? 0);
      } else {
        _totalCustomers = 0;
      }

      // 2. Process Products
      final productsData = results[1];
      if (productsData != null) {
        _totalProducts = _parseDouble(productsData['count'] ?? 0);
      } else {
        _totalProducts = 0;
      }

      // 3. Process Staff
      final staffData = results[2];
      if (staffData != null) {
        // Handle { data: { total: 10 } } or { count: 10 }
        _totalStaff = _parseDouble(staffData['data']?['total'] ?? staffData['count'] ?? 0);
      } else {
        _totalStaff = 0;
      }

      // 4. Process Bookings
      final bookingsData = results[3];
      if (bookingsData != null) {
        final List bList = bookingsData is List ? bookingsData : (bookingsData['data'] ?? []);
        final allBookings = bList.map((b) => BookingItem.fromJson(b)).toList();
        
        _totalBookings = allBookings.length.toDouble();
        
        // Calculate status counts (case-insensitive)
        _pendingBookings = allBookings.where((b) => b.bookingStatus.toLowerCase() == 'pending').length;
        _completedBookings = allBookings.where((b) => b.bookingStatus.toLowerCase() == 'completed').length;
        _rejectedBookings = allBookings.where((b) => b.bookingStatus.toLowerCase() == 'rejected').length;

        _recentBookings = allBookings;
        if (_recentBookings.length > 5) {
          _recentBookings = _recentBookings.sublist(0, 5);
        }
      } else {
        _totalBookings = 0;
        _pendingBookings = 0;
        _completedBookings = 0;
        _rejectedBookings = 0;
        _recentBookings = [];
      }

      // 5. Process Revenue
      final revenueData = results[4];
      if (revenueData != null) {
        // Handle { revenue: 100 } or { data: { revenue: 100 } }
        _totalSales = _parseDouble(revenueData['revenue'] ?? revenueData['data']?['revenue'] ?? 0.0);
      } else {
        _totalSales = 0;
      }

      debugPrint('DASHBOARD: Global stats processed. Sales: $_totalSales, Bookings: $_totalBookings');

      // Fetch Recent Sales and Chart Data if permitted
      if (showSales) {
        await _fetchRecentSales();
        await fetchChartData();
      }
    } catch (e) {
      debugPrint('DASHBOARD: Unexpected error in fetchDashboardStats: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Fetch recent sales invoices
  Future<void> _fetchRecentSales() async {
    try {
      final response = await _apiService.get('/sale-invoices?limit=5');
      debugPrint('DASHBOARD: Recent sales status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final rawData = jsonDecode(response.body);
        final List sList = rawData is List ? rawData : (rawData['data'] ?? []);
        debugPrint('DASHBOARD: Recent sales count: ${sList.length}');
        
        _recentSales = sList.map((s) => SalesInvoiceItem.fromJson(s)).toList();
        if (_recentSales.length > 5) {
          _recentSales = _recentSales.sublist(0, 5);
        }
      }
    } catch (e) {
      debugPrint('DASHBOARD: ERROR fetching recent sales: $e');
    }
  }

  // Fetch chart data
  Future<void> fetchChartData() async {
    try {
      final response = await _apiService.get('/sale-invoices/period?period=$_selectedPeriod');
      debugPrint('DASHBOARD: Chart data status: ${response.statusCode} for period: $_selectedPeriod');
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        debugPrint('DASHBOARD: Chart data items: ${list.length}');
        _salesOverview = list.map((item) => SalesPeriodChartItem.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DASHBOARD: ERROR fetching chart data: $e');
    }
  }
}
