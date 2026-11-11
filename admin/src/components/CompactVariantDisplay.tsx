'use client';

import React from 'react';
import { ProductVariant } from '../lib/types';
import { NGUONG_SAP_HET } from '../lib/inventory-alert';

export function getColorHex(colorName?: string): string {
  if (!colorName) return '#94a3b8';
  const c = colorName.toLowerCase().trim();
  if (c.includes('đen') || c.includes('black')) return '#1e293b';
  if (c.includes('trắng') || c.includes('white')) return '#f8fafc';
  if (c.includes('xám') || c.includes('ghi') || c.includes('grey') || c.includes('gray')) return '#64748b';
  if (c.includes('đỏ') || c.includes('red')) return '#ef4444';
  if (c.includes('navy') || c.includes('xanh than')) return '#1e3a8a';
  if (c.includes('xanh lam') || c.includes('xanh dương') || c.includes('blue')) return '#3b82f6';
  if (c.includes('xanh lá') || c.includes('rêu') || c.includes('green')) return '#10b981';
  if (c.includes('vàng') || c.includes('yellow')) return '#f59e0b';
  if (c.includes('cam') || c.includes('orange')) return '#f97316';
  if (c.includes('hồng') || c.includes('pink')) return '#ec4899';
  if (c.includes('tím') || c.includes('purple')) return '#8b5cf6';
  if (c.includes('nâu') || c.includes('brown')) return '#78350f';
  if (c.includes('be') || c.includes('beige') || c.includes('kem')) return '#d4d4d8';
  return '#38bdf8';
}

export interface CompactVariantDisplayProps {
  variants?: ProductVariant[];
  showStockCount?: boolean;
  sizePrefix?: string;
  colorPrefix?: string;
  className?: string;
}

export function CompactVariantDisplay({
  variants = [],
  showStockCount = false,
  sizePrefix = 'Size:',
  colorPrefix = 'Màu:',
  className = '',
}: CompactVariantDisplayProps) {
  // San pham chua khai bien the thi noi dung thang. Truoc day cho nay ve san
  // day pill S/M/L/XL/XXL, nhin vao tuong san pham co du size trong khi kho
  // khong he co dong nao.
  if (!variants || variants.length === 0) {
    return (
      <div className={`flex flex-col gap-1.5 ${className}`}>
        <span className="text-[11px] italic text-ink-muted">Chưa có biến thể nào</span>
      </div>
    );
  }

  // Aggregate unique sizes and their total stock
  const uniqueSizes: { size: string; stock: number }[] = [];
  const seenSizes = new Set<string>();
  for (const v of variants) {
    const s = (v.size || '').trim();
    if (!s) continue;
    if (!seenSizes.has(s)) {
      seenSizes.add(s);
      uniqueSizes.push({ size: s, stock: v.stock || 0 });
    } else {
      const existing = uniqueSizes.find((item) => item.size === s);
      if (existing) existing.stock += v.stock || 0;
    }
  }

  // Aggregate unique colors and their total stock
  const uniqueColors: { color: string; stock: number }[] = [];
  const seenColors = new Set<string>();
  for (const v of variants) {
    const c = (v.color || '').trim();
    if (!c) continue;
    if (!seenColors.has(c)) {
      seenColors.add(c);
      uniqueColors.push({ color: c, stock: v.stock || 0 });
    } else {
      const existing = uniqueColors.find((item) => item.color === c);
      if (existing) existing.stock += v.stock || 0;
    }
  }

  return (
    <div className={`flex flex-col gap-1.5 ${className}`}>
      {/* Size row on top (Bên trên là Size) */}
      <div className="flex items-center gap-1.5 flex-wrap">
        <span className="text-[10px] font-semibold text-ink-muted uppercase tracking-wider shrink-0">
          {sizePrefix}
        </span>
        <div className="flex items-center gap-1 flex-wrap">
          {uniqueSizes.map((s) => (
            <span
              key={s.size}
              title={showStockCount && s.stock <= NGUONG_SAP_HET ? `Size ${s.size} chỉ còn ${s.stock}` : undefined}
              className={`inline-flex items-center gap-1 px-1.5 py-0.5 rounded-md border text-[11px] font-mono shadow-xs ${
                showStockCount && s.stock <= NGUONG_SAP_HET
                  ? 'bg-danger-bg border-danger-line'
                  : 'bg-panel border-line-strong'
              }`}
            >
              <strong
                className={`font-bold ${
                  showStockCount && s.stock <= NGUONG_SAP_HET ? 'text-danger' : 'text-camel-dark'
                }`}
              >
                {s.size}
              </strong>
              {showStockCount && (
                <span
                  className={`text-[10px] font-bold ${
                    s.stock <= NGUONG_SAP_HET ? 'text-danger' : 'text-ink'
                  }`}
                >
                  ({s.stock})
                </span>
              )}
            </span>
          ))}
        </div>
      </div>

      {/* Color row below (Bên dưới là Màu) */}
      {uniqueColors.length > 0 && (
        <div className="flex items-center gap-1.5 flex-wrap">
          <span className="text-[10px] font-semibold text-ink-muted uppercase tracking-wider shrink-0">
            {colorPrefix}
          </span>
          <div className="flex items-center gap-1 flex-wrap">
            {uniqueColors.map((c) => (
              <span
                key={c.color}
                className="inline-flex items-center gap-1.5 px-1.5 py-0.5 rounded-md bg-tint border border-line text-[11px] text-ink-mid font-medium shadow-xs"
              >
                <span
                  className="w-2 h-2 rounded-full border border-line shrink-0"
                  style={{ backgroundColor: getColorHex(c.color) }}
                />
                <span>{c.color}</span>
                {showStockCount && (
                  <span className="text-ink-muted text-[10px] font-mono">({c.stock})</span>
                )}
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
