import { supabase } from '../config/supabase.js';
import type { CalculateShippingFeeInput } from '../validators/shipping.validator.js';
import { VoucherModel } from './voucher.model.js';

// =========== INTERFACES CHO ĐƠN HÀNG ===========

export interface CreateOrderInput {
  userId: string;
  payment_method: 'cod' | 'vnpay';
  ship_name: string;
  ship_phone: string;
  ship_address: string;
  subtotal: number;
  shipping_fee: number;
  discount_amount?: number;
  total: number;
  voucher_code?: string;
  items: Array<{
    variant_id?: string;
    product_name: string;
    size: string;
    color: string;
    unit_price: number;
    quantity: number;
  }>;
}

export interface OrderRow {
  id: string;
  code: string;
  user_id: string;
  status: string;
  payment_method: string;
  is_paid?: boolean;
  subtotal: number;
  discount_amount?: number;
  shipping_fee: number;
  total: number;
  ship_name: string;
  ship_phone: string;
  ship_address: string;
  cancel_reason?: string;
  created_at: string;
  order_items?: OrderItemRow[];
}

export interface OrderItemRow {
  id: string;
  order_id: string;
  variant_id?: string;
  product_name: string;
  size: string;
  color: string;
  unit_price: number;
  quantity: number;
  thumbnail_url?: string;
}

export interface ShippingPolicy {
  standardBaseFee: number;
  expressBaseFee: number;
  freeShippingThreshold: number;
  supportedMethods: Array<{
    id: 'standard' | 'express';
    name: string;
    description: string;
    baseFee: number;
  }>;
  provincesFastDelivery: string[];
}

export interface ShippingFeeCalculationResult {
  shippingFee: number;
  originalFee: number;
  discount: number;
  isFreeShipping: boolean;
  freeShippingThreshold: number;
  amountNeededForFreeShipping: number;
  shippingMethod: 'standard' | 'express';
  estimatedDays: string;
  note: string;
}

export const DEFAULT_SHIPPING_POLICY: ShippingPolicy = {
  standardBaseFee: 25000,
  expressBaseFee: 45000,
  freeShippingThreshold: 499000,
  supportedMethods: [
    {
      id: 'standard',
      name: 'Giao hàng tiêu chuẩn',
      description: 'Giao hàng tận nơi toàn quốc qua các đơn vị vận chuyển uy tín (GHN, GHTK, Viettel Post)',
      baseFee: 25000,
    },
    {
      id: 'express',
      name: 'Giao hàng hỏa tốc',
      description: 'Nhận hàng nhanh trong ngày hoặc tối đa 24h đối với khu vực nội thành',
      baseFee: 45000,
    },
  ],
  provincesFastDelivery: [
    'hà nội',
    'ha noi',
    'hồ chí minh',
    'ho chi minh',
    'tphcm',
    'sài gòn',
    'đà nẵng',
    'da nang',
  ],
};

export class OrderModel {
  protected db = supabase;
  private voucherModel = new VoucherModel();

  /**
   * Lấy thông tin chính sách vận chuyển của shop
   */
  getShippingPolicy(): ShippingPolicy {
    return DEFAULT_SHIPPING_POLICY;
  }

  /**
   * Tính toán phí giao hàng (MC-DH3: Phí ship đồng giá hoặc Miễn phí Freeship)
   */
  calculateShippingFee(input: CalculateShippingFeeInput): ShippingFeeCalculationResult {
    const { subtotal, province = '', shippingMethod = 'standard', voucherCode = '' } = input;
    const policy = this.getShippingPolicy();

    const normalizedProvince = province.trim().toLowerCase();
    const isMajorCity = policy.provincesFastDelivery.some((city) =>
      normalizedProvince.includes(city)
    );

    // Xác định phí gốc dựa theo phương thức vận chuyển
    const originalFee = shippingMethod === 'express' ? policy.expressBaseFee : policy.standardBaseFee;

    // Kiểm tra điều kiện Freeship:
    // 1. Đơn hàng đạt giá trị tối thiểu (>= 499.000 VNĐ)
    // 2. Hoặc người dùng áp dụng mã Freeship hợp lệ (chứa 'FREESHIP' hoặc bắt đầu bằng 'FS')
    const isEligibleBySubtotal = subtotal >= policy.freeShippingThreshold;
    const normalizedVoucher = voucherCode.trim().toUpperCase();
    const isEligibleByVoucher =
      normalizedVoucher.includes('FREESHIP') || normalizedVoucher.startsWith('FS');

    const isFreeShipping = isEligibleBySubtotal || isEligibleByVoucher;

    let discount = 0;
    let shippingFee = originalFee;

    if (shippingMethod === 'standard') {
      if (isFreeShipping) {
        discount = originalFee;
        shippingFee = 0;
      }
    } else {
      // Đối với đơn Hỏa tốc, nếu đủ điều kiện freeship sẽ được trừ phí ship chuẩn (25.000đ)
      if (isFreeShipping) {
        discount = policy.standardBaseFee;
        shippingFee = Math.max(0, originalFee - discount);
      }
    }

    // Tính số tiền cần mua thêm để được Freeship (nếu chưa đạt)
    const amountNeededForFreeShipping = isFreeShipping
      ? 0
      : Math.max(0, policy.freeShippingThreshold - subtotal);

    // Dự kiến thời gian giao hàng
    let estimatedDays: string;
    if (shippingMethod === 'express') {
      estimatedDays = isMajorCity ? 'Trong ngày (4-8 giờ)' : '1–2 ngày';
    } else {
      estimatedDays = isMajorCity ? '1–2 ngày làm việc' : '2–4 ngày làm việc';
    }

    // Lời nhắn ghi chú hiển thị cho khách hàng
    let note = '';
    if (isFreeShipping) {
      if (isEligibleByVoucher) {
        note = `Bạn được miễn phí vận chuyển nhờ mã giảm giá ${normalizedVoucher}!`;
      } else {
        note = `Đơn hàng từ ${policy.freeShippingThreshold.toLocaleString('vi-VN')} đ được miễn phí vận chuyển toàn quốc!`;
      }
    } else {
      note = `Mua thêm ${amountNeededForFreeShipping.toLocaleString('vi-VN')} đ để được MIỄN PHÍ VẬN CHUYỂN toàn quốc!`;
    }

    return {
      shippingFee,
      originalFee,
      discount,
      isFreeShipping,
      freeShippingThreshold: policy.freeShippingThreshold,
      amountNeededForFreeShipping,
      shippingMethod,
      estimatedDays,
      note,
    };
  }

