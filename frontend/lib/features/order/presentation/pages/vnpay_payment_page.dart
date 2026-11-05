import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/network/api_client.dart';
import 'package:menly_app/core/utils/format.dart';
import 'package:menly_app/features/order/data/models/order_model.dart';
import 'package:menly_app/features/order/presentation/providers/order_provider.dart';

/// Man hinh thanh toan online VNPay su dung flutter_inappwebview (AP-TT1)
/// Dong bo truc tiep voi Backend API:
/// - POST /api/v1/payments/vnpay/create (Tao URL thanh toan VNPay Sandbox voi chu ky HmacSHA512)
/// - GET /api/v1/payments/vnpay/return (Xac thuc chu ky & cap nhat trang thai don hang)
class VNPayPaymentPage extends StatefulWidget {
  final OrderModel order;

  const VNPayPaymentPage({super.key, required this.order});

  @override
  State<VNPayPaymentPage> createState() => _VNPayPaymentPageState();
}

class _VNPayPaymentPageState extends State<VNPayPaymentPage> {
  InAppWebViewController? _webViewController;
  double _progress = 0;
  bool _isLoading = true;
  bool _isVerifying = false;
  bool _hasHandledResult = false;
  String? _paymentUrl;
  String? _error;
  bool _paymentResultHandled = false;
  final ApiClient _api = ApiClient();

  final InAppWebViewSettings _settings = InAppWebViewSettings(
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    javaScriptEnabled: true,
    domStorageEnabled: true,
    transparentBackground: true,
    supportZoom: false,
  );

  static const Map<String, String> _vnpayMessages = {
    '00': 'Giao dịch thành công',
    '07': 'Trừ tiền thành công. Giao dịch bị nghi ngờ bất thường',
    '09': 'Thẻ/Tài khoản chưa đăng ký dịch vụ InternetBanking',
    '10': 'Xác thực thông tin thẻ/tài khoản không đúng quá 3 lần',
    '11': 'Đã hết hạn chờ thanh toán',
    '12': 'Thẻ/Tài khoản của khách hàng bị khóa',
    '13': 'Quý khách nhập sai mật khẩu xác thực OTP',
    '24': 'Khách hàng hủy giao dịch thanh toán',
    '51': 'Tài khoản không đủ số dư để thực hiện giao dịch',
    '65': 'Tài khoản đã vượt quá hạn mức giao dịch trong ngày',
    '75': 'Ngân hàng thanh toán đang bảo trì',
    '79': 'Khách hàng nhập sai mật khẩu thanh toán quá số lần quy định',
    '99': 'Lỗi không xác định từ cổng VNPay',
  };

  @override
  void initState() {
    super.initState();
    _fetchPaymentUrl();
  }

