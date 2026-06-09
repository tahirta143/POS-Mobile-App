import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AccessDeniedWidget extends StatelessWidget {
  final String module;
  final String? action;

  const AccessDeniedWidget({
    super.key,
    required this.module,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? AppConstants.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 36,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You don't have permission to access this page.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'REQUIRED PERMISSIONS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                      ),
                      children: [
                        const TextSpan(text: 'Module: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(
                          text: module,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppConstants.primaryTeal),
                        ),
                      ],
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                        ),
                        children: [
                          const TextSpan(text: 'Action: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(
                            text: action!.toUpperCase(),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.amber),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
