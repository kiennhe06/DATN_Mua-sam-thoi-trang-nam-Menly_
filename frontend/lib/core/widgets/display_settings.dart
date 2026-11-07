import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_accent.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

/// Hien thi bang dieu khien giao dien va mau chu dao
Future<void> showDisplaySettings(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _DisplaySettingsSheet(),
  );
}

class _DisplaySettingsSheet extends StatelessWidget {
  const _DisplaySettingsSheet();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final controller = context.watch<ThemeController>();

    return Container(
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 14, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giao diện & Hiển thị',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Xong'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tùy chỉnh tông màu chủ đạo và chế độ hiển thị',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Che do Sang / Toi
          Text('Chế độ', style: _labelStyle(c)),
          const SizedBox(height: 10),
          Row(
            children: [
              _ModeChip(
                label: 'Chế độ Sáng',
                selected: controller.mode == ThemeMode.light,
                onTap: () => controller.setMode(ThemeMode.light),
              ),
              const SizedBox(width: 12),
              _ModeChip(
                label: 'Chế độ Tối',
                selected: controller.mode == ThemeMode.dark,
                onTap: () => controller.setMode(ThemeMode.dark),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Bang chon mau chu dao (AppAccent)
          Text('Màu điểm nhấn', style: _labelStyle(c)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final accent in AppAccent.values)
                _AccentDot(
                  accent: accent,
                  selected: controller.accent == accent,
                  onTap: () => controller.setAccent(accent),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  TextStyle _labelStyle(AppColors c) => TextStyle(
        color: c.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      );
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: selected ? c.primarySoft : c.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: selected ? c.primary : Colors.transparent,
              width: 1.4,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? c.primary : c.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  final AppAccent accent;
  final bool selected;
  final VoidCallback onTap;

  const _AccentDot({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? c.textPrimary : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.color.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: selected
                ? const Center(
                    child: Text(
                      '✓',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            accent.label,
            style: TextStyle(
              color: selected ? c.textPrimary : c.textMuted,
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
