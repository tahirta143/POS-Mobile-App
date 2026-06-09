import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'dashboard/dashboard_screen.dart';
import 'items/item_list_screen.dart';

import 'opening_stock/difine_customer.dart';
import 'opening_stock/goods_reciept.dart';
import 'opening_stock/purchase_return.dart';
import 'opening_stock/sales_reciept.dart';
import 'opening_stock/sales_return.dart';

import '../utils/constants.dart';
import '../widgets/custom_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _pageIndex = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<CurvedNavigationBarState> _bottomNavKey =
      GlobalKey<CurvedNavigationBarState>();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onPageChanged(int index) {
    if (index < 0 || index >= _screens.length) return;
    setState(() {
      _pageIndex = index;
    });
    // Sync bottom nav bar only for Dashboard (0) and Items List (6)
    if (index == 0) {
      _bottomNavKey.currentState?.setPage(0);
    } else if (index == 6) {
      _bottomNavKey.currentState?.setPage(1);
    }
  }

  // Index mapping (must match CustomDrawer):
  // 0 = Dashboard
  // 1 = Goods Receipt Note
  // 2 = Purchase Return
  // 3 = Define Customer
  // 4 = Sales Receipt
  // 5 = Sales Return
  // 6 = Items List
  late final List<Widget> _screens = [
    DashboardScreen(onMenuPressed: _openDrawer),  // 0
    GoodsReceiptNoteScreen(onMenuPressed: _openDrawer),  // 1
    PurchaseReturnScreen(onMenuPressed: _openDrawer),    // 2
    DefineCustomerScreen(onMenuPressed: _openDrawer),    // 3
    SalesReceiptScreen(onMenuPressed: _openDrawer),      // 4
    SalesReturnScreen(onMenuPressed: _openDrawer),       // 5
    ItemListScreen(onMenuPressed: _openDrawer),          // 6
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      drawer: CustomDrawer(
        currentIndex: _pageIndex,
        onNavigate: _onPageChanged,
      ),

      body: _screens[_pageIndex],

      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavKey,
        // Bottom bar only tracks Dashboard and Items List
        index: _pageIndex == 6 ? 1 : 0,
        height: 60,
        items: const [
          Icon(Icons.dashboard_rounded, color: Colors.white, size: 28),
          Icon(Icons.inventory_2_rounded, color: Colors.white, size: 28),
        ],
        color: AppConstants.primaryTeal,
        buttonBackgroundColor: AppConstants.primaryTeal,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) {
          // 0 = Dashboard, 1 = Items List
          _onPageChanged(index == 1 ? 6 : 0);
        },
      ),
    );
  }
}
