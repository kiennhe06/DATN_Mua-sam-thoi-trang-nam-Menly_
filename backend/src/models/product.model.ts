import { supabase } from '../config/supabase.js';
import type {
  AdminProductInput,
  AdminProductListOptions,
  AdminProductUpdate,
} from '../validators/admin-product.validator.js';

// Lop truy cap du lieu cho: San pham
export class ProductModel {
  protected db = supabase;

  // Lay danh sach san pham (loc theo danh muc, tim theo ten)
  async findAll(opts: { search?: string; categoryId?: string; limit?: number } = {}) {
    let query = this.db
      .from('products')
      .select('*, product_images(id, url, sort_order)')
      .eq('is_active', true)
      .eq('approval_status', 'approved');
    if (opts.categoryId) query = query.eq('category_id', opts.categoryId);
    if (opts.search) query = query.ilike('name', `%${opts.search}%`);
    query = query.order('created_at', { ascending: false }).limit(opts.limit ?? 50);

    const { data, error } = await query;
    if (error) throw new Error(error.message);
    return (data || []).map((p: any, idx: number) => {
      if (!p.thumbnail_url || p.thumbnail_url.includes('picsum')) {
        p.thumbnail_url = 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=600&auto=format&fit=crop';
      }
      p.is_new = idx < 10;
      p.is_best_seller = (idx >= 6 && idx < 18) || (p.rating_count && p.rating_count >= 10);
      return p;
    });
  }

  // Lay chi tiet 1 san pham kem bien the + anh
  async findById(id: string) {
    const { data, error } = await this.db
      .from('products')
      .select('*, product_variants(*), product_images(*)')
      .eq('id', id)
      .eq('is_active', true)
      .eq('approval_status', 'approved')
      .single();
    if (error) throw new Error(error.message);
    if (data && (!data.thumbnail_url || data.thumbnail_url.includes('picsum'))) {
      data.thumbnail_url = 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=600&auto=format&fit=crop';
    }
    return data;
  }

  async findAdminAll(opts: AdminProductListOptions) {
    let query = this.db.from('products').select('*');
    if (opts.categoryId) query = query.eq('category_id', opts.categoryId);
    if (opts.search) query = query.ilike('name', `%${opts.search}%`);
    if (opts.approvalStatus) query = query.eq('approval_status', opts.approvalStatus);
    if (opts.isActive !== undefined) query = query.eq('is_active', opts.isActive);

    const { data, error } = await query
      .order('created_at', { ascending: false })
      .limit(opts.limit);
    if (error) throw new Error(error.message);
    return data;
  }

  async createAdminProduct(input: AdminProductInput) {
    const { data, error } = await this.db
      .from('products')
      .insert({
        category_id: input.categoryId,
        name: input.name,
        slug: input.slug,
        description: input.description || null,
        price: input.price,
        thumbnail_url: input.thumbnailUrl || null,
        search_text: [input.name, input.description].filter(Boolean).join(' '),
        approval_status: 'pending',
        is_active: false,
      })
      .select('*')
      .single();

    if (error) throw new Error(error.message);
    return data;
  }

  async updateAdminProduct(id: string, input: AdminProductUpdate) {
    const updates: Record<string, string | number | null> = {};
    if (input.categoryId !== undefined) updates.category_id = input.categoryId;
    if (input.name !== undefined) updates.name = input.name;
    if (input.slug !== undefined) updates.slug = input.slug;
    if (input.description !== undefined) updates.description = input.description || null;
    if (input.price !== undefined) updates.price = input.price;
    if (input.thumbnailUrl !== undefined) updates.thumbnail_url = input.thumbnailUrl || null;

    if (input.name !== undefined || input.description !== undefined) {
      const { data: current, error: currentError } = await this.db
        .from('products')
        .select('name, description')
        .eq('id', id)
        .maybeSingle();

      if (currentError) throw new Error(currentError.message);
      if (!current) return null;

      const name = input.name ?? current.name;
      const description = input.description === undefined ? current.description : input.description || null;
      updates.search_text = [name, description].filter(Boolean).join(' ');
    }

    const { data, error } = await this.db
      .from('products')
      .update(updates)
      .eq('id', id)
      .select('*')
      .maybeSingle();

    if (error) throw new Error(error.message);
    return data;
  }

  async deactivateAdminProduct(id: string) {
    const { data, error } = await this.db
      .from('products')
      .update({ is_active: false })
      .eq('id', id)
      .select('*')
      .maybeSingle();

    if (error) throw new Error(error.message);
    return data;
  }

  async activateAdminProduct(id: string) {
    const { data, error } = await this.db
      .from('products')
      .update({ is_active: true })
      .eq('id', id)
      .select('*')
      .maybeSingle();

    if (error) throw new Error(error.message);
    return data;
  }

  async approveAdminProduct(id: string) {
    const { data, error } = await this.db
      .from('products')
      .update({ approval_status: 'approved', is_active: true })
      .eq('id', id)
      .select('*')
      .maybeSingle();

    if (error) throw new Error(error.message);
    return data;
  }
}
