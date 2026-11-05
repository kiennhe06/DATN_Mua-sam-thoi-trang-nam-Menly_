import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ProductPerkItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const ProductPerkItem({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
