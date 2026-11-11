import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:menly_app/core/theme/app_colors.dart';
import 'package:menly_app/core/theme/app_spacing.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/utils/format.dart';
import 'package:menly_app/core/network/api_client.dart';
import 'package:menly_app/core/widgets/app_buttons.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';

class OrderTrackPage extends StatefulWidget {
  const OrderTrackPage({super.key});

  @override
  State<OrderTrackPage> createState() => _OrderTrackPageState();
}

class _OrderTrackPageState extends State<OrderTrackPage> {
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  OrderModel? _order;

  Future<void> _searchOrder() async {
    final code = _codeController.text.trim();
    final phone = _phoneController.text.trim();

    if (code.isEmpty && phone.isEmpty) {
      setState(() {
        _error = 'Vui lòng nhập mã đơn hàng hoặc số điện thoại để tra cứu.';
        _order = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _order = null;
    });

    try {
      final queryParameters = <String, dynamic>{};
      if (code.isNotEmpty) queryParameters['code'] = code;
      if (phone.isNotEmpty) queryParameters['phone'] = phone;

      final response = await ApiClient().dio.get('/orders/track', queryParameters: queryParameters);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        if (data is Map<String, dynamic>) {
          _order = OrderModel.fromJson(data);
        } else {
          _error = 'Không tìm thấy đơn hàng phù hợp.';
        }
      } else {
        _error = response.data?['error'] ?? 'Không tìm thấy đơn hàng phù hợp.';
      }
    } on DioException catch (e) {
      final serverMessage = e.response?.data is Map ? e.response?.data['error'] : null;
      _error = serverMessage ?? 'Không thể tra cứu đơn hàng. Vui lòng thử lại.';
    } catch (_) {
      _error = 'Không thể tra cứu đơn hàng. Vui lòng thử lại.';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Tra cứu đơn hàng'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhập mã đơn hoặc số điện thoại người nhận',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Bạn có thể tra cứu nhanh tình trạng đơn hàng của mình mà không cần đăng nhập.',
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Mã đơn hàng',
                  hintText: 'Ví dụ: MNL-12345 hoặc 12345',
                  prefixIcon: Icon(Icons.confirmation_num_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  hintText: 'Ví dụ: 0901234567',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                // Giu nguyen chu "Dang tra cuu..." nhu truoc, khong thay bang
                // vong xoay, de nguoi dung doc duoc may chu dang lam gi.
                label: _isLoading ? 'Đang tra cứu...' : 'Tra cứu đơn hàng',
                icon: Icons.search,
                onPressed: _isLoading ? null : _searchOrder,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: c.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: c.danger.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: c.danger, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              if (_order != null) ...[
                const SizedBox(height: AppSpacing.xxl),
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: c.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    side: BorderSide(color: c.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Kết quả tra cứu',
                                style: TextStyle(
                                    color: c.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Builder(builder: (context) {
                              // Don huy to mau canh bao, cac trang thai con lai
                              // deu la dien bien binh thuong nen to mau thanh cong.
                              final statusColor =
                                  _order!.status == OrderStatus.canceled
                                      ? c.danger
                                      : c.success;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusPill),
                                ),
                                child: Text(
                                  _order!.nhanTrangThai,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _infoRow(c, 'Mã đơn', _order!.code),
                        _infoRow(c, 'Người nhận', _order!.shipName),
                        _infoRow(c, 'SĐT', _order!.shipPhone),
                        _infoRow(c, 'Tổng tiền', formatPrice(_order!.total)),
                        _infoRow(c, 'Ngày đặt', _formatDate(_order!.createdAt)),
                        _infoRow(c, 'Địa chỉ', _order!.shipAddress),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Sản phẩm',
                            style: TextStyle(
                                color: c.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(height: AppSpacing.sm),
                        ..._order!.items.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: c.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName,
                                        style: TextStyle(
                                            color: c.textPrimary,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text('${item.size} • ${item.color}',
                                        style: TextStyle(color: c.textSecondary)),
                                  ],
                                ),
                              ),
                              Text('x${item.quantity}',
                                  style: TextStyle(
                                      color: c.textPrimary,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(AppColors c, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(color: c.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
