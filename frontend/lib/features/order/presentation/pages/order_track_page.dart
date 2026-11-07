import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:menly_app/core/utils/format.dart';
import 'package:menly_app/core/network/api_client.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tra cứu đơn hàng'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập mã đơn hoặc số điện thoại người nhận',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bạn có thể tra cứu nhanh tình trạng đơn hàng của mình mà không cần đăng nhập.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Mã đơn hàng',
                  hintText: 'Ví dụ: MNL-12345 hoặc 12345',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.confirmation_num_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  hintText: 'Ví dụ: 0901234567',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _searchOrder,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isLoading ? 'Đang tra cứu...' : 'Tra cứu đơn hàng'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              if (_order != null) ...[
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kết quả tra cứu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _order!.status == OrderStatus.canceled
                                    ? Colors.red.shade50
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _order!.status.label,
                                style: TextStyle(
                                  color: _order!.status == OrderStatus.canceled ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _infoRow('Mã đơn', _order!.code),
                        _infoRow('Người nhận', _order!.shipName),
                        _infoRow('SĐT', _order!.shipPhone),
                        _infoRow('Tổng tiền', formatPrice(_order!.total)),
                        _infoRow('Ngày đặt', _formatDate(_order!.createdAt)),
                        _infoRow('Địa chỉ', _order!.shipAddress),
                        const SizedBox(height: 16),
                        const Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        ..._order!.items.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 3),
                                    Text('${item.size} • ${item.color}', style: TextStyle(color: Colors.grey.shade700)),
                                  ],
                                ),
                              ),
                              Text('x${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
