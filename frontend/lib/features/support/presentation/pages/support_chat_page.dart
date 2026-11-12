import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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

  /// Ben kia co dang go phim khong (lay tu phan hoi cua may chu).
  bool _doiPhuongDangSoan = false;

  /// Lan cuoi bao len may chu rang minh dang go, de khong bao lien tuc.
  DateTime? _lanBaoDangSoan;

  /// Con tin cu hon chua tai ve khong, va dang tai do khong.
  bool _conTinCu = false;
  bool _dangTaiTinCu = false;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _loadChat();
    _messageController.addListener(_khiGoPhim);
    // 2 giay thay vi 5: tin nhan va dong "dang soan" phai den gan nhu tuc thi
    // thi cuoc tro chuyen moi tu nhien. Mot vong lam moi gio chi ton mot cau
    // truy van nen tang nhip van nhe.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _loadChat(silent: true),
    );
  }

  /// Go phim thi bao len may chu, nhung nhieu nhat 3 giay mot lan.
  void _khiGoPhim() {
    final conversation = _conversation;
    if (conversation == null) return;
    if (_messageController.text.trim().isEmpty) return;

    final bayGio = DateTime.now();
    final lanTruoc = _lanBaoDangSoan;
    if (lanTruoc != null && bayGio.difference(lanTruoc).inSeconds < 3) return;

    _lanBaoDangSoan = bayGio;
    unawaited(_service.baoDangSoan(conversation.id));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.removeListener(_khiGoPhim);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Gop tin moi vao danh sach dang co, loai trung theo ma tin.
  ///
  /// May chu lay tin bang >= moc nen tin o ranh gioi ve hai lan; gop theo ma
  /// vua loai trung vua cap nhat duoc trang thai da doc cua tin cu.
  void _gopTin(List<SupportChatMessage> veThem) {
    if (veThem.isEmpty) return;
    final theoMa = <String, SupportChatMessage>{
      for (final tin in _messages) tin.id: tin,
    };
    for (final tin in veThem) {
      theoMa[tin.id] = tin;
    }
    final gop = theoMa.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _messages
      ..clear()
      ..addAll(gop);
  }

  /// Moc thoi gian de xin tin moi o vong tu lam moi.
  ///
  /// Thuong la tin cuoi cung. Nhung neu minh con tin chua duoc doc thi phai
  /// lui moc ve tin do, khong thi nhan "Da xem" se khong bao gio sang.
  String? get _mocXinTinMoi {
    if (_messages.isEmpty) return null;
    var moc = _messages.last.createdAt;
    for (final tin in _messages) {
      final cuaToi = widget.isStaffConversation
          ? tin.senderRole == 'staff' || tin.senderRole == 'admin'
          : tin.senderRole == 'customer';
      if (cuaToi && !tin.isRead && tin.createdAt.isBefore(moc)) {
        moc = tin.createdAt;
      }
    }
    return moc.toUtc().toIso8601String();
  }

  /// Bam "xem tin cu hon": lay them mot doan phia truoc tin dau tien dang co.
  Future<void> _taiTinCu() async {
    final conversation = _conversation;
    if (conversation == null || _messages.isEmpty || _dangTaiTinCu) return;

    setState(() => _dangTaiTinCu = true);
    try {
      final ketQua = await _service.getMessages(
        conversation.id,
        truocMoc: _messages.first.createdAt.toUtc().toIso8601String(),
      );
      if (!mounted) return;
      setState(() {
        _gopTin(ketQua.messages);
        _conTinCu = ketQua.conTinCu;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.of(context).danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _dangTaiTinCu = false);
    }
  }

  /// Ma cua tin cuoi cung do chinh minh gui, de chi gan "Da xem" o do.
  ///
  /// Gan o moi tin da doc se roi rac va kho nhin; cac ung dung nhan tin deu chi
  /// hien o tin duoi cung.
  String? get _idTinCuoiCuaToi {
    for (var i = _messages.length - 1; i >= 0; i -= 1) {
      final tin = _messages[i];
      final cuaToi = widget.isStaffConversation
          ? tin.senderRole == 'staff' || tin.senderRole == 'admin'
          : tin.senderRole == 'customer';
      if (cuaToi) return tin.id;
    }
    return null;
  }

  Future<void> _loadChat({bool silent = false}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    if (!silent && mounted) setState(() => _isLoading = true);

    try {
      // Lan dau chua co hoi thoai thi lay ca hoi thoai lan tin nhan trong mot
      // request. Nhung lan tu lam moi sau do chi can lay tin nhan.
      final SupportConversation conversation;
      final List<SupportChatMessage> messages;
      final bool khachDangSoan;
      final bool nhanVienDangSoan;
      final bool conTinCu;
      // Lan dau thay sach danh sach, nhung lan sau chi gop them tin moi.
      final bool thayToanBo;
      final daCo = _conversation;
      if (daCo == null) {
        final snapshot = await _service.getMyChat();
        conversation = snapshot.conversation;
        messages = snapshot.messages;
        khachDangSoan = snapshot.khachDangSoan;
        nhanVienDangSoan = snapshot.nhanVienDangSoan;
        conTinCu = snapshot.conTinCu;
        thayToanBo = true;
      } else {
        conversation = daCo;
        // Vong lam moi chi xin tin tu moc cuoi tro di, khong keo ca doan chat
        // ve moi 2 giay.
        final moc = _mocXinTinMoi;
        final ketQua = await _service.getMessages(daCo.id, tuMoc: moc);
        messages = ketQua.messages;
        khachDangSoan = ketQua.khachDangSoan;
        nhanVienDangSoan = ketQua.nhanVienDangSoan;
        conTinCu = moc == null ? ketQua.conTinCu : _conTinCu;
        thayToanBo = moc == null;
      }
      if (!mounted) return;
      setState(() {
        _conversation = conversation;
        if (thayToanBo) {
          _messages
            ..clear()
            ..addAll(messages);
        } else {
          _gopTin(messages);
        }
        _conTinCu = conTinCu;
        // Man nhan vien quan tam khach co go khong, man khach thi nguoc lai.
        _doiPhuongDangSoan =
            widget.isStaffConversation ? khachDangSoan : nhanVienDangSoan;
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

    final authUser = context.read<AuthProvider>().user;
    final role = widget.isStaffConversation
        ? (authUser?.role ?? 'staff')
        : 'customer';

    final tempMessage = SupportChatMessage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversation.id,
      senderId: authUser?.id ?? '',
      senderRole: role,
      content: content,
      createdAt: DateTime.now(),
    );

    setState(() {
      _isSending = true;
      _messages.add(tempMessage);
    });
    _messageController.clear();

    try {
      final daGui = await _service.sendMessage(conversation.id, content);
      // Gui xong coi nhu bat dau mot luot go moi: go tiep la bao ngay, khong
      // phai cho het 3 giay gian cach cua luot truoc.
      _lanBaoDangSoan = null;
      if (mounted) {
        setState(() {
          // Bo tin tam roi gop tin that vao. Tin tam mang ma rieng nen neu
          // khong bo tay thi _gopTin se giu lai ca hai.
          _messages.remove(tempMessage);
          _gopTin([daGui]);
        });
      }
      // Khong cho vong tai lai: tin da hien roi, bat nguoi dung doi them mot
      // vong di ve mang nua chi lam nut gui treo lau hon.
      unawaited(_loadChat(silent: true));
    } catch (error) {
      if (mounted) {
        setState(() {
          _messages.remove(tempMessage);
        });
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
    final auth = context.watch<AuthProvider>();

    // Nếu là khách hàng nhưng chưa đăng nhập, hiển thị thông báo yêu cầu đăng nhập
    if (!widget.isStaffConversation && !auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('Chat với CSKH')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: StatusView(
              icon: Icons.lock_outline_rounded,
              title: 'Vui lòng đăng nhập',
              message:
                  'Bạn cần đăng nhập tài khoản Menly để lưu giữ và trao đổi đoạn chat với nhân viên CSKH.',
              actionLabel: 'Đăng nhập ngay',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
            ),
          ),
        ),
      );
    }

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
                ? const LoadingView(message: 'Đang tải đoạn chat...')
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
                            // Danh sach ve nguoc, nen o dang soan nam o index 0
                            // moi hien ra duoi cung.
                            // Them mot o cuoi danh sach (tuc tren cung tren
                            // man hinh) cho nut xem tin cu hon.
                            itemCount: _messages.length +
                                (_doiPhuongDangSoan ? 1 : 0) +
                                (_conTinCu ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (_conTinCu &&
                                  index ==
                                      _messages.length +
                                          (_doiPhuongDangSoan ? 1 : 0)) {
                                return _NutTinCu(
                                  dangTai: _dangTaiTinCu,
                                  onTap: _taiTinCu,
                                );
                              }
                              if (_doiPhuongDangSoan && index == 0) {
                                return _DongDangSoan(
                                  nhan: widget.isStaffConversation
                                      ? 'Khách đang soạn tin...'
                                      : 'Nhân viên đang soạn tin...',
                                );
                              }
                              final viTri =
                                  _doiPhuongDangSoan ? index - 1 : index;
                              final message =
                                  _messages[_messages.length - 1 - viTri];
                              final isMine = widget.isStaffConversation
                                  ? message.senderRole == 'staff' ||
                                      message.senderRole == 'admin'
                                  : message.senderRole == 'customer';
                              return _ChatBubble(
                                message: message,
                                isMine: isMine,
                                time: _formatTime(message.createdAt),
                                daXem: isMine &&
                                    message.isRead &&
                                    message.id == _idTinCuoiCuaToi,
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

  /// Hien them chu "Da xem" duoi gio. Chi dat true o tin cuoi cung cua minh.
  final bool daXem;

  const _ChatBubble({
    required this.message,
    required this.isMine,
    required this.time,
    this.daXem = false,
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMine
                        ? c.onPrimary.withValues(alpha: 0.7)
                        : c.textMuted,
                    fontSize: 10,
                  ),
                ),
                if (daXem) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.done_all_rounded,
                    size: 12,
                    color: c.onPrimary.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Đã xem',
                    style: TextStyle(
                      color: c.onPrimary.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}


/// Dong nho bao doi phuong dang go phim, ve nhu mot bong chat nhat mau.
class _DongDangSoan extends StatelessWidget {
  final String nhan;

  const _DongDangSoan({required this.nhan});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: c.textMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              nhan,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Nut nam tren cung doan chat de keo ve them mot doan tin cu hon.
class _NutTinCu extends StatelessWidget {
  final bool dangTai;
  final VoidCallback onTap;

  const _NutTinCu({required this.dangTai, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Center(
        child: TextButton.icon(
          onPressed: dangTai ? null : onTap,
          icon: dangTai
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: c.textMuted,
                  ),
                )
              : Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: c.textSecondary),
          label: Text(
            dangTai ? 'Đang tải...' : 'Xem tin cũ hơn',
            style: TextStyle(color: c.textSecondary, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
