import { VoucherModel, type VoucherRow, type ApplyVoucherResult } from '../models/voucher.model.js';

// Lop xu ly nghiep vu cho: Ma giam gia
export class VoucherViewModel {
  private model = new VoucherModel();

  async list(): Promise<VoucherRow[]> {
    return this.model.listActive();
  }

  async apply(code: string, subtotal: number): Promise<ApplyVoucherResult> {
    if (!code?.trim()) throw new Error('Vui lòng nhập mã giảm giá');
    return this.model.applyVoucher(code, subtotal);
  }
}
