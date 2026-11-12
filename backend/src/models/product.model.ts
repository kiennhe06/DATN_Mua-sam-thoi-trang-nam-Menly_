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

// Nguong gan nhan hien thi tren ung dung. Doi o day la doi toan bo app.
const NEW_PRODUCTS_PER_CATEGORY = 4;
const BEST_SELLER_MIN_REVIEWS = 10;

// Lop truy cap du lieu cho: San pham
export class ProductModel {
  protected db = supabase;

  // Lay danh sach san pham (loc theo danh muc, tim theo ten)
  async findAll(opts: { search?: string; categoryId?: string; limit?: number } = {}) {
    // Kem product_variants de ung dung co id bien the that khi them vao gio hang
    let query = this.db
      .from('products')
      .select(
        '*, product_variants(id, size, color, sku, stock), product_images(id, url, sort_order), categories(id, name)',
      )
      .eq('is_active', true)
      .eq('approval_status', 'approved');
    if (opts.categoryId) query = query.eq('category_id', opts.categoryId);
    if (opts.search) query = query.ilike('name', `%${opts.search}%`);
    query = query.order('created_at', { ascending: false }).limit(opts.limit ?? 50);

    const { data, error } = await query;
    if (error) throw new Error(error.message);

    const products = (data || []).map((p: any) => normalizePublicProduct(p));

    // Nhan "moi" tinh theo tung danh muc chu khong theo ngay tao: ca kho hien tai
    // deu duoc them trong cung mot dot, neu tinh theo ngay thi san pham nao cung
    // la hang moi va nhan mat y nghia.
    const newestIds = new Set<string>();
    const byCategory = new Map<string, any[]>();
    for (const product of products) {
      const key = product.category_id ?? 'khong-danh-muc';
      const group = byCategory.get(key);
      if (group) group.push(product);
      else byCategory.set(key, [product]);
    }
    for (const group of byCategory.values()) {
      group
        .sort((a, b) => String(b.created_at ?? '').localeCompare(String(a.created_at ?? '')))
        .slice(0, NEW_PRODUCTS_PER_CATEGORY)
        .forEach((product) => newestIds.add(product.id));
    }

    for (const product of products) {
      if (product.is_new == null) product.is_new = newestIds.has(product.id);
      if (product.is_best_seller == null) {
        product.is_best_seller = Number(product.rating_count ?? 0) >= BEST_SELLER_MIN_REVIEWS;
      }
    }
    return products;
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
        // San pham moi luon cho duyet va chua duoc bat. Quan tri bam Duyet o
        // trang San pham thi approveAdminProduct bat ca hai cung luc.
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

      const anhBanDau = [input.thumbnailUrl, ...(input.images ?? [])].filter(Boolean);
      if (anhBanDau.length) await this.ghiDeGallery(data.id, anhBanDau);
    } catch (createError) {
      const { error: rollbackError } = await this.db.from('products').delete().eq('id', data.id);
      if (rollbackError) throw new Error(`Tạo sản phẩm thất bại và không thể hoàn tác: ${createError instanceof Error ? createError.message : String(createError)}; ${rollbackError.message}`);
      throw createError;
    }

