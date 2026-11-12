import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';

class OrderTimelineCard extends StatelessWidget {
  final OrderModel order;

  const OrderTimelineCard({super.key, required this.order});

  /// Thu tu cac trang thai mot don hang di qua.
  static const List<OrderStatus> _hanhTrinh = [
    OrderStatus.pendingPayment,
    OrderStatus.paid,
    OrderStatus.processing,
    OrderStatus.shipping,
    OrderStatus.delivered,
    OrderStatus.completed,
  ];

  static const Map<OrderStatus, String> _moTa = {
    OrderStatus.pendingPayment: 'Chờ khách thanh toán',
    OrderStatus.paid: 'Đã ghi nhận thanh toán',
    OrderStatus.processing: 'Cửa hàng đang chuẩn bị hàng',
    OrderStatus.shipping: 'Đã bàn giao cho đơn vị vận chuyển',
    OrderStatus.delivered: 'Khách hàng đã nhận hàng',
    OrderStatus.completed: 'Đơn hàng kết thúc',
  };

  static const Map<OrderStatus, String> _tieuDe = {
    OrderStatus.pendingPayment: 'Chờ thanh toán',
    OrderStatus.paid: 'Đã thanh toán',
    OrderStatus.processing: 'Đang xử lý',
    OrderStatus.shipping: 'Đang vận chuyển',
    OrderStatus.delivered: 'Đã giao',
    OrderStatus.completed: 'Hoàn tất',
  };

