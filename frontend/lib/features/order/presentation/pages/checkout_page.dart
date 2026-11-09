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
import 'package:menly_app/core/widgets/app_image.dart';

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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
        const SnackBar(
            content: Text('Không có sản phẩm nào để đặt hàng!'),
            backgroundColor: Colors.red),
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
        const SnackBar(
          content: Text(
              'Vui lòng điền đầy đủ thông tin người nhận và địa chỉ giao hàng!'),
          backgroundColor: Colors.orange,
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
          backgroundColor: Colors.red,
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
    final cart = context.watch<CartProvider>();
    // Van theo doi so dia chi de man nay ve lai khi nguoi dung sua dia chi
    // o cho khac, du du lieu hien thi lay tu cac o nhap tren man nay.
    context.watch<AddressProvider>();
    final items = widget.customItems ?? cart.selectedItems;
    final totalAmount = _calculateTotal(cart);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận đặt hàng'),
        centerTitle: true,
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có sản phẩm nào được chọn',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Quay lại giỏ hàng'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DIA CHI GIAO HANG
                  _buildSectionHeader('Địa chỉ nhận hàng', onAction: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AddressPage(isSelectionMode: true),
                      ),
                    );
                    _initAddressFromProvider();
                    _recalculateShippingFee();
                  }, actionLabel: 'Thay đổi'),
                  const SizedBox(height: 8),
                  _buildAddressCard(),
                  const SizedBox(height: 20),

                  // 2. SAN PHAM DAT HANG
                  _buildSectionHeader('Danh sách sản phẩm (${items.length})'),
                  const SizedBox(height: 8),
                  _buildItemsCard(items),
                  const SizedBox(height: 20),

                  // 3. PHUONG THUC VAN CHUYEN
                  _buildSectionHeader('Phương thức vận chuyển'),
                  const SizedBox(height: 8),
                  _buildShippingMethodCard(cart),
                  const SizedBox(height: 20),

                  // 4. MA GIAM GIA (VOUCHER)
                  _buildSectionHeader('Mã giảm giá Menly', onAction: _openVoucherSheet, actionLabel: cart.appliedVoucher != null ? 'Đổi mã' : 'Chọn mã'),
                  const SizedBox(height: 8),
                  _buildVoucherCard(cart),
                  const SizedBox(height: 20),

                  // 5. PHUONG THUC THANH TOAN (COD HOAC VNPAY)
                  _buildSectionHeader('Phương thức thanh toán'),
                  const SizedBox(height: 8),
                  _buildPaymentMethodCard(),
                  const SizedBox(height: 20),

                  // 6. CHI TIET THANH TOAN
                  _buildSectionHeader('Chi tiết thanh toán'),
                  const SizedBox(height: 8),
                  _buildSummaryCard(cart),
                  const SizedBox(height: 30),
                ],
              ),
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
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
                        const Text('Tổng thanh toán:',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          formatPrice(totalAmount),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _paymentMethod == 'vnpay'
                              ? const Color(0xFF005BAA)
                              : Colors.black87,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSubmitting ? null : _handlePlaceOrder,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _paymentMethod == 'vnpay'
                                    ? 'Thanh toán qua VNPay'
                                    : 'Đặt hàng (COD)',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAction, String? actionLabel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        if (onAction != null && actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            child: Text(actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _moRongDiaChi ? _buildAddressForm() : _buildAddressSummary(),
    );
  }

  /// Dang thu gon: chi mot dong nguoi nhan va mot dong dia chi.
  Widget _buildAddressSummary() {
    final ten = _nameCtrl.text.trim();
    final sdt = _phoneCtrl.text.trim();

    return InkWell(
      onTap: () => setState(() => _moRongDiaChi = true),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [ten, sdt].where((phan) => phan.isNotEmpty).join(' · '),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _diaChiDayDu,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade600),
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
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AdministrativeUnitPicker(
          giaTri: _donViHanhChinh,
          onChanged: (chon) {
            setState(() => _donViHanhChinh = chon);
            // Phi ship tinh theo tinh / thanh nen phai tinh lai ngay.
            _recalculateShippingFee();
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _addressCtrl,
          decoration: const InputDecoration(
            labelText: 'Địa chỉ cụ thể (Số nhà, tên đường)',
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _moRongDiaChi = false),
            icon: const Icon(Icons.expand_less, size: 18),
            label: const Text('Thu gọn'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCard(List<CartItemModel> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 20),
        itemBuilder: (_, index) {
          final item = items[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AppImage(
                  url: item.product.thumbnailUrl,
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                  errorWidget: (_) => Container(
                    width: 55,
                    height: 55,
                    color: Colors.grey.shade100,
                    alignment: Alignment.center,
                    child: const Text('Menly', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phân loại: ${item.color} / Size ${item.size}',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatPrice(item.product.price),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'x${item.quantity}',
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 13),
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

  Widget _buildShippingMethodCard(CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() => _shippingMethod = 'standard');
              _recalculateShippingFee();
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _shippingMethod == 'standard' ? Colors.black87 : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: _shippingMethod == 'standard'
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black87),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Giao hàng tiêu chuẩn',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('2–4 ngày làm việc • 25.000 đ',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: () {
              setState(() => _shippingMethod = 'express');
              _recalculateShippingFee();
            },
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _shippingMethod == 'express' ? Colors.black87 : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: _shippingMethod == 'express'
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black87),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Giao hàng hỏa tốc',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Trong ngày hoặc 24h • 45.000 đ',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (cart.shippingNote != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.green.shade50,
              child: Text(
                cart.shippingNote!,
                style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoucherCard(CartProvider cart) {
    final voucher = cart.appliedVoucher;
    final discount = _calculateDiscount(cart);

    if (voucher != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepOrange.shade200),
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.deepOrange),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${formatPrice(discount)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    voucher.title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                cart.removeVoucher();
                _recalculateShippingFee();
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _openVoucherSheet,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chọn hoặc nhập mã giảm giá Menly',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text('Chọn mã >', style: TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Option 1: COD
          InkWell(
            onTap: () => setState(() => _paymentMethod = 'cod'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _paymentMethod == 'cod' ? Colors.black87 : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: _paymentMethod == 'cod'
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black87),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Thanh toán khi nhận hàng (COD)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text(
                            'Thanh toán bằng tiền mặt cho nhân viên giao hàng khi nhận',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Option 2: VNPay
          InkWell(
            onTap: () => setState(() => _paymentMethod = 'vnpay'),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _paymentMethod == 'vnpay' ? const Color(0xFF005BAA) : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: _paymentMethod == 'vnpay'
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF005BAA)),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Cổng thanh toán VNPay',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF005BAA),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Sandbox',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                            'Quét mã VNPAY-QR, thẻ ATM nội địa hoặc thẻ Visa/Master',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
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

  Widget _buildSummaryCard(CartProvider cart) {
    final subtotal = _currentSubtotal;
    final discount = _calculateDiscount(cart);
    final shippingFee = cart.shippingFee;
    final total = _calculateTotal(cart);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng tiền hàng:',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              Text(formatPrice(subtotal),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Phí vận chuyển:',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              Text(
                shippingFee == 0 ? 'Miễn phí' : formatPrice(shippingFee),
                style: TextStyle(
                  color: shippingFee == 0 ? Colors.green : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (cart.appliedVoucher != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Giảm giá voucher (${cart.appliedVoucher!.code}):',
                    style: TextStyle(
                        color: Colors.deepOrange.shade600, fontSize: 13)),
                Text('-${formatPrice(discount)}',
                    style: TextStyle(
                        color: Colors.deepOrange.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng thanh toán:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                formatPrice(total),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
