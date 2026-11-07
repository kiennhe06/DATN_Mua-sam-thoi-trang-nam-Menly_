import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../pages/notifications_page.dart';
import '../providers/notification_provider.dart';

/// Nut chuong thong bao kem so chua doc that tu API.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (_, notifProv, __) {
        final count = notifProv.unreadCount;
        final label = count > 99 ? '99+' : '$count';

        return IconButton(
          tooltip: count > 0 ? 'Thông báo ($count chưa đọc)' : 'Thông báo',
          visualDensity: VisualDensity.compact,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
            if (context.mounted) {
              await notifProv.loadNotifications();
            }
          },
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(
              label,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.accentRed,
            child: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.textPrimary,
              size: 22,
            ),
          ),
        );
      },
    );
  }
}
