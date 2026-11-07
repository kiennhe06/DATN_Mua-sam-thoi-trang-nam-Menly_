import { supabase } from '../config/supabase.js';

// Dong product_reviews trong DB (snake_case)
interface ReviewRow {
  id: string;
  product_id: string;
  user_id: string;
  rating: number;
  comment: string | null;
  reply_comment: string | null;
  reply_at: string | null;
  created_at: string;
}

// Dang camelCase tra ve cho admin frontend
export interface AdminReview {
  id: string;
  userId: string;
  productId: string;
  rating: number;
  comment: string | null;
  replyComment: string | null;
  replyAt: string | null;
  createdAt: string;
  user?: {
    id: string;
    email: string;
    name: string | null;
  };
}

const ADMIN_REVIEW_COLUMNS =
  'id, product_id, user_id, rating, comment, reply_comment, reply_at, created_at';

// Lop truy cap du lieu cho: Danh gia
const REVIEW_BUCKET = 'review-images';
const MAX_REVIEW_IMAGES = 5;

export class ReviewModel {
  protected db = supabase;
  private bucketName = REVIEW_BUCKET;
  private bucketEnsured = false;

  private async ensureBucketExists() {
    if (this.bucketEnsured) return;
    try {
      const { data: buckets } = await this.db.storage.listBuckets();
      const exists = buckets?.some((b) => b.name === this.bucketName);
      if (!exists) {
        await this.db.storage.createBucket(this.bucketName, {
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

  private async attachUserInfo(rows: any[]) {
    if (!rows.length) return rows;

    const userIds = [...new Set(rows.map((row) => row.user_id).filter(Boolean))];
    const { data: profiles } = await this.db
      .from('profiles')
      .select('id, full_name, avatar_url')
      .in('id', userIds);

    const profileMap = new Map((profiles ?? []).map((profile) => [profile.id, profile]));

    return rows.map((row) => {
      const profile = profileMap.get(row.user_id);
      return {
        ...row,
        user_name: profile?.full_name ?? null,
        user_avatar: profile?.avatar_url ?? null,
      };
    });
  }

  async findByProduct(productId: string) {
    const { data, error } = await this.db
      .from('product_reviews')
      .select('id, product_id, order_item_id, user_id, rating, comment, images, reply_comment, reply_at, created_at')
      .eq('product_id', productId)
      .order('created_at', { ascending: false });
    if (error) throw new Error(error.message);
    return this.attachUserInfo(data ?? []);
  }

  async findByUser(userId: string) {
    const { data, error } = await this.db
      .from('product_reviews')
      .select('id, product_id, order_item_id, user_id, rating, comment, images, reply_comment, reply_at, created_at')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });
    if (error) throw new Error(error.message);
    return data ?? [];
  }

  async findPurchasedOrderItem(orderItemId: string, userId: string) {
    const { data, error } = await this.db
      .from('order_items')
      .select('id, order_id, variant_id, orders!inner(id, user_id, status), product_variants(id, product_id)')
      .eq('id', orderItemId)
      .maybeSingle();
    if (error) throw new Error(error.message);
    if (!data) return null;

    const row = data as any;
    const order = Array.isArray(row.orders) ? row.orders[0] : row.orders;
    const variant = Array.isArray(row.product_variants) ? row.product_variants[0] : row.product_variants;

    if (!order || order.user_id !== userId) return null;

    return {
      orderItemId: row.id as string,
      orderStatus: order.status as string,
      productId: (variant?.product_id as string | undefined) ?? null,
    };
  }

  async findReviewableOrderItemForProduct(userId: string, productId: string) {
    const { data: items, error } = await this.db
      .from('order_items')
      .select('id, orders!inner(user_id, status), product_variants!inner(product_id)')
      .eq('orders.user_id', userId)
      .eq('product_variants.product_id', productId)
      .in('orders.status', ['delivered', 'completed', 'paid', 'processing']);

    if (error || !items || !items.length) return null;

    const { data: reviewed } = await this.db
      .from('product_reviews')
      .select('order_item_id')
      .eq('user_id', userId);

    const reviewedIds = new Set((reviewed ?? []).map((r: any) => r.order_item_id));
    const unreviewedItem = items.find((it: any) => !reviewedIds.has(it.id));
    return unreviewedItem ?? null;
  }

  async uploadImages(userId: string, files: Express.Multer.File[]) {
    if (!files.length) return [] as string[];

    await this.ensureBucketExists();

    const urls: string[] = [];
    for (const file of files.slice(0, MAX_REVIEW_IMAGES)) {
      const extMatch = file.originalname.match(/\.([a-zA-Z0-9]+)$/);
      const ext = extMatch ? extMatch[1].toLowerCase() : file.mimetype.split('/')[1] || 'jpg';
      const fileName = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`;
      const filePath = `${userId}/${fileName}`;

      const { error } = await this.db.storage
        .from(this.bucketName)
        .upload(filePath, file.buffer, {
          contentType: file.mimetype,
          upsert: false,
        });

      if (error) {
        throw new Error(`Lỗi tải ảnh đánh giá lên lưu trữ: ${error.message}`);
      }

      const { data } = this.db.storage.from(this.bucketName).getPublicUrl(filePath);
      urls.push(data.publicUrl);
    }

    return urls;
  }

  async create(input: {
    userId: string;
    productId: string;
    orderItemId: string;
    rating: number;
    comment?: string;
    images?: string[];
  }) {
    const comment = input.comment?.trim();
    const { data, error } = await this.db
      .from('product_reviews')
      .insert({
        user_id: input.userId,
        product_id: input.productId,
        order_item_id: input.orderItemId,
        rating: input.rating,
        comment: comment ? comment : null,
        images: (input.images ?? []).slice(0, MAX_REVIEW_IMAGES),
      })
      .select('*')
      .single();
    if (error) {
      if (error.code === '23505') {
        throw new Error('Sản phẩm trong đơn hàng này đã được đánh giá');
      }
      throw new Error(error.message);
    }

    const enriched = await this.attachUserInfo([data]);
    return enriched[0];
  }

  async removeOwn(reviewId: string, userId: string) {
    const { data, error } = await this.db
      .from('product_reviews')
      .delete()
      .eq('id', reviewId)
      .eq('user_id', userId)
      .select('id')
      .maybeSingle();
    if (error) throw new Error(error.message);
    return data;
  }

  /**
   * [Admin] Danh sach danh gia (kem thong tin nguoi dung).
   * product_reviews.user_id tro toi auth.users nen khong join truc tiep profiles duoc;
   * lay profiles rieng theo danh sach user_id roi ghep lai.
   */
  async adminList(opts: { limit?: number } = {}): Promise<AdminReview[]> {
    const { data, error } = await this.db
      .from('product_reviews')
      .select(ADMIN_REVIEW_COLUMNS)
      .order('created_at', { ascending: false })
      .limit(opts.limit ?? 50);

    if (error) throw new Error(error.message);
    const rows = (data ?? []) as ReviewRow[];
    if (rows.length === 0) return [];

    // Lay ho so nguoi dung tuong ung de hien ten/email
    const userIds = [...new Set(rows.map((r) => r.user_id).filter(Boolean))];
    const profileMap = new Map<string, { id: string; email: string | null; full_name: string | null }>();
    if (userIds.length > 0) {
      const { data: profiles, error: profileError } = await this.db
        .from('profiles')
        .select('id, email, full_name')
        .in('id', userIds);
      if (profileError) throw new Error(profileError.message);
      for (const p of profiles ?? []) {
        profileMap.set(p.id, p);
      }
    }

    return rows.map((r) => {
      const profile = profileMap.get(r.user_id);
      return {
        id: r.id,
        userId: r.user_id,
        productId: r.product_id,
        rating: r.rating,
        comment: r.comment,
        replyComment: r.reply_comment,
        replyAt: r.reply_at,
        createdAt: r.created_at,
        user: profile
          ? { id: profile.id, email: profile.email ?? '', name: profile.full_name }
          : undefined,
      };
    });
  }

  /** [Admin] Xoa 1 danh gia vi pham */
  async adminDelete(id: string): Promise<boolean> {
    const { error } = await this.db.from('product_reviews').delete().eq('id', id);
    if (error) throw new Error(error.message);
    return true;
  }

  /** [Admin] Tra loi 1 danh gia */
  async adminReply(id: string, reply: string): Promise<AdminReview | null> {
    const { data, error } = await this.db
      .from('product_reviews')
      .update({ reply_comment: reply, reply_at: new Date().toISOString() })
      .eq('id', id)
      .select(ADMIN_REVIEW_COLUMNS)
      .maybeSingle();

    if (error) throw new Error(error.message);
    if (!data) return null;
    const r = data as ReviewRow;
    return {
      id: r.id,
      userId: r.user_id,
      productId: r.product_id,
      rating: r.rating,
      comment: r.comment,
      replyComment: r.reply_comment,
      replyAt: r.reply_at,
      createdAt: r.created_at,
    };
  }
}
