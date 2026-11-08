'use client';

import { useState, useEffect, useCallback } from 'react';
import { Header } from '../../components/Header';
import { InventoryProductsTable } from '../../components/InventoryProductsTable';
import { InventoryRestockForm } from '../../components/InventoryRestockForm';
import { InventoryMovementsTable } from '../../components/InventoryMovementsTable';
import {
  fetchInventoryMovements,
  fetchAdminProducts,
  fetchCategories,
} from '../../lib/api';
import { InventoryMovement, Product, Category } from '../../lib/types';

export default function InventoryPage() {
  const [movements, setMovements] = useState<InventoryMovement[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [selectedVariantId, setSelectedVariantId] = useState('');

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [movs, prods, cats] = await Promise.all([
        fetchInventoryMovements(),
        fetchAdminProducts({ limit: 400 }),
        fetchCategories(),
      ]);
      setMovements(movs);
      setProducts(prods.items || []);
      setCategories(cats || []);
      if (
        prods.items &&
        prods.items.length > 0 &&
        prods.items[0].variants &&
        prods.items[0].variants.length > 0
      ) {
        setSelectedVariantId(prods.items[0].variants[0].id);
      }
      setLoadError(null);
    } catch (err) {
      // Truoc day loi bi nuot: bang kho hien rong y het luc kho that su trong,
      // thu kho nhin vao tuong khong co hang nao can nhap.
      console.error('Loi tai du lieu kho:', err);
      setLoadError(err instanceof Error ? err.message : 'Không tải được dữ liệu kho.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const reloadMovementsAndProducts = async () => {
    const [updatedMovs, updatedProds] = await Promise.all([
      fetchInventoryMovements(),
      fetchAdminProducts({ limit: 400 }),
    ]);
    setMovements(updatedMovs);
    setProducts(updatedProds.items || []);
  };

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Quản lý Kho Hàng & Tồn Kho Toàn Bộ Sản Phẩm"
        subtitle={`Theo dõi ${products.length} sản phẩm, số lượng tồn kho theo từng kích cỡ và hiệu chỉnh xuất nhập tồn`}
        onRefresh={loadData}
      />

      <div className="flex-1 space-y-6 p-4 sm:space-y-8 sm:p-6 xl:p-8">
        {loadError && (
          <p className="rounded-2xl border border-danger-line bg-danger-bg px-4 py-3 text-sm text-danger">
            Không tải được dữ liệu kho: {loadError} — số liệu bên dưới chưa phản ánh kho thật.
          </p>
        )}
        {/* Quick restock and policy cards */}
        <InventoryRestockForm
          products={products}
          selectedVariantId={selectedVariantId}
          onVariantChange={setSelectedVariantId}
          onSuccess={reloadMovementsAndProducts}
        />

        {/* 1. HIỂN THỊ TOÀN BỘ SẢN PHẨM & SỐ LƯỢNG ĐANG CÓ */}
        <InventoryProductsTable
          products={products}
          categories={categories}
          loading={loading}
          onSelectVariantToAdjust={(variantId) => {
            setSelectedVariantId(variantId);
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }}
        />

        {/* 2. LỊCH SỬ BIẾN ĐỘNG KHO */}
        <InventoryMovementsTable movements={movements} loading={loading} />
      </div>
    </div>
  );
}
