'use client';

import { useState } from 'react';
import { AlertTriangle, LoaderCircle, Package, Trash2, X } from 'lucide-react';
import { deleteProduct } from '../lib/api';
import type { Product } from '../lib/types';

interface DeleteProductModalProps {
  product: Product;
  onClose: () => void;
  onDeleted: () => void;
}

export function DeleteProductModal({ product, onClose, onDeleted }: DeleteProductModalProps) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleDelete = async () => {
    setLoading(true);
    setError(null);
    try {
      await deleteProduct(product.id);
      onDeleted();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Không thể xóa sản phẩm.');
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-ink/40 p-4 backdrop-blur-md" onMouseDown={(event) => event.target === event.currentTarget && !loading && onClose()}>
      <section role="alertdialog" aria-modal="true" aria-labelledby="delete-product-title" aria-describedby="delete-product-description" className="w-full max-w-md overflow-hidden rounded-3xl border border-danger-line bg-panel text-ink shadow-panel-lg">
        <header className="relative overflow-hidden border-b border-line px-6 pb-5 pt-6">
          <div className="absolute inset-0 bg-gradient-to-br from-danger-bg via-transparent to-transparent" />
          <button type="button" onClick={onClose} disabled={loading} aria-label="Đóng" className="absolute right-5 top-5 rounded-lg border border-line-strong bg-tint p-2 text-ink-muted transition hover:bg-tint-strong hover:text-ink disabled:opacity-50">
            <X className="h-4 w-4" />
          </button>
          <div className="relative flex h-12 w-12 items-center justify-center rounded-2xl border border-danger-line bg-danger-bg text-danger">
            <AlertTriangle className="h-6 w-6" />
          </div>
          <h2 id="delete-product-title" className="relative mt-4 text-xl font-bold">Xóa sản phẩm?</h2>
          <p id="delete-product-description" className="relative mt-1 max-w-sm text-sm leading-6 text-ink-muted">
            Sản phẩm sẽ được ẩn khỏi ứng dụng. Thông tin vẫn được giữ để bảo toàn các đơn hàng đã phát sinh.
          </p>
        </header>

        <div className="p-6">
          <div className="flex items-center gap-4 rounded-2xl border border-line bg-tint p-3">
            <div className="flex h-16 w-14 shrink-0 items-center justify-center overflow-hidden rounded-xl border border-line bg-panel shadow-panel">
              {product.thumbnailUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={product.thumbnailUrl} alt={product.name} className="h-full w-full object-cover" />
              ) : <Package className="h-6 w-6 text-ink-muted" />}
            </div>
            <div className="min-w-0 flex-1">
              <p className="line-clamp-2 text-sm font-semibold text-ink">{product.name}</p>
              <p className="mt-1 font-mono text-xs text-ink-muted">Mã: {product.id}</p>
              <p className="mt-1 text-sm font-bold text-camel-dark">{product.price.toLocaleString('vi-VN')} ₫</p>
            </div>
          </div>

          {error && <div role="alert" className="mt-4 rounded-xl border border-danger-line bg-danger-bg px-4 py-3 text-sm text-danger">{error}</div>}

          <div className="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
            <button type="button" onClick={onClose} disabled={loading} className="rounded-xl border border-line-strong px-4 py-2.5 text-sm font-semibold text-ink-mid transition hover:bg-tint disabled:opacity-50">Giữ lại</button>
            <button type="button" onClick={handleDelete} disabled={loading} className="inline-flex items-center justify-center gap-2 rounded-xl bg-danger px-4 py-2.5 text-sm font-bold text-white shadow-panel transition hover:bg-danger/90 disabled:cursor-not-allowed disabled:opacity-60">
              {loading ? <LoaderCircle className="h-4 w-4 animate-spin" /> : <Trash2 className="h-4 w-4" />}
              {loading ? 'Đang xử lý...' : 'Xóa sản phẩm'}
            </button>
          </div>
        </div>
      </section>
    </div>
  );
}
