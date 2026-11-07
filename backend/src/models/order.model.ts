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
  idempotency_key?: string;
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

  private static readonly ORDER_WITH_ITEMS_SELECT =
    '*, order_items(*, product_variants(size, color, products(name, thumbnail_url)))';

  private realImageUrl(url: unknown): string {
    const value = String(url ?? '').trim();
    if (!value) return '';
    if (/unsplash|picsum|placeholder/i.test(value)) return '';
    return value;
  }

  /** Lam giau thong tin don hang: gan anh/size/mau that, khong dung anh gia */
  private enrichOrders(rows: any[]): OrderRow[] {
    return (rows || []).map((order) => {
      const items = (order.order_items || []).map((it: any) => {
        const variant = it.product_variants;
        const prod = variant?.products;
        const thumbnail = this.realImageUrl(prod?.thumbnail_url) || this.realImageUrl(it.thumbnail_url);
        return {
          id: it.id,
          order_id: it.order_id,
          variant_id: it.variant_id,
          product_name: it.product_name || prod?.name || '',
          size: it.size || variant?.size || '',
          color: it.color || variant?.color || '',
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
    if (!input.items.length || input.items.some((item) => !item.variant_id || !Number.isInteger(item.quantity) || item.quantity < 1)) {
      throw new Error('Sản phẩm hoặc số lượng đặt hàng không hợp lệ');
    }

    const { data: created, error } = await this.db.rpc('create_order', {
      p_user_id: input.userId,
      p_payment_method: input.payment_method,
      p_ship_name: input.ship_name,
      p_ship_phone: input.ship_phone,
      p_ship_address: input.ship_address,
      p_items: input.items.map((item) => ({ variant_id: item.variant_id, quantity: item.quantity })),
      p_voucher_code: input.voucher_code ?? null,
      p_idempotency_key: input.idempotency_key ?? null,
      p_shipping_fee: input.shipping_fee ?? 0,
    });
    if (error) throw new Error(error.message);

    const rpcOrder = Array.isArray(created) ? created[0] : created;
    if (!rpcOrder?.id) throw new Error('Backend không trả về mã đơn hàng vừa tạo');

    const order = await this.loadEnrichedOrder(rpcOrder.id);
    if (!order) throw new Error('Không tải được đơn hàng vừa tạo');

    const createdOrder = {
      ...order,
      discount_amount: Math.max(0, order.subtotal + order.shipping_fee - order.total),
    } as OrderRow;
    await this.notifyOrderUser(
      createdOrder,
      'Đặt hàng thành công',
      `Đơn hàng #${createdOrder.code} đã được tạo. Menly sẽ cập nhật khi đơn được xử lý.`,
    );
    return createdOrder;
  }

  /** Lấy danh sách đơn hàng của 1 user (kèm items) */
  async getOrdersByUser(userId: string): Promise<OrderRow[]> {
    const { data, error } = await this.db
      .from('orders')
      .select(OrderModel.ORDER_WITH_ITEMS_SELECT)
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw new Error(error.message);
    return this.enrichOrders(data ?? []);
  }

  /** Lấy chi tiết 1 đơn hàng (kèm items), kiểm tra quyền sở hữu */
  async getOrderById(orderId: string, userId: string): Promise<OrderRow | null> {
    return this.loadEnrichedOrder(orderId, userId);
  }

  private async loadEnrichedOrder(orderId: string, userId?: string): Promise<OrderRow | null> {
    let query = this.db.from('orders').select(OrderModel.ORDER_WITH_ITEMS_SELECT).eq('id', orderId);
    if (userId) query = query.eq('user_id', userId);
    const { data, error } = await query.maybeSingle();
    if (error || !data) return null;
    return this.enrichOrders([data])[0] ?? null;
  }

  /** Hủy đơn hàng (chỉ khi status là processing hoặc pending_payment) */
  async cancelOrder(orderId: string, userId: string, reason: string): Promise<OrderRow> {
    const { data, error } = await this.db.rpc('cancel_order', {
      p_order_id: orderId,
      p_user_id: userId,
      p_reason: reason,
      p_is_admin: false,
    });
    if (error) throw new Error(error.message);
    const cancelled = Array.isArray(data) ? data[0] : data;
    if (!cancelled?.id) throw new Error('Backend không trả về đơn hàng đã hủy');
    const cancelledOrder = await this.loadEnrichedOrder(orderId);
    if (!cancelledOrder) throw new Error('Không tải được đơn hàng đã hủy');
    await this.notifyOrderUser(
      cancelledOrder,
      'Đơn hàng đã hủy',
      `Đơn hàng #${cancelledOrder.code} đã được hủy.`,
    );
    return cancelledOrder;
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
    return this.enrichOrders((data ?? []) as OrderRow[]);
  }

  async staffUpdateOrderStatus(orderId: string, toStatus: string, staffId: string, note?: string) {
    const { data: current, error } = await this.db.from('orders')
      .select('status').eq('id', orderId).maybeSingle();
    if (error) throw new Error(error.message);
    if (!current) return null;

    const transitions: Record<string, string[]> = {
      paid: ['processing'],
      processing: ['shipping'],
      shipping: ['delivered'],
      delivered: ['completed'],
    };
    if (!transitions[current.status]?.includes(toStatus)) {
      throw new Error('Không thể chuyển đơn hàng từ trạng thái hiện tại');
    }

    return this.adminUpdateOrderStatus(orderId, toStatus, staffId, note);
  }

  /** [Admin] Doi trang thai 1 don hang + ghi lich su trang thai */
  async adminUpdateOrderStatus(
    orderId: string,
    toStatus: string,
    adminId: string,
    note?: string
  ): Promise<OrderRow | null> {
    if (toStatus === 'cancelled') {
      const { data, error } = await this.db.rpc('cancel_order', {
        p_order_id: orderId,
        p_user_id: adminId,
        p_reason: note ?? null,
        p_is_admin: true,
      });
      if (error) throw new Error(error.message);
      if (!data) return null;
      const { data: order, error: orderError } = await this.db.from('orders')
        .select('*, order_items(*)').eq('id', orderId).single();
      if (orderError) throw new Error(orderError.message);
      const cancelledOrder = order as OrderRow;
      await this.notifyOrderUser(
        cancelledOrder,
        'Đơn hàng đã hủy',
        `Đơn hàng #${cancelledOrder.code} đã được hủy.`,
      );
      return cancelledOrder;
    }

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

    const updatedOrder = updated as OrderRow;
    await this.notifyOrderUser(
      updatedOrder,
      this.orderStatusTitle(toStatus),
      `Đơn hàng #${updatedOrder.code} ${this.orderStatusBody(toStatus)}`,
    );
    return updatedOrder;
  }

  private orderStatusTitle(status: string): string {
    switch (status) {
      case 'paid':
        return 'Đã thanh toán';
      case 'processing':
        return 'Đơn đang được xử lý';
      case 'shipping':
        return 'Đơn đang giao';
      case 'delivered':
        return 'Đã giao hàng';
      case 'completed':
        return 'Đơn hàng hoàn tất';
      case 'cancelled':
        return 'Đơn hàng đã hủy';
      default:
        return 'Cập nhật đơn hàng';
    }
  }

  private orderStatusBody(status: string): string {
    switch (status) {
      case 'paid':
        return 'đã thanh toán thành công.';
      case 'processing':
        return 'đang được Menly xử lý.';
      case 'shipping':
        return 'đang được giao đến bạn.';
      case 'delivered':
        return 'đã giao thành công.';
      case 'completed':
        return 'đã hoàn tất. Cảm ơn bạn đã mua sắm tại Menly.';
      case 'cancelled':
        return 'đã được hủy.';
      default:
        return 'đã được cập nhật.';
    }
  }

  private async notifyOrderUser(order: OrderRow, title: string, body: string): Promise<void> {
    if (!order?.user_id) return;
    const { error } = await this.db.from('notifications').insert({
      user_id: order.user_id,
      title,
      body,
      type: 'order',
      data: { order_id: order.id, code: order.code },
    });
    if (error) {
      console.error('Khong tao duoc thong bao don hang:', error.message);
    }
  }
}
