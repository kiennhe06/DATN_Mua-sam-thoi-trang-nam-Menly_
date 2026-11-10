import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/support_chat_service.dart';
import 'package:menly_app/features/chat/presentation/pages/live_chat_page.dart';

class SupportChatPage extends StatefulWidget {
  final SupportConversation? conversation;

  const SupportChatPage({super.key, this.conversation});

  bool get isStaffConversation => conversation != null;

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final _service = SupportChatService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<SupportChatMessage> _messages = [];
  SupportConversation? _conversation;
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _loadChat();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadChat(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChat({bool silent = false}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    if (!silent && mounted) setState(() => _isLoading = true);

    try {
      final conversation = _conversation ?? await _service.getMyConversation();
      final messages = await _service.getMessages(conversation.id);
      if (!mounted) return;
      setState(() {
        _conversation = conversation;
        _messages
          ..clear()
          ..addAll(messages);
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

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    final conversation = _conversation;
    if (content.isEmpty || conversation == null || _isSending) return;

    setState(() => _isSending = true);
    try {
      await _service.sendMessage(conversation.id, content);
      _messageController.clear();
      await _loadChat(silent: true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.of(context).danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final conversation = _conversation;
    final title = widget.isStaffConversation
        ? (conversation?.customerName?.trim().isNotEmpty == true
            ? conversation!.customerName!
            : 'Khách hàng')
        : 'Chat với CSKH';

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(
              widget.isStaffConversation
                  ? 'Hỗ trợ khách hàng'
                  : 'Nhân viên Menly sẽ phản hồi sớm',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tư vấn AI Stylist 24/7',
            icon: Icon(Icons.auto_awesome, color: c.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LiveChatPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _isRefreshing ? null : () => _loadChat(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const LoadingView()
                : _error != null && conversation == null
                    ? StatusView(
                        icon: Icons.error_outline,
                        title: _error!,
                        danger: true,
                        actionLabel: 'Thử lại',
                        onAction: _loadChat,
                      )
                    : _messages.isEmpty
                        ? const StatusView(
                            icon: Icons.support_agent_rounded,
                            title: 'Menly sẵn sàng hỗ trợ bạn',
                            message:
                                'Gửi câu hỏi về đơn hàng, sản phẩm hoặc đổi trả. Nhân viên CSKH sẽ phản hồi tại đây.',
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message =
                                  _messages[_messages.length - 1 - index];
                              final isMine = widget.isStaffConversation
                                  ? message.senderRole == 'staff' ||
                                      message.senderRole == 'admin'
                                  : message.senderRole == 'customer';
                              return _ChatBubble(
                                message: message,
                                isMine: isMine,
                                time: _formatTime(message.createdAt),
                              );
                            },
                          ),
          ),
          if (_error != null && conversation != null)
            MaterialBanner(
              content: Text(_error!),
              leading: const Icon(Icons.wifi_off_rounded),
              actions: [
                TextButton(onPressed: _loadChat, child: const Text('Thử lại')),
              ],
            ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: widget.isStaffConversation
                            ? 'Nhập phản hồi cho khách...'
                            : 'Nhập tin nhắn cho CSKH...',
                        counterText: '',
                        filled: true,
                        fillColor: c.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: _isSending ? null : _sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: c.onPrimary,
                    ),
                    icon: _isSending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final SupportChatMessage message;
  final bool isMine;
  final String time;

  const _ChatBubble({
    required this.message,
    required this.isMine,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isMine ? c.primary : c.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppTheme.radiusLg),
            topRight: const Radius.circular(AppTheme.radiusLg),
            bottomLeft: Radius.circular(
              isMine ? AppTheme.radiusLg : AppTheme.radiusXs,
            ),
            bottomRight: Radius.circular(
              isMine ? AppTheme.radiusXs : AppTheme.radiusLg,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMine ? c.onPrimary : c.textPrimary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              time,
              style: TextStyle(
                color: isMine
                    ? c.onPrimary.withValues(alpha: 0.7)
                    : c.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
