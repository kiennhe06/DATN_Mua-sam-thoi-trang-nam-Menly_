import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_buttons.dart';

/// Centered loading indicator used across screens.
class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: c.primary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Generic empty/error state display.
class StatusView extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool danger;

  const StatusView({
    super.key,
    this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final tint = danger ? c.danger : c.secondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, size: 36, color: tint)
                    : Text(
                        danger ? '!' : 'M',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: tint),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 14, height: 1.5),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              SecondaryButton(
                label: actionLabel!,
                expanded: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
