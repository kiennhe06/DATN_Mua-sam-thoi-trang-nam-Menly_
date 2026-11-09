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
  /** Ban sao cua order_items, ten ma ung dung doc. Do enrichOrders gan vao. */
  items?: OrderItemRow[];
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

  // Man chi tiet don can them lich su doi trang thai de ve hanh trinh giao hang
  // theo moc thoi gian that, thay vi suy ra tu mot trang thai hien tai.
  private static readonly ORDER_DETAIL_SELECT =
    '*, order_items(*, product_variants(size, color, products(name, thumbnail_url))), order_status_history(from_status, to_status, created_at)';

  /**
   * Bo cac dia chi sinh anh ngau nhien (picsum, placeholder) vi moi lan goi tra
   * ve mot anh khac, khong phai anh cua san pham. Anh unsplash van duoc giu vi
   * do la anh that cua kho hang, dang hien o trang chu va trang chi tiet; bo no
   * thi don hang tro thanh o trong trong khi cac man khac van co anh.
   */
  private realImageUrl(url: unknown): string {
    const value = String(url ?? '').trim();
    if (!value) return '';
    if (/picsum|placeholder/i.test(value)) return '';
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

      // Bang orders khong co cot giam gia; phan chenh giua (tam tinh + phi ship)
      // va tong thanh toan chinh la so da giam. Khong tra ve thi man chi tiet
      // hien tam tinh 299k, ship 25k nhung tong 274k, nguoi dung thay nhu sai.
      const giamGia = Math.max(
        0,
        Number(order.subtotal ?? 0) + Number(order.shipping_fee ?? 0) - Number(order.total ?? 0),
      );

      return {
        ...order,
        discount_amount: giamGia,
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
      // Dung chung select va buoc lam giau voi cac man khac, neu khong thi tra
      // cuu don bang ma se khong co anh san pham va khong co dong giam gia.
      const { data, error } = await this.db
        .from('orders')
        .select(OrderModel.ORDER_WITH_ITEMS_SELECT)
        .order('created_at', { ascending: false });

      if (error) return null;

      const orders = this.enrichOrders(data ?? []);

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
  /**
   * Tao don hang tu gio hang: MOI SAN PHAM MOT DON RIENG.
   *
   * Moi don co ma rieng va trang thai rieng, nen quan tri danh dau da giao
   * tung mon duoc, khong keo theo cac mon khac trong cung lan dat.
   *
   * Phi van chuyen tinh MOT LAN cho ca lan dat nen dat het vao don dau tien;
   * giam gia cung vay, tru dan cho tung don cho den het. Nho do tong tien khach
   * tra khong doi so voi so hien o man thanh toan.
   */
  async createOrder(input: CreateOrderInput): Promise<OrderRow> {
    if (!input.items.length) {
      throw new Error('Sản phẩm hoặc số lượng đặt hàng không hợp lệ');
    }

    const createdOrders: OrderRow[] = [];
    let giamGiaConLai = input.discount_amount ?? 0;

    for (let i = 0; i < input.items.length; i++) {
      const phiShip = i === 0 ? (input.shipping_fee ?? 0) : 0;

      // Tao don truoc de biet subtotal that cua rieng mon nay
      const don = await this.createSingleOrder({
        ...input,
        items: [input.items[i]],
        subtotal: 0,
        total: 0,
        shipping_fee: phiShip,
        discount_amount: 0,
        voucher_code: i === 0 ? input.voucher_code : undefined,
        idempotency_key: input.idempotency_key
          ? `${input.idempotency_key}-${i + 1}`
          : undefined,
      }, false);

      // Tru dan giam gia, khong de vuot qua gia tri cua chinh don do
      const giamChoDonNay = Math.min(giamGiaConLai, don.subtotal);
      giamGiaConLai -= giamChoDonNay;

      if (giamChoDonNay > 0) {
        const tongMoi = Math.max(0, don.subtotal + phiShip - giamChoDonNay);
        await this.db.from('orders').update({ total: tongMoi }).eq('id', don.id);
        don.total = tongMoi;
      }

      // Noi cac don sau ve don dau tien. Cong thanh toan doi chieu theo tung
      // don, nen phai biet duoc nhung don nao thuoc cung mot lan tra tien.
      if (i > 0) {
        await this.db
          .from('orders')
          .update({ parent_order_id: createdOrders[0].id })
          .eq('id', don.id);
      }

      createdOrders.push(don);
    }

    // Mot thong bao duy nhat cho ca lan dat, du tach thanh bao nhieu don
    const donDau = createdOrders[0];
    await this.notifyOrderUser(
      donDau,
      'Đặt hàng thành công',
      createdOrders.length > 1
        ? `Đã tạo ${createdOrders.length} đơn cho lần đặt này: ${createdOrders
            .map((o) => `#${o.code}`)
            .join(', ')}. Mỗi sản phẩm một đơn để theo dõi giao hàng riêng.`
        : `Đơn hàng #${donDau.code} đã được tạo. Menly sẽ cập nhật khi đơn được xử lý.`,
    );

    // Tra ve don dau tien de giao dien cu van chay, kem ma cua cac don con lai
    return {
      ...donDau,
      split_order_codes: createdOrders.map((o) => o.code),
    } as OrderRow;
  }

  /// Tao MOT don hang cho danh sach san pham duoc truyen vao.
  ///
  /// Khong goi truc tiep tu ben ngoai: createOrder se goi ham nay nhieu lan,
  /// moi san pham mot don.
  private async createSingleOrder(
    input: CreateOrderInput,
    tuTaoThongBao = true,
  ): Promise<OrderRow> {
    if (!input.items.length || input.items.some((item) => !item.variant_id || !Number.isInteger(item.quantity) || item.quantity < 1)) {
      throw new Error('Sản phẩm hoặc số lượng đặt hàng không hợp lệ');
    }

    let created: any;
    let error: any;

    // Thử gọi hàm create_order có hỗ trợ p_shipping_fee (9 tham số)
    const rpc9 = await this.db.rpc('create_order', {
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

    const errMsg = (rpc9.error?.message ?? '').toLowerCase();
    const errCode = rpc9.error?.code ?? '';
    if (rpc9.error && (errMsg.includes('schema cache') || errMsg.includes('create_order') || errMsg.includes('function') || errCode === 'PGRST202' || errCode === '42883')) {
      // Fallback cho Supabase instance chưa cập nhật tham số p_shipping_fee (hàm 8 tham số)
      const rpc8 = await this.db.rpc('create_order', {
        p_user_id: input.userId,
        p_payment_method: input.payment_method,
        p_ship_name: input.ship_name,
        p_ship_phone: input.ship_phone,
        p_ship_address: input.ship_address,
        p_items: input.items.map((item) => ({ variant_id: item.variant_id, quantity: item.quantity })),
        p_voucher_code: input.voucher_code ?? null,
        p_idempotency_key: input.idempotency_key ?? null,
      });
      created = rpc8.data;
      error = rpc8.error;

    } else {
      created = rpc9.data;
      error = rpc9.error;
    }

    if (error) throw new Error(error.message);

    const rpcOrder = Array.isArray(created) ? created[0] : created;
    if (!rpcOrder?.id) throw new Error('Backend không trả về mã đơn hàng vừa tạo');

    // Đồng bộ chính xác tổng thanh toán, phí ship và giảm giá voucher theo đúng dữ liệu app gửi.
    // Khi tach don thi app khong gui subtotal/total cho tung don, luc do lay
    // subtotal do ham create_order tu tinh theo gia that cua san pham.
    const { data: vuaTao } = await this.db
      .from('orders')
      .select('subtotal')
      .eq('id', rpcOrder.id)
      .maybeSingle();
    const baseSubtotal = (input.subtotal && input.subtotal > 0)
      ? input.subtotal
      : Number(vuaTao?.subtotal ?? 0);
    const calculatedTotal = (input.total !== undefined && input.total > 0)
      ? input.total
      : Math.max(0, baseSubtotal + (input.shipping_fee ?? 0) - (input.discount_amount ?? 0));

    const updatePayload: Record<string, any> = {
      shipping_fee: input.shipping_fee ?? 0,
      total: calculatedTotal,
    };
    if (input.subtotal && input.subtotal > 0) {
      updatePayload.subtotal = input.subtotal;
    }

    await this.db.from('orders').update(updatePayload).eq('id', rpcOrder.id);

    // Đồng bộ chi tiết mã giảm giá vào order_vouchers nếu có mã và chiết khấu
    if (input.voucher_code && (input.discount_amount ?? 0) > 0) {
      try {
        const { data: existingVoucher } = await this.db
          .from('order_vouchers')
          .select('id')
          .eq('order_id', rpcOrder.id)
          .maybeSingle();

        if (!existingVoucher) {
          const cleanCode = input.voucher_code.trim();
          const { data: vRow } = await this.db
            .from('vouchers')
            .select('id, used_count')
            .ilike('code', cleanCode)
            .maybeSingle();

          if (vRow) {
            await this.db.from('order_vouchers').insert({
              order_id: rpcOrder.id,
              voucher_id: vRow.id,
              discount_amount: input.discount_amount,
            });
            await this.db.from('vouchers').update({
              used_count: (vRow.used_count ?? 0) + 1,
            }).eq('id', vRow.id);
          }
        }
      } catch {
        // Bỏ qua lỗi phụ nếu bảng vouchers tạm thời không khả dụng
      }
    }

    const order = await this.loadEnrichedOrder(rpcOrder.id);
    if (!order) throw new Error('Không tải được đơn hàng vừa tạo');

    const createdOrder = {
      ...order,
      discount_amount: input.discount_amount ?? Math.max(0, order.subtotal + order.shipping_fee - order.total),
    } as OrderRow;
    // Khi tach don thi createOrder tu gui MOT thong bao tong hop, neu de day
    // gui thi mua 3 mon se nhan 3 thong bao giong het nhau.
    if (tuTaoThongBao) {
      await this.notifyOrderUser(
        createdOrder,
        'Đặt hàng thành công',
        `Đơn hàng #${createdOrder.code} đã được tạo. Menly sẽ cập nhật khi đơn được xử lý.`,
      );
    }
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
    let query = this.db.from('orders').select(OrderModel.ORDER_DETAIL_SELECT).eq('id', orderId);
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

  /**
   * Huy cac don VNPay qua han tra tien va tra hang ve kho.
   *
   * Don VNPay duoc tao truoc khi khach sang cong thanh toan va da tru kho ngay
   * de giu cho. Khach bo ngang thi so hang do bi giu mai neu khong co ai don.
   * Ham SQL expire_pending_orders lam viec do, nhung phai co cho goi dinh ky.
   *
   * Tra ve false khi khong don duoc, de noi goi tu quyet dinh ghi log hay bo qua.
   */
  async expirePendingOrders(): Promise<boolean> {
    const { error } = await this.db.rpc('expire_pending_orders');
    if (error) {
      console.error('Khong huy duoc don qua han:', error.message);
      return false;
    }
    return true;
  }

  // =========== ADMIN: QUAN LY DON HANG ===========

  /**
   * [Admin] Danh sach don hang (kem items), loc theo trang thai va khoang ngay.
   *
   * from / to la moc thoi gian dang ISO do trang quan tri tinh san theo mui gio
   * cua may admin, nen "hom nay" o Viet Nam khong bi lech 7 tieng so voi UTC.
   * to la moc KHONG tinh vao ket qua (dau ngay hom sau).
   */
  async adminListOrders(params: {
    status?: string;
    limit?: number;
    from?: string;
    to?: string;
  }): Promise<OrderRow[]> {
    let query = this.db
      .from('orders')
      .select('*, order_items(*)')
      .order('created_at', { ascending: false });

    if (params.status) query = query.eq('status', params.status);
    if (params.from) query = query.gte('created_at', params.from);
    if (params.to) query = query.lt('created_at', params.to);
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
