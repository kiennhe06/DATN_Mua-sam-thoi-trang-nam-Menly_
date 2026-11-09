import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../product/presentation/pages/product_detail_page.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/services/ai_chat_service.dart';
import 'package:menly_app/core/widgets/app_image.dart';

class LiveChatPage extends StatefulWidget {
  const LiveChatPage({super.key});

  @override
  State<LiveChatPage> createState() => _LiveChatPageState();
}

class _LiveChatPageState extends State<LiveChatPage> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final AiChatService _aiChatService = AiChatService();
  bool _isStaffTyping = false;
  int? _heightCm;
  int? _weightKg;
  static const List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL'];
  final List<ChatMessageModel> _messages = [
    ChatMessageModel(
      id: 'm1',
      senderType: 'staff',
      senderName: 'Nhân viên tư vấn Menly',
      content:
          'Xin chào bạn! Em là nhân viên tư vấn của Menly. Rất hân hạnh được đồng hành và hỗ trợ bạn chọn size chuẩn, giải đáp đơn hàng hoặc tư vấn phối đồ.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      isStaff: true,
    ),
    ChatMessageModel(
      id: 'm2',
      senderType: 'staff',
      senderName: 'Nhân viên tư vấn Menly',
      content:
          'Bạn có thể gõ câu hỏi hoặc chọn nhanh một trong các chủ đề gợi ý phía dưới để được em hỗ trợ ngay nhé!',
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
      isStaff: true,
    ),
  ];

  final List<String> _quickTopics = [
    '📏 Tư vấn chọn Size chuẩn',
    '📦 Kiểm tra tình trạng đơn hàng',
    '🔄 Hướng dẫn đổi trả 7 ngày',
    '✨ Gợi ý phối đồ Nam Lookbook',
    '🚚 Phí & Thời gian vận chuyển',
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend([String? presetText]) async {
    final text = presetText ?? _msgCtrl.text.trim();
    if (text.isEmpty) return;

    if (presetText == null) {
      _msgCtrl.clear();
    }

    final authUser = context.read<AuthProvider>().user;
    final userName = authUser?.fullName.isNotEmpty == true
        ? authUser!.fullName
        : 'Khách hàng';

    // 1. Thêm tin nhắn từ Khách hàng
    setState(() {
      _messages.add(
        ChatMessageModel(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          senderType: 'user',
          senderName: userName,
          content: text,
          createdAt: DateTime.now(),
          isStaff: false,
        ),
      );
      _isStaffTyping = true;
    });
    _scrollToBottom();

    // 2. Lấy tối đa 10 tin nhắn gần nhất để gửi kèm ngữ cảnh cho AI
    final recentHistory = _messages
        .where((m) => m.id != 'm1' && m.id != 'm2')
        .take(_messages.length - 1)
        .map((m) => {
              'role': m.isStaff ? 'model' : 'user',
              'content': m.content,
            })
        .toList();

    // 3. Gọi Gemini AI qua Backend, tự động fallback về mẫu offline nếu gặp lỗi kết nối
    String staffReply;
    List<SuggestedProductItem> suggestedProducts = [];
    try {
      final res = await _aiChatService.askAssistant(
        message: text,
        history: recentHistory,
      );
      staffReply = res.reply;
      suggestedProducts = res.suggestedProducts;
    } catch (_) {
      staffReply = _buildStaffReply(text);
    }

    if (!mounted) return;

    setState(() {
      _isStaffTyping = false;
      _messages.add(
        ChatMessageModel(
          id: 'staff_${DateTime.now().millisecondsSinceEpoch}',
          senderType: 'staff',
          senderName: 'Nhân viên tư vấn Menly',
          content: staffReply,
          createdAt: DateTime.now(),
          isStaff: true,
          suggestedProducts:
              suggestedProducts.isNotEmpty ? suggestedProducts : null,
        ),
      );
    });
    _scrollToBottom();
  }

  /// Tách chiều cao (cm) và cân nặng (kg) từ câu chat tự do.
  /// Chiều cao: "1m60", "1m6", "1.60m", "1,6m", "160cm", "cao 160"
  /// Cân nặng:  "56kg", "56 ký", "nặng 56", "56 cân"
  ({int? heightCm, int? weightKg}) _parseBodyInfo(String raw) {
    var t = raw.toLowerCase();
    int? height;
    int? weight;

    // ---- Chiều cao (dạng mét) ----
    final meterPatterns = [
      RegExp(r'(\d)\s*m\s*(\d{1,2})(?!\d)'), // 1m60, 1m6, 1 m 65
      RegExp(r'(\d)\s*[.,]\s*(\d{1,2})\s*m(?![a-z])'), // 1.60m, 1,6m
    ];
    for (final p in meterPatterns) {
      final m = p.firstMatch(t);
      if (m == null) continue;
      final frac = m.group(2)!;
      final cm = frac.length == 1 ? int.parse(frac) * 10 : int.parse(frac);
      height = int.parse(m.group(1)!) * 100 + cm;
      t = t.replaceRange(m.start, m.end, ' '); // xóa để khỏi lẫn sang cân nặng
      break;
    }

    // ---- Chiều cao (dạng cm) ----
    if (height == null) {
      final m =
          RegExp(r'(\d{3})\s*cm').firstMatch(t) ??
          RegExp(r'cao\s*(\d{3})(?!\d)').firstMatch(t);
      if (m != null) {
        height = int.parse(m.group(1)!);
        t = t.replaceRange(m.start, m.end, ' ');
      }
    }
    if (height != null && (height < 140 || height > 210)) height = null;

    // ---- Cân nặng ----
    final wm =
        RegExp(r'(\d{2,3})(?:[.,]\d)?\s*(?:kg|ký|kí)').firstMatch(t) ??
        RegExp(r'nặng\s*(\d{2,3})').firstMatch(t) ??
        RegExp(r'(\d{2,3})\s*cân').firstMatch(t);
    if (wm != null) weight = int.parse(wm.group(1)!);
    if (weight != null && (weight < 30 || weight > 160)) weight = null;

    return (heightCm: height, weightKg: weight);
  }

  /// Gợi ý size dựa trên chiều cao + cân nặng.
  String _suggestSize(int heightCm, int weightKg) {
    const weightLimits = [52, 58, 65, 72, 80, 88]; // XS, S, M, L, XL, 2XL, 3XL
    const heightLimits = [160, 166, 171, 176, 181, 186];

    int idxOf(int v, List<int> limits) {
      for (var i = 0; i < limits.length; i++) {
        if (v <= limits[i]) return i;
      }
      return limits.length;
    }

    final w = idxOf(weightKg, weightLimits);
    final h = idxOf(heightCm, heightLimits);
    final hi = w > h ? w : h;
    final lo = w > h ? h : w;
    // Lệch từ 2 cỡ trở lên (người cao gầy / thấp đậm) -> lấy cỡ trung gian
    final best = (hi - lo) >= 2 ? lo + 1 : hi;
    final comfy = best < _sizes.length - 1 ? best + 1 : best;

    final heightText =
        '${heightCm ~/ 100}m${(heightCm % 100).toString().padLeft(2, '0')}';

    final buffer = StringBuffer()
      ..writeln(
        'Dạ với chiều cao $heightText và cân nặng ${weightKg}kg thì Menly gợi ý anh/chị mặc size ${_sizes[best]} là vừa vặn nhất ạ 👕',
      )
      ..writeln()
      ..writeln('• Thích mặc ôm gọn, đúng form: size ${_sizes[best]}');
    if (comfy != best) {
      buffer.writeln('• Thích mặc rộng rãi, thoải mái: size ${_sizes[comfy]}');
    }
    buffer
      ..writeln()
      ..write(
        'Anh/chị có thể vào trang sản phẩm → "Tư vấn Size" để xem bảng số đo chi tiết từng mẫu nhé!',
      );
    return buffer.toString();
  }

  String _buildStaffReply(String text) {
    final lower = text.toLowerCase();

    // 1. Ưu tiên nhận diện số đo TRƯỚC khi xét từ khóa "size"
    final body = _parseBodyInfo(text);
    if (body.heightCm != null) _heightCm = body.heightCm;
    if (body.weightKg != null) _weightKg = body.weightKg;

    if (_heightCm != null && _weightKg != null) {
      final reply = _suggestSize(_heightCm!, _weightKg!);
      _heightCm = null; // reset để lần tư vấn sau bắt đầu lại
      _weightKg = null;
      return reply;
    }
    if (_heightCm != null) {
      return 'Dạ em đã ghi nhận chiều cao ${_heightCm}cm. Anh/chị cho em xin thêm Cân nặng (kg) để em tư vấn size chuẩn nhé!';
    }
    if (_weightKg != null) {
      return 'Dạ em đã ghi nhận cân nặng ${_weightKg}kg. Anh/chị cho em xin thêm Chiều cao (cm) để em tư vấn size chuẩn nhé!';
    }

    // 2. Các chủ đề còn lại
    if (lower.contains('size') || lower.contains('cỡ')) {
      return 'Dạ anh/chị cho em xin Chiều cao (cm) và Cân nặng (kg) nhé! Ví dụ: "1m70, 65kg". Hệ thống Menly có bảng 7 size chuẩn (XS đến 3XL) để em tư vấn size vừa vặn nhất ạ.';
    } else if (lower.contains('đơn hàng') || lower.contains('kiểm tra')) {
      return 'Dạ anh/chị có thể vào tab "Đơn mua" để theo dõi trực tiếp thanh tiến trình 5 bước kèm mã vận đơn hỏa tốc (MENLY-VN). Hoặc anh/chị nhắn giúp em Mã đơn để em tra cứu ngay nhé!';
    } else if (lower.contains('đổi trả')) {
      return 'Dạ Menly cam kết đổi hàng miễn phí trong vòng 7 ngày kể từ khi nhận kiện hàng ạ. Quý khách chỉ cần giữ nguyên tem mác sản phẩm, bên em sẽ cử shipper đến thu hồi và giao size mới tận nơi!';
    } else if (lower.contains('phối đồ') || lower.contains('lookbook')) {
      return 'Dạ ngay dưới từng sản phẩm đều có chuyên mục "Lookbook - Gợi ý phối đồ chuẩn Quý ông" (Áo sơ mi Oxford + Quần tây công sở + Áo blazer) giảm 15% khi mua trọn bộ combo đấy ạ!';
    } else if (lower.contains('vận chuyển') || lower.contains('ship')) {
      return 'Dạ Menly miễn phí vận chuyển toàn quốc cho đơn hàng từ 499.000đ. Đơn nội thành HCM/Hà Nội nhận hàng trong 1-2 ngày, các tỉnh thành khác từ 2-4 ngày anh/chị nhé!';
    }
    return 'Dạ em đã ghi nhận thông tin từ bạn: "$text". Nhân viên tư vấn Menly đang sẵn sàng hỗ trợ, bạn cần em giải đáp thêm chi tiết nào nữa không ạ?';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Staff Avatar with online green indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: c.secondary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: c.secondary,
                    size: 24,
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: c.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Nhân viên tư vấn Menly',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: c.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Staff',
                          style: TextStyle(
                            color: c.secondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Đang trực tuyến • Phản hồi ngay',
                    style: TextStyle(
                      color: c.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Notice banner explaining Staff role (Not Admin)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: c.surfaceVariant.withValues(alpha: 0.6),
              border: Border(
                bottom: BorderSide(color: c.border.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: c.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Kênh kết nối trực tiếp với Nhân viên hỗ trợ Menly. Bảo mật & Hỗ trợ 24/7.',
                    style: TextStyle(color: c.textMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, c);
              },
            ),
          ),

          // Typing indicator
          if (_isStaffTyping) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: c.secondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Nhân viên đang soạn phản hồi...',
                          style: TextStyle(color: c.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Quick Topics suggestion chips
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _quickTopics.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final topic = _quickTopics[i];
                return Pressable(
                  onTap: () => _handleSend(topic),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(color: c.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      topic,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Message input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(
                top: BorderSide(color: c.border.withValues(alpha: 0.6)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: c.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      style: TextStyle(color: c.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Nhắn cho nhân viên Menly...',
                        hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _handleSend(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: c.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, AppColors c) {
    final isStaff = msg.isStaff;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isStaff ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isStaff) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: c.secondary.withValues(alpha: 0.15),
              child: Icon(
                Icons.support_agent_rounded,
                color: c.secondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isStaff ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    msg.senderName,
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isStaff ? c.surface : c.inkCard,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isStaff ? 4 : 16),
                      bottomRight: Radius.circular(isStaff ? 16 : 4),
                    ),
                    border: Border.all(
                      color: isStaff
                          ? c.border.withValues(alpha: 0.6)
                          : Colors.transparent,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.shadow.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: isStaff ? c.textPrimary : c.onInk,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ),
                if (isStaff &&
                    msg.suggestedProducts != null &&
                    msg.suggestedProducts!.isNotEmpty) ...[
                  _buildSuggestedProductsSection(msg.suggestedProducts!, c),
                ],
              ],
            ),
          ),
          if (!isStaff) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: c.primarySoft,
              child: Icon(Icons.person_rounded, color: c.secondary, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestedProductsSection(
    List<SuggestedProductItem> products,
    AppColors c,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 15,
                color: Color(0xFFD4AF37),
              ),
              const SizedBox(width: 6),
              Text(
                'Sản phẩm Menly gợi ý theo set:',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final p = products[index];
                return Pressable(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailPage(product: p.toProductModel()),
                      ),
                    );
                  },
                  child: Container(
                    width: 130,
                    decoration: BoxDecoration(
                      color: c.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: c.border.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(9),
                          ),
                          child: p.thumbnailUrl != null &&
                                  p.thumbnailUrl!.isNotEmpty
                              ? AppImage(
                                  url: p.thumbnailUrl!,
                                  height: 95,
                                  width: 130,
                                  fit: BoxFit.cover,
                                  placeholder: (_) => Container(
                                    height: 95,
                                    width: 130,
                                    color: c.surface,
                                  ),
                                  errorWidget: (_) => Container(
                                    height: 95,
                                    width: 130,
                                    color: c.surface,
                                    child: Icon(
                                      Icons.checkroom_rounded,
                                      color: c.textMuted,
                                      size: 32,
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 95,
                                  width: 130,
                                  color: c.surface,
                                  child: Icon(
                                    Icons.checkroom_rounded,
                                    color: c.textMuted,
                                    size: 32,
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: c.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatPrice(p.price),
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Xem ngay',
                                    style: TextStyle(
                                      color: c.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 9,
                                    color: c.textMuted,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
