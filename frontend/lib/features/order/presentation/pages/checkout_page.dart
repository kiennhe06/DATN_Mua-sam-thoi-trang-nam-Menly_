import 'package:dio/dio.dart';
import 'package:menly_app/core/utils/format.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';
import '../widgets/checkout_payment_cancelled_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'order_success_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/features/cart/data/models/cart_item_model.dart';
import '../../../address/presentation/pages/address_page.dart';
import '../../../address/presentation/providers/address_provider.dart';
import '../../../address/presentation/widgets/administrative_unit_picker.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../voucher/presentation/widgets/voucher_select_sheet.dart';
import '../providers/order_provider.dart';
import 'vnpay_payment_page.dart';
import 'package:menly_app/features/notification/presentation/providers/notification_provider.dart';
import 'package:menly_app/core/theme/app_colors.dart';
import 'package:menly_app/core/theme/app_spacing.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/widgets/app_buttons.dart';
import 'package:menly_app/core/widgets/app_image.dart';
import 'package:menly_app/core/widgets/section_header.dart';
import 'package:menly_app/core/widgets/state_views.dart';

/// Man hinh Dat hang & Thanh toan (AP-DH2, AP-TT1, AP-VC1, AP-DC1)
/// Ho tro:
/// - Chon dia chi giao hang
/// - Chon phuong thuc giao hang (Tieu chuan / Hoa toc)
/// - Ap dung / Doi ma giam gia Voucher (khong gioi han so tien)
/// - Chon phuong thuc thanh toan: COD hoac VNPay
/// - Hien thi day du va chinh xac so tien khi mua truc tiep hoac tu gio hang
class CheckoutPage extends StatefulWidget {
  final List<CartItemModel>? customItems;

  const CheckoutPage({super.key, this.customItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _paymentMethod = 'cod'; // 'cod' hoac 'vnpay'
  String _shippingMethod = 'standard'; // 'standard' hoac 'express'
  bool _isSubmitting = false;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  /// Chi chua so nha va ten duong. Phuong / quan / tinh nam o _donViHanhChinh.
  final _addressCtrl = TextEditingController();

  DonViHanhChinh _donViHanhChinh = DonViHanhChinh.chuanHoa();

  /// Khoi dia chi mo san khi chua du thong tin, con lai thu gon cho do dai.
  bool _moRongDiaChi = false;

  /// Dia chi day du gui len may chu va luu lai cho lan sau.
  String get _diaChiDayDu => [
        _addressCtrl.text.trim(),
        _donViHanhChinh.moTa,
      ].where((phan) => phan.isNotEmpty).join(', ');

  int get _currentSubtotal {
    final items = widget.customItems ?? context.read<CartProvider>().selectedItems;
    return items.fold(0, (sum, i) => sum + i.totalPrice);
  }

  int _calculateDiscount(CartProvider cart) {
    if (cart.appliedVoucher == null) return 0;
    return cart.appliedVoucher!.calculateDiscount(_currentSubtotal);
  }

  int _calculateTotal(CartProvider cart) {
    final subtotal = _currentSubtotal;
    final discount = _calculateDiscount(cart);
    final shipping = cart.shippingFee;
    final total = subtotal - discount + shipping;
    return total > 0 ? total : 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAddressFromProvider();
      _recalculateShippingFee();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _initAddressFromProvider() {
    final addrProv = context.read<AddressProvider>();
    final defaultAddr = addrProv.selectedAddress;
    if (defaultAddr != null) {
      _nameCtrl.text = defaultAddr.recipientName;
      _phoneCtrl.text = defaultAddr.phone;
      _addressCtrl.text = defaultAddr.detailAddress;
      _donViHanhChinh = DonViHanhChinh.chuanHoa(
        province: defaultAddr.province,
        district: defaultAddr.district,
        ward: defaultAddr.ward,
      );
      _capNhatTrangThaiMoRong();
    } else {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        if (user.fullName.isNotEmpty && user.fullName != 'Khách hàng Menly') {
          _nameCtrl.text = user.fullName;
        }
        if (user.phone != null && user.phone!.isNotEmpty) {
          _phoneCtrl.text = user.phone!;
        }
      }
      SharedPreferences.getInstance().then((prefs) {
        if (!mounted) return;
        if (_nameCtrl.text.isEmpty) {
          _nameCtrl.text = prefs.getString('saved_user_name') ??
              prefs.getString('last_ship_name') ??
              '';
        }
        if (_phoneCtrl.text.isEmpty) {
          _phoneCtrl.text = prefs.getString('saved_user_phone') ??
              prefs.getString('last_ship_phone') ??
              '';
        }
        if (_addressCtrl.text.isEmpty) {
          _addressCtrl.text = prefs.getString('last_ship_detail') ??
              prefs.getString('last_ship_address') ??
              '';
        }
        setState(() {
          _donViHanhChinh = DonViHanhChinh.chuanHoa(
            province: prefs.getString('last_ship_province') ?? '',
            district: prefs.getString('last_ship_district') ?? '',
            ward: prefs.getString('last_ship_ward') ?? '',
          );
        });
        _capNhatTrangThaiMoRong();
        _recalculateShippingFee();
      });
    }
  }

  /// Chua du ten, so dien thoai hoac dia chi thi mo san de nguoi dung dien
  /// ngay, khong bat ho phai tim nut mo ra.
  void _capNhatTrangThaiMoRong() {
    final duThongTin = _nameCtrl.text.trim().isNotEmpty &&
        _phoneCtrl.text.trim().isNotEmpty &&
        _addressCtrl.text.trim().isNotEmpty &&
        _donViHanhChinh.dayDu;
    if (!mounted) return;
    setState(() => _moRongDiaChi = !duThongTin);
  }

  void _recalculateShippingFee() {
    final cart = context.read<CartProvider>();
    final addrProv = context.read<AddressProvider>();
    // Lay tinh dang chon tren man nay, vi nguoi dung co the doi truc tiep o day
    // ma khong luu vao so dia chi.
    final province = _donViHanhChinh.province.isNotEmpty
        ? _donViHanhChinh.province
        : (addrProv.selectedAddress?.province ?? '');
    cart.calculateShippingFeeApi(
      province: province,
      shippingMethod: _shippingMethod,
      customSubtotal: _currentSubtotal,
    );
  }

  Future<void> _openVoucherSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (_) => const VoucherSelectSheet(),
    );
    if (!mounted) return;
    _recalculateShippingFee();
  }

