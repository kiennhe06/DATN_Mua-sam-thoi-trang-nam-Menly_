import 'models/notification_model.dart';

/// Danh sách thông báo mặc định ban đầu phong phú, bao quát toàn bộ các hoạt động của Menly
List<NotificationModel> getInitialSampleNotifications() {
  final now = DateTime.now();
  return [
    NotificationModel(
      id: 'notif-ord-1',
      title: 'Đặt hàng thành công #MNL-8924',
      body: 'Đơn hàng trị giá 549.000đ (01 Áo Polo Cotton Pique, 01 Quần Short Kaki) đã được xác nhận và đang chờ đóng gói xuất kho.',
      type: 'order',
      isRead: false,
      createdAt: now.subtract(const Duration(minutes: 25)),
      data: {'orderId': 'MNL-8924'},
    ),
    NotificationModel(
      id: 'notif-prm-1',
      title: 'Tặng bạn voucher 50.000đ thành viên mới',
      body: 'Chào mừng gia nhập Menly! Nhập mã MENLYNEW tại bước thanh toán để giảm ngay 50.000đ cho đơn hàng từ 299.000đ.',
      type: 'promo',
      isRead: false,
      createdAt: now.subtract(const Duration(hours: 1, minutes: 15)),
      data: {'code': 'MENLYNEW'},
    ),
    NotificationModel(
      id: 'notif-ord-2',
      title: 'Đơn hàng #MNL-8731 đang được giao',
      body: 'Đơn vị vận chuyển Giao Hàng Nhanh đang trên đường giao kiện hàng đến bạn. Vui lòng chú ý điện thoại từ shipper nhé!',
      type: 'order',
      isRead: false,
      createdAt: now.subtract(const Duration(hours: 3)),
      data: {'orderId': 'MNL-8731'},
    ),
    NotificationModel(
      id: 'notif-sys-1',
      title: 'Cập nhật ứng dụng: Chọn 63 tỉnh thành',
      body: 'Trải nghiệm mua sắm mượt mà hơn với tính năng chọn nhanh 63 tỉnh thành Việt Nam và hệ thống phân loại lọc thông báo thông minh.',
      type: 'system',
      isRead: false,
      createdAt: now.subtract(const Duration(hours: 6)),
    ),
    NotificationModel(
      id: 'notif-prm-2',
      title: 'Flash Sale Cuối Tuần: Giảm đến 50%',
      body: 'Đại tiệc thời trang nam cuối tuần! Hàng trăm mẫu áo sơ mi công sở, polo và quần âu cao cấp đang có giá sốc duy nhất tuần này.',
      type: 'promo',
      isRead: true,
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
    ),
    NotificationModel(
      id: 'notif-ord-3',
      title: 'Xác nhận thanh toán VNPay thành công',
      body: 'Giao dịch thanh toán trực tuyến 890.000đ cho đơn hàng #MNL-8924 qua cổng VNPay đã được hệ thống ghi nhận thành công.',
      type: 'order',
      isRead: true,
      createdAt: now.subtract(const Duration(days: 1, hours: 8)),
      data: {'orderId': 'MNL-8924'},
    ),
    NotificationModel(
      id: 'notif-prm-3',
      title: 'Miễn phí vận chuyển toàn quốc',
      body: 'Nhận ngay ưu đãi Freeship cho đơn hàng từ 199.000đ khi áp dụng mã FREESHIP trong tuần lễ tri ân khách hàng.',
      type: 'promo',
      isRead: true,
      createdAt: now.subtract(const Duration(days: 2)),
      data: {'code': 'FREESHIP'},
    ),
    NotificationModel(
      id: 'notif-ord-4',
      title: 'Giao hàng thành công #MNL-8610',
      body: 'Kiện hàng gồm 02 Áo Thun Nam Regular Fit đã được giao thành công. Đánh giá sản phẩm ngay để nhận thêm voucher ưu đãi!',
      type: 'order',
      isRead: true,
      createdAt: now.subtract(const Duration(days: 3)),
      data: {'orderId': 'MNL-8610'},
    ),
    NotificationModel(
      id: 'notif-sys-2',
      title: 'Chính sách đổi trả miễn phí trong 30 ngày',
      body: 'Menly hỗ trợ đổi size, đổi mẫu hoàn toàn miễn phí tại tất cả hệ thống cửa hàng và mua hàng online trong vòng 30 ngày.',
      type: 'system',
      isRead: true,
      createdAt: now.subtract(const Duration(days: 4)),
    ),
    NotificationModel(
      id: 'notif-sys-3',
      title: 'Chào mừng bạn đến với Menly!',
      body: 'Cảm ơn bạn đã lựa chọn Menly - Thương hiệu thời trang nam cao cấp, hiện đại và phong cách. Chúc bạn có trải nghiệm mua sắm tuyệt vời!',
      type: 'system',
      isRead: true,
      createdAt: now.subtract(const Duration(days: 7)),
    ),
  ];
}
