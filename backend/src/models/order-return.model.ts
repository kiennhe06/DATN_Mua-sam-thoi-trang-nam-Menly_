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

const RETURN_BUCKET = 'order-return-images';
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

  async updateStatus(
    id: string,
    payload: {
      status: string;
      rejectionReason?: string | null;
      adminResolutionNote?: string | null;
    }
  ): Promise<OrderReturnRow | null> {
    const { data, error } = await this.db
      .from('order_returns')
      .update({
        status: payload.status,
        rejection_reason: payload.rejectionReason ?? null,
        admin_resolution_note: payload.adminResolutionNote ?? null,
        resolved_at: ['refunded', 'rejected'].includes(payload.status) ? new Date().toISOString() : null,
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw new Error(error.message);
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
      const filePath = `${userId}/${fileName}`;

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
