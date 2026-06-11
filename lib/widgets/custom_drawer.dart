import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/permission_constants.dart';

class CustomDrawer extends StatelessWidget {
  final Function(int)? onNavigate;
  final int currentIndex;

  const CustomDrawer({
    super.key,
    this.onNavigate,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isOpeningStockSelected = currentIndex >= 1 && currentIndex <= 5;
    final isAccountsFinanceSelected = currentIndex >= 7 && currentIndex <= 14;

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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              accountEmail: Text(
                auth.user?.email ?? 'user@company.com',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Dashboard
                  if (auth.isAdmin || auth.canAccess(PermissionConstants.dashboard))
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.dashboard_outlined,
                      label: 'Dashboard',
                      isSelected: currentIndex == 0,
                      onTap: () {
                        Navigator.of(context).pop();
                        onNavigate?.call(0);
                      },
                    ),

                  // Items List
                  if (auth.isAdmin ||
                      auth.canAccess(PermissionConstants.items) ||
                      auth.canAccess(PermissionConstants.item))
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.inventory_2_outlined,
                      label: 'Items List',
                      isSelected: currentIndex == 6,
                      onTap: () {
                        Navigator.of(context).pop();
                        onNavigate?.call(6);
                      },
                    ),

                  // Opening Stock Dropdown
                  () {
                    final showGRN = auth.isAdmin || (auth.canAccess(PermissionConstants.stock) && auth.can(PermissionConstants.stock, PermissionConstants.create));
                    final showPurchaseReturn = auth.isAdmin || (auth.canAccess(PermissionConstants.purchaseReturn) && auth.can(PermissionConstants.purchaseReturn, PermissionConstants.read));
                    final showDefineCustomer = auth.isAdmin || (auth.canAccess(PermissionConstants.customer) && auth.can(PermissionConstants.customer, PermissionConstants.read));
                    final showSalesReceipt = auth.isAdmin || (auth.canAccess(PermissionConstants.sale) && auth.can(PermissionConstants.sale, PermissionConstants.create));
                    final showSalesReturn = auth.isAdmin || (auth.canAccess(PermissionConstants.saleReturn) && auth.can(PermissionConstants.saleReturn, PermissionConstants.read));

                    if (!showGRN && !showPurchaseReturn && !showDefineCustomer && !showSalesReceipt && !showSalesReturn) {
                      return const SizedBox.shrink();
                    }

                    return ExpansionTile(
                      key: ValueKey('opening_stock_$isOpeningStockSelected'),
                      initiallyExpanded: isOpeningStockSelected,
                      leading: const Icon(Icons.inventory),
                      title: const Text(
                        'Opening Stock',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children: [
                        if (showGRN)
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.receipt_long,
                            label: 'Goods Receipt Note',
                            isSelected: currentIndex == 1,
                            onTap: () {
                              Navigator.of(context).pop();
                              onNavigate?.call(1);
                            },
                          ),
                        if (showPurchaseReturn)
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.undo,
                            label: 'Purchase Return',
                            isSelected: currentIndex == 2,
                            onTap: () {
                              Navigator.of(context).pop();
                              onNavigate?.call(2);
                            },
                          ),
                        if (showDefineCustomer)
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.people_outline,
                            label: 'Define Customer',
                            isSelected: currentIndex == 3,
                            onTap: () {
                              Navigator.of(context).pop();
                              onNavigate?.call(3);
                            },
                          ),
                        if (showSalesReceipt)
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.point_of_sale,
                            label: 'Sales Receipt',
                            isSelected: currentIndex == 4,
                            onTap: () {
                              Navigator.of(context).pop();
                              onNavigate?.call(4);
                            },
                          ),
                        if (showSalesReturn)
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.assignment_return,
                            label: 'Sales Return',
                            isSelected: currentIndex == 5,
                            onTap: () {
                              Navigator.of(context).pop();
                              onNavigate?.call(5);
                            },
                          ),
                      ],
                    );
                  }(),

                  // Accounts & Finance Dropdown
                  () {
                    final showExpenseVoucher = auth.isAdmin || auth.canAccess(PermissionConstants.expenseVoucher);
                    final showExpenseHead = auth.isAdmin || auth.canAccess(PermissionConstants.expenseHead);
                    final showSupplierPayment = auth.isAdmin || (auth.canAccess(PermissionConstants.supplierPayment) && auth.can(PermissionConstants.supplierPayment, PermissionConstants.read));
                    final showCustomerPayment = auth.isAdmin || (auth.canAccess(PermissionConstants.customerPayment) && auth.can(PermissionConstants.customerPayment, PermissionConstants.read));
                    final showDayBook = auth.isAdmin || auth.canAccess(PermissionConstants.dayBook);
                    final showAmountPayable = auth.isAdmin || (auth.canAccess(PermissionConstants.supplierPayment) && auth.can(PermissionConstants.supplierPayment, PermissionConstants.read));
                    final showAmountReceivable = auth.isAdmin || (auth.canAccess(PermissionConstants.customerPayment) && auth.can(PermissionConstants.customerPayment, PermissionConstants.read));
                    final showSupplierLedger = auth.isAdmin || (auth.canAccess(PermissionConstants.supplierLedger) && auth.can(PermissionConstants.supplierLedger, PermissionConstants.read));

                    if (!showExpenseVoucher && !showExpenseHead && !showSupplierPayment && !showCustomerPayment &&
                        !showDayBook && !showAmountPayable && !showAmountReceivable && !showSupplierLedger) {
                      return const SizedBox.shrink();
                    }

                    return ExpansionTile(
                      key: ValueKey('accounts_finance_$isAccountsFinanceSelected'),
                      initiallyExpanded: isAccountsFinanceSelected,
                      leading: const Icon(Icons.account_balance_wallet_outlined),
                      title: const Text(
                        'Accounts & Finance',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children: [
                        if (showExpenseVoucher)
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.receipt_long_outlined,
                            label: 'Expense Voucher',
                            isSelected: currentIndex == 7,
                            onTap: () {
                              Navigator.of(context).pop();
                              onNavigate?.call(7);
                            },
                          ),
                        if (showExpenseHead)
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.category_outlined,
                            label: 'Expense Head',
                            isSelected: currentIndex == 14,
                            onTap: () {
                              Navigator.of(context).pop();
                              onNavigate?.call(14);
                            },
                          ),
                        if (showSupplierPayment)
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.payment_outlined,
                            label: 'Supplier Payment',
                            isSelected: currentIndex == 8,
                            onTap: () {
                              Navigator.of(context).pop();
                              onNavigate?.call(8);
                            },
                          ),
                        if (showCustomerPayment)
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.monetization_on_outlined,
                            label: 'Customer Payment',
                            isSelected: currentIndex == 9,
                            onTap: () {
                              Navigator.of(context).pop();
                              onNavigate?.call(9);
                            },
                          ),
                        if (showDayBook)
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.calendar_month_outlined,
                            label: 'Day Book',
                            isSelected: currentIndex == 10,
                            onTap: () {
                              Navigator.of(context).pop();
                              onNavigate?.call(10);
                            },
                          ),
                        if (showAmountPayable)
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.arrow_upward_rounded,
                            label: 'Amount Payable',
                            isSelected: currentIndex == 11,
                            onTap: () {
                              Navigator.of(context).pop();
                              onNavigate?.call(11);
                            },
                          ),
                        if (showAmountReceivable)
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.arrow_downward_rounded,
                            label: 'Amount Receivable',
                            isSelected: currentIndex == 12,
                            onTap: () {
                              Navigator.of(context).pop();
                              onNavigate?.call(12);
                            },
                          ),
                        if (showSupplierLedger)
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.receipt_outlined,
                            label: 'Supplier Ledger',
                            isSelected: currentIndex == 13,
                            onTap: () {
                              Navigator.of(context).pop();
                              onNavigate?.call(13);
                            },
                          ),
                      ],
                    );
                  }(),
                ],
              ),
            ),
            const Divider(),
            _buildDrawerItem(
              context: context,
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              isSelected: false,
              onTap: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        )
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
