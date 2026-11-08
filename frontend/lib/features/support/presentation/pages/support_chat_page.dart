import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
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
            backgroundColor: Colors.red,
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
    final conversation = _conversation;
    final title = widget.isStaffConversation
        ? (conversation?.customerName?.trim().isNotEmpty == true
            ? conversation!.customerName!
            : 'Khách hàng')
        : 'Chat với CSKH';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(
              widget.isStaffConversation
                  ? 'Hỗ trợ khách hàng'
                  : 'Nhân viên Menly sẽ phản hồi sớm',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tư vấn AI Stylist 24/7',
            icon: const Icon(Icons.auto_awesome, color: AppTheme.primaryAccent),
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
                ? const Center(child: CircularProgressIndicator())
                : _error != null && conversation == null
                    ? _ChatLoadError(message: _error!, onRetry: _loadChat)
                    : _messages.isEmpty
                        ? const _ChatWelcome()
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.border)),
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
                        fillColor: AppTheme.scaffoldBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
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
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMine ? Colors.white : AppTheme.textPrimary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMine ? Colors.white70 : AppTheme.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatWelcome extends StatelessWidget {
  const _ChatWelcome();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppTheme.softShadow,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: AppTheme.primaryAccent,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Menly sẵn sàng hỗ trợ bạn',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 6),
            const Text(
              'Gửi câu hỏi về đơn hàng, sản phẩm hoặc đổi trả. Nhân viên CSKH sẽ phản hồi tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ChatLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
