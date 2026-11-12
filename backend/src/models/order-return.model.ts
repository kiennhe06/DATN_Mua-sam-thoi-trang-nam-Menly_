import { supabase } from '../config/supabase.js';
import { OrderModel, type OrderRow } from './order.model.js';

export interface OrderReturnRow {
  id: string;
  order_id: string;
  user_id: string;
  shop_id?: string | null;
  reason: string;
  proof_images: string[];
  status: string;
  refund_amount: number;
  rejection_reason?: string | null;
  admin_resolution_note?: string | null;
  /** true: hang con ban duoc va da nhap lai kho; false: hang loi. */
  restocked?: boolean | null;
  created_at: string;
  resolved_at?: string | null;
}

export interface CreateOrderReturnInput {
  orderId: string;
  userId: string;
  reason: string;
  proofImages?: string[];
  files?: Express.Multer.File[];
  refundAmount?: number;
  shopId?: string | null;
}

const RETURN_BUCKET = 'review-images';
const MAX_PROOF_IMAGES = 5;
const RETURNABLE_STATUSES = ['delivered', 'completed'];
const OPEN_RETURN_STATUSES = ['requested', 'shop_approved', 'admin_dispute_review'];

// Lop truy cap du lieu cho: Tra hang
export class OrderReturnModel {
  protected db = supabase;
  private orderModel = new OrderModel();
  private bucketEnsured = false;

  async createReturnRequest(input: CreateOrderReturnInput): Promise<OrderReturnRow> {
    const reason = input.reason?.trim();
    if (!reason) {
      throw new Error('Vui lòng nhập lý do trả hàng');
    }

    const order = await this.orderModel.getOrderById(input.orderId, input.userId);
    if (!order) {
      throw new Error('Không tìm thấy đơn hàng của bạn');
    }
    if (!RETURNABLE_STATUSES.includes(order.status)) {
      throw new Error('Chỉ có thể trả hàng khi đơn đã giao');
    }

    const openReturn = await this.findOpenByOrder(input.orderId, input.userId);
    if (openReturn) {
      throw new Error('Đơn hàng này đã có yêu cầu trả hàng đang xử lý');
    }

    // Don da hoan tien mot lan roi thi khong nhan yeu cau thu hai: trang thai
    // don van la 'delivered' nen khong co gi chan, ma duyet lan nua se hoan
    // tien lan hai va cong kho lan hai cho cung mot lo hang.
    const { data: daHoanTien, error: loiKiemTra } = await this.db
      .from('order_returns')
      .select('id')
      .eq('order_id', input.orderId)
      .eq('status', 'refunded')
      .limit(1);
    if (loiKiemTra) throw new Error(loiKiemTra.message);
    if ((daHoanTien ?? []).length > 0) {
      throw new Error('Đơn hàng này đã được hoàn tiền trả hàng trước đó');
    }

    const uploaded = await this.uploadImages(input.userId, input.files ?? []);
    const images = [...(Array.isArray(input.proofImages) ? input.proofImages : []), ...uploaded]
      .map((url) => String(url).trim())
      .filter(Boolean);

    if (images.length === 0) {
      throw new Error('Vui lòng đính kèm ít nhất 1 hình ảnh minh chứng');
    }
    if (images.length > MAX_PROOF_IMAGES) {
      throw new Error(`Chỉ được đính kèm tối đa ${MAX_PROOF_IMAGES} ảnh`);
    }

    const { data, error } = await this.db
      .from('order_returns')
      .insert({
        order_id: order.id,
        user_id: input.userId,
        shop_id: input.shopId ?? null,
        reason,
        proof_images: images,
        refund_amount: Number(order.total ?? input.refundAmount ?? 0),
        status: 'requested',
      })
      .select()
      .single();

    if (error || !data) {
      throw new Error(error?.message ?? 'Không thể tạo yêu cầu trả hàng');
    }

    await this.notifyReturnCreated(order);
    return this.normalize(data);
  }

  async findByUser(userId: string): Promise<OrderReturnRow[]> {
    const { data, error } = await this.db
      .from('order_returns')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw new Error(error.message);
    return (data ?? []).map((row) => this.normalize(row));
  }

