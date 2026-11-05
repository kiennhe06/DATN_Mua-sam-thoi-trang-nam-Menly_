import { supabase } from '../config/supabase.js';

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
  refundAmount?: number;
  shopId?: string | null;
}

// Lop truy cap du lieu cho: Tra hang
export class OrderReturnModel {
  protected db = supabase;

  async createReturnRequest(input: CreateOrderReturnInput): Promise<OrderReturnRow> {
    const reason = input.reason?.trim();
    if (!reason) {
      throw new Error('Vui lòng nhập lý do trả hàng');
    }

    const images = Array.isArray(input.proofImages) ? input.proofImages.filter(Boolean) : [];
    if (images.length === 0) {
      throw new Error('Vui lòng đính kèm ít nhất 1 hình ảnh minh chứng');
    }

    const { data, error } = await this.db
      .from('order_returns')
      .insert({
        order_id: input.orderId,
        user_id: input.userId,
        shop_id: input.shopId ?? null,
        reason,
        proof_images: images,
        refund_amount: Number(input.refundAmount ?? 0),
        status: 'requested',
      })
      .select()
      .single();

    if (error || !data) {
      throw new Error(error?.message ?? 'Không thể tạo yêu cầu trả hàng');
    }

    return data as OrderReturnRow;
  }

  async findByUser(userId: string): Promise<OrderReturnRow[]> {
    const { data, error } = await this.db
      .from('order_returns')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw new Error(error.message);
    return (data ?? []) as OrderReturnRow[];
  }

  async findById(id: string, userId?: string): Promise<OrderReturnRow | null> {
    let query = this.db.from('order_returns').select('*').eq('id', id);
    if (userId) query = query.eq('user_id', userId);

    const { data, error } = await query.maybeSingle();
    if (error) throw new Error(error.message);
    return (data as OrderReturnRow) ?? null;
  }

  async listAll(): Promise<OrderReturnRow[]> {
    const { data, error } = await this.db
      .from('order_returns')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw new Error(error.message);
    return (data ?? []) as OrderReturnRow[];
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
    return (data as OrderReturnRow) ?? null;
  }
}