  /// Goi API POST /api/v1/payments/vnpay/create de tao URL thanh toan VNPay
  Future<void> _fetchPaymentUrl() async {
    setState(() {
      _isLoading = true;
      _isVerifying = false;
      _hasHandledResult = false;
      _error = null;
    });

    final amount = widget.order.total.toInt();
    if (amount < 1000) {
      setState(() {
        _paymentUrl = null;
        _error = 'Số tiền thanh toán tối thiểu qua VNPay là 1.000 đ.';
        _isLoading = false;
      });
      return;
    }

    try {
      final payload = <String, dynamic>{
        'amount': amount,
        'orderCode': widget.order.code,
        'orderInfo': 'Thanh toan don hang ${widget.order.code}',
        'locale': 'vn',
      };

      // Kiem tra orderId neu la UUID hop le thi gui kem cho backend
      final uuidRegex = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      if (uuidRegex.hasMatch(widget.order.id)) {
        payload['orderId'] = widget.order.id;
      }

      final res = await _api.dio.post('/payments/vnpay/create', data: payload);

      if (res.statusCode == 200 && res.data != null) {
        final url = res.data['paymentUrl']?.toString() ??
            res.data['data']?['paymentUrl']?.toString();
        if (url != null && url.isNotEmpty) {
          setState(() {
            _paymentUrl = url;
            _error = null;
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _paymentUrl = null;
        _error = 'Không khởi tạo được cổng thanh toán VNPay. Vui lòng thử lại.';
        _isLoading = false;
      });
    } on DioException catch (e) {
      final backendError = e.response?.data?['error']?.toString();
      setState(() {
        _paymentUrl = null;
        _error = backendError ??
            'Không kết nối được tới máy chủ thanh toán. Vui lòng kiểm tra kết nối mạng.';
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _paymentUrl = null;
        _error =
            'Không kết nối được tới cổng thanh toán VNPay. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  /// Kiem tra va chan url callback khi VNPay dieu huong ve ket qua giao dich
  bool _handleVNPayReturn(WebUri? uri) {
    if (uri == null || _hasHandledResult) return false;
    final urlStr = uri.toString();

    final hasResponseParams = uri.queryParameters.containsKey('vnp_ResponseCode') ||
        urlStr.contains('vnp_ResponseCode=') ||
        urlStr.contains('/vnpay/return') ||
        urlStr.contains('vnpay_return');

    if (hasResponseParams) {
      _hasHandledResult = true;
      _processPaymentResult(uri);
      return true;
    }
    return false;
  }

  /// Xu ly ket qua tra ve: Goi Backend /payments/vnpay/return de xac thuc chu ky & cap nhat DB
  Future<void> _processPaymentResult(WebUri uri) async {
    setState(() {
      _isVerifying = true;
      _isLoading = true;
    });

    final queryParams = Map<String, dynamic>.from(uri.queryParameters);
    final responseCode = queryParams['vnp_ResponseCode']?.toString();
    final bankCode = queryParams['vnp_BankCode']?.toString();
    final transactionNo = queryParams['vnp_TransactionNo']?.toString();
    final txnRef = queryParams['vnp_TxnRef']?.toString() ?? widget.order.code;

    bool isSuccess = responseCode == '00';
    String message = _vnpayMessages[responseCode] ?? 'Giao dịch thanh toán hoàn tất';

    // Goi backend xac thuc chu ky checksum HmacSHA512 va cap nhat don hang trong database
    try {
      final res = await _api.dio.get(
        '/payments/vnpay/return',
        queryParameters: queryParams,
      );

      if (res.statusCode == 200 && res.data != null) {
        final data = res.data['data'] ?? res.data;
        if (data is Map<String, dynamic>) {
          if (data['isSuccess'] != null) {
            isSuccess = data['isSuccess'] == true;
          }
          if (data['message'] != null && data['message'].toString().isNotEmpty) {
            message = data['message'].toString();
          }
        }
      }
    } catch (_) {
      // Neu loi ket noi toi backend return, giu nguyen danh gia theo responseCode cua VNPay
    }

    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _isLoading = false;
    });

    if (isSuccess) {
      _handleSuccess(
        bankCode: bankCode,
        transactionNo: transactionNo,
        txnRef: txnRef,
      );
    } else {
      _handleFailure(responseCode, customMessage: message);
    }
  }

  void _handleSuccess(
      {String? bankCode, String? transactionNo, String? txnRef}) {
    final orderProv = context.read<OrderProvider>();
    orderProv.markAsPaidVNPay(widget.order.id);
    orderProv.loadOrders();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Thanh toán VNPay thành công!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                formatPrice(widget.order.total),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005BAA)),
              ),
            ),
            const SizedBox(height: 12),
            Text('• Mã đơn hàng: ${widget.order.code}',
                style: const TextStyle(fontSize: 13)),
            if (txnRef != null && txnRef.isNotEmpty)
              Text('• Mã giao dịch: $txnRef',
                  style: const TextStyle(fontSize: 13)),
            if (bankCode != null && bankCode.isNotEmpty)
              Text('• Ngân hàng thanh toán: $bankCode',
                  style: const TextStyle(fontSize: 13)),
            if (transactionNo != null && transactionNo.isNotEmpty)
              Text('• Số GD VNPay: $transactionNo',
                  style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Text(
                'Đơn hàng đã được xác nhận thanh toán thành công và đồng bộ tới hệ thống.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005BAA),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text('Xem đơn hàng'),
          ),
        ],
      ),
    );
  }

  void _handleFailure(String? code, {String? customMessage}) {
    final msg = customMessage ??
        _vnpayMessages[code] ??
        'Giao dịch thanh toán qua VNPay không thành công.';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(code == '24' ? 'Đã hủy giao dịch VNPay' : 'Thanh toán thất bại'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14)),
            if (code != null && code.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('(Mã phản hồi VNPay: $code)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _fetchPaymentUrl();
            },
            child: const Text('Thử lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black87,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, false);
            },
            child: const Text('Hủy bỏ'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_isVerifying) return false;
    if (_webViewController != null && await _webViewController!.canGoBack()) {
      await _webViewController!.goBack();
      return false;
    }
    if (!mounted) return false;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy phiên thanh toán?'),
        content: const Text(
            'Bạn có chắc muốn thoát khỏi cổng thanh toán VNPay? Giao dịch sẽ không được hoàn tất.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ở lại')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  /// Giao dien thong bao loi khi khong tao duoc URL thanh toan VNPay
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Text(
                '!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Không khởi tạo được cổng thanh toán VNPay.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005BAA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _fetchPaymentUrl,
              child: const Text('Thử lại'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context, false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF005BAA),
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cổng Thanh Toán VNPAY',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Đơn hàng: ${widget.order.code}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _webViewController?.reload(),
              child: const Text('Tải lại',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: _isLoading && !_isVerifying
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF005BAA)))
            : _paymentUrl == null
                ? _buildErrorView()
                : Stack(
                    children: [
                      InAppWebView(
                        initialUrlRequest:
                            URLRequest(url: WebUri(_paymentUrl!)),
                        initialSettings: _settings,
                        onWebViewCreated: (controller) {
                          _webViewController = controller;
                        },
                        onLoadStart: (controller, url) {
                          _handleVNPayReturn(url);
                        },
                        onLoadStop: (controller, url) {
                          _handleVNPayReturn(url);
                        },
                        onProgressChanged: (controller, progress) {
                          setState(() {
                            _progress = progress / 100;
                            if (progress == 100) _isLoading = false;
                          });
                        },
                        shouldOverrideUrlLoading:
                            (controller, navigationAction) async {
                          final uri = navigationAction.request.url;
                          if (_handleVNPayReturn(uri)) {
                            return NavigationActionPolicy.CANCEL;
                          }
                          return NavigationActionPolicy.ALLOW;
                        },
                      ),
                      if (_progress < 1.0 && !_isVerifying)
                        LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.transparent,
                          color: Colors.amber,
                          minHeight: 3,
                        ),
                      if (_isVerifying)
                        Container(
                          color: Colors.white.withValues(alpha: 0.92),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: Color(0xFF005BAA)),
                                SizedBox(height: 16),
                                Text(
                                  'Đang xác thực kết quả thanh toán...',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Vui lòng không đóng ứng dụng trong giây lát',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