  async findOpenByOrder(orderId: string, userId: string): Promise<OrderReturnRow | null> {
    const { data, error } = await this.db
      .from('order_returns')
      .select('*')
      .eq('order_id', orderId)
      .eq('user_id', userId)
      .in('status', OPEN_RETURN_STATUSES)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) throw new Error(error.message);
    return data ? this.normalize(data) : null;
  }

  async findById(id: string, userId?: string): Promise<OrderReturnRow | null> {
    let query = this.db.from('order_returns').select('*').eq('id', id);
    if (userId) query = query.eq('user_id', userId);

    const { data, error } = await query.maybeSingle();
    if (error) throw new Error(error.message);
    return data ? this.normalize(data) : null;
  }

  async listAll(): Promise<OrderReturnRow[]> {
    const { data, error } = await this.db
      .from('order_returns')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw new Error(error.message);
    return (data ?? []).map((row) => this.normalize(row));
  }

  /**
   * Cong lai kho cho tung mon trong don tra hang.
   *
   * Chi goi khi nguoi duyet xac nhan hang con ban duoc. Hang loi thi khong
   * goi ham nay: so hang do da bi tru luc khach dat va khong quay lai kho.
   */
  private async nhapLaiKho(orderId: string, actorId?: string): Promise<void> {
    // Nhat ky kho la bang chung don nay da duoc nhap lai hay chua. Nho no ma
    // bam duyet lai, hoac luu trang thai that bai roi thu lai, deu khong cong
    // kho them lan nua.
    const { data: daNhap, error: loiKiemTra } = await this.db
      .from('inventory_movements')
      .select('id')
      .eq('order_id', orderId)
      .eq('reason', 'return')
      .limit(1);
    if (loiKiemTra) throw new Error(loiKiemTra.message);
    if ((daNhap ?? []).length > 0) return;

    const { data: items, error } = await this.db
      .from('order_items')
      .select('variant_id, quantity')
      .eq('order_id', orderId);
    if (error) throw new Error(error.message);

    for (const item of items ?? []) {
      // Bien the co the da bi xoa khoi danh muc, luc do variant_id la null va
      // khong con cho nao de cong vao.
      if (!item.variant_id) continue;
      await this.congTonKho(item.variant_id, item.quantity, orderId, actorId);
    }
  }

  /**
   * Cong them mot so luong vao ton kho cua mot bien the.
   *
   * Doc roi ghi de thang se nuot mat don hang dat xen vao giua, nen lenh ghi
   * phai kem dieu kien "ton kho van dung bang so vua doc". Khong khop thi doc
   * lai va thu lai, giong cach man Kho dang lam.
   */
  private async congTonKho(
    variantId: string,
    soLuong: number,
    orderId: string,
    actorId?: string,
  ): Promise<void> {
    for (let lan = 0; lan < 3; lan += 1) {
      const { data: bienThe, error: loiDoc } = await this.db
        .from('product_variants')
        .select('stock')
        .eq('id', variantId)
        .maybeSingle();
      if (loiDoc) throw new Error(loiDoc.message);
      if (!bienThe) return;

      const { data: daGhi, error: loiCong } = await this.db
        .from('product_variants')
        .update({ stock: bienThe.stock + soLuong })
        .eq('id', variantId)
        .eq('stock', bienThe.stock)
        .select('id')
        .maybeSingle();
      if (loiCong) throw new Error(loiCong.message);
      if (!daGhi) continue; // Co thao tac khac vua doi ton kho, doc lai roi thu lai.

      const { error: loiNhatKy } = await this.db.from('inventory_movements').insert({
        variant_id: variantId,
        change: soLuong,
        reason: 'return' as const,
        order_id: orderId,
        created_by: actorId || null,
        note: 'Hàng trả còn bán được, nhập lại kho',
      });
      if (loiNhatKy) throw new Error(loiNhatKy.message);
      return;
    }

    throw new Error('Tồn kho đang được thao tác bởi người khác, vui lòng thử lại');
  }

  async updateStatus(
    id: string,
    payload: {
      status: string;
      rejectionReason?: string | null;
      adminResolutionNote?: string | null;
      /** Hang tra con ban duoc khong. Chi co nghia khi chuyen sang 'refunded'. */
      restock?: boolean;
      actorId?: string;
    }
  ): Promise<OrderReturnRow | null> {
    const { data: hienTai, error: loiDoc } = await this.db
      .from('order_returns')
      .select('id, order_id, status')
      .eq('id', id)
      .maybeSingle();
    if (loiDoc) throw new Error(loiDoc.message);
    if (!hienTai) return null;

    // Chi nhap lai kho dung mot lan, ngay khi don chuyen sang da hoan tien.
    // Bam duyet lai lan nua se khong cong them nua.
    const laLanHoanTienDauTien =
      payload.status === 'refunded' && hienTai.status !== 'refunded';
    if (laLanHoanTienDauTien && payload.restock === true) {
      await this.nhapLaiKho(hienTai.order_id, payload.actorId);
    }

    const thayDoi: Record<string, string | boolean | null> = {
      status: payload.status,
      rejection_reason: payload.rejectionReason ?? null,
      admin_resolution_note: payload.adminResolutionNote ?? null,
      resolved_at: ['refunded', 'rejected'].includes(payload.status) ? new Date().toISOString() : null,
    };
    if (payload.status === 'refunded' && payload.restock !== undefined) {
      thayDoi.restocked = payload.restock;
    }

    const { data, error } = await this.db
      .from('order_returns')
      .update(thayDoi)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      // Co so du lieu chua chay 09_tra_hang_nhap_kho.sql thi chua co cot
      // restocked. Van luu duoc trang thai, chi thieu ghi chu con ban duoc.
      const thieuCot = error.message.toLowerCase().includes('restocked');
      if (!thieuCot) throw new Error(error.message);

      delete thayDoi.restocked;
      const { data: lanHai, error: loiLanHai } = await this.db
        .from('order_returns')
        .update(thayDoi)
        .eq('id', id)
        .select()
        .single();
      if (loiLanHai) throw new Error(loiLanHai.message);
      return lanHai ? this.normalize(lanHai) : null;
    }

    return data ? this.normalize(data) : null;
  }

  private async uploadImages(userId: string, files: Express.Multer.File[]): Promise<string[]> {
    if (!files.length) return [];

    await this.ensureBucketExists();

    const urls: string[] = [];
    for (const file of files.slice(0, MAX_PROOF_IMAGES)) {
      const extMatch = file.originalname.match(/\.([a-zA-Z0-9]+)$/);
      const ext = extMatch ? extMatch[1].toLowerCase() : file.mimetype.split('/')[1] || 'jpg';
      const fileName = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`;
      const filePath = `returns/${userId}/${fileName}`;

      const { error } = await this.db.storage.from(RETURN_BUCKET).upload(filePath, file.buffer, {
        contentType: file.mimetype,
        upsert: false,
      });

      if (error) {
        throw new Error(`Không tải được ảnh minh chứng: ${error.message}`);
      }

      const { data } = this.db.storage.from(RETURN_BUCKET).getPublicUrl(filePath);
      urls.push(data.publicUrl);
    }

    return urls;
  }

  private async ensureBucketExists() {
    if (this.bucketEnsured) return;
    try {
      const { data: buckets } = await this.db.storage.listBuckets();
      const exists = buckets?.some((b) => b.name === RETURN_BUCKET);
      if (!exists) {
        await this.db.storage.createBucket(RETURN_BUCKET, {
          public: true,
          fileSizeLimit: 5 * 1024 * 1024,
          allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
        });
      }
      this.bucketEnsured = true;
    } catch {
      this.bucketEnsured = true;
    }
  }

  private async notifyReturnCreated(order: OrderRow): Promise<void> {
    const { error } = await this.db.from('notifications').insert({
      user_id: order.user_id,
      title: 'Đã gửi yêu cầu trả hàng',
      body: `Yêu cầu trả hàng cho đơn #${order.code} đã được ghi nhận. Menly sẽ phản hồi sớm.`,
      type: 'order',
      data: { order_id: order.id, code: order.code },
    });
    if (error) {
      console.error('Khong tao duoc thong bao tra hang:', error.message);
    }
  }

  private normalize(row: Record<string, unknown>): OrderReturnRow {
    const rawImages = row.proof_images;
    let proofImages: string[] = [];
    if (Array.isArray(rawImages)) {
      proofImages = rawImages.map((item) => String(item)).filter(Boolean);
    } else if (typeof rawImages === 'string' && rawImages.trim()) {
      try {
        const parsed = JSON.parse(rawImages);
        proofImages = Array.isArray(parsed) ? parsed.map((item) => String(item)).filter(Boolean) : [rawImages];
      } catch {
        proofImages = [rawImages];
      }
    }

    return {
      ...(row as unknown as OrderReturnRow),
      proof_images: proofImages,
      refund_amount: Number(row.refund_amount ?? 0),
    };
  }
}
