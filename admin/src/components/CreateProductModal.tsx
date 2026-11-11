'use client';

import { useEffect, useState } from 'react';
import type { FormEvent } from 'react';
import { X } from 'lucide-react';
import { createAdminProduct } from '../lib/api';
import {
  taoSkuTuDong,
  validateProductDetails,
  validateProductVariants,
} from '../lib/product-form-validation';
import { danhSachSize, type BienTheNhap } from '../lib/product-options';
import { VariantEditor } from './VariantEditor';
import type { Category, Product } from '../lib/types';

interface CreateProductModalProps {
  categories: Category[];
  onClose: () => void;
  onCreated: (product: Product) => void;
}

const fieldClass = 'w-full rounded-lg border border-line-strong bg-panel px-3 py-2.5 text-sm text-ink placeholder:text-ink-muted focus:border-camel focus:outline-none';

export function CreateProductModal({ categories, onClose, onCreated }: CreateProductModalProps) {
  const [categoryId, setCategoryId] = useState('');
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [price, setPrice] = useState('');
  const [thumbnailUrl, setThumbnailUrl] = useState('');
  const [variants, setVariants] = useState<BienTheNhap[]>([
    { size: 'M', color: 'Đen', sku: '', stock: '0' },
  ]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!categoryId && categories.length > 0) setCategoryId(categories[0].id);
  }, [categories, categoryId]);

  // Quan dung size so (28, 30...), ao dung size chu (S, M, L...). Lay theo
  // danh muc dang chon chu khong bat nguoi dung nho.
  const danhMucDangChon = categories.find((item) => item.id === categoryId);
  const tenDanhMuc = danhMucDangChon?.slug || danhMucDangChon?.name || '';
  const sizes = danhSachSize(tenDanhMuc);

  // San pham moi chua luu gi, nen doi danh muc thi keo size ve bang cua danh
  // muc do luon (quan dung size so). Man chinh sua khong lam vay vi o do doi
  // size dong nghia voi xoa bien the that.
  useEffect(() => {
    const bangSize = danhSachSize(tenDanhMuc);
    setVariants((current) => {
      if (current.every((variant) => bangSize.includes(variant.size))) return current;
      const daCo = new Set<string>();
      const ketQua: BienTheNhap[] = [];
      for (const variant of current) {
        const size = bangSize.includes(variant.size) ? variant.size : bangSize[0];
        const khoa = `${size}|${variant.color}`;
        if (daCo.has(khoa)) continue;
        daCo.add(khoa);
        ketQua.push({ ...variant, size });
      }
      return ketQua;
    });
  }, [tenDanhMuc]);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);

    if (!categoryId) {
      setError('Vui lòng chọn danh mục cho sản phẩm.');
      return;
    }

    const detailsError = validateProductDetails({ name, price, thumbnailUrl });
    if (detailsError) {
      setError(detailsError);
      return;
    }

    // O SKU ghi "tu tao neu bo trong", nen dien ho truoc khi kiem tra, khong
    // thi nguoi dung bo trong dung nhu goi y lai bi bao loi thieu SKU.
    const variantsCoSku = variants.map((variant) => ({
      ...variant,
      sku: variant.sku.trim() || taoSkuTuDong(name, variant.size, variant.color),
    }));

    const variantsError = validateProductVariants(variantsCoSku);
    if (variantsError) {
      setError(variantsError);
      return;
    }

    const normalizedVariants = variantsCoSku.map((variant) => ({
      size: variant.size.trim(),
      color: variant.color.trim(),
      sku: variant.sku.trim(),
      stock: Number(variant.stock),
    }));

    setLoading(true);
    try {
      const imageUrl = thumbnailUrl.trim() || null;
      const product = await createAdminProduct({
        categoryId,
        name: name.trim(),
        description: description.trim() || null,
        price: Number(price),
        thumbnailUrl: imageUrl,
        images: imageUrl ? [imageUrl] : [],
        variants: normalizedVariants,
      });
      onCreated(product);
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Không thể tạo sản phẩm.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4 backdrop-blur-sm">
      <section className="max-h-[92vh] w-full max-w-3xl overflow-y-auto rounded-3xl border border-line-strong bg-panel p-6 text-ink shadow-panel-lg">
        <div className="mb-6 flex items-start justify-between border-b border-line pb-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-camel-dark">Danh mục sản phẩm</p>
            <h2 className="mt-1 text-xl font-bold">Thêm sản phẩm mới</h2>
            <p className="mt-1 text-sm text-ink-muted">Nhập thông tin sản phẩm và ít nhất một biến thể.</p>
          </div>
          <button type="button" onClick={onClose} aria-label="Đóng" className="rounded-xl p-2 text-ink-muted hover:bg-tint hover:text-ink">
            <X className="h-5 w-5" />
          </button>
        </div>

        {error && <div role="alert" className="mb-5 rounded-xl border border-danger-line bg-danger-bg px-4 py-3 text-sm text-danger">{error}</div>}

        <form onSubmit={handleSubmit} className="space-y-5">
          <div className="grid gap-4 md:grid-cols-2">
            <label className="space-y-1.5 text-sm font-medium text-ink-mid">
              Tên sản phẩm <span className="text-danger">*</span>
              <input className={fieldClass} value={name} onChange={(event) => setName(event.target.value)} minLength={2} maxLength={150} required placeholder="Ví dụ: Áo sơ mi Oxford" />
            </label>
            <label className="space-y-1.5 text-sm font-medium text-ink-mid">
              Danh mục <span className="text-danger">*</span>
              <select className={fieldClass} value={categoryId} onChange={(event) => setCategoryId(event.target.value)} required>
                <option value="" disabled>Chọn danh mục</option>
                {categories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
              </select>
            </label>
            <label className="space-y-1.5 text-sm font-medium text-ink-mid">
              Giá bán (₫) <span className="text-danger">*</span>
              <input className={fieldClass} type="number" min="0" step="1" value={price} onChange={(event) => setPrice(event.target.value)} required placeholder="350000" />
            </label>
            <label className="space-y-1.5 text-sm font-medium text-ink-mid">
              Ảnh đại diện (URL)
              <input className={fieldClass} type="url" value={thumbnailUrl} onChange={(event) => setThumbnailUrl(event.target.value)} placeholder="https://..." />
            </label>
          </div>

          {thumbnailUrl.trim() && (
            <div className="flex items-center gap-3 rounded-xl border border-line bg-tint p-3">
              <img src={thumbnailUrl} alt="Xem trước ảnh sản phẩm" className="h-16 w-16 rounded-lg border border-line-strong object-cover" />
              <span className="break-all text-xs text-ink-muted">Ảnh xem trước</span>
            </div>
          )}

          <label className="block space-y-1.5 text-sm font-medium text-ink-mid">
            Mô tả
            <textarea className={`${fieldClass} min-h-24 resize-y`} value={description} onChange={(event) => setDescription(event.target.value)} maxLength={5000} placeholder="Mô tả chất liệu, kiểu dáng và đặc điểm sản phẩm..." />
          </label>

          <div className="space-y-3">
            <div>
              <h3 className="text-sm font-bold text-ink">Biến thể và tồn kho</h3>
              <p className="text-xs text-ink-muted">
                Chọn nhiều size và nhiều màu, hệ thống tự ghép thành từng biến thể.
              </p>
            </div>
            <VariantEditor sizes={sizes} variants={variants} onChange={setVariants} />
          </div>

          <p className="rounded-xl border border-warn-line bg-warn-bg px-3 py-2.5 text-xs text-ink-mid">
            Sản phẩm mới luôn ở trạng thái <span className="font-semibold">Chờ duyệt</span> và chưa
            hiện trong ứng dụng. Sau khi tạo, bấm nút duyệt ở danh sách sản phẩm để đưa lên ứng dụng.
          </p>

          <div className="flex justify-end gap-3 border-t border-line pt-4">
            <button type="button" onClick={onClose} disabled={loading} className="rounded-xl border border-line-strong px-4 py-2.5 text-sm font-semibold text-ink-mid hover:bg-tint disabled:opacity-50">Hủy</button>
            <button type="submit" disabled={loading || categories.length === 0} className="rounded-xl bg-camel px-5 py-2.5 text-sm font-bold text-ink hover:bg-camel-hover disabled:cursor-not-allowed disabled:opacity-50">
              {loading ? 'Đang lưu...' : 'Tạo sản phẩm'}
            </button>
          </div>
        </form>
      </section>
    </div>
  );
}