  /** Lam giau thong tin don hang: gan anh san pham va dong bo format */
  private enrichOrders(rows: any[]): OrderRow[] {
    return (rows || []).map((order) => {
      const items = (order.order_items || []).map((it: any) => {
        const prod = it.product_variants?.products;
        const thumbnail =
          prod?.thumbnail_url ||
          it.thumbnail_url ||
          'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=500&auto=format&fit=crop';
        return {
          id: it.id,
          order_id: it.order_id,
          variant_id: it.variant_id,
          product_name: it.product_name || prod?.name || 'Sản phẩm Menly',
          size: it.size || 'M',
          color: it.color || 'Đen',
          unit_price: it.unit_price,
          quantity: it.quantity,
          thumbnail_url: thumbnail,
        };
      });

      return {
        ...order,
        order_items: items,
        items,
      };
    });
  }

  // =========== CRUD ĐƠN HÀNG ===========

  private normalizePhoneNumber(value: string): string {
    const digits = value.replace(/\D/g, '');
    if (!digits) return '';
    return digits.startsWith('84') ? `0${digits.slice(2)}` : digits;
  }

  private normalizeOrderCode(value: string): string {
    return value
      .trim()
      .toUpperCase()
      .replace(/^MNL-?/i, '')
      .replace(/[^A-Z0-9]/g, '');
  }

  async findPublicOrderByCodeOrPhone(code?: string, phone?: string): Promise<OrderRow | null> {
    const normalizedCode = (code ?? '').trim();
    const normalizedPhone = this.normalizePhoneNumber(phone ?? '');

    if (!normalizedCode && !normalizedPhone) return null;

    try {
      const { data, error } = await this.db
        .from('orders')
        .select('*, order_items(*)')
        .order('created_at', { ascending: false });

      if (error) return null;

      const orders = (data ?? []) as OrderRow[];

      return (
        orders.find((order) => {
          const orderCode = this.normalizeOrderCode(order.code ?? '');
          const orderPhone = this.normalizePhoneNumber(String(order.ship_phone ?? ''));
          const matchCode = normalizedCode ? orderCode === this.normalizeOrderCode(normalizedCode) : false;
          const matchPhone = normalizedPhone ? orderPhone === normalizedPhone : false;

          if (normalizedCode && normalizedPhone) {
            return matchCode && matchPhone;
          }

          return matchCode || matchPhone;
        }) ?? null
      );
    } catch {
      return null;
    }
  }

  /** Tạo đơn hàng mới, lưu vào bảng orders + order_items trên Supabase */
  async createOrder(input: CreateOrderInput): Promise<OrderRow> {
    const code = `MNL-${Date.now() % 100000}`;
    const status = input.payment_method === 'vnpay' ? 'pending_payment' : 'processing';

    const { data: order, error } = await this.db
      .from('orders')
      .insert({
        code,
        user_id: input.userId,
        status,
        payment_method: input.payment_method,
        subtotal: input.subtotal,
        shipping_fee: input.shipping_fee,
        total: input.total,
        ship_name: input.ship_name,
        ship_phone: input.ship_phone,
        ship_address: input.ship_address,
      })
      .select()
      .single();

    if (error || !order) {
      throw new Error(error?.message ?? 'Không thể tạo đơn hàng');
    }

    // Lưu các items vào bảng order_items
    if (input.items.length > 0) {
      const itemRows = input.items.map((item) => ({
        order_id: order.id,
        variant_id: item.variant_id ?? null,
        product_name: item.product_name,
        size: item.size,
        color: item.color,
        unit_price: item.unit_price,
        quantity: item.quantity,
      }));
      const { error: itemError } = await this.db.from('order_items').insert(itemRows);
      if (itemError) {
        console.error('Loi khi luu order items:', itemError.message);
      }
    }

    // Luu voucher da ap dung vao bang order_vouchers (neu co) + tang so lan da dung
    if (input.voucher_code?.trim() && (input.discount_amount ?? 0) > 0) {
      const voucher = await this.voucherModel.findActiveByCode(input.voucher_code);
      if (voucher) {
        const { error: voucherErr } = await this.db.from('order_vouchers').insert({
          order_id: order.id,
          voucher_id: voucher.id,
          discount_amount: input.discount_amount,
        });
        if (voucherErr) {
          console.error('Khong luu duoc order_vouchers:', voucherErr.message);
        } else {
          await this.voucherModel.incrementUsage(voucher.id, voucher.used_count ?? 0);
        }
      }
    }

    const fullOrder = await this.getOrderById(order.id, input.userId);
    return fullOrder ?? (order as OrderRow);
  }