  /// Dung hanh trinh tu du lieu that.
  ///
  /// Moc thoi gian lay tu bang lich su doi trang thai, rieng buoc dau lay tu
  /// ngay tao don. Buoc nao chua co moc thi de xam — truoc day moi buoc dung
  /// truoc trang thai hien tai deu duoc to xanh, nen don vua dat trong nhu da
  /// qua ba buoc.
  List<_BuocHanhTrinh> _dungCacBuoc() {
    final trangThaiBanDau = order.statusHistory.isNotEmpty
        ? order.statusHistory.first.fromStatus
        : order.status;

    final daDatToi = <OrderStatus, DateTime>{trangThaiBanDau: order.createdAt};
    for (final lan in order.statusHistory) {
      daDatToi[lan.toStatus] = lan.at;
    }

    final viTriBatDau = _hanhTrinh.indexOf(trangThaiBanDau);
    final conLai = viTriBatDau >= 0
        ? _hanhTrinh.sublist(viTriBatDau + 1)
        : <OrderStatus>[];

    final cacBuoc = <_BuocHanhTrinh>[
      _BuocHanhTrinh(
        tieuDe: 'Đã đặt hàng',
        moTa: _moTa[trangThaiBanDau] ?? 'Hệ thống đã ghi nhận đơn',
        luc: order.createdAt,
        laHienTai: order.status == trangThaiBanDau && !order.daHoanTien,
      ),
      for (final trangThai in conLai)
        _BuocHanhTrinh(
          tieuDe: _tieuDe[trangThai] ?? trangThai.label,
          moTa: _moTa[trangThai] ?? '',
          luc: daDatToi[trangThai],
          laHienTai: order.status == trangThai && !order.daHoanTien,
        ),
      // Hoan tien la cai ket cua don, phai nam cuoi hanh trinh. Khong co buoc
      // nay thi man chi tiet van ke chuyen "Hoan tat" trong khi the don o danh
      // sach da ghi la da hoan tien.
      if (order.daHoanTien)
        _BuocHanhTrinh(
          tieuDe: 'Đã hoàn tiền',
          moTa: 'Cửa hàng đã hoàn tiền cho khách',
          luc: order.hoanTienLuc,
          laHienTai: true,
          luonCoi: true,
        ),
    ];

    // Quan tri co the nhay thang tu "Dang van chuyen" sang "Hoan tat", bo lai
    // buoc "Da giao" khong co moc. Ghi "chua dien ra" trong khi don da hoan tat
    // la noi sai; buoc do co xay ra, chi la khong ai ghi lai gio.
    var daThayMocSau = false;
    for (var i = cacBuoc.length - 1; i >= 0; i -= 1) {
      if (cacBuoc[i].daXayRa) {
        daThayMocSau = true;
      } else if (daThayMocSau) {
        cacBuoc[i] = cacBuoc[i].danhDauBoQua();
      }
    }
    return cacBuoc;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final cacBuoc = _dungCacBuoc();
    final isCancelled = order.status == OrderStatus.canceled;
    final daHoanTien = order.daHoanTien;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: (isCancelled || daHoanTien)
              ? c.danger.withValues(alpha: 0.3)
              : c.border.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: ((isCancelled || daHoanTien) ? c.danger : c.secondary)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Text(
                  isCancelled
                      ? 'ĐÃ HỦY'
                      : daHoanTien
                          ? 'ĐÃ HOÀN TIỀN'
                          : 'TIẾN TRÌNH',
                  style: TextStyle(
                    color: (isCancelled || daHoanTien) ? c.danger : c.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Hành trình giao hàng',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Khong lap lai order.code o day: AppBar cua man chi tiet don
              // da hien dung ma nay, nhet them vao lam tieu de bi cat cut.
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isCancelled) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: c.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: c.danger.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('✕',
                          style: TextStyle(
                              color: c.onInk,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn hàng đã hủy',
                          style: TextStyle(
                              color: c.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        if (order.cancelReason != null &&
                            order.cancelReason!.isNotEmpty)
                          Text(
                            'Lý do: ${order.cancelReason}',
                            style:
                                TextStyle(color: c.textSecondary, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildTimeline(context, cacBuoc),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<_BuocHanhTrinh> cacBuoc) {
    final c = AppColors.of(context);
    return Column(
      children: [
        for (int i = 0; i < cacBuoc.length; i++)
          _buildStepRow(
            context,
            index: i,
            title: cacBuoc[i].tieuDe,
            subtitle: cacBuoc[i].moTaKemGio,
            isDone: cacBuoc[i].daXayRa,
            isCurrent: cacBuoc[i].laHienTai,
            isLast: i == cacBuoc.length - 1,
            c: c,
          ),
      ],
    );
  }

  Widget _buildStepRow(
    BuildContext context, {
    required int index,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    required bool isLast,
    required AppColors c,
  }) {
    // Mot bo mau duy nhat cho ca cot moc: da qua va dang o day deu to ink,
    // chua toi thi de rong vien xam. Truoc day moc da qua to xanh la con moc
    // hien tai to mau nhan, nhin nhu hai he mau khac nhau tren cung mot cot.
    final activeColor = (isDone || isCurrent) ? c.primary : c.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot & vertical line
          Column(
            children: [
              // Cham da qua: to dac. Cham chua toi: de rong, chi co vien.
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isDone ? activeColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone ? activeColor : c.border,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? Text(
                          '✓',
                          style: TextStyle(
                            color: isCurrent ? c.inkCard : c.onInk,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: c.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                // Duong noi manh giua hai cham.
                Expanded(
                  child: Container(
                    width: 1.5,
                    color:
                        isDone ? activeColor.withValues(alpha: 0.5) : c.border,
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          // Texts
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDone ? c.textPrimary : c.textMuted,
                      fontWeight: isCurrent
                          ? FontWeight.w800
                          : (isDone ? FontWeight.w600 : FontWeight.normal),
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDone ? c.textSecondary : c.textMuted,
                      fontSize: 11.5,
                    ),
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

/// Mot buoc tren hanh trinh giao hang.
class _BuocHanhTrinh {
  final String tieuDe;
  final String moTa;

  /// Null nghia la khong co moc thoi gian cho buoc nay.
  final DateTime? luc;
  final bool laHienTai;

  /// Buoc da xay ra nhung khong ai ghi lai moc thoi gian.
  final bool boQuaMoc;

  /// Buoc luon tinh la da xay ra du khong co moc, vi du buoc hoan tien.
  final bool luonCoi;

  const _BuocHanhTrinh({
    required this.tieuDe,
    required this.moTa,
    required this.luc,
    required this.laHienTai,
    this.boQuaMoc = false,
    this.luonCoi = false,
  });

  /// Ban sao duoc danh dau la da xay ra nhung thieu moc thoi gian.
  _BuocHanhTrinh danhDauBoQua() => _BuocHanhTrinh(
        tieuDe: tieuDe,
        moTa: moTa,
        luc: luc,
        laHienTai: laHienTai,
        boQuaMoc: true,
        luonCoi: luonCoi,
      );

  bool get daXayRa => luc != null || boQuaMoc || luonCoi;

  String get moTaKemGio {
    final moc = luc;
    if (moc == null) {
      if (boQuaMoc || luonCoi) {
        return moTa.isEmpty
            ? 'Không ghi nhận mốc thời gian'
            : '$moTa · không ghi nhận mốc thời gian';
      }
      return moTa.isEmpty ? 'Chưa diễn ra' : '$moTa · chưa diễn ra';
    }
    // May chu tra ve gio quoc te; phai doi sang gio may moi khop voi hoa don
    // va cac man khac trong ung dung.
    final theoGioMay = moc.toLocal();
    final gio = theoGioMay.hour.toString().padLeft(2, '0');
    final phut = theoGioMay.minute.toString().padLeft(2, '0');
    final ngay = theoGioMay.day.toString().padLeft(2, '0');
    final thang = theoGioMay.month.toString().padLeft(2, '0');
    return moTa.isEmpty ? '$gio:$phut $ngay/$thang' : '$moTa · $gio:$phut $ngay/$thang';
  }
}
