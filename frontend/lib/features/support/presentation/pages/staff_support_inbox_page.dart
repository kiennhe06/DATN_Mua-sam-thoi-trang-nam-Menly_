import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/support_chat_service.dart';
import 'support_chat_page.dart';

class StaffSupportInboxPage extends StatefulWidget {
  const StaffSupportInboxPage({super.key});

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
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Hội thoại CSKH'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _isRefreshing ? null : () => _loadConversations(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 40),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _loadConversations,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : _conversations.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 160),
                          Icon(
                            Icons.mark_chat_unread_outlined,
                            size: 52,
                            color: AppTheme.textMuted,
                          ),
                          SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Chưa có hội thoại cần hỗ trợ',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _conversations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          return Card(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: AppTheme.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.primary.withValues(alpha: 0.08),
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppTheme.primary,
                                ),
                              ),
                              title: Text(
                                conversation.customerName?.trim().isNotEmpty ==
                                        true
                                    ? conversation.customerName!
                                    : 'Khách hàng',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
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
                                    ),
                                  Text(
                                    conversation.lastMessage?.isNotEmpty == true
                                        ? conversation.lastMessage!
                                        : 'Khách hàng đang cần hỗ trợ',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  if (conversation.unreadStaffCount > 0) ...[
                                    const SizedBox(height: 5),
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: AppTheme.accentRed,
                                      child: Text(
                                        conversation.unreadStaffCount > 9
                                            ? '9+'
                                            : '${conversation.unreadStaffCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
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
