import { Router } from 'express';
import { validateBody } from '../../middlewares/validate.js';
import { PaymentViewModel } from '../../viewmodels/payment.viewmodel.js';
import { PaymentError } from '../../models/payment.model.js';
import { createPaymentUrlSchema } from '../../validators/payment.validator.js';

// Thanh toan VNPay routes
const router = Router();
const vm = new PaymentViewModel();

function handlePaymentError(
  error: unknown,
  res: import('express').Response,
  next: import('express').NextFunction
) {
  if (error instanceof PaymentError) {
    return res.status(error.statusCode).json({ error: error.message });
  }
  return next(error);
}

// POST /api/v1/payments/vnpay/create - Tạo URL thanh toán VNPay Sandbox với checksum HmacSHA512
router.post('/vnpay/create', validateBody(createPaymentUrlSchema), async (req, res, next) => {
  try {
    const rawIp =
      (req.headers['x-forwarded-for'] as string)?.split(',')[0] ||
      req.socket.remoteAddress ||
      '127.0.0.1';
    const clientIp = rawIp.replace('::ffff:', '').trim();

    const result = await vm.createPaymentUrl(req.body, clientIp);

    return res.json({
      message: 'Tạo URL thanh toán VNPay thành công',
      paymentUrl: result.paymentUrl,
      data: result,
    });
  } catch (error) {
    return handlePaymentError(error, res, next);
  }
});

// GET /api/v1/payments/vnpay/ipn - Xử lý IPN callback từ server VNPay (Webhook Server-to-Server)
router.get('/vnpay/ipn', async (req, res, next) => {
  try {
    const ipnResponse = await vm.handleIpn(req.query);
    return res.status(200).json(ipnResponse);
  } catch (error) {
    return handlePaymentError(error, res, next);
  }
});

// GET /api/v1/payments/vnpay/return - Nhận kết quả điều hướng trở lại từ VNPay sau khi khách hàng hoàn tất giao dịch
router.get('/vnpay/return', async (req, res, next) => {
  try {
    const result = await vm.handleReturn(req.query);

    // Nếu client chấp nhận HTML (trình duyệt web), có thể render giao diện thông báo
    const acceptsHtml = req.accepts('html', 'json') === 'html';
    if (acceptsHtml) {
      const statusClass = result.isSuccess ? 'success' : 'failed';
      const statusIcon = result.isSuccess ? '✔' : '✖';
      const title = result.isSuccess ? 'Thanh toán thành công!' : 'Thanh toán không thành công';

      return res.status(200).send(`
        <!DOCTYPE html>
        <html lang="vi">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>${title} - Menly</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: #f8fafc; color: #1e293b; }
            .card { background: white; padding: 2rem; border-radius: 12px; box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1); max-width: 450px; width: 90%; text-align: center; }
            .icon { font-size: 3rem; margin-bottom: 1rem; width: 64px; height: 64px; line-height: 64px; border-radius: 50%; margin: 0 auto 1rem; }
            .success .icon { background: #dcfce7; color: #16a34a; }
            .failed .icon { background: #fee2e2; color: #dc2626; }
            h2 { margin: 0 0 0.5rem; font-size: 1.5rem; }
            p { margin: 0.25rem 0; color: #64748b; font-size: 0.95rem; }
            .info-table { margin-top: 1.5rem; text-align: left; border-top: 1px solid #e2e8f0; padding-top: 1rem; }
            .info-row { display: flex; justify-content: space-between; margin-bottom: 0.5rem; font-size: 0.9rem; }
            .info-label { color: #64748b; }
            .info-val { font-weight: 600; color: #0f172a; }
          </style>
        </head>
        <body class="${statusClass}">
          <div class="card">
            <div class="icon">${statusIcon}</div>
            <h2>${title}</h2>
            <p>${result.message}</p>
            <div class="info-table">
              <div class="info-row"><span class="info-label">Mã giao dịch:</span><span class="info-val">${result.txnRef}</span></div>
              <div class="info-row"><span class="info-label">Số tiền:</span><span class="info-val">${result.amount.toLocaleString('vi-VN')} đ</span></div>
              ${result.bankCode ? `<div class="info-row"><span class="info-label">Ngân hàng:</span><span class="info-val">${result.bankCode}</span></div>` : ''}
              ${result.transactionNo ? `<div class="info-row"><span class="info-label">Mã GD VNPay:</span><span class="info-val">${result.transactionNo}</span></div>` : ''}
            </div>
          </div>
        </body>
        </html>
      `);
    }

    return res.json({
      message: result.message,
      data: result,
    });
  } catch (error) {
    return handlePaymentError(error, res, next);
  }
});

export default router;
