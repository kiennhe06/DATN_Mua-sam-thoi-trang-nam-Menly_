import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'order_success_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/address_model.dart';
import '../../../../models/cart_item_model.dart';
import '../../../address/presentation/pages/address_page.dart';
import '../../../address/presentation/providers/address_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../voucher/presentation/widgets/voucher_select_sheet.dart';
import '../providers/order_provider.dart';
import 'vnpay_payment_page.dart';

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
  final _addressCtrl = TextEditingController();

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
      _addressCtrl.text = defaultAddr.fullAddress;
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
          _addressCtrl.text = prefs.getString('last_ship_address') ?? '';
        }
      });
    }
  }

  void _recalculateShippingFee() {
    final cart = context.read<CartProvider>();
    final addrProv = context.read<AddressProvider>();
    final province = addrProv.selectedAddress?.province ?? '';
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
    final address = _addressCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
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

      // Xoa cac mon da mua khoi gio hang neu dat tu gio
      if (widget.customItems == null) {
        await cart.clearSelectedItems();
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (_paymentMethod == 'vnpay') {
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => VNPayPaymentPage(order: createdOrder),
          ),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderSuccessPage(order: createdOrder),
            ),
          );
        }
      } else {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lỗi đặt hàng: $e'), backgroundColor: Colors.red),
      );
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final addrProv = context.watch<AddressProvider>();
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
                  _buildAddressCard(addrProv.selectedAddress),
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
                          '$totalAmount đ',
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

  Widget _buildAddressCard(AddressModel? selectedAddr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
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
          TextField(
            controller: _addressCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Địa chỉ nhận hàng chi tiết',
              hintText:
                  'Số nhà, tên đường, phường/xã, quận/huyện, tỉnh/thành...',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ],
      ),
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
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.product.thumbnailUrl,
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
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
                          '${item.product.price} đ',
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
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-$discount đ',
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
                                borderRadius: BorderRadius.circular(4),
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
              Text('$subtotal đ',
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
                shippingFee == 0 ? 'Miễn phí' : '$shippingFee đ',
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
                Text('-$discount đ',
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
                '$total đ',
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
