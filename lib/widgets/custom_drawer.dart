import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

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

            // Dashboard
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
                auth.canAccess('Items') ||
                auth.canAccess('Item'))
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
            ExpansionTile(
              leading: const Icon(Icons.inventory),
              title: const Text(
                'Opening Stock',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
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
            ),


            const Spacer(),
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
