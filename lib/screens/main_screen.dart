import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:provider/provider.dart';

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
import '../utils/permission_constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/access_denied_widget.dart';

class TabItem {
  final int pageIndex;
  final IconData icon;
  final String moduleName;
  final String action;

  const TabItem({
    required this.pageIndex,
    required this.icon,
    required this.moduleName,
    required this.action,
  });
}

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
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final allowedTabs = _getAllowedTabs(auth);
      final navIndex = allowedTabs.indexWhere((tab) => tab.pageIndex == index);
      if (navIndex != -1) {
        _bottomNavKey.currentState?.setPage(navIndex);
      }
    }
  }

  List<TabItem> _getAllowedTabs(AuthProvider auth) {
    final List<TabItem> allTabs = [
      const TabItem(
        pageIndex: 0,
        icon: Icons.dashboard_rounded,
        moduleName: PermissionConstants.dashboard,
        action: PermissionConstants.read,
      ),
      const TabItem(
        pageIndex: 6,
        icon: Icons.inventory_2_rounded,
        moduleName: PermissionConstants.items,
        action: PermissionConstants.read,
      ),
      const TabItem(
        pageIndex: 7,
        icon: Icons.receipt_long_rounded,
        moduleName: PermissionConstants.expenseVoucher,
        action: PermissionConstants.read,
      ),
      const TabItem(
        pageIndex: 8,
        icon: Icons.payment_rounded,
        moduleName: PermissionConstants.supplierPayment,
        action: PermissionConstants.read,
      ),
      const TabItem(
        pageIndex: 9,
        icon: Icons.monetization_on_rounded,
        moduleName: PermissionConstants.customerPayment,
        action: PermissionConstants.read,
      ),
    ];

    final allowed = allTabs.where((tab) {
      if (auth.isAdmin) return true;
      if (tab.moduleName == PermissionConstants.dashboard) {
        return auth.canAccess(PermissionConstants.dashboard);
      }
      return auth.canAccess(tab.moduleName) && auth.can(tab.moduleName, tab.action);
    }).toList();

    if (allowed.isEmpty) {
      allowed.add(const TabItem(
        pageIndex: 0,
        icon: Icons.dashboard_rounded,
        moduleName: PermissionConstants.dashboard,
        action: PermissionConstants.read,
      ));
    }
    return allowed;
  }

  Widget _buildRestrictedPage(int index, AuthProvider auth) {
    if (auth.isAdmin) return _screens[index];

    String moduleName = '';
    String? actionName;
    bool hasPermission = false;

    switch (index) {
      case 0: // Dashboard
        moduleName = PermissionConstants.dashboard;
        actionName = PermissionConstants.read;
        hasPermission = auth.canAccess(PermissionConstants.dashboard);
        break;
      case 1: // Goods Receipt Note
        moduleName = PermissionConstants.stock;
        actionName = PermissionConstants.create;
        hasPermission = auth.canAccess(PermissionConstants.stock) && auth.can(PermissionConstants.stock, PermissionConstants.create);
        break;
      case 2: // Purchase Return
        moduleName = PermissionConstants.purchaseReturn;
        actionName = PermissionConstants.read;
        hasPermission = auth.canAccess(PermissionConstants.purchaseReturn) && auth.can(PermissionConstants.purchaseReturn, PermissionConstants.read);
        break;
      case 3: // Define Customer
        moduleName = PermissionConstants.customer;
        actionName = PermissionConstants.read;
        hasPermission = auth.canAccess(PermissionConstants.customer) && auth.can(PermissionConstants.customer, PermissionConstants.read);
        break;
      case 4: // Sales Receipt
        moduleName = PermissionConstants.sale;
        actionName = PermissionConstants.create;
        hasPermission = auth.canAccess(PermissionConstants.sale) && auth.can(PermissionConstants.sale, PermissionConstants.create);
        break;
      case 5: // Sales Return
        moduleName = PermissionConstants.saleReturn;
        actionName = PermissionConstants.read;
        hasPermission = auth.canAccess(PermissionConstants.saleReturn) && auth.can(PermissionConstants.saleReturn, PermissionConstants.read);
        break;
      case 6: // Items List
        moduleName = PermissionConstants.items;
        actionName = PermissionConstants.read;
        hasPermission = auth.canAccess(PermissionConstants.items) || auth.canAccess(PermissionConstants.item);
        break;
      case 7: // Expense Voucher
        moduleName = PermissionConstants.expenseVoucher;
        actionName = PermissionConstants.read;
        hasPermission = auth.canAccess(PermissionConstants.expenseVoucher);
        break;
      case 8: // Supplier Payment
        moduleName = PermissionConstants.supplierPayment;
        actionName = PermissionConstants.read;
        hasPermission = auth.canAccess(PermissionConstants.supplierPayment) && auth.can(PermissionConstants.supplierPayment, PermissionConstants.read);
        break;
      case 9: // Customer Payment
        moduleName = PermissionConstants.customerPayment;
        actionName = PermissionConstants.read;
        hasPermission = auth.canAccess(PermissionConstants.customerPayment) && auth.can(PermissionConstants.customerPayment, PermissionConstants.read);
        break;
      case 10: // Daybook
        moduleName = PermissionConstants.dayBook;
        actionName = PermissionConstants.read;
        hasPermission = auth.canAccess(PermissionConstants.dayBook);
        break;
      case 11: // Amount Payable
        moduleName = PermissionConstants.supplierPayment;
        actionName = PermissionConstants.read;
        hasPermission = auth.canAccess(PermissionConstants.supplierPayment) && auth.can(PermissionConstants.supplierPayment, PermissionConstants.read);
        break;
      case 12: // Amount Receivable
        moduleName = PermissionConstants.customerPayment;
        actionName = PermissionConstants.read;
        hasPermission = auth.canAccess(PermissionConstants.customerPayment) && auth.can(PermissionConstants.customerPayment, PermissionConstants.read);
        break;
      case 13: // Supplier Ledger
        moduleName = PermissionConstants.supplierLedger;
        actionName = PermissionConstants.read;
        hasPermission = auth.canAccess(PermissionConstants.supplierLedger) && auth.can(PermissionConstants.supplierLedger, PermissionConstants.read);
        break;
      case 14: // Expense Head
        moduleName = PermissionConstants.expenseHead;
        actionName = PermissionConstants.read;
        hasPermission = auth.canAccess(PermissionConstants.expenseHead);
        break;
      default:
        hasPermission = false;
    }

    if (hasPermission) {
      return _screens[index];
    } else {
      return AccessDeniedWidget(module: moduleName, action: actionName);
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
    final authProvider = Provider.of<AuthProvider>(context);
    final allowedTabs = _getAllowedTabs(authProvider);

    int activeNavIndex = allowedTabs.indexWhere((tab) => tab.pageIndex == _pageIndex);
    if (activeNavIndex == -1) {
      // Find closest tab match or default to 0
      if (_pageIndex >= 1 && _pageIndex <= 5) {
        activeNavIndex = allowedTabs.indexWhere((tab) => tab.pageIndex == 0);
      } else if (_pageIndex == 14 || _pageIndex == 10) {
        activeNavIndex = allowedTabs.indexWhere((tab) => tab.pageIndex == 7);
      } else if (_pageIndex == 11 || _pageIndex == 13) {
        activeNavIndex = allowedTabs.indexWhere((tab) => tab.pageIndex == 8);
      } else if (_pageIndex == 12) {
        activeNavIndex = allowedTabs.indexWhere((tab) => tab.pageIndex == 9);
      }

      if (activeNavIndex == -1 || activeNavIndex >= allowedTabs.length) {
        activeNavIndex = 0;
      }
    }

    return Scaffold(
      key: _scaffoldKey,

      drawer: CustomDrawer(
        currentIndex: _pageIndex,
        onNavigate: _onPageChanged,
      ),

      body: _buildRestrictedPage(_pageIndex, authProvider),

      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavKey,
        index: activeNavIndex,
        height: 60,
        items: allowedTabs.map((tab) => Icon(tab.icon, color: Colors.white, size: 28)).toList(),
        color: AppConstants.primaryTeal,
        buttonBackgroundColor: AppConstants.primaryTeal,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) {
          if (index < 0 || index >= allowedTabs.length) return;
          _isTapping = true;
          _onPageChanged(allowedTabs[index].pageIndex);
          _isTapping = false;
        },
      ),
    );
  }
}