  /** Lấy danh sách đơn hàng của 1 user (kèm items) */
  async getOrdersByUser(userId: string): Promise<OrderRow[]> {
    const { data, error } = await this.db
      .from('orders')
      .select('*, order_items(*)')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw new Error(error.message);
    return (data ?? []) as OrderRow[];
  }

  /** Lấy chi tiết 1 đơn hàng (kèm items), kiểm tra quyền sở hữu */
  async getOrderById(orderId: string, userId: string): Promise<OrderRow | null> {
    const { data, error } = await this.db
      .from('orders')
      .select('*, order_items(*)')
      .eq('id', orderId)
      .eq('user_id', userId)
      .single();

    if (error || !data) return null;
    return data as OrderRow;
  }

  /** Hủy đơn hàng (chỉ khi status là processing hoặc pending_payment) */
  async cancelOrder(orderId: string, userId: string, reason: string): Promise<OrderRow> {
    // Kiểm tra tồn tại và quyền sở hữu
    const { data: existing, error: fetchErr } = await this.db
      .from('orders')
      .select('id, status, user_id')
      .eq('id', orderId)
      .eq('user_id', userId)
      .single();

    if (fetchErr || !existing) {
      throw new Error('Không tìm thấy đơn hàng');
    }

    const cancellable = ['processing', 'pending_payment', 'pending'];
    if (!cancellable.includes(existing.status)) {
      throw new Error('Đơn hàng không thể hủy ở trạng thái hiện tại');
    }

    const { data: updated, error: updateErr } = await this.db
      .from('orders')
      .update({ status: 'cancelled' })
      .eq('id', orderId)
      .select('*, order_items(*)')
      .single();

    if (updateErr || !updated) {
      throw new Error(updateErr?.message ?? 'Không thể hủy đơn hàng');
    }

    // Ghi lich su huy don (ly do luu o note; khong lam hong request neu bang chua co)
    const { error: historyErr } = await this.db.from('order_status_history').insert({
      order_id: orderId,
      from_status: existing.status,
      to_status: 'cancelled',
      changed_by: userId,
      note: reason,
    });
    if (historyErr) {
      console.error('Khong ghi duoc lich su huy don:', historyErr.message);
    }

    return updated as OrderRow;
  }

  // =========== ADMIN: QUAN LY DON HANG ===========

  /** [Admin] Danh sach tat ca don hang (kem items), loc theo trang thai, gioi han so luong */
  async adminListOrders(params: { status?: string; limit?: number }): Promise<OrderRow[]> {
    let query = this.db
      .from('orders')
      .select('*, order_items(*)')
      .order('created_at', { ascending: false });

    if (params.status) query = query.eq('status', params.status);
    if (params.limit && params.limit > 0) query = query.limit(params.limit);

    const { data, error } = await query;
    if (error) throw new Error(error.message);
    return (data ?? []) as OrderRow[];
  }

  /** [Admin] Doi trang thai 1 don hang + ghi lich su trang thai */
  async adminUpdateOrderStatus(
    orderId: string,
    toStatus: string,
    adminId: string,
    note?: string
  ): Promise<OrderRow | null> {
    const { data: current, error: fetchErr } = await this.db
      .from('orders')
      .select('id, status')
      .eq('id', orderId)
      .maybeSingle();

    if (fetchErr) throw new Error(fetchErr.message);
    if (!current) return null;

    const { data: updated, error: updateErr } = await this.db
      .from('orders')
      .update({ status: toStatus })
      .eq('id', orderId)
      .select('*, order_items(*)')
      .single();

    if (updateErr || !updated) {
      throw new Error(updateErr?.message ?? 'Không thể cập nhật trạng thái đơn hàng');
    }

    // Ghi lich su trang thai (khong lam hong request neu bang chua co)
    const { error: historyErr } = await this.db.from('order_status_history').insert({
      order_id: orderId,
      from_status: current.status,
      to_status: toStatus,
      changed_by: adminId || null,
      note: note ?? null,
    });
    if (historyErr) {
      console.error('Khong ghi duoc lich su trang thai don:', historyErr.message);
    }

    return updated as OrderRow;
  }
}

