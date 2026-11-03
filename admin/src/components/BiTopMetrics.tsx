'use client';

import { Order, Product, Category } from '../lib/types';

interface BiTopMetricsProps {
  orders: Order[];
  products: Product[];
  categories?: Category[];
}

export function BiTopMetrics({ orders, products }: BiTopMetricsProps) {
  const validOrders = orders.filter((o) => o.status !== 'cancelled');
  const totalRevenue = validOrders.reduce((acc, o) => acc + (o.total || 0), 0);
  const totalOrdersCount = validOrders.length;

  const totalStock = products.reduce((acc, p) => {
    if (p.variants && p.variants.length > 0) {
      return acc + p.variants.reduce((vSum, v) => vSum + (v.stock || 0), 0);
    }
    return acc;
  }, 0);

  const totalStockDisplay = totalStock >= 1000 ? `${(totalStock / 1000).toFixed(1)}K` : `${totalStock}`;
  const totalOrdersDisplay = totalOrdersCount > 0 ? `${totalOrdersCount}` : '0';
  const totalRevDisplay =
    totalRevenue >= 1000000
      ? `${(totalRevenue / 1000000).toFixed(2)}M`
      : totalRevenue > 0
      ? `${new Intl.NumberFormat('vi-VN').format(totalRevenue)} ₫`
      : '0 ₫';

  return (
    <div className="w-full rounded-2xl border border-[#371b63] bg-[#1c0d36]/90 p-4 sm:p-6">
      <h3 className="mb-5 flex items-center gap-2 text-sm font-semibold text-slate-300 sm:mb-6">
        <span className="w-2 h-2 rounded-full bg-cyan-400"></span>
        Số liệu thống kê nhanh
      </h3>
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 sm:gap-x-6 sm:gap-y-7 xl:grid-cols-4">
        <div>
          <div className="text-2xl font-extrabold tracking-tight text-white sm:text-3xl">{totalStockDisplay}</div>
          <div className="text-xs text-slate-400 mt-1">Khối lượng sản xuất & Tồn kho</div>
        </div>
        <div>
          <div className="text-2xl font-extrabold text-cyan-400 sm:text-3xl">{products.length}</div>
          <div className="text-xs text-slate-400 mt-1">Sản phẩm mở bán</div>
        </div>

        <div>
          <div className="text-2xl font-extrabold text-white sm:text-3xl">{totalOrdersDisplay}</div>
          <div className="text-xs text-slate-400 mt-1">Số lượng đặt hàng</div>
        </div>

        <div className="text-right flex flex-col justify-end">
          <div className="break-words text-2xl font-extrabold text-cyan-400 sm:text-3xl">{totalRevDisplay}</div>
          <div className="text-xs text-slate-400 mt-1">Doanh thu bán hàng (VND)</div>
        </div>
      </div>
    </div>
  );
}
