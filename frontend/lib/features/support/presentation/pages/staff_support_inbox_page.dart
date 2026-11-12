import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/support_chat_service.dart';
import 'support_chat_page.dart';

class StaffSupportInboxPage extends StatefulWidget {
  final bool showBackButton;
  const StaffSupportInboxPage({super.key, this.showBackButton = true});

  @override
  State<StaffSupportInboxPage> createState() => _StaffSupportInboxPageState();
}

class _StaffSupportInboxPageState extends State<StaffSupportInboxPage> {
  final _service = SupportChatService();
  List<SupportConversation> _conversations = [];
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadConversations(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final conversations = await _service.getStaffConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _error = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    } finally {
      _isRefreshing = false;
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final today = DateTime.now();
    if (local.year == today.year &&
        local.month == today.month &&
        local.day == today.day) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Hội thoại CSKH'),
        centerTitle: true,
        automaticallyImplyLeading: widget.showBackButton,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _isRefreshing ? null : () => _loadConversations(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingView()
          : _error != null
              ? StatusView(
                  icon: Icons.error_outline,
                  title: _error!,
                  danger: true,
                  actionLabel: 'Thử lại',
                  onAction: _loadConversations,
                )
              : _conversations.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          StatusView(
                            icon: Icons.mark_chat_unread_outlined,
                            title: 'Chưa có hội thoại cần hỗ trợ',
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _conversations.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          return Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusCard),
                              border: Border.all(color: c.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.xs,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    c.primary.withValues(alpha: 0.08),
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  color: c.primary,
                                ),
                              ),
                              title: Text(
                                conversation.customerName?.trim().isNotEmpty ==
                                        true
                                    ? conversation.customerName!
                                    : 'Khách hàng',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (conversation.customerEmail?.isNotEmpty ==
                                      true)
                                    Text(
                                      conversation.customerEmail!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: c.textSecondary),
                                    ),
                                  Text(
                                    conversation.lastMessage?.isNotEmpty == true
                                        ? conversation.lastMessage!
                                        : 'Khách hàng đang cần hỗ trợ',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: c.textSecondary),
                                  ),
                                ],
                              ),
                              isThreeLine:
                                  conversation.customerEmail?.isNotEmpty ==
                                      true,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatDate(conversation.lastMessageAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                  if (conversation.unreadStaffCount > 0) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: c.danger,
                                      child: Text(
                                        conversation.unreadStaffCount > 9
                                            ? '9+'
                                            : '${conversation.unreadStaffCount}',
                                        style: TextStyle(
                                          color: c.onInk,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SupportChatPage(
                                      conversation: conversation,
                                    ),
                                  ),
                                );
                                if (mounted) _loadConversations(silent: true);
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
