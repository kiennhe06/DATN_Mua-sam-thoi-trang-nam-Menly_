import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../product/presentation/pages/product_detail_page.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/services/ai_chat_service.dart';
import 'package:menly_app/core/widgets/app_image.dart';
import 'package:menly_app/features/order/data/models/shipping_policy_model.dart';
import 'package:menly_app/features/order/data/services/shipping_policy_service.dart';
import 'package:menly_app/features/support/presentation/pages/support_chat_page.dart';

/// Ten hien thi cua man nay. Day la tro ly Gemini chu khong phai nhan vien
/// that, nen moi noi deu phai goi dung la tro ly ao. Nhan vien that nam o
/// SupportChatPage.
const String kTenTroLyAo = 'Trợ lý ảo Menly';

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

  /// Bang gia giao hang lay tu API de cau tra loi ve phi ship khong lech voi
  /// gia may chu dang tinh tien.
  ShippingPolicyModel? _bangGiaGiaoHang;

  static const List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL'];
  List<ChatMessageModel> _messages = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadSavedMessages();
    ShippingPolicyService.instance.tai().then((bangGia) {
      if (!mounted) return;
      setState(() => _bangGiaGiaoHang = bangGia);
    });
  }

  String _getStorageKey() {
    final user = context.read<AuthProvider>().user;
    return 'menly_staff_chat_messages_${user?.id ?? 'guest'}';
  }

  List<ChatMessageModel> _defaultWelcomeMessages() {
    return [
      ChatMessageModel(
        id: 'm1',
        senderType: 'staff',
        senderName: kTenTroLyAo,
        content:
            'Xin chào bạn! Em là trợ lý ảo của Menly, trả lời tự động 24/7. Em hỗ trợ bạn chọn size chuẩn, giải đáp đơn hàng hoặc tư vấn phối đồ.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        isStaff: true,
      ),
      ChatMessageModel(
        id: 'm2',
        senderType: 'staff',
        senderName: kTenTroLyAo,
        content:
            'Bạn có thể gõ câu hỏi hoặc chọn nhanh một chủ đề gợi ý phía dưới. Cần gặp nhân viên thật, bạn mở menu ở góc trên bên phải và chọn Gặp nhân viên CSKH trực tiếp nhé!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
        isStaff: true,
      ),
    ];
  }

  Future<void> _loadSavedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey();
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final loaded = decoded
              .map((item) => ChatMessageModel.fromJson(
                  Map<String, dynamic>.from(item as Map)))
              .toList();
          if (loaded.isNotEmpty && mounted) {
            setState(() {
              _messages = loaded;
              _isLoadingHistory = false;
            });
            _scrollToBottom();
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _messages = _defaultWelcomeMessages();
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey();
      final toSave = _messages.length > 100
          ? _messages.sublist(_messages.length - 100)
          : _messages;
      final encoded = jsonEncode(toSave.map((m) => m.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (_) {}
  }

  void _confirmClearHistory() {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Làm mới đoạn chat?'),
        content: const Text(
          'Đoạn chat hiện tại sẽ được xoá và đưa về lời chào ban đầu của trợ lý ảo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(_getStorageKey());
              if (!mounted) return;
              setState(() {
                _messages = _defaultWelcomeMessages();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã làm mới đoạn chat')),
              );
            },
            child: Text('Làm mới', style: TextStyle(color: c.danger)),
          ),
        ],
      ),
    );
  }

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
    _saveMessages();

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
          senderName: kTenTroLyAo,
          content: staffReply,
          createdAt: DateTime.now(),
          isStaff: true,
          suggestedProducts:
              suggestedProducts.isNotEmpty ? suggestedProducts : null,
        ),
      );
    });
    _scrollToBottom();
    _saveMessages();
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
      final bangGia = _bangGiaGiaoHang;
      final phi = bangGia == null
          ? 'Biểu phí giao hàng đang được cập nhật, anh/chị xem phí chính xác ở bước thanh toán giúp em ạ.'
          : bangGia.moTaPhiGiaoHang;
      return 'Dạ $phi Đơn nội thành HCM/Hà Nội nhận hàng trong 1-2 ngày, các tỉnh thành khác từ 2-4 ngày anh/chị nhé!';
    }
    return 'Dạ em đã ghi nhận thông tin từ bạn: "$text". Nếu cần nhân viên CSKH hỗ trợ trực tiếp, bạn mở menu ở góc trên bên phải giúp em. Bạn cần em giải đáp thêm gì nữa không ạ?';
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
            // Avatar tro ly ao, cham xanh bao dich vu dang hoat dong
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: c.secondary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.smart_toy_rounded,
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
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        kTenTroLyAo,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: c.secondary.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXs),
                        ),
                        child: Text(
                          'AI',
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
                    'Trả lời tự động 24/7',
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
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Tuỳ chọn',
            icon: Icon(Icons.more_vert_rounded, color: c.textSecondary),
            onSelected: (val) {
              if (val == 'clear') {
                _confirmClearHistory();
              } else if (val == 'support') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportChatPage()),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'support',
                child: Row(
                  children: [
                    Icon(Icons.headset_mic_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Gặp nhân viên CSKH trực tiếp'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Làm mới đoạn chat',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Notice banner explaining Staff role (Not Admin)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: c.surfaceVariant.withValues(alpha: 0.6),
              border: Border(
                bottom: BorderSide(color: c.border.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: c.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Kênh tư vấn tự động của Menly, trả lời ngay 24/7. Bảo mật thông tin khách hàng.',
                    style: TextStyle(color: c.textMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // Message list
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
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
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Trợ lý ảo đang soạn phản hồi...',
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
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _quickTopics.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (ctx, i) {
                final topic = _quickTopics[i];
                return Pressable(
                  onTap: () => _handleSend(topic),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
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
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              MediaQuery.of(context).padding.bottom + AppSpacing.sm,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
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
                        hintText: 'Nhắn cho trợ lý ảo Menly...',
                        hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () => _handleSend(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: c.onPrimary,
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                Icons.smart_toy_rounded,
                color: c.secondary,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isStaff ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
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
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isStaff ? c.surface : c.inkCard,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppTheme.radiusLg),
                      topRight: const Radius.circular(AppTheme.radiusLg),
                      bottomLeft: Radius.circular(
                        isStaff ? AppTheme.radiusXs : AppTheme.radiusLg,
                      ),
                      bottomRight: Radius.circular(
                        isStaff ? AppTheme.radiusLg : AppTheme.radiusXs,
                      ),
                    ),
                    border: Border.all(
                      color: isStaff
                          ? c.border.withValues(alpha: 0.6)
                          : Colors.transparent,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.shadow,
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
            const SizedBox(width: AppSpacing.sm),
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
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 15,
                color: c.secondary,
              ),
              const SizedBox(width: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: products.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.md),
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
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: c.border.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppTheme.radiusSm),
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
                          padding: const EdgeInsets.all(AppSpacing.sm),
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
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                formatPrice(p.price),
                                style: TextStyle(
                                  color: c.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
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
