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
export class ReviewModel {
  protected db = supabase;

  // Danh sach danh gia cua 1 san pham
  async findByProduct(productId: string) {
    const { data, error } = await this.db
      .from('product_reviews')
      .select('id, user_id, rating, comment, images, reply_comment, reply_at, created_at')
      .eq('product_id', productId)
      .order('created_at', { ascending: false });
    if (error) throw new Error(error.message);
    return data;
  }

  // Tao danh gia (gan voi 1 order_item da mua)
  async create(input: {
    userId: string;
    productId: string;
    orderItemId: string;
    rating: number;
    comment?: string;
  }) {
    const { data, error } = await this.db
      .from('product_reviews')
      .insert({
        user_id: input.userId,
        product_id: input.productId,
        order_item_id: input.orderItemId,
        rating: input.rating,
        comment: input.comment ?? null,
      })
      .select('*')
      .single();
    if (error) throw new Error(error.message);
    return data;
  }

  // Xoa danh gia cua chinh minh
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
