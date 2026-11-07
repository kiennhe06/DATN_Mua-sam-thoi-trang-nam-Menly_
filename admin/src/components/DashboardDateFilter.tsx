'use client';

import React from 'react';
import { Calendar, Filter, RotateCcw } from 'lucide-react';

export type DateFilterPreset = 'all' | 'today' | 'yesterday' | '7days' | '30days' | 'custom_day' | 'custom_range';

interface DashboardDateFilterProps {
  preset: DateFilterPreset;
  customDay: string;
  fromDay: string;
  toDay: string;
  onPresetChange: (preset: DateFilterPreset) => void;
  onCustomDayChange: (day: string) => void;
  onRangeChange: (from: string, to: string) => void;
  onReset: () => void;
  ordersCount: number;
  revenue: number;
}

export function DashboardDateFilter({
  preset,
  customDay,
  fromDay,
  toDay,
  onPresetChange,
  onCustomDayChange,
  onRangeChange,
  onReset,
  ordersCount,
  revenue,
}: DashboardDateFilterProps) {
  const formattedRevenue = `${new Intl.NumberFormat('vi-VN').format(revenue)} ₫`;

  const presetButtons: { label: string; value: DateFilterPreset }[] = [
    { label: 'Tất cả', value: 'all' },
    { label: 'Hôm nay', value: 'today' },
    { label: 'Hôm qua', value: 'yesterday' },
    { label: '7 ngày qua', value: '7days' },
    { label: '30 ngày qua', value: '30days' },
  ];

  return (
    <div className="bg-panel border border-line rounded-2xl p-5 space-y-4 shadow-panel">
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        {/* Title & Presets */}
        <div className="flex flex-wrap items-center gap-2">
          <div className="flex items-center gap-2 text-ink-mid font-semibold text-xs mr-2">
            <Filter className="w-4 h-4 text-camel-dark" />
            <span>Lọc ngày:</span>
          </div>

          {presetButtons.map((btn) => (
            <button
              key={btn.value}
              type="button"
              onClick={() => onPresetChange(btn.value)}
              className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all cursor-pointer ${
                preset === btn.value
                  ? 'bg-camel text-ink font-bold shadow-panel'
                  : 'bg-panel text-ink-mid hover:text-ink hover:bg-tint border border-line'
              }`}
            >
              {btn.label}
            </button>
          ))}
        </div>

        {/* Live Filter Result Summary */}
        <div className="flex items-center gap-3 bg-tint border border-line px-4 py-2 rounded-lg text-xs">
          <span className="text-ink-muted">Kết quả lọc:</span>
          <span className="font-bold text-camel-dark font-mono">{ordersCount} đơn</span>
          <span className="text-ink-muted">|</span>
          <span className="font-bold text-ok font-mono">{formattedRevenue}</span>
        </div>
      </div>

      {/* Custom Date Pickers */}
      <div className="pt-3 border-t border-line flex flex-wrap items-center gap-4 text-xs">
        {/* Single specific date picker */}
        <div className="flex items-center gap-2">
          <span className="text-ink-muted flex items-center gap-1.5 font-medium">
            <Calendar className="w-3.5 h-3.5 text-camel-dark" />
            Chọn ngày cụ thể:
          </span>
          <input
            type="date"
            value={customDay}
            onChange={(e) => onCustomDayChange(e.target.value)}
            className={`px-2.5 py-1.5 rounded-xl bg-panel border text-ink font-mono text-xs focus:outline-none focus:border-camel ${
              preset === 'custom_day' ? 'border-camel text-camel-dark' : 'border-line'
            }`}
          />
        </div>

        {/* Date range picker */}
        <div className="flex items-center gap-2">
          <span className="text-ink-muted font-medium">Khoảng ngày:</span>
          <input
            type="date"
            value={fromDay}
            onChange={(e) => onRangeChange(e.target.value, toDay)}
            className={`px-2 py-1.5 rounded-xl bg-panel border text-ink font-mono text-xs focus:outline-none focus:border-camel ${
              preset === 'custom_range' ? 'border-camel' : 'border-line'
            }`}
          />
          <span className="text-ink-muted">-</span>
          <input
            type="date"
            value={toDay}
            onChange={(e) => onRangeChange(fromDay, e.target.value)}
            className={`px-2 py-1.5 rounded-xl bg-panel border text-ink font-mono text-xs focus:outline-none focus:border-camel ${
              preset === 'custom_range' ? 'border-camel' : 'border-line'
            }`}
          />
        </div>

        {/* Reset button if not all */}
        {preset !== 'all' && (
          <button
            type="button"
            onClick={onReset}
            className="flex items-center gap-1 px-2.5 py-1 rounded-lg text-ink-muted hover:text-ink bg-tint hover:bg-tint-strong transition-colors ml-auto cursor-pointer"
            title="Xem tất cả ngày"
          >
            <RotateCcw className="w-3 h-3" />
            <span>Mặc định (Tất cả)</span>
          </button>
        )}
      </div>
    </div>
  );
}
