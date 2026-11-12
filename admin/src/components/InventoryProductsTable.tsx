'use client';

import React, { useState } from 'react';
import { Product, Category, ProductVariant } from '../lib/types';
import { CompactVariantDisplay } from './CompactVariantDisplay';
import { Search, Boxes, Shirt, Edit3, AlertTriangle } from 'lucide-react';
import { NGUONG_SAP_HET, mucTonKho, nhanTonKho } from '../lib/inventory-alert';

interface InventoryProductsTableProps {
  products: Product[];
  categories: Category[];
  loading: boolean;
  onSelectVariantToAdjust: (variantId: string) => void;
}

export function InventoryProductsTable({
  products,
  categories,
  loading,
  onSelectVariantToAdjust,
}: InventoryProductsTableProps) {
  const [search, setSearch] = useState('');
  const [selectedCat, setSelectedCat] = useState('all');
  const [chiXemSapHet, setChiXemSapHet] = useState(false);

  // Chi lay bien the that cua san pham. Truoc day cho nay bia ra 6 bien the
  // voi ton kho 20-60 cai khi san pham chua co bien the nao, nen thu kho nhin
  // bang thay hang day du trong khi kho that su trong.
  const getVariants = (p: Product): ProductVariant[] => p.variants ?? [];

  const getProductCategory = (p: Product): Category | undefined => {
    if (p.categoryId) {
      const found = categories.find((c) => c.id === p.categoryId || c.slug === p.categoryId);
      if (found) return found;
    }
    const s = p.slug.toLowerCase();
    if (s.startsWith('ao-so-mi')) return categories.find((c) => c.slug === 'ao-so-mi-nam');
    if (s.startsWith('ao-polo') || s.startsWith('ao-thun')) return categories.find((c) => c.slug === 'ao-polo-t-shirt');
    if (s.startsWith('quan-tay') || s.startsWith('quan-kaki') || s.startsWith('quan-au') || s.startsWith('quan-short')) {
      return categories.find((c) => c.slug === 'quan-tay-kaki');
    }
    if (s.startsWith('quan-jeans') || s.startsWith('quan-bo')) return categories.find((c) => c.slug === 'quan-jeans-nam');
    if (
      s.startsWith('ao-khoac') ||
      s.startsWith('ao-blazer') ||
      s.startsWith('ao-mang-to') ||
      s.startsWith('ao-phao') ||
      s.startsWith('ao-gile') ||
      s.startsWith('ao-hoodie')
    ) {
      return categories.find((c) => c.slug === 'ao-khoac-blazer');
    }
    return categories[0];
  };

  /** Tong ton kho that cua mot san pham. */
  const tongTon = (p: Product) => getVariants(p).reduce((sum, v) => sum + v.stock, 0);

  /** San pham can de y: het sach hoac con it hon nguong canh bao. */
  const canChuY = (p: Product) => mucTonKho(tongTon(p)) !== 'du';

  const soSanPhamCanChuY = products.filter(canChuY).length;

  const filteredProducts = products.filter((p) => {
    const matchesSearch =
      p.name.toLowerCase().includes(search.toLowerCase()) ||
      p.slug.toLowerCase().includes(search.toLowerCase());
    const pCat = getProductCategory(p);
    const matchesCat = selectedCat === 'all' || p.categoryId === selectedCat || pCat?.id === selectedCat;
    const matchesAlert = !chiXemSapHet || canChuY(p);
    return matchesSearch && matchesCat && matchesAlert;
  });

  const getCategoryName = (p: Product) => {
    const cat = getProductCategory(p);
    return cat?.name || 'Thời trang nam';
  };

  return (
    <div className="bg-panel border border-line rounded-2xl overflow-hidden shadow-xl">
      <div className="p-5 border-b border-line flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h3 className="font-bold text-ink text-base flex items-center gap-2">
            <Boxes className="w-5 h-5 text-camel-dark" />
            Danh Sách Toàn Bộ Sản Phẩm & Số Lượng Đang Có Trong Kho
          </h3>
          <p className="text-xs text-ink-muted mt-0.5">
            Tổng hợp {products.length} sản phẩm và chi tiết số lượng tồn kho theo từng kích cỡ
          </p>
          {soSanPhamCanChuY > 0 && (
            <button
              type="button"
              onClick={() => setChiXemSapHet((truoc) => !truoc)}
              className={`mt-2 inline-flex cursor-pointer items-center gap-1.5 rounded-full border px-3 py-1 text-[11px] font-semibold transition-colors ${
                chiXemSapHet
                  ? 'bg-danger text-white border-danger'
                  : 'bg-danger-bg text-danger border-danger-line hover:bg-danger/10'
              }`}
            >
              <AlertTriangle className="h-3.5 w-3.5" />
              {soSanPhamCanChuY} sản phẩm còn từ {NGUONG_SAP_HET} cái trở xuống
              <span className="font-normal opacity-80">
                {chiXemSapHet ? '· đang lọc, bấm để xem tất cả' : '· bấm để lọc'}
              </span>
            </button>
          )}
        </div>

        <div className="flex items-center gap-2 w-full sm:w-auto">
          <div className="relative flex-1 sm:w-64">
            <Search className="w-3.5 h-3.5 text-ink-muted absolute left-3 top-2.5" />
            <input
              type="text"
              placeholder="Tìm theo tên hoặc SKU..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-8 pr-3 py-1.5 bg-panel border border-line rounded-xl text-xs text-ink placeholder:text-ink-muted focus:outline-none focus:border-camel shadow-panel"
            />
          </div>

          <select
            value={selectedCat}
            onChange={(e) => setSelectedCat(e.target.value)}
            className="px-3 py-1.5 bg-panel border border-line rounded-xl text-xs text-ink-mid shadow-panel"
          >
            <option value="all">Tất cả danh mục</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {loading ? (
        <div className="py-20 text-center text-ink-muted text-sm">Đang tải toàn bộ sản phẩm trong kho...</div>
      ) : filteredProducts.length === 0 ? (
        <div className="py-20 text-center text-ink-muted text-sm">Không tìm thấy sản phẩm nào</div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-line text-xs text-ink-muted uppercase tracking-wider font-semibold bg-tint">
                <th className="py-3 px-4">Sản phẩm</th>
                <th className="py-3 px-4">Danh mục</th>
                <th className="py-3 px-4">Giá bán</th>
                <th className="py-3 px-4">Tổng số lượng có</th>
                <th className="py-3 px-4">Phân loại & Tồn kho (Size trên / Màu dưới)</th>
                <th className="py-3 px-4 text-right">Hiệu chỉnh</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-line text-ink-mid text-xs">
              {filteredProducts.map((p) => {
                const variants = getVariants(p);
                const totalStock = variants.reduce((sum, v) => sum + v.stock, 0);
                const muc = mucTonKho(totalStock);

                return (
                  <tr
                    key={p.id}
                    className={`transition-colors hover:bg-tint ${
                      muc === 'du' ? '' : 'bg-danger-bg/40'
                    }`}
                  >
                    <td className="py-3 px-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-tint border border-line-strong flex items-center justify-center shrink-0">
                          <Shirt className="w-5 h-5 text-camel-dark" />
                        </div>
                        <div>
                          <p className="font-semibold text-ink line-clamp-1">{p.name}</p>
                          <p className="text-[11px] font-mono text-ink-muted">ID: {p.id.slice(0, 13)}...</p>
                        </div>
                      </div>
                    </td>

                    <td className="py-3 px-4">
                      <span className="px-2 py-0.5 rounded-md bg-panel border border-line text-ink-mid text-[11px]">
                        {getCategoryName(p)}
                      </span>
                    </td>

                    <td className="py-3 px-4 font-mono font-semibold text-ink">
                      {p.price.toLocaleString('vi-VN')} đ
                    </td>

                    <td className="py-3 px-4">
                      <span
                        className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full font-mono font-bold text-xs border ${
                          muc === 'du'
                            ? 'bg-ok-bg text-ok border-ok-line'
                            : 'bg-danger-bg text-danger border-danger-line'
                        }`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${
                            muc === 'du' ? 'bg-ok' : 'bg-danger'
                          }`}
                        />
                        {totalStock} cái
                        {muc !== 'du' && (
                          <span className="font-sans text-[10px] font-semibold">
                            · {nhanTonKho(muc)}
                          </span>
                        )}
                      </span>
                    </td>

                    <td className="py-3 px-4 min-w-[260px]">
                      <CompactVariantDisplay variants={variants} showStockCount={true} />
                    </td>

                    <td className="py-3 px-4 text-right">
                      {variants.length > 0 && (
                        <button
                          onClick={() => {
                            // Chon san bien the it hang nhat, vi do moi la cai
                            // thu kho dinh nhap. Truoc day luon chon bien the
                            // dau tien nen bam xong con phai doi lai size.
                            const canNhap = [...variants].sort((a, b) => a.stock - b.stock)[0];
                            onSelectVariantToAdjust(canNhap.id);
                          }}
                          className="px-2.5 py-1 rounded-lg bg-tint hover:bg-tint-strong text-camel-dark border border-line-strong text-[11px] font-semibold transition-all inline-flex items-center gap-1 cursor-pointer"
                        >
                          <Edit3 className="w-3 h-3" />
                          Nhập kho
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