  Future<void> _handlePlaceOrder() async {
    final cart = context.read<CartProvider>();
    final orderProv = context.read<OrderProvider>();

    final items = widget.customItems ?? cart.selectedItems;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Không có sản phẩm nào để đặt hàng!'),
            backgroundColor: AppColors.of(context).danger),
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final detail = _addressCtrl.text.trim();
    final address = _diaChiDayDu;

    if (name.isEmpty || phone.isEmpty || detail.isEmpty || !_donViHanhChinh.dayDu) {
      setState(() => _moRongDiaChi = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Vui lòng điền đầy đủ thông tin người nhận và địa chỉ giao hàng!'),
          backgroundColor: AppColors.of(context).danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final subtotal = _currentSubtotal;
      final discount = _calculateDiscount(cart);
      final shippingFee = cart.shippingFee;
      final total = _calculateTotal(cart);

      final authProv = context.read<AuthProvider>();

      // Tu dong ghi nho ten, so dien thoai, dia chi cho cac lan mua sam tiep theo
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_user_name', name);
      await prefs.setString('saved_user_phone', phone);
      await prefs.setString('last_ship_name', name);
      await prefs.setString('last_ship_phone', phone);
      await prefs.setString('last_ship_address', address);
      // Luu rieng tung phan de lan sau mo lai dung o chon tinh / quan / phuong.
      await prefs.setString('last_ship_detail', detail);
      await prefs.setString('last_ship_province', _donViHanhChinh.province);
      await prefs.setString('last_ship_district', _donViHanhChinh.district);
      await prefs.setString('last_ship_ward', _donViHanhChinh.ward);

      // Dong bo lai sdt vao ho so nguoi dung neu chua co
      if (authProv.user != null) {
        final currentPhone = authProv.user!.phone;
        if (currentPhone == null || currentPhone.trim().isEmpty) {
          authProv.updateProfile(
            fullName: name.isNotEmpty ? name : authProv.user!.fullName,
            phone: phone,
          );
        }
      }

      final createdOrder = await orderProv.createOrder(
        items: items,
        shipName: name,
        shipPhone: phone,
        shipAddress: address,
        paymentMethod: _paymentMethod,
        subtotal: subtotal,
        discountAmount: discount,
        shippingFee: shippingFee,
        total: total,
        voucherCode: cart.appliedVoucher?.code,
      );

      // Xóa các món vừa đặt hàng khỏi giỏ hàng
      await cart.removePurchasedItems(items);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (_paymentMethod == 'vnpay') {
        final orderForPayment = (createdOrder.total == total && createdOrder.discountAmount == discount)
            ? createdOrder
            : createdOrder.copyWith(
                total: total,
                discountAmount: discount,
                shippingFee: shippingFee,
              );
        final paymentSuccess = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => VNPayPaymentPage(order: orderForPayment),
          ),
        );
        if (!mounted) return;

        if (paymentSuccess == true) {
          context.read<NotificationProvider>().addNotification(
            title: 'Thanh toán VNPay thành công #${createdOrder.code}',
            body: 'Giao dịch thanh toán trực tuyến ${formatPrice(createdOrder.total)} cho đơn hàng #${createdOrder.code} qua VNPay đã thành công.',
            type: 'order',
            data: {'orderId': createdOrder.id, 'orderCode': createdOrder.code},
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderSuccessPage(order: createdOrder),
            ),
          );
        } else {
          // Nguoi dung huy thanh toan hoac thanh toan that bai:
          // KHONG chuyen den trang thanh toan thanh cong!
          context.read<NotificationProvider>().addNotification(
            title: 'Chưa hoàn tất thanh toán #${createdOrder.code}',
            body: 'Giao dịch qua VNPay chưa hoàn tất. Đơn hàng #${createdOrder.code} đang ở trạng thái chờ thanh toán.',
            type: 'order',
            data: {'orderId': createdOrder.id, 'orderCode': createdOrder.code},
          );
          _showPaymentCancelledDialog(createdOrder);
        }
      } else {
        context.read<NotificationProvider>().addNotification(
          title: 'Đặt hàng thành công #${createdOrder.code}',
          body: 'Đơn hàng gồm ${createdOrder.items.length} sản phẩm trị giá ${formatPrice(createdOrder.total)} đã được ghi nhận. Menly đang chuẩn bị đơn cho bạn.',
          type: 'order',
          data: {'orderId': createdOrder.id, 'orderCode': createdOrder.code},
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessPage(order: createdOrder),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      String errorMessage = 'Không thể đặt hàng, vui lòng thử lại sau.';
      if (e is DioException) {
        final serverMsg = e.response?.data is Map ? e.response?.data['error']?.toString() : null;
        if (serverMsg != null && serverMsg.isNotEmpty) {
          errorMessage = serverMsg;
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        } else if (e.response?.statusCode == 400) {
          errorMessage = 'Thông tin đặt hàng không hợp lệ. Vui lòng kiểm tra lại.';
        }
      } else {
        errorMessage = e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đặt hàng: $errorMessage'),
          backgroundColor: AppColors.of(context).danger,
        ),
      );
    }
  }
  void _showPaymentCancelledDialog(OrderModel order) {
    CheckoutPaymentCancelledDialog.show(
      context: context,
      order: order,
      onRetry: () => _retryVNPayPayment(order),
    );
  }

  Future<void> _retryVNPayPayment(OrderModel order) async {
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VNPayPaymentPage(order: order),
      ),
    );
    if (!mounted) return;
    if (success == true) {
      context.read<NotificationProvider>().addNotification(
        title: 'Thanh toán VNPay thành công #${order.code}',
        body: 'Giao dịch thanh toán trực tuyến cho đơn hàng #${order.code} qua cổng VNPay đã thành công.',
        type: 'order',
        data: {'orderId': order.id, 'orderCode': order.code},
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessPage(order: order),
        ),
      );
    } else {
      _showPaymentCancelledDialog(order);
    }
  }
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final cart = context.watch<CartProvider>();
    // Van theo doi so dia chi de man nay ve lai khi nguoi dung sua dia chi
    // o cho khac, du du lieu hien thi lay tu cac o nhap tren man nay.
    context.watch<AddressProvider>();
    final items = widget.customItems ?? cart.selectedItems;
    final totalAmount = _calculateTotal(cart);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Xác nhận đặt hàng'),
        centerTitle: true,
      ),
      body: items.isEmpty
          ? StatusView(
              icon: Icons.shopping_bag_outlined,
              title: 'Chưa có sản phẩm nào được chọn',
              actionLabel: 'Quay lại giỏ hàng',
              onAction: () => Navigator.pop(context),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DIA CHI GIAO HANG
                  SectionHeader(
                    title: 'Địa chỉ nhận hàng',
                    actionLabel: 'Thay đổi',
                    onAction: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AddressPage(isSelectionMode: true),
                        ),
                      );
                      _initAddressFromProvider();
                      _recalculateShippingFee();
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildAddressCard(c),
                  const SizedBox(height: AppSpacing.xl),

                  // 2. SAN PHAM DAT HANG
                  SectionHeader(title: 'Danh sách sản phẩm (${items.length})'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildItemsCard(c, items),
                  const SizedBox(height: AppSpacing.xl),

                  // 3. PHUONG THUC VAN CHUYEN
                  const SectionHeader(title: 'Phương thức vận chuyển'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildShippingMethodCard(c, cart),
                  const SizedBox(height: AppSpacing.xl),

                  // 4. MA GIAM GIA (VOUCHER)
                  SectionHeader(
                    title: 'Mã giảm giá Menly',
                    actionLabel:
                        cart.appliedVoucher != null ? 'Đổi mã' : 'Chọn mã',
                    onAction: _openVoucherSheet,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildVoucherCard(c, cart),
                  const SizedBox(height: AppSpacing.xl),

                  // 5. PHUONG THUC THANH TOAN (COD HOAC VNPAY)
                  const SectionHeader(title: 'Phương thức thanh toán'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildPaymentMethodCard(c),
                  const SizedBox(height: AppSpacing.xl),

                  // 6. CHI TIET THANH TOAN
                  const SectionHeader(title: 'Chi tiết thanh toán'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSummaryCard(c, cart),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
              // Thanh dat hang bo tron manh o canh tren, bong do rat nhe
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusXl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: c.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tổng thanh toán:',
                            style:
                                TextStyle(fontSize: 12, color: c.textMuted)),
                        Text(
                          formatPrice(totalAmount),
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: c.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: PrimaryButton(
                        label: _paymentMethod == 'vnpay'
                            ? 'Thanh toán qua VNPay'
                            : 'Đặt hàng (COD)',
                        loading: _isSubmitting,
                        height: 54,
                        onPressed: _handlePlaceOrder,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Kieu the dung chung cho moi khoi tren man dat hang: nen [AppColors.surface],
  /// bo goc [AppTheme.radiusXl] va vien mong [AppColors.border].
  BoxDecoration _cardDecoration(AppColors c) {
    return BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      border: Border.all(color: c.border),
    );
  }

  Widget _buildAddressCard(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(c),
      child: _moRongDiaChi ? _buildAddressForm() : _buildAddressSummary(c),
    );
  }

  /// Dang thu gon: chi mot dong nguoi nhan va mot dong dia chi.
  Widget _buildAddressSummary(AppColors c) {
    final ten = _nameCtrl.text.trim();
    final sdt = _phoneCtrl.text.trim();

    return InkWell(
      onTap: () => setState(() => _moRongDiaChi = true),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [ten, sdt].where((phan) => phan.isNotEmpty).join(' · '),
                  style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _diaChiDayDu,
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.edit_outlined, size: 18, color: c.textSecondary),
        ],
      ),
    );
  }

  /// Dang mo: sua duoc ten, so dien thoai, tinh / quan / phuong va so nha.
  Widget _buildAddressForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên người nhận',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AdministrativeUnitPicker(
          giaTri: _donViHanhChinh,
          onChanged: (chon) {
            setState(() => _donViHanhChinh = chon);
            // Phi ship tinh theo tinh / thanh nen phai tinh lai ngay.
            _recalculateShippingFee();
          },
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _addressCtrl,
          decoration: const InputDecoration(
            labelText: 'Địa chỉ cụ thể (Số nhà, tên đường)',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _moRongDiaChi = false),
            icon: const Icon(Icons.expand_less, size: 18),
            label: const Text('Thu gọn'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCard(AppColors c, List<CartItemModel> items) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(c),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: AppSpacing.xxl),
        itemBuilder: (_, index) {
          final item = items[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: AppImage(
                  url: item.product.thumbnailUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorWidget: (_) => Container(
                    width: 64,
                    height: 64,
                    color: c.surfaceVariant,
                    alignment: Alignment.center,
                    child: Text('Menly',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: c.textMuted)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Phân loại: ${item.color} / Size ${item.size}',
                      style: TextStyle(color: c.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatPrice(item.product.price),
                          style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        Text(
                          'x${item.quantity}',
                          style:
                              TextStyle(color: c.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShippingMethodCard(AppColors c, CartProvider cart) {
    return Column(
      children: [
        _buildOptionRow(
          c: c,
          selected: _shippingMethod == 'standard',
          title: 'Giao hàng tiêu chuẩn',
          subtitle: '2–4 ngày làm việc • 25.000 đ',
          titleWeight: FontWeight.w600,
          onTap: () {
            setState(() => _shippingMethod = 'standard');
            _recalculateShippingFee();
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _buildOptionRow(
          c: c,
          selected: _shippingMethod == 'express',
          title: 'Giao hàng hỏa tốc',
          subtitle: 'Trong ngày hoặc 24h • 45.000 đ',
          titleWeight: FontWeight.w600,
          onTap: () {
            setState(() => _shippingMethod = 'express');
            _recalculateShippingFee();
          },
        ),
        if (cart.shippingNote != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: c.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Text(
              cart.shippingNote!,
              style: TextStyle(
                  fontSize: 11,
                  color: c.success,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }

  /// Mot hang lua chon rieng: the bo [AppTheme.radiusXl] co vien, hang dang
  /// chon duoc danh dau bang vien ink day hon. Dung chung cho van chuyen va
  /// thanh toan de hai khoi khong lech nhau.
  Widget _buildOptionRow({
    required AppColors c,
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    FontWeight titleWeight = FontWeight.bold,
    Widget? titleTrailing,
  }) {
    final radius = BorderRadius.circular(AppTheme.radiusXl);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: radius,
            border: Border.all(
              color: selected ? c.primary : c.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.primary : c.border,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: c.primary),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(title,
                              style: TextStyle(
                                  color: c.textPrimary,
                                  fontWeight: titleWeight,
                                  fontSize: 14)),
                        ),
                        if (titleTrailing != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          titleTrailing,
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherCard(AppColors c, CartProvider cart) {
    final voucher = cart.appliedVoucher;
    final discount = _calculateDiscount(cart);

    if (voucher != null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.primarySoft,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: c.secondary.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        voucher.code,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: c.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: c.success,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Text(
                          '-${formatPrice(discount)}',
                          style: TextStyle(
                              color: c.onInk,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    voucher.title,
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                cart.removeVoucher();
                _recalculateShippingFee();
              },
              child: Text('Xóa',
                  style: TextStyle(
                      color: c.danger, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _openVoucherSheet,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        decoration: _cardDecoration(c),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chọn hoặc nhập mã giảm giá Menly',
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            Text('Chọn mã >',
                style: TextStyle(
                    fontSize: 12,
                    color: c.primary,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(AppColors c) {
    return Column(
      children: [
        // Option 1: COD
        _buildOptionRow(
          c: c,
          selected: _paymentMethod == 'cod',
          title: 'Thanh toán khi nhận hàng (COD)',
          subtitle:
              'Thanh toán bằng tiền mặt cho nhân viên giao hàng khi nhận',
          onTap: () => setState(() => _paymentMethod = 'cod'),
        ),
        const SizedBox(height: AppSpacing.md),
        // Option 2: VNPay
        _buildOptionRow(
          c: c,
          selected: _paymentMethod == 'vnpay',
          title: 'Cổng thanh toán VNPay',
          subtitle:
              'Quét mã VNPAY-QR, thẻ ATM nội địa hoặc thẻ Visa/Master',
          onTap: () => setState(() => _paymentMethod = 'vnpay'),
          titleTrailing: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text('Sandbox',
                style: TextStyle(
                    color: c.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(AppColors c, CartProvider cart) {
    final subtotal = _currentSubtotal;
    final discount = _calculateDiscount(cart);
    final shippingFee = cart.shippingFee;
    final total = _calculateTotal(cart);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: _cardDecoration(c),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng tiền hàng:',
                  style: TextStyle(color: c.textSecondary, fontSize: 13)),
              Text(formatPrice(subtotal),
                  style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Phí vận chuyển:',
                  style: TextStyle(color: c.textSecondary, fontSize: 13)),
              Text(
                shippingFee == 0 ? 'Miễn phí' : formatPrice(shippingFee),
                style: TextStyle(
                  color: shippingFee == 0 ? c.success : c.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          if (cart.appliedVoucher != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Giảm giá voucher (${cart.appliedVoucher!.code}):',
                    style: TextStyle(color: c.success, fontSize: 13)),
                Text('-${formatPrice(discount)}',
                    style: TextStyle(
                        color: c.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5)),
              ],
            ),
          ],
          // Duong ke manh ngan cach truoc dong tong
          const Divider(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng thanh toán:',
                  style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text(
                formatPrice(total),
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    color: c.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
