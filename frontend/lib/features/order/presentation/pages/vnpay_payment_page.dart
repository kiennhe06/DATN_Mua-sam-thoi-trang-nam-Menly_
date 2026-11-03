import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/network/api_client.dart';
import 'package:menly_app/models/order_model.dart';
import 'package:menly_app/features/order/presentation/providers/order_provider.dart';

/// Man hinh thanh toan online VNPay su dung thu vien flutter_inappwebview: ^6.1.5 (AP-TT1)
/// Ket noi truc tiep voi Backend API moi:
/// - POST /api/v1/payments/vnpay/create (Tao link VNPay Sandbox HMAC-SHA512)
/// - GET /api/v1/payments/vnpay/return (Nhan ket qua dieu huong tra ve)
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
  String? _paymentUrl;
  String? _error;
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

  /// Goi API POST /api/v1/payments/vnpay/create de tao URL thanh toan THAT
  Future<void> _fetchPaymentUrl() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final payload = <String, dynamic>{
        'amount': widget.order.total,
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

      if (res.statusCode == 200 && res.data['paymentUrl'] != null) {
        setState(() {
          _paymentUrl = res.data['paymentUrl'].toString();
          _error = null;
          _isLoading = false;
        });
        return;
      }

      // Backend khong tra ve URL hop le -> bao loi that, KHONG mo phong
      setState(() {
        _paymentUrl = null;
        _error = 'Không khởi tạo được cổng thanh toán VNPay. Vui lòng thử lại.';
        _isLoading = false;
      });
    } catch (_) {
      // Loi mang/backend -> bao loi that, KHONG mo phong
      setState(() {
        _paymentUrl = null;
        _error =
            'Không kết nối được tới cổng thanh toán VNPay. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  /// Kiem tra va xu ly khi VNPay dieu huong ve trang ket qua
  bool _handleVNPayReturn(WebUri? uri) {
    if (uri == null) return false;
    final urlStr = uri.toString();

    // Kiem tra xem URL co chua tham so ket qua cua VNPay hay khong
    if (urlStr.contains('vnp_ResponseCode') ||
        urlStr.contains('vnpay_return') ||
        urlStr.contains('/vnpay/return')) {
      final responseCode = uri.queryParameters['vnp_ResponseCode'];
      final bankCode = uri.queryParameters['vnp_BankCode'];
      final transactionNo = uri.queryParameters['vnp_TransactionNo'];
      final txnRef = uri.queryParameters['vnp_TxnRef'] ?? widget.order.code;

      if (responseCode == '00') {
        _handleSuccess(
            bankCode: bankCode, transactionNo: transactionNo, txnRef: txnRef);
      } else if (responseCode != null) {
        _handleFailure(responseCode);
      }
      return true;
    }
    return false;
  }

  void _handleSuccess(
      {String? bankCode, String? transactionNo, String? txnRef}) {
    context.read<OrderProvider>().markAsPaidVNPay(widget.order.id);

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
                '${widget.order.total} đ',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005BAA)),
              ),
            ),
            const SizedBox(height: 12),
            Text('• Mã đơn hàng: ${widget.order.code}',
                style: const TextStyle(fontSize: 13)),
            if (txnRef != null)
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
                'Đơn hàng đã được xác nhận thanh toán thành công qua cổng VNPay.',
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

  void _handleFailure(String? code) {
    final msg = _vnpayMessages[code] ??
        'Giao dịch thanh toán qua VNPay không thành công.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thanh toán thất bại'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14)),
            if (code != null) ...[
              const SizedBox(height: 6),
              Text('(Mã lỗi VNPay: $code)',
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

  /// Giao dien loi that khi backend khong tra ve URL thanh toan VNPay
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Không khởi tạo được cổng thanh toán VNPay.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005BAA),
                foregroundColor: Colors.white,
              ),
              onPressed: _fetchPaymentUrl,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
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
        body: _isLoading
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
                          setState(() => _isLoading = true);
                          _handleVNPayReturn(url);
                        },
                        onLoadStop: (controller, url) {
                          setState(() => _isLoading = false);
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
                      if (_progress < 1.0)
                        LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.transparent,
                          color: Colors.amber,
                          minHeight: 3,
                        ),
                    ],
                  ),
      ),
    );
  }
}
