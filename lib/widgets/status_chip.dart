import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final String? type; // Optional override

  const StatusChip({
    super.key,
    required this.label,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    final status = (type ?? label).toLowerCase().trim();

    Color bgColor;
    Color textColor;

    switch (status) {
      case 'active':
      case 'done':
      case 'completed':
      case 'teal':
        bgColor = const Color(0xFFE6F4EA); // Light emerald green
        textColor = const Color(0xFF137333); // Dark emerald green
        break;
      case 'inactive':
      case 'cancelled':
      case 'rejected':
      case 'rose':
        bgColor = const Color(0xFFFCE8E6); // Light rose/red
        textColor = const Color(0xFFC5221F); // Dark rose/red
        break;
      case 'pending':
      case 'waitlist':
      case 'amber':
        bgColor = const Color(0xFFFEF7E0); // Light amber
        textColor = const Color(0xFFB06000); // Dark amber
        break;
      default:
        bgColor = const Color(0xFFF1F3F4); // Grey
        textColor = const Color(0xFF3C4043); // Dark grey
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
