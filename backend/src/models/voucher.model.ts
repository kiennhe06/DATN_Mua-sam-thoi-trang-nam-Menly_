import { supabase } from '../config/supabase.js';
import type {
  AdminVoucherInput,
  AdminVoucherUpdate,
} from '../validators/admin-voucher.validator.js';

export interface VoucherRow {
  id: string;
  code: string;
  title: string;
  discount_type: 'percentage' | 'fixed_amount';
  discount_value: number;
  min_order_value: number;
  max_discount?: number | null;
  usage_limit?: number;
  used_count?: number;
  start_date?: string;
  end_date: string;
  is_active: boolean;
  created_at?: string;
}

// Dang camelCase tra ve cho admin frontend
export interface AdminVoucher {
  id: string;
  code: string;
  title: string;
  discountType: 'percentage' | 'fixed_amount';
  discountValue: number;
  minOrderValue: number;
  maxDiscount: number | null;
  usageLimit: number;
  usedCount: number;
  startDate: string | null;
  endDate: string;
  isActive: boolean;
  createdAt: string | null;
}

export interface ApplyVoucherResult {
  valid: boolean;
  voucher?: VoucherRow;
  discountAmount: number;
  message: string;
}

/** Chuyen 1 dong voucher tu DB (snake_case) sang dang camelCase cho admin */
function toAdminVoucher(row: VoucherRow): AdminVoucher {
  return {
    id: row.id,
    code: row.code,
    title: row.title,
    discountType: row.discount_type,
    discountValue: row.discount_value,
    minOrderValue: row.min_order_value ?? 0,
    maxDiscount: row.max_discount ?? null,
    usageLimit: row.usage_limit ?? 0,
    usedCount: row.used_count ?? 0,
    startDate: row.start_date ?? null,
    endDate: row.end_date,
    isActive: row.is_active,
    createdAt: row.created_at ?? null,
  };
}

// Lop truy cap du lieu cho: Ma giam gia
export class VoucherModel {
  protected db = supabase;

  /** Lay danh sach voucher dang hoat dong (dung cho app khach) */
  async listActive(): Promise<VoucherRow[]> {
    const { data, error } = await this.db
      .from('vouchers')
      .select('*')
      .eq('is_active', true)
      .gt('end_date', new Date().toISOString())
      .order('created_at', { ascending: false });

    if (error) throw new Error(error.message);
    return (data ?? []) as VoucherRow[];
  }

  /** Tim 1 voucher con hieu luc theo ma (dung khi tao don) */
  async findActiveByCode(code: string): Promise<VoucherRow | null> {
    const { data, error } = await this.db
      .from('vouchers')
      .select('*')
      .ilike('code', code.trim())
      .eq('is_active', true)
      .maybeSingle();

    if (error || !data) return null;
    return data as VoucherRow;
  }

  /** Kiem tra va tinh toan gia tri giam gia cua 1 ma */
  async applyVoucher(code: string, subtotal: number): Promise<ApplyVoucherResult> {
    const voucher = await this.findActiveByCode(code.toUpperCase());

    if (!voucher) {
      return { valid: false, discountAmount: 0, message: 'Mã giảm giá không tồn tại hoặc đã hết hạn' };
    }

    const now = Date.now();
    const startDate = voucher.start_date ? Date.parse(voucher.start_date) : Number.NaN;
    const endDate = Date.parse(voucher.end_date);
    if (!Number.isFinite(startDate) || !Number.isFinite(endDate) || startDate > now || endDate < now) {
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

  /** Tang so lan da dung cua voucher len 1 (goi sau khi dat don thanh cong) */
  async incrementUsage(voucherId: string, current: number): Promise<void> {
    const { error } = await this.db
      .from('vouchers')
      .update({ used_count: current + 1 })
      .eq('id', voucherId);
    if (error) console.error('Khong cap nhat duoc used_count voucher:', error.message);
  }

  // =========== ADMIN: QUAN LY VOUCHER ===========

  /** [Admin] Danh sach tat ca voucher (ca het han / da tat) */
  async adminList(): Promise<AdminVoucher[]> {
    const { data, error } = await this.db
      .from('vouchers')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw new Error(error.message);
    return (data ?? []).map((row) => toAdminVoucher(row as VoucherRow));
  }

  /** [Admin] Tao voucher moi */
  async adminCreate(input: AdminVoucherInput): Promise<AdminVoucher> {
    const { data, error } = await this.db
      .from('vouchers')
      .insert({
        code: input.code,
        title: input.title,
        discount_type: input.discountType,
        discount_value: input.discountValue,
        min_order_value: input.minOrderValue,
        max_discount: input.maxDiscount ?? null,
        usage_limit: input.usageLimit,
        start_date: input.startDate ?? new Date().toISOString(),
        end_date: input.endDate,
        is_active: input.isActive,
      })
      .select('*')
      .single();

    if (error || !data) {
      if (error?.code === '23505') throw new Error('Mã giảm giá đã tồn tại');
      throw new Error(error?.message ?? 'Không thể tạo mã giảm giá');
    }
    return toAdminVoucher(data as VoucherRow);
  }

  /** [Admin] Cap nhat voucher */
  async adminUpdate(id: string, input: AdminVoucherUpdate): Promise<AdminVoucher | null> {
    const patch: Record<string, unknown> = {};
    if (input.code !== undefined) patch.code = input.code;
    if (input.title !== undefined) patch.title = input.title;
    if (input.discountType !== undefined) patch.discount_type = input.discountType;
    if (input.discountValue !== undefined) patch.discount_value = input.discountValue;
    if (input.minOrderValue !== undefined) patch.min_order_value = input.minOrderValue;
    if (input.maxDiscount !== undefined) patch.max_discount = input.maxDiscount;
    if (input.usageLimit !== undefined) patch.usage_limit = input.usageLimit;
    if (input.startDate !== undefined) patch.start_date = input.startDate;
    if (input.endDate !== undefined) patch.end_date = input.endDate;
    if (input.isActive !== undefined) patch.is_active = input.isActive;

    const { data, error } = await this.db
      .from('vouchers')
      .update(patch)
      .eq('id', id)
      .select('*')
      .maybeSingle();

    if (error) {
      if (error.code === '23505') throw new Error('Mã giảm giá đã tồn tại');
      throw new Error(error.message);
    }
    if (!data) return null;
    return toAdminVoucher(data as VoucherRow);
  }

  /** [Admin] Xoa voucher; neu da gan vao don hang (FK) thi chuyen sang tat (is_active=false) */
  async adminRemove(id: string): Promise<boolean> {
    const { error } = await this.db.from('vouchers').delete().eq('id', id);
    if (!error) return true;

    // Bi rang buoc khoa ngoai -> khong xoa cung duoc, chuyen sang vo hieu hoa
    if (error.code === '23503') {
      const { error: softErr } = await this.db
        .from('vouchers')
        .update({ is_active: false })
        .eq('id', id);
      if (softErr) throw new Error(softErr.message);
      return true;
    }
    throw new Error(error.message);
  }
}
