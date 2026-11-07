'use client';

import React from 'react';
import { Sparkles } from 'lucide-react';
import { CircularProgressRing, DonutChart, DonutSegment } from './CircularCharts';

interface DashboardCircularSectionProps {
  orderFulfillmentRate: number;
  completedOrProcessing: number;
  totalOrdersCount: number;
  totalRevenue: number;
  finalDonutSegments: DonutSegment[];
  totalProducts: number;
  dateLabel?: string;
}

export function DashboardCircularSection({
  orderFulfillmentRate,
  completedOrProcessing,
  totalOrdersCount,
  totalRevenue,
  finalDonutSegments,
  totalProducts,
  dateLabel,
}: DashboardCircularSectionProps) {
  const fullRevenueVnd = `${new Intl.NumberFormat('vi-VN').format(totalRevenue)} ₫`;

  return (
    <div className="space-y-6">
      {/* 2 Circular Rings: Tỷ lệ Xử lý Đơn & Doanh thu */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-camel-dark" />
            <h2 className="text-base font-bold text-ink tracking-tight">
              Chỉ số Xử lý Đơn & Doanh thu {dateLabel ? `(${dateLabel})` : ''}
            </h2>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <CircularProgressRing
            value={orderFulfillmentRate}
            size={140}
            strokeWidth={12}
            title="Tỷ lệ Xử lý Đơn"
            subtitle={
              totalOrdersCount > 0
                ? `${completedOrProcessing}/${totalOrdersCount} đơn đã xử lý / hoàn tất`
                : '0/0 đơn hàng'
            }
            gradientFrom="#1f5c8b"
            gradientTo="#3b82f6"
          />

          <CircularProgressRing
            value={totalRevenue > 0 ? 100 : 0}
            size={140}
            strokeWidth={12}
            title={dateLabel ? `Doanh thu (${dateLabel})` : 'Doanh thu Ngày'}
            subtitle={`Tổng thực thu: ${fullRevenueVnd}`}
            valueDisplay={fullRevenueVnd}
            gradientFrom="#b8824a"
            gradientTo="#d4a373"
          />
        </div>
      </div>

      {/* Cơ cấu danh mục (Donut Chart) */}
      <div>
        {finalDonutSegments.length > 0 ? (
          <DonutChart
            title="Phân bổ Cơ cấu Danh mục (Donut Chart)"
            subtitle={`Tỷ trọng ${totalProducts} sản phẩm phân bổ qua ${finalDonutSegments.length} danh mục`}
            segments={finalDonutSegments}
            totalLabel={`${totalProducts} SP`}
            size={190}
            thickness={24}
          />
        ) : (
          <div className="p-6 rounded-2xl bg-panel border border-line shadow-panel">
            <h3 className="font-bold text-ink text-base">
              Phân bổ Cơ cấu Danh mục (Donut Chart)
            </h3>
            <p className="mt-8 mb-6 text-center text-sm text-ink-muted">
              Chưa có dữ liệu sản phẩm theo danh mục.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
