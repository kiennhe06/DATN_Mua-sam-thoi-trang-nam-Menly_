import crypto from 'node:crypto';
import { supabase } from '../config/supabase.js';
import { env } from '../config/env.js';
import type { CreatePaymentUrlInput } from '../validators/payment.validator.js';

export class PaymentError extends Error {
  statusCode: number;
  constructor(message: string, statusCode = 400) {
    super(message);
    this.name = 'PaymentError';
    this.statusCode = statusCode;
  }
}

export interface PaymentUrlResult {
  paymentUrl: string;
  txnRef: string;
  amount: number;
  orderId?: string;
  orderCode?: string;
}

export interface VNPayIpnResponse {
  RspCode: string;
  Message: string;
}

export interface VNPayReturnResult {
  isSuccess: boolean;
  isValidChecksum: boolean;
  responseCode: string;
  message: string;
  txnRef: string;
  amount: number;
  bankCode?: string;
  transactionNo?: string;
  payDate?: string;
  orderId?: string;
  orderCode?: string;
}

export const VNPAY_RESPONSE_MESSAGES: Record<string, string> = {
  '00': 'Giao dịch thành công',
  '07': 'Trừ tiền thành công. Giao dịch bị nghi ngờ (liên quan tới lừa đảo, bất thường)',
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

/**
 * Định dạng thời gian theo chuẩn VNPay (YYYYMMDDHHmmss) múi giờ GMT+7
 */
export function formatVnpayDate(date = new Date()): string {
  const gmt7Date = new Date(date.getTime() + 7 * 60 * 60 * 1000);
  const yyyy = gmt7Date.getUTCFullYear().toString();
  const MM = String(gmt7Date.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(gmt7Date.getUTCDate()).padStart(2, '0');
  const HH = String(gmt7Date.getUTCHours()).padStart(2, '0');
  const mm = String(gmt7Date.getUTCMinutes()).padStart(2, '0');
  const ss = String(gmt7Date.getUTCSeconds()).padStart(2, '0');
  return `${yyyy}${MM}${dd}${HH}${mm}${ss}`;
}

/**
 * Sắp xếp các tham số VNPay theo thứ tự alphabet và mã hóa URL
 */
export function sortObject(obj: Record<string, any>): Record<string, string> {
  const sorted: Record<string, string> = {};
  const keys = Object.keys(obj).sort();
  for (const key of keys) {
    if (obj[key] !== undefined && obj[key] !== null && obj[key] !== '') {
      sorted[key] = encodeURIComponent(String(obj[key])).replace(/%20/g, '+');
    }
  }
  return sorted;
}

/**
 * Tạo chữ ký HMAC-SHA512
 */
export function createHmacSha512(data: string, secretKey: string): string {
  return crypto.createHmac('sha512', secretKey).update(Buffer.from(data, 'utf-8')).digest('hex');
}

/**
 * Kiểm tra tính hợp lệ của chữ ký phản hồi từ VNPay
 */
export function verifyVnpayChecksum(
  query: Record<string, any>,
  secretKey: string
): { isValid: boolean; secureHash: string; calculatedHash: string } {
  const secureHash = String(query['vnp_SecureHash'] || query['vnp_securehash'] || '');

  const cleanParams: Record<string, any> = {};
  for (const [key, value] of Object.entries(query)) {
    if (
      key.startsWith('vnp_') &&
      key !== 'vnp_SecureHash' &&
      key !== 'vnp_SecureHashType' &&
      value !== undefined &&
      value !== null &&
      value !== ''
    ) {
      cleanParams[key] = value;
    }
  }

  const sorted = sortObject(cleanParams);
  const signData = Object.keys(sorted)
    .map((k) => `${k}=${sorted[k]}`)
    .join('&');

  const calculatedHash = createHmacSha512(signData, secretKey);
  const isValid = calculatedHash.toLowerCase() === secureHash.toLowerCase();

  return { isValid, secureHash, calculatedHash };
}

// Lop truy cap du lieu va xu ly thanh toan VNPay Sandbox
export interface CreatePaymentUrlParams {
  orderId?: string;
  orderCode?: string;
  amount: number;
  orderInfo?: string;
  bankCode?: string;
  locale?: 'vn' | 'en';
}

export class PaymentModel {
  protected db = supabase;

  /**
   * Tạo URL thanh toán VNPay Sandbox với mã bảo mật HmacSHA512
   */
  async createPaymentUrl(input: CreatePaymentUrlParams, clientIp = '127.0.0.1'): Promise<PaymentUrlResult> {
    const { amount, locale = 'vn', bankCode } = input;
    let paymentAmount = amount;
    let orderId = input.orderId;
    let orderCode = input.orderCode;

    // 1. Kiểm tra đơn hàng nếu có trong database
    if (orderId || orderCode) {
      let query = this.db.from('orders').select('id, code, total, status');
      if (orderId) {
        query = query.eq('id', orderId);
      } else if (orderCode) {
        query = query.eq('code', orderCode);
      }

      const { data: order } = await query.maybeSingle();
      if (order) {
        orderId = order.id;
        orderCode = order.code;

        if (order.status === 'paid' || order.status === 'completed') {
          throw new PaymentError('Đơn hàng này đã được thanh toán trước đó', 400);
        }

        // Luôn đồng bộ chính xác số tiền cần thanh toán theo tổng tiền đơn hàng đã lưu (đã trừ voucher)
        if (typeof order.total === 'number' && order.total > 0) {
          paymentAmount = order.total;
        }
      }
    }

    // 2. Tạo mã giao dịch duy nhất txnRef
    const timestamp = Date.now();
    const txnRef = orderCode ? `${orderCode}_${timestamp}` : `MENLY_${timestamp}`;

    // 3. Lưu giao dịch pending vào bảng payments nếu có orderId hợp lệ
    if (orderId) {
      try {
        await this.db.from('payments').insert({
          order_id: orderId,
          provider: 'vnpay',
          txn_ref: txnRef,
          amount: paymentAmount,
          status: 'pending',
        });
      } catch {
        // Bỏ qua lỗi khóa ngoại nếu orderId kiểm thử không tồn tại
      }
    }

    // 4. Chuẩn bị tham số theo đúng định dạng VNPay 2.1.0
    const vnpParams: Record<string, string> = {
      vnp_Version: '2.1.0',
      vnp_Command: 'pay',
      vnp_TmnCode: env.vnpay.tmnCode,
      vnp_Locale: locale,
      vnp_CurrCode: 'VND',
      vnp_TxnRef: txnRef,
      vnp_OrderInfo: input.orderInfo || `Thanh toan don hang ${orderCode || txnRef}`,
      vnp_OrderType: 'other',
      vnp_Amount: String(paymentAmount * 100), // VNPay yêu cầu nhân 100
      vnp_ReturnUrl: env.vnpay.returnUrl,
      vnp_IpAddr: clientIp === '::1' ? '127.0.0.1' : clientIp,
      vnp_CreateDate: formatVnpayDate(),
    };

    if (bankCode && bankCode.trim() !== '') {
      vnpParams.vnp_BankCode = bankCode.trim();
    }

    // 5. Sắp xếp tham số & tạo chữ ký HmacSHA512
    const sorted = sortObject(vnpParams);
    const signData = Object.keys(sorted)
      .map((k) => `${k}=${sorted[k]}`)
      .join('&');

    const secureHash = createHmacSha512(signData, env.vnpay.hashSecret);
    const paymentUrl = `${env.vnpay.url}?${signData}&vnp_SecureHash=${secureHash}`;

    return {
      paymentUrl,
      txnRef,
      amount: paymentAmount,
      orderId,
      orderCode,
    };
  }

  /**
   * Xử lý IPN (Instant Payment Notification) từ máy chủ VNPay
   * Quy chuẩn trả về theo chuẩn tài liệu VNPay: { RspCode: string, Message: string }
   */
  async processIpn(query: Record<string, any>): Promise<VNPayIpnResponse> {
    // 1. Kiểm tra chữ ký HmacSHA512
    const { isValid } = verifyVnpayChecksum(query, env.vnpay.hashSecret);
    if (!isValid) {
      return { RspCode: '97', Message: 'Invalid Checksum' };
    }

    const txnRef = String(query['vnp_TxnRef'] || '');
    const vnpAmount = Number(query['vnp_Amount'] || 0) / 100;
    const responseCode = String(query['vnp_ResponseCode'] || '');
    const transactionNo = String(query['vnp_TransactionNo'] || '');
    const bankCode = String(query['vnp_BankCode'] || '');
    const isSuccess = responseCode === '00';

    // 2. Tra cứu giao dịch trong bảng payments
    const { data: payment } = await this.db
      .from('payments')
      .select('id, order_id, amount, status')
      .eq('txn_ref', txnRef)
      .maybeSingle();

    if (!payment) {
      // Thử tìm theo order_id hoặc code nếu txnRef chứa mã đơn
      const orderCodeFromTxn = txnRef.includes('_') ? txnRef.split('_')[0] : txnRef;
      const { data: order } = await this.db
        .from('orders')
        .select('id, code, total, status')
        .eq('code', orderCodeFromTxn)
        .maybeSingle();

      if (!order) {
        return { RspCode: '01', Message: 'Order not found' };
      }

      if (order.status === 'paid' || order.status === 'completed') {
        return { RspCode: '02', Message: 'Order already confirmed' };
      }

      // Mot lan dat hang co the sinh nhieu don (moi san pham mot don) nhung
      // khach chi tra tien MOT LAN cho ca nhom. Phai cong tong ca nhom roi moi
      // doi chieu, neu khong cong thanh toan se bao sai so tien.
      const idsCungNhom = await this.layIdCungLanDat(order.id);
      const { data: donCungNhom } = await this.db
        .from('orders')
        .select('id, total')
        .in('id', idsCungNhom);
      const tongCaNhom = (donCungNhom ?? []).reduce(
        (tong, d) => tong + Number(d.total ?? 0),
        0,
      );

      if (tongCaNhom !== vnpAmount) {
        return { RspCode: '04', Message: 'Invalid amount' };
      }

      // Cập nhật trạng thái đơn hàng khi thanh toán thành công
      if (isSuccess) {
        await this.db.from('orders').update({ status: 'paid' }).in('id', idsCungNhom);
        await this.db.from('order_status_history').insert(
          idsCungNhom.map((id) => ({
            order_id: id,
            from_status: 'pending_payment',
            to_status: 'paid',
            note: `VNPay IPN: Thanh toán thành công (Mã GD: ${transactionNo})`,
          })),
        );
      }

      return { RspCode: '00', Message: 'Confirm Success' };
    }

    // 3. Kiểm tra nếu giao dịch đã được xác nhận trước đó
    if (payment.status === 'paid') {
      return { RspCode: '02', Message: 'Order already confirmed' };
    }

    // 4. Kiểm tra số tiền khớp với dữ liệu hệ thống
    if (payment.amount !== vnpAmount) {
      return { RspCode: '04', Message: 'Invalid amount' };
    }

    // 5. Cập nhật bảng payments
    const paymentStatus = isSuccess ? 'paid' : 'failed';
    await this.db
      .from('payments')
      .update({
        status: paymentStatus,
        provider_txn_no: transactionNo,
        bank_code: bankCode,
        response_code: responseCode,
        raw: query,
        paid_at: isSuccess ? new Date().toISOString() : null,
      })
      .eq('id', payment.id);

    // 6. Cập nhật trạng thái đơn hàng trong bảng orders
    if (payment.order_id) {
      if (isSuccess) {
        await this.db.from('orders').update({ status: 'paid' }).eq('id', payment.order_id);
        await this.db.from('order_status_history').insert({
          order_id: payment.order_id,
          from_status: 'pending_payment',
          to_status: 'paid',
          note: `VNPay IPN: Thanh toán thành công (Mã GD: ${transactionNo})`,
        });
      }
    }

    return { RspCode: '00', Message: 'Confirm Success' };
  }

  /**
   * Xử lý callback khi người dùng được chuyển hướng về trang Return URL
   */
  async processReturn(query: Record<string, any>): Promise<VNPayReturnResult> {
    const { isValid } = verifyVnpayChecksum(query, env.vnpay.hashSecret);

    const txnRef = String(query['vnp_TxnRef'] || '');
    const amount = Number(query['vnp_Amount'] || 0) / 100;
    const responseCode = String(query['vnp_ResponseCode'] || '');
    const bankCode = query['vnp_BankCode'] ? String(query['vnp_BankCode']) : undefined;
    const transactionNo = query['vnp_TransactionNo'] ? String(query['vnp_TransactionNo']) : undefined;
    const payDate = query['vnp_PayDate'] ? String(query['vnp_PayDate']) : undefined;

    const isSuccess = isValid && responseCode === '00';
    const message = !isValid
      ? 'Chữ ký phản hồi không hợp lệ (Sai Checksum)'
      : VNPAY_RESPONSE_MESSAGES[responseCode] || 'Giao dịch không thành công';

    let orderId: string | undefined;
    let orderCode: string | undefined;

    if (isValid && txnRef) {
      // Đồng bộ cập nhật nếu IPN chưa chạy kịp
      const { data: payment } = await this.db
        .from('payments')
        .select('id, order_id, status')
        .eq('txn_ref', txnRef)
        .maybeSingle();

      if (payment) {
        orderId = payment.order_id;
        if (payment.status !== 'paid' && isSuccess) {
          await this.db
            .from('payments')
            .update({
              status: 'paid',
              provider_txn_no: transactionNo,
              bank_code: bankCode,
              response_code: responseCode,
              raw: query,
              paid_at: new Date().toISOString(),
            })
            .eq('id', payment.id);

          if (payment.order_id) {
            await this.db.from('orders').update({ status: 'paid' }).eq('id', payment.order_id);
          }
        }
      }

      const orderCodeFromTxn = txnRef.includes('_') ? txnRef.split('_')[0] : txnRef;
      const { data: order } = await this.db
        .from('orders')
        .select('id, code, status')
        .eq('code', orderCodeFromTxn)
        .maybeSingle();

      if (order) {
        orderId = orderId || order.id;
        orderCode = order.code;
        if (order.status !== 'paid' && isSuccess) {
          await this.db.from('orders').update({ status: 'paid' }).eq('id', order.id);
        }
      }
    }

    return {
      isSuccess,
      isValidChecksum: isValid,
      responseCode,
      message,
      txnRef,
      amount,
      bankCode,
      transactionNo,
      payDate,
      orderId,
      orderCode,
    };
  }
  /// Lay id cua tat ca don thuoc cung mot lan dat hang.
  ///
  /// Don dau tien lam don goc, cac don sau tro ve no qua parent_order_id.
  private async layIdCungLanDat(orderId: string): Promise<string[]> {
    const { data: don } = await this.db
      .from('orders')
      .select('id, parent_order_id')
      .eq('id', orderId)
      .maybeSingle();
    if (!don) return [orderId];

    const idGoc = don.parent_order_id ?? don.id;
    const { data: cacDon } = await this.db
      .from('orders')
      .select('id')
      .or(`id.eq.${idGoc},parent_order_id.eq.${idGoc}`);

    const ids = (cacDon ?? []).map((d) => d.id as string);
    return ids.length ? ids : [orderId];
  }

}
