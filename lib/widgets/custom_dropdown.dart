import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String placeholder;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool required;
  final String? Function(T?)? validator;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.items,
    required this.onChanged,
    this.required = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextPrimary,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
          ),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: Text(
            placeholder,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          items: items,
          dropdownColor: isDark ? AppConstants.darkCard : AppConstants.lightCard,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
            size: 18,
          ),
        ),
      ],
    );
  }
}
