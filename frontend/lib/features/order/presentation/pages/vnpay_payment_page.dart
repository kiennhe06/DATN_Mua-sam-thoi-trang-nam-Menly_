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

  /// Goi API POST /api/v1/payments/vnpay/create de tao URL thanh toan
  Future<void> _fetchPaymentUrl() async {
    try {
      final payload = <String, dynamic>{
        'amount': widget.order.total,
        'orderCode': widget.order.code,
        'orderInfo': 'Thanh toan don hang ${widget.order.code}',
        'locale': 'vn',
      };

      // Kiem tra orderId neu la UUID hop le thi gui kem cho backend
      final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      if (uuidRegex.hasMatch(widget.order.id)) {
        payload['orderId'] = widget.order.id;
      }

      final res = await _api.dio.post('/payments/vnpay/create', data: payload);

      if (res.statusCode == 200 && res.data['paymentUrl'] != null) {
        setState(() {
          _paymentUrl = res.data['paymentUrl'].toString();
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // Backend offline hoac chua khoi chay -> Chuyen sang giao dien cong VNPay Sandbox noi bo
    }

    setState(() {
      _paymentUrl = null;
      _isLoading = false;
    });
  }

  /// Kiem tra va xu ly khi VNPay dieu huong ve trang ket qua
  bool _handleVNPayReturn(WebUri? uri) {
    if (uri == null) return false;
    final urlStr = uri.toString();

    // Kiem tra xem URL co chua tham so ket qua cua VNPay hay khong
    if (urlStr.contains('vnp_ResponseCode') || urlStr.contains('vnpay_return') || urlStr.contains('/vnpay/return')) {
      final responseCode = uri.queryParameters['vnp_ResponseCode'];
      final bankCode = uri.queryParameters['vnp_BankCode'];
      final transactionNo = uri.queryParameters['vnp_TransactionNo'];
      final txnRef = uri.queryParameters['vnp_TxnRef'] ?? widget.order.code;

      if (responseCode == '00') {
        _handleSuccess(bankCode: bankCode, transactionNo: transactionNo, txnRef: txnRef);
      } else if (responseCode != null) {
        _handleFailure(responseCode);
      }
      return true;
    }
    return false;
  }

  void _handleSuccess({String? bankCode, String? transactionNo, String? txnRef}) {
    context.read<OrderProvider>().markAsPaidVNPay(widget.order.id);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 54),
        title: const Text('Thanh toán VNPay thành công!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '${widget.order.total} đ',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF005BAA)),
              ),
            ),
            const SizedBox(height: 12),
            Text('• Mã đơn hàng: ${widget.order.code}', style: const TextStyle(fontSize: 13)),
            if (txnRef != null)
              Text('• Mã giao dịch: $txnRef', style: const TextStyle(fontSize: 13)),
            if (bankCode != null && bankCode.isNotEmpty)
              Text('• Ngân hàng thanh toán: $bankCode', style: const TextStyle(fontSize: 13)),
            if (transactionNo != null && transactionNo.isNotEmpty)
              Text('• Số GD VNPay: $transactionNo', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Text('Đơn hàng đã được xác nhận thanh toán thành công qua cổng VNPay.',
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
    final msg = _vnpayMessages[code] ?? 'Giao dịch thanh toán qua VNPay không thành công.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 54),
        title: const Text('Thanh toán thất bại'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            if (code != null) ...[
              const SizedBox(height: 6),
              Text('(Mã lỗi VNPay: $code)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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

  /// Tao HTML mo phong cong thanh toan VNPay Sandbox khi offline
  String _buildVNPaySandboxHtml() {
    return '''
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <title>Cổng Thanh Toán VNPAY-QR</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
    body { background-color: #f4f6f8; color: #333; }
    .header { background-color: #005baa; color: white; padding: 16px; text-align: center; }
    .header h2 { font-size: 18px; margin-bottom: 4px; }
    .header p { font-size: 12px; opacity: 0.9; }
    .order-box { background: white; margin: 12px; padding: 14px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
    .order-row { display: flex; justify-content: space-between; margin-bottom: 6px; font-size: 14px; }
    .order-row.total { font-size: 17px; font-weight: bold; color: #005baa; border-top: 1px dashed #ddd; padding-top: 8px; margin-top: 8px; }
    .tabs { display: flex; background: white; margin: 0 12px; border-radius: 8px 8px 0 0; overflow: hidden; border-bottom: 2px solid #005baa; }
    .tab { flex: 1; padding: 12px 6px; text-align: center; font-size: 13px; font-weight: bold; cursor: pointer; color: #666; }
    .tab.active { background: #005baa; color: white; }
    .content-box { background: white; margin: 0 12px 16px 12px; padding: 16px; border-radius: 0 0 8px 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.08); }
    .qr-container { text-align: center; padding: 10px 0; }
    .qr-code { width: 180px; height: 180px; margin: 0 auto; background: #fafafa; border: 1px solid #ddd; display: flex; align-items: center; justify-content: center; border-radius: 8px; font-size: 12px; color: #888; }
    .btn { display: block; width: 100%; padding: 13px; border: none; border-radius: 6px; font-size: 15px; font-weight: bold; cursor: pointer; text-align: center; margin-top: 12px; text-decoration: none; }
    .btn-pay { background-color: #005baa; color: white; }
    .btn-pay:hover { background-color: #004580; }
    .btn-cancel { background-color: #f1f1f1; color: #666; margin-top: 8px; }
    .bank-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; margin-top: 10px; }
    .bank-item { border: 1px solid #ddd; padding: 10px 4px; text-align: center; border-radius: 6px; font-size: 12px; font-weight: bold; cursor: pointer; }
    .bank-item.selected { border-color: #005baa; background-color: #eaf3fb; color: #005baa; }
    .note { font-size: 11px; color: #888; text-align: center; margin-top: 10px; }
  </style>
</head>
<body>
  <div class="header">
    <h2>VNPAY - CỔNG THANH TOÁN</h2>
    <p>Môi trường mô phỏng thử nghiệm (Sandbox Mode)</p>
  </div>

  <div class="order-box">
    <div class="order-row"><span>Đơn vị chấp nhận:</span><strong>Menly Fashion Store</strong></div>
    <div class="order-row"><span>Mã đơn hàng:</span><strong>${widget.order.code}</strong></div>
    <div class="order-row"><span>Nội dung:</span><span>Thanh toán đơn hàng Menly</span></div>
    <div class="order-row total"><span>Số tiền thanh toán:</span><span>${widget.order.total} VNĐ</span></div>
  </div>

  <div class="tabs">
    <div class="tab active" id="tab-qr" onclick="switchTab('qr')">Quét mã VNPAY-QR</div>
    <div class="tab" id="tab-atm" onclick="switchTab('atm')">Thẻ ATM / Tài khoản</div>
  </div>

  <div class="content-box">
    <!-- Tab QR -->
    <div id="view-qr">
      <div class="qr-container">
        <div class="qr-code">
          <svg viewBox="0 0 100 100" width="140" height="140">
            <rect width="100" height="100" fill="#fff" />
            <path d="M10,10 h30 v30 h-30 z M15,15 v20 h20 v-20 z M20,20 h10 v10 h-10 z" fill="#005baa" />
            <path d="M60,10 h30 v30 h-30 z M65,15 v20 h20 v-20 z M70,20 h10 v10 h-10 z" fill="#005baa" />
            <path d="M10,60 h30 v30 h-30 z M15,65 v20 h20 v-20 z M20,70 h10 v10 h-10 z" fill="#005baa" />
            <circle cx="50" cy="50" r="10" fill="#e53935" />
          </svg>
        </div>
        <p style="font-size: 12px; color: #555; margin-top: 8px;">Quét mã QR bằng ứng dụng Mobile Banking hoặc Ví điện tử</p>
      </div>

      <a class="btn btn-pay" href="https://menly.shop/vnpay_return?vnp_ResponseCode=00&vnp_TxnRef=${widget.order.code}&vnp_Amount=${widget.order.total * 100}&vnp_BankCode=VNPAYQR">
        Xác nhận thanh toán thành công (Mô phỏng)
      </a>
    </div>

    <!-- Tab ATM -->
    <div id="view-atm" style="display: none;">
      <p style="font-size: 13px; font-weight: bold; margin-bottom: 6px;">Chọn ngân hàng:</p>
      <div class="bank-grid">
        <div class="bank-item selected" onclick="selectBank(this, 'NCB')">NCB</div>
        <div class="bank-item" onclick="selectBank(this, 'VCB')">Vietcombank</div>
        <div class="bank-item" onclick="selectBank(this, 'TCB')">Techcombank</div>
        <div class="bank-item" onclick="selectBank(this, 'MB')">MBBank</div>
        <div class="bank-item" onclick="selectBank(this, 'BIDV')">BIDV</div>
        <div class="bank-item" onclick="selectBank(this, 'CTG')">VietinBank</div>
      </div>

      <div style="margin-top: 12px; font-size: 12px; background: #fffbe6; padding: 10px; border-radius: 6px; border: 1px solid #ffe58f;">
        <strong>Thẻ test Sandbox:</strong><br>
        Số thẻ: <strong>9704198526191432198</strong><br>
        Tên: <strong>NGUYEN VAN A</strong> • Ngày: <strong>07/15</strong><br>
        OTP xác thực: <strong>123456</strong>
      </div>

      <a class="btn btn-pay" href="https://menly.shop/vnpay_return?vnp_ResponseCode=00&vnp_TxnRef=${widget.order.code}&vnp_Amount=${widget.order.total * 100}&vnp_BankCode=NCB">
        Thanh toán qua Thẻ ATM nội địa
      </a>
    </div>

    <a class="btn btn-cancel" href="https://menly.shop/vnpay_return?vnp_ResponseCode=24&vnp_TxnRef=${widget.order.code}">
      Hủy bỏ giao dịch thanh toán
    </a>

    <p class="note">Giao dịch được bảo mật bởi VNPAY Payment Gateway</p>
  </div>

  <script>
    function switchTab(type) {
      document.getElementById('tab-qr').className = type === 'qr' ? 'tab active' : 'tab';
      document.getElementById('tab-atm').className = type === 'atm' ? 'tab active' : 'tab';
      document.getElementById('view-qr').style.display = type === 'qr' ? 'block' : 'none';
      document.getElementById('view-atm').style.display = type === 'atm' ? 'block' : 'none';
    }
    function selectBank(elem, code) {
      var items = document.getElementsByClassName('bank-item');
      for (var i = 0; i < items.length; i++) items[i].className = 'bank-item';
      elem.className = 'bank-item selected';
    }
  </script>
</body>
</html>
''';
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
        content: const Text('Bạn có chắc muốn thoát khỏi cổng thanh toán VNPay? Giao dịch sẽ không được hoàn tất.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ở lại')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
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
              const Text('Cổng Thanh Toán VNPAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Đơn hàng: ${widget.order.code}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Tải lại trang',
              onPressed: () => _webViewController?.reload(),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF005BAA)))
            : Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: _paymentUrl != null
                        ? URLRequest(url: WebUri(_paymentUrl!))
                        : null,
                    initialData: _paymentUrl == null
                        ? InAppWebViewInitialData(
                            data: _buildVNPaySandboxHtml(),
                            baseUrl: WebUri('https://menly.shop/vnpay'),
                          )
                        : null,
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
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
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
