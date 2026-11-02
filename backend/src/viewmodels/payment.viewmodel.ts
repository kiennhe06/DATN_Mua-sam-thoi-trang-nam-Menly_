import {
  PaymentModel,
  type PaymentUrlResult,
  type VNPayIpnResponse,
  type VNPayReturnResult,
  type CreatePaymentUrlParams,
} from '../models/payment.model.js';

// Lop xu ly nghiep vu cho: Thanh toan VNPay
export class PaymentViewModel {
  private model = new PaymentModel();

  async createPaymentUrl(input: CreatePaymentUrlParams, clientIp = '127.0.0.1'): Promise<PaymentUrlResult> {
    return this.model.createPaymentUrl(input, clientIp);
  }

  async handleIpn(query: Record<string, any>): Promise<VNPayIpnResponse> {
    return this.model.processIpn(query);
  }

  async handleReturn(query: Record<string, any>): Promise<VNPayReturnResult> {
    return this.model.processReturn(query);
  }
}
