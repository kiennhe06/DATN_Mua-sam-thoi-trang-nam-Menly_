import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HomeFilterTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const HomeFilterTab({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2.5,
              width: 28,
              decoration: BoxDecoration(
                color: active ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

