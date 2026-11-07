import { supabase } from '../config/supabase.js';
import type {
  AdminProductInput,
  AdminProductListOptions,
  AdminProductUpdate,
} from '../validators/admin-product.validator.js';

function slugify(value: string) {
  return value.toLowerCase().replace(/đ/g, 'd').normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

function isPlaceholderImage(url?: string | null) {
  if (!url) return true;
  return url.includes('picsum.photos');
}

function sizeRank(size: string) {
  const order = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '2XL', '3XL'];
  const idx = order.indexOf(size.trim().toUpperCase());
  if (idx >= 0) return idx;
  const numeric = Number.parseInt(size, 10);
  return Number.isFinite(numeric) ? 100 + numeric : 1000;
}

/** Chuan hoa san pham public: anh + bien the that, khong thay bang anh mau. */
function normalizePublicProduct(product: any) {
  const images = [...(product.product_images || [])]
    .filter((image: any) => image?.url && !isPlaceholderImage(image.url))
    .sort((a: any, b: any) => (a.sort_order ?? 0) - (b.sort_order ?? 0));

  const variants = [...(product.product_variants || product.variants || [])]
    .filter((variant: any) => variant?.id)
    .sort((a: any, b: any) => {
      const bySize = sizeRank(String(a.size ?? '')) - sizeRank(String(b.size ?? ''));
      if (bySize !== 0) return bySize;
      return String(a.color ?? '').localeCompare(String(b.color ?? ''), 'vi');
    });

  const realThumb = isPlaceholderImage(product.thumbnail_url) ? '' : product.thumbnail_url;
  const thumbnailUrl = realThumb || images[0]?.url || '';

  return {
    ...product,
    category_name: product.categories?.name || product.category_name || '',
    thumbnail_url: thumbnailUrl,
    product_images: images,
    product_variants: variants,
    variants,
    images: images.map((image: any) => image.url),
  };
}

// Lop truy cap du lieu cho: San pham
export class ProductModel {
  protected db = supabase;

  // Lay danh sach san pham (loc theo danh muc, tim theo ten)
  async findAll(opts: { search?: string; categoryId?: string; limit?: number } = {}) {
    let query = this.db
      .from('products')
      .select('*, product_images(id, url, sort_order), product_variants(id, size, color, sku, stock), categories(id, name)')
      .eq('is_active', true)
      .eq('approval_status', 'approved');
    if (opts.categoryId) query = query.eq('category_id', opts.categoryId);
    if (opts.search) query = query.ilike('name', `%${opts.search}%`);
    query = query.order('created_at', { ascending: false }).limit(opts.limit ?? 50);

    const { data, error } = await query;
    if (error) throw new Error(error.message);
    return (data || []).map((p: any, idx: number) => {
      const product = normalizePublicProduct(p);
      if (product.is_new == null) product.is_new = idx < 10;
      if (product.is_best_seller == null) {
        product.is_best_seller = Boolean((idx >= 6 && idx < 18) || (product.rating_count && product.rating_count >= 10));
      }
      return product;
    });
  }

  // Lay chi tiet 1 san pham kem bien the + anh
  async findById(id: string) {
    const { data, error } = await this.db
      .from('products')
      .select('*, product_variants(*), product_images(*), categories(id, name)')
      .eq('id', id)
      .eq('is_active', true)
      .eq('approval_status', 'approved')
      .single();
    if (error) throw new Error(error.message);
    return data ? normalizePublicProduct(data) : data;
  }

  async findAdminAll(opts: AdminProductListOptions) {
    // Kem bien the (product_variants) de trang quan tri tinh dung ton kho tung san pham
    let query = this.db.from('products').select('*, product_variants(*)');
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

  async findAdminById(id: string) {
    const { data, error } = await this.db
      .from('products')
      .select('*, product_variants(*), product_images(*)')
      .eq('id', id)
      .maybeSingle();

    if (error) throw new Error(error.message);
    return data;
  }

  async createAdminProduct(input: AdminProductInput, actorId?: string) {
    const { data, error } = await this.db
      .from('products')
      .insert({
        category_id: input.categoryId,
        name: input.name,
        slug: input.slug || slugify(input.name),
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

    try {
      if (input.variants?.length) {
        const { error: variantsError } = await this.db.from('product_variants').insert(
          input.variants.map((variant) => ({
            product_id: data.id,
            size: variant.size,
            color: variant.color,
            sku: variant.sku,
            stock: variant.stock,
          })),
        );
        if (variantsError) throw new Error(variantsError.message);
        if (input.variants.some((variant) => variant.stock > 0)) {
          const { data: insertedVariants, error: variantsFetchError } = await this.db
            .from('product_variants').select('id, sku').eq('product_id', data.id);
          if (variantsFetchError) throw new Error(variantsFetchError.message);
          const variantIdBySku = new Map((insertedVariants ?? []).map((variant) => [variant.sku, variant.id]));
          const movements = input.variants.filter((variant) => variant.stock > 0).map((variant) => ({
            variant_id: variantIdBySku.get(variant.sku),
            change: variant.stock,
            reason: 'restock' as const,
            created_by: actorId || null,
            note: 'Tồn kho ban đầu khi tạo sản phẩm',
          }));
          const { error: movementError } = await this.db.from('inventory_movements').insert(movements);
          if (movementError) throw new Error(movementError.message);
        }
      }

      const imageUrls = [...new Set([input.thumbnailUrl, ...(input.images ?? [])].filter((url): url is string => Boolean(url)))];
      if (imageUrls.length) {
        const { error: imageError } = await this.db.from('product_images').insert(
          imageUrls.map((url, sortOrder) => ({ product_id: data.id, url, sort_order: sortOrder })),
        );
        if (imageError) throw new Error(imageError.message);
      }
    } catch (createError) {
      const { error: rollbackError } = await this.db.from('products').delete().eq('id', data.id);
      if (rollbackError) throw new Error(`Tạo sản phẩm thất bại và không thể hoàn tác: ${createError instanceof Error ? createError.message : String(createError)}; ${rollbackError.message}`);
      throw createError;
    }

    return this.findAdminById(data.id);
  }

  async updateAdminProduct(id: string, input: AdminProductUpdate) {
    const updates: Record<string, string | number | boolean | null> = {};
    if (input.categoryId !== undefined) updates.category_id = input.categoryId;
    if (input.name !== undefined) updates.name = input.name;
    if (input.slug !== undefined) updates.slug = input.slug;
    if (input.description !== undefined) updates.description = input.description || null;
    if (input.price !== undefined) updates.price = input.price;
    if (input.thumbnailUrl !== undefined) updates.thumbnail_url = input.thumbnailUrl || null;
    if (input.isActive !== undefined) updates.is_active = input.isActive;

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
