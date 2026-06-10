import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'dashboard/dashboard_screen.dart';
import 'items/item_list_screen.dart';

import 'opening_stock/difine_customer.dart';
import 'opening_stock/goods_reciept.dart';
import 'opening_stock/purchase_return.dart';
import 'opening_stock/sales_reciept.dart';
import 'opening_stock/sales_return.dart';

import 'expense/expense_voucher_screen.dart';
import 'finance/supplier_payment_screen.dart';
import 'finance/customer_payment_screen.dart';
import 'expense/daybook_screen.dart';
import 'expense/expense_head_screen.dart';
import 'finance/amount_payable_screen.dart';
import 'finance/amount_receivable_screen.dart';
import 'finance/supplier_ledger_screen.dart';

import '../utils/constants.dart';
import '../widgets/custom_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _pageIndex = 0;
  bool _isTapping = false;

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
    // Sync bottom nav bar if not triggered by tapping the bar itself
    if (!_isTapping) {
      int? navIndex;
      if (index == 0) navIndex = 0;
      else if (index == 6) navIndex = 1;
      else if (index == 7) navIndex = 2;
      else if (index == 8) navIndex = 3;
      else if (index == 9) navIndex = 4;
      if (navIndex != null) {
        _bottomNavKey.currentState?.setPage(navIndex);
      }
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
  // 7 = Expense Voucher
  // 8 = Supplier Payment
  // 9 = Customer Payment
  late final List<Widget> _screens = [
    DashboardScreen(onMenuPressed: _openDrawer),  // 0
    GoodsReceiptNoteScreen(onMenuPressed: _openDrawer),  // 1
    PurchaseReturnScreen(onMenuPressed: _openDrawer),    // 2
    DefineCustomerScreen(onMenuPressed: _openDrawer),    // 3
    SalesReceiptScreen(onMenuPressed: _openDrawer),      // 4
    SalesReturnScreen(onMenuPressed: _openDrawer),       // 5
    ItemListScreen(onMenuPressed: _openDrawer),          // 6
    ExpenseVoucherScreen(onMenuPressed: _openDrawer),    // 7
    SupplierPaymentScreen(onMenuPressed: _openDrawer),   // 8
    CustomerPaymentScreen(onMenuPressed: _openDrawer),   // 9
    DaybookScreen(onMenuPressed: _openDrawer),           // 10
    AmountPayableScreen(onMenuPressed: _openDrawer),     // 11
    AmountReceivableScreen(onMenuPressed: _openDrawer),  // 12
    SupplierLedgerScreen(onMenuPressed: _openDrawer),    // 13
    ExpenseHeadScreen(onMenuPressed: _openDrawer),       // 14
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
        index: _pageIndex == 6
            ? 1
            : _pageIndex == 7
                ? 2
                : _pageIndex == 8
                    ? 3
                    : _pageIndex == 9
                        ? 4
                        : 0,
        height: 60,
        items: const [
          Icon(Icons.dashboard_rounded, color: Colors.white, size: 28),
          Icon(Icons.inventory_2_rounded, color: Colors.white, size: 28),
          Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
          Icon(Icons.payment_rounded, color: Colors.white, size: 28),
          Icon(Icons.monetization_on_rounded, color: Colors.white, size: 28),
        ],
        color: AppConstants.primaryTeal,
        buttonBackgroundColor: AppConstants.primaryTeal,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) {
          _isTapping = true;
          if (index == 0) {
            _onPageChanged(0);
          } else if (index == 1) {
            _onPageChanged(6);
          } else if (index == 2) {
            _onPageChanged(7);
          } else if (index == 3) {
            _onPageChanged(8);
          } else if (index == 4) {
            _onPageChanged(9);
          }
          _isTapping = false;
        },
      ),
    );
  }
}
