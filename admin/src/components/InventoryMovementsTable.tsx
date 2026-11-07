'use client';

import React from 'react';
import { ReasonBadge } from './Badge';
import { InventoryMovement } from '../lib/types';
import { Clock, ArrowUpRight, ArrowDownRight } from 'lucide-react';

interface InventoryMovementsTableProps {
  movements: InventoryMovement[];
  loading: boolean;
}

export function InventoryMovementsTable({ movements, loading }: InventoryMovementsTableProps) {
  return (
    <div className="bg-panel border border-line rounded-2xl overflow-hidden shadow-xl">
      <div className="p-4 border-b border-line flex items-center justify-between text-xs text-ink-muted font-medium">
        <span className="flex items-center gap-1.5 font-bold text-ink text-sm">
          <Clock className="w-4 h-4 text-camel-dark" />
          Lịch sử Biến động Kho (Inventory Movements)
        </span>
        <span>Ghi nhận thời gian thực</span>
      </div>

      {loading ? (
        <div className="py-20 text-center text-ink-muted text-sm">Đang tải lịch sử kho...</div>
      ) : movements.length === 0 ? (
        <div className="py-20 text-center text-ink-muted text-sm">Chưa có lịch sử biến động nào</div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-line text-xs text-ink-muted uppercase tracking-wider font-semibold bg-tint">
                <th className="py-3 px-4">Thời gian</th>
                <th className="py-3 px-4">Sản phẩm / SKU</th>
                <th className="py-3 px-4">Thay đổi (+/-)</th>
                <th className="py-3 px-4">Lý do</th>
                <th className="py-3 px-4">Ghi chú</th>
                <th className="py-3 px-4">Người thực hiện</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-line text-ink-mid">
              {movements.map((m) => (
                <tr key={m.id} className="hover:bg-tint transition-colors text-xs">
                  <td className="py-3 px-4 font-mono text-ink-muted whitespace-nowrap">
                    {new Date(m.createdAt).toLocaleString('vi-VN')}
                  </td>
                  <td className="py-3 px-4 font-semibold text-ink">
                    {m.productName || m.sku || m.variantId}
                  </td>
                  <td className="py-3 px-4">
                    <span
                      className={`font-bold font-mono px-2 py-0.5 rounded-md flex items-center gap-1 w-fit ${
                        m.delta > 0
                          ? 'text-ok bg-ok-bg'
                          : 'text-danger bg-danger-bg'
                      }`}
                    >
                      {m.delta > 0 ? (
                        <ArrowUpRight className="w-3.5 h-3.5" />
                      ) : (
                        <ArrowDownRight className="w-3.5 h-3.5" />
                      )}
                      {m.delta > 0 ? `+${m.delta}` : m.delta}
                    </span>
                  </td>
                  <td className="py-3 px-4">
                    <ReasonBadge reason={m.reason} />
                  </td>
                  <td className="py-3 px-4 text-ink-muted max-w-xs truncate">
                    {m.note || 'Không có'}
                  </td>
                  <td className="py-3 px-4 font-mono text-ink-muted">
                    {m.actorId || 'system'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
