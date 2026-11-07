import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
/// Thanh phang tren nen kem, chi mot duong ke mong o tren. Tab dang mo khong
/// duoc to nen ma chi dam mau icon len va hien mot cham camel ben duoi, de thanh
/// nay khong canh tranh su chu y voi noi dung man hinh.
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
    return Container(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 11, 32, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: SizedBox(
        width: 44,
        child: Semantics(
          label: item.label,
          selected: selected,
          button: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge.count(
                count: item.badge,
                isLabelVisible: item.badge > 0,
                backgroundColor: c.danger,
                textColor: c.onPrimary,
                textStyle:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                child: Icon(
                  item.icon,
                  size: 21,
                  color: selected ? c.textPrimary : c.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: selected ? c.secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