    return this.findAdminById(data.id);
  }

  /**
   * Ghi de toan bo product_images cua mot san pham bang danh sach duoc truyen vao.
   * Bo url rong va url trung nhau, giu thu tu da cho.
   */
  private async ghiDeGallery(productId: string, urls: (string | null | undefined)[]) {
    const imageUrls = [...new Set(urls.filter((url): url is string => Boolean(url)))];

    const { error: deleteError } = await this.db
      .from('product_images')
      .delete()
      .eq('product_id', productId);
    if (deleteError) throw new Error(deleteError.message);

    if (!imageUrls.length) return;

    const { error: insertError } = await this.db.from('product_images').insert(
      imageUrls.map((url, sortOrder) => ({ product_id: productId, url, sort_order: sortOrder })),
    );
    if (insertError) throw new Error(insertError.message);
  }

  /**
   * Dong bo danh sach bien the cua mot san pham theo danh sach moi gui len.
   *
   * Ghep bien the cu va moi theo cap size + mau:
   * - Cap moi xuat hien  -> them bien the kem ton kho ban dau, ghi nhat ky kho.
   * - Cap da co          -> chi cap nhat SKU. Ton kho KHONG sua o day.
   * - Cap bi bo di       -> xoa, tru khi bien the do da tung nam trong mot don
   *                         hang; luc do tu choi de khong lam dut lien ket
   *                         don hang cu.
   *
   * Vi sao khong sua ton kho cua bien the cu: form gui len mot con so tuyet
   * doi doc tu luc mo form. Khach dat hang trong luc admin dang go thi con so
   * do da cu, luu xuong se ghi de mat cac don vua ban. Moi thay doi ton kho
   * di qua man Kho, noi cong tru theo chenh lech va co khoa lac quan.
   */
  async dongBoBienThe(
    productId: string,
    variants: Array<{ size: string; color: string; sku: string; stock: number }>,
    actorId?: string,
  ) {
    const { data: hienCo, error: loiDoc } = await this.db
      .from('product_variants')
      .select('id, size, color, sku, stock')
      .eq('product_id', productId);
    if (loiDoc) throw new Error(loiDoc.message);

    const khoaCua = (size: string, color: string) =>
      `${size.trim().toLowerCase()}|${color.trim().toLowerCase()}`;
    const banDoCu = new Map((hienCo ?? []).map((item) => [khoaCua(item.size, item.color), item]));
    const khoaMoi = new Set(variants.map((item) => khoaCua(item.size, item.color)));

    const canXoa = (hienCo ?? []).filter((item) => !khoaMoi.has(khoaCua(item.size, item.color)));
    if (canXoa.length > 0) {
      const idCanXoa = canXoa.map((item) => item.id);
      const { data: daBan, error: loiKiemTra } = await this.db
        .from('order_items')
        .select('variant_id')
        .in('variant_id', idCanXoa);
      if (loiKiemTra) throw new Error(loiKiemTra.message);

      const idDaBan = new Set((daBan ?? []).map((row) => row.variant_id));
      const biChan = canXoa.filter((item) => idDaBan.has(item.id));
      if (biChan.length > 0) {
        const ten = biChan.map((item) => `${item.size} / ${item.color}`).join(', ');
        throw new Error(
          `Không xóa được biến thể đã từng có đơn hàng: ${ten}. Hãy đặt tồn kho về 0 để ngừng bán thay vì xóa.`,
        );
      }

      const { error: loiXoa } = await this.db.from('product_variants').delete().in('id', idCanXoa);
      if (loiXoa) throw new Error(loiXoa.message);
    }

    for (const bienThe of variants) {
      const cu = banDoCu.get(khoaCua(bienThe.size, bienThe.color));

      if (!cu) {
        const { data: vuaThem, error: loiThem } = await this.db
          .from('product_variants')
          .insert({
            product_id: productId,
            size: bienThe.size,
            color: bienThe.color,
            sku: bienThe.sku,
            stock: bienThe.stock,
          })
          .select('id')
          .single();
        if (loiThem) throw new Error(loiThem.message);

        if (bienThe.stock > 0) {
          const { error: loiNhatKy } = await this.db.from('inventory_movements').insert({
            variant_id: vuaThem.id,
            change: bienThe.stock,
            reason: 'restock' as const,
            created_by: actorId || null,
            note: 'Tồn kho ban đầu khi thêm biến thể',
          });
          if (loiNhatKy) throw new Error(loiNhatKy.message);
        }
        continue;
      }

      if (cu.sku === bienThe.sku) continue;

      const { error: loiSua } = await this.db
        .from('product_variants')
        .update({ sku: bienThe.sku })
        .eq('id', cu.id);
      if (loiSua) throw new Error(loiSua.message);
    }
  }

  async updateAdminProduct(id: string, input: AdminProductUpdate, actorId?: string) {
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

    // Co the chi gui moi danh sach anh, luc do khong co cot nao de ghi nen
    // doc lai san pham thay vi goi update rong.
    const { data, error } = Object.keys(updates).length
      ? await this.db.from('products').update(updates).eq('id', id).select('*').maybeSingle()
      : await this.db.from('products').select('*').eq('id', id).maybeSingle();

    if (error) throw new Error(error.message);
    if (!data) return null;

    // Chi dong bo khi nguoi goi khai bao ro danh sach anh. San pham co nhieu anh
    // ma chi doi moi anh dai dien thi gallery van giu nguyen.
    if (input.images !== undefined) {
      await this.ghiDeGallery(id, [data.thumbnail_url, ...input.images]);
    }

    if (input.variants !== undefined) {
      await this.dongBoBienThe(id, input.variants, actorId);
    }

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
