import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

class BottomNavItem {
  final IconData icon;
  final int badge;
  final String label;

  const BottomNavItem(this.icon, {this.badge = 0, this.label = ''});
}

/// Thanh dieu huong duoi cua Menly.
///
/// Dang vien thuoc mau ink noi tren noi dung, cach le hai ben va le duoi.
/// Tab dang mo nam trong mot vong tron sang, cac tab con lai la icon mo tren
/// nen ink. Day la dau nhan de nhan ra nhat cua bo giao dien.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: c.inkCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < items.length; i++)
              _NavButton(
                item: items[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final BottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.9,
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: Semantics(
        label: item.label,
        selected: selected,
        button: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            // Tab dang mo duoc boc trong vong tron sang de noi hẳn tren nen ink.
            color: selected ? c.surface : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Badge.count(
              count: item.badge,
              isLabelVisible: item.badge > 0,
              backgroundColor: c.danger,
              textColor: c.onPrimary,
              textStyle:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              child: Icon(
                item.icon,
                size: 22,
                color: selected ? c.textPrimary : c.onInk.withValues(alpha: 0.72),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
