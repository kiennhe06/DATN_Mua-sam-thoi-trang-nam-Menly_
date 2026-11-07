'use client';

import { useState } from 'react';
import type { FormEvent } from 'react';
import { Image as ImageIcon, Package2, Save, X } from 'lucide-react';
import { updateProduct } from '../lib/api';
import { validateProductDetails } from '../lib/product-form-validation';
import type { Category, Product } from '../lib/types';

interface EditProductModalProps {
  product: Product;
  categories: Category[];
  onClose: () => void;
  onSaved: (product: Product) => void;
}

const fieldClass = 'mt-1.5 w-full rounded-lg border border-line-strong bg-panel px-3.5 py-3 text-sm text-ink outline-none transition placeholder:text-ink-muted focus:border-camel focus:ring-2 focus:ring-camel/20';
const labelClass = 'block text-xs font-semibold uppercase tracking-wide text-ink-muted';

export function EditProductModal({ product, categories, onClose, onSaved }: EditProductModalProps) {
  const [name, setName] = useState(product.name);
  const [categoryId, setCategoryId] = useState(product.categoryId);
  const [description, setDescription] = useState(product.description || '');
  const [price, setPrice] = useState(String(product.price));
  const [thumbnailUrl, setThumbnailUrl] = useState(product.thumbnailUrl || '');
  const [isActive, setIsActive] = useState(product.isActive !== false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);
    const validationError = validateProductDetails({ name, price, thumbnailUrl });
    if (validationError) {
      setError(validationError);
      return;
    }
    setLoading(true);

    try {
      const updated = await updateProduct(product.id, {
        name: name.trim(),
        categoryId,
        description: description.trim() || null,
        price: Number(price),
        thumbnailUrl: thumbnailUrl.trim() || null,
        isActive,
      });
      onSaved(updated);
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Không thể cập nhật sản phẩm.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4 backdrop-blur-md" onMouseDown={(event) => event.target === event.currentTarget && !loading && onClose()}>
      <section role="dialog" aria-modal="true" aria-labelledby="edit-product-title" className="max-h-[92vh] w-full max-w-3xl overflow-hidden rounded-3xl border border-line-strong bg-panel text-ink shadow-panel-lg">
        <header className="relative overflow-hidden border-b border-line px-6 py-5 sm:px-8">
          <div className="absolute inset-0 bg-gradient-to-r from-camel-tint via-transparent to-transparent" />
          <div className="relative flex items-start justify-between gap-4">
            <div className="flex items-center gap-4">
              <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl border border-camel/25 bg-camel-tint text-camel-dark">
                <Package2 className="h-6 w-6" />
              </div>
              <div>
                <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-camel-dark">Danh mục sản phẩm</p>
                <h2 id="edit-product-title" className="mt-1 text-xl font-bold sm:text-2xl">Chỉnh sửa sản phẩm</h2>
                <p className="mt-1 max-w-xl truncate text-xs text-ink-muted">{product.name}</p>
              </div>
            </div>
            <button type="button" onClick={onClose} disabled={loading} aria-label="Đóng" className="rounded-lg border border-line-strong bg-tint p-2 text-ink-muted transition hover:bg-tint-strong hover:text-ink disabled:opacity-50">
              <X className="h-4 w-4" />
            </button>
          </div>
        </header>

        <form onSubmit={handleSubmit} className="flex max-h-[calc(92vh-82px)] flex-col">
          <div className="overflow-y-auto px-6 py-6 sm:px-8">
            {error && <div role="alert" className="mb-5 rounded-xl border border-danger-line bg-danger-bg px-4 py-3 text-sm text-danger">{error}</div>}

            <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_240px]">
              <div className="space-y-5">
                <div className="grid gap-4 sm:grid-cols-2">
                  <label className={`${labelClass} sm:col-span-2`}>
                    Tên sản phẩm
                    <input className={fieldClass} value={name} onChange={(event) => setName(event.target.value)} minLength={2} maxLength={150} required placeholder="Nhập tên sản phẩm" />
                  </label>
                  <label className={labelClass}>
                    Danh mục
                    <select className={fieldClass} value={categoryId} onChange={(event) => setCategoryId(event.target.value)} required>
                      {categories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
                    </select>
                  </label>
                  <label className={labelClass}>
                    Giá bán (₫)
                    <input className={fieldClass} type="number" min="0" step="1" value={price} onChange={(event) => setPrice(event.target.value)} required placeholder="350000" />
                  </label>
                </div>

                <label className={labelClass}>
                  Mô tả sản phẩm
                  <textarea className={`${fieldClass} min-h-32 resize-y leading-6`} value={description} onChange={(event) => setDescription(event.target.value)} maxLength={5000} placeholder="Chất liệu, kiểu dáng và thông tin sản phẩm..." />
                  <span className="mt-1 block text-right text-[10px] font-normal normal-case tracking-normal text-ink-muted">{description.length}/5000 ký tự</span>
                </label>

                <label className={labelClass}>
                  Đường dẫn ảnh đại diện
                  <input className={fieldClass} type="url" value={thumbnailUrl} onChange={(event) => setThumbnailUrl(event.target.value)} placeholder="https://..." />
                </label>

                <div className={`flex items-center justify-between gap-4 rounded-2xl border p-4 transition ${isActive ? 'border-ok-line bg-ok-bg' : 'border-line-strong bg-tint'}`}>
                  <div>
                    <p className="text-sm font-semibold text-ink">Hiển thị trên ứng dụng</p>
                    <p className="mt-1 text-xs text-ink-muted">{isActive ? 'Khách hàng có thể tìm và mua sản phẩm.' : 'Sản phẩm đang được ẩn khỏi khách hàng.'}</p>
                  </div>
                  <button type="button" role="switch" aria-checked={isActive} aria-label="Bật hoặc tắt hiển thị sản phẩm" onClick={() => setIsActive((value) => !value)} className={`relative h-7 w-12 shrink-0 rounded-full transition ${isActive ? 'bg-ok' : 'bg-tint-strong'}`}>
                    <span className={`absolute top-1 h-5 w-5 rounded-full bg-panel shadow transition-all ${isActive ? 'left-6' : 'left-1'}`} />
                  </button>
                </div>
              </div>

              <aside className="space-y-3">
                <div className="overflow-hidden rounded-2xl border border-line-strong bg-panel shadow-panel">
                  <div className="flex aspect-[4/5] items-center justify-center bg-gradient-to-br from-tint to-panel">
                    {thumbnailUrl ? (
                      <img src={thumbnailUrl} alt={`Ảnh ${name}`} className="h-full w-full object-cover" />
                    ) : (
                      <div className="flex flex-col items-center gap-2 text-ink-muted">
                        <ImageIcon className="h-9 w-9" />
                        <span className="text-xs">Chưa có ảnh</span>
                      </div>
                    )}
                  </div>
                  <div className="space-y-1 border-t border-line p-4">
                    <p className="line-clamp-2 text-sm font-semibold text-ink">{name || 'Tên sản phẩm'}</p>
                    <p className="font-mono text-sm font-bold text-camel-dark">{Number(price || 0).toLocaleString('vi-VN')} ₫</p>
                  </div>
                </div>
                <p className="px-1 text-[11px] leading-5 text-ink-muted">Biến thể và số lượng tồn kho được quản lý trong phần chi tiết sản phẩm.</p>
              </aside>
            </div>
          </div>

          <footer className="flex flex-col-reverse gap-3 border-t border-line bg-tint px-6 py-4 sm:flex-row sm:justify-between sm:px-8">
            <p className="self-center text-[11px] text-ink-muted">Mã sản phẩm: <span className="font-mono text-ink-muted">{product.id}</span></p>
            <div className="flex justify-end gap-3">
              <button type="button" onClick={onClose} disabled={loading} className="rounded-xl border border-line-strong px-4 py-2.5 text-sm font-semibold text-ink-mid transition hover:bg-tint disabled:opacity-50">Hủy</button>
              <button type="submit" disabled={loading || categories.length === 0} className="inline-flex items-center justify-center gap-2 rounded-xl bg-camel px-5 py-2.5 text-sm font-bold text-ink shadow-panel transition hover:bg-camel-hover disabled:cursor-not-allowed disabled:opacity-50">
                <Save className="h-4 w-4" />
                {loading ? 'Đang lưu...' : 'Lưu thay đổi'}
              </button>
            </div>
          </footer>
        </form>
      </section>
    </div>
  );
}
