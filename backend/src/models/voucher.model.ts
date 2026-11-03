import { supabase } from '../config/supabase.js';

export interface VoucherRow {
  id: string;
  code: string;
  title: string;
  discount_type: 'percentage' | 'fixed_amount';
  discount_value: number;
  min_order_value: number;
  max_discount?: number;
  end_date: string;
  is_active: boolean;
}

export interface ApplyVoucherResult {
  valid: boolean;
  voucher?: VoucherRow;
  discountAmount: number;
  message: string;
}

// Danh sach voucher mac dinh cua he thong Menly
const SYSTEM_VOUCHERS: VoucherRow[] = [
  {
    id: 'vouch-1',
    code: 'MENLY10',
    title: 'Giảm 10% tối đa 50.000 đ',
    discount_type: 'percentage',
    discount_value: 10,
    min_order_value: 200000,
    max_discount: 50000,
    end_date: new Date(Date.now() + 30 * 86400000).toISOString(),
    is_active: true,
  },
  {
    id: 'vouch-2',
    code: 'MENLY50',
    title: 'Giảm 50.000 đ cho đơn từ 400.000 đ',
    discount_type: 'fixed_amount',
    discount_value: 50000,
    min_order_value: 400000,
    end_date: new Date(Date.now() + 30 * 86400000).toISOString(),
    is_active: true,
  },
  {
    id: 'vouch-3',
    code: 'FREESHIP',
    title: 'Miễn phí vận chuyển toàn quốc',
    discount_type: 'fixed_amount',
    discount_value: 25000,
    min_order_value: 300000,
    end_date: new Date(Date.now() + 30 * 86400000).toISOString(),
    is_active: true,
  },
  {
    id: 'vouch-4',
    code: 'WELCOME20',
    title: 'Giảm 20.000 đ cho khách hàng mới',
    discount_type: 'fixed_amount',
    discount_value: 20000,
    min_order_value: 150000,
    end_date: new Date(Date.now() + 60 * 86400000).toISOString(),
    is_active: true,
  },
];

// Lop truy cap du lieu cho: Ma giam gia
export class VoucherModel {
  protected db = supabase;

  /** Lay danh sach tat ca voucher dang hoat dong */
  async listActive(): Promise<VoucherRow[]> {
    // Thu lay tu DB truoc, neu loi thi dung system vouchers
    try {
      const { data, error } = await this.db
        .from('vouchers')
        .select('*')
        .eq('is_active', true)
        .gt('end_date', new Date().toISOString())
        .order('created_at', { ascending: false });
      if (!error && data && data.length > 0) {
        return data as VoucherRow[];
      }
    } catch (_) {}
    return SYSTEM_VOUCHERS;
  }

  /** Kiem tra va tinh toan gia tri giam gia cua 1 ma */
  async applyVoucher(code: string, subtotal: number): Promise<ApplyVoucherResult> {
    const cleanCode = code.trim().toUpperCase();

    // Thu tim trong DB truoc
    let voucher: VoucherRow | undefined;
    try {
      const { data } = await this.db
        .from('vouchers')
        .select('*')
        .ilike('code', cleanCode)
        .eq('is_active', true)
        .single();
      if (data) voucher = data as VoucherRow;
    } catch (_) {}

    // Fallback system vouchers
    if (!voucher) {
      voucher = SYSTEM_VOUCHERS.find((v) => v.code.toUpperCase() === cleanCode);
    }

    if (!voucher) {
      return { valid: false, discountAmount: 0, message: 'Mã giảm giá không tồn tại hoặc đã hết hạn' };
    }

    if (new Date(voucher.end_date) < new Date()) {
      return { valid: false, discountAmount: 0, message: 'Mã giảm giá đã hết hạn' };
    }

    if (subtotal < voucher.min_order_value) {
      return {
        valid: false,
        discountAmount: 0,
        message: `Đơn hàng tối thiểu ${voucher.min_order_value.toLocaleString('vi-VN')} đ để dùng mã này`,
      };
    }

    let discountAmount = 0;
    if (voucher.discount_type === 'percentage') {
      discountAmount = Math.round((subtotal * voucher.discount_value) / 100);
      if (voucher.max_discount) {
        discountAmount = Math.min(discountAmount, voucher.max_discount);
      }
    } else {
      discountAmount = voucher.discount_value;
    }

    return {
      valid: true,
      voucher,
      discountAmount,
      message: `Áp dụng thành công! Giảm ${discountAmount.toLocaleString('vi-VN')} đ`,
    };
  }
}
