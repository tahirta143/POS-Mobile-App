import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        elevation: 0.5,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 80,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Category Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Module under development.',
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
}
