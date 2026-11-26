'use client';

import React, { useMemo, useState } from 'react';
import { ReasonBadge } from './Badge';
import { InventoryMovement } from '../lib/types';
import { Clock, ArrowUpRight, ArrowDownRight } from 'lucide-react';

interface InventoryMovementsTableProps {
  movements: InventoryMovement[];
  loading: boolean;
}

/**
 * Các nhóm lọc nhật ký kho.
 *
 * Gộp theo việc chứ không theo đúng từng giá trị trong database: người xem
 * muốn biết "hàng hỏng mất bao nhiêu", không quan tâm nó đến từ màn chỉnh kho
 * hay từ duyệt trả hàng.
 */
const NHOM_LOC: { nhan: string; lyDo: string[] | null }[] = [
  { nhan: 'Tất cả', lyDo: null },
  { nhan: 'Hàng hỏng / mất', lyDo: ['damaged', 'admin_damaged'] },
  { nhan: 'Nhập kho', lyDo: ['restock', 'admin_restock'] },
  { nhan: 'Khách đặt / hủy', lyDo: ['order', 'order_created', 'cancel', 'order_cancelled'] },
  { nhan: 'Trả hàng / đổi size', lyDo: ['return', 'exchange'] },
  { nhan: 'Kiểm kê', lyDo: ['adjust', 'admin_correction'] },
];

export function InventoryMovementsTable({ movements, loading }: InventoryMovementsTableProps) {
  const [nhomDangXem, setNhomDangXem] = useState(0);

  const danhSach = useMemo(() => {
    const lyDo = NHOM_LOC[nhomDangXem]?.lyDo;
    if (!lyDo) return movements;
    return movements.filter((m) => lyDo.includes(m.reason));
  }, [movements, nhomDangXem]);

  // Dem rieng hang hong de nguoi xem thay ngay co van de hay khong, khong phai
  // bam vao loc moi biet.
  // So sanh qua string: may chu doi ten 'damaged' thanh 'admin_damaged' truoc
  // khi tra ve, nhung du lieu cu co the con mang ten goc.
  const soDongHangHong = useMemo(
    () => movements.filter((m) => NHOM_LOC[1].lyDo!.includes(m.reason)).length,
    [movements],
  );

  return (
    <div className="bg-panel border border-line rounded-2xl overflow-hidden shadow-xl">
      <div className="p-4 border-b border-line space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <span className="flex items-center gap-1.5 font-bold text-ink text-sm">
            <Clock className="w-4 h-4 text-camel-dark" />
            Nhật ký kho
          </span>
          {soDongHangHong > 0 && (
            <span className="rounded-full border border-danger-line bg-danger-bg px-2.5 py-1 text-[11px] font-semibold text-danger">
              {soDongHangHong} lần ghi nhận hàng hỏng / mất
            </span>
          )}
        </div>

        <div className="flex flex-wrap gap-1.5">
          {NHOM_LOC.map((nhom, i) => (
            <button
              key={nhom.nhan}
              type="button"
              onClick={() => setNhomDangXem(i)}
              className={`cursor-pointer rounded-full border px-3 py-1 text-[11px] font-semibold transition-colors ${
                i === nhomDangXem
                  ? 'border-camel/40 bg-camel-tint text-camel-dark'
                  : 'border-line text-ink-muted hover:bg-tint'
              }`}
            >
              {nhom.nhan}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div className="py-20 text-center text-ink-muted text-sm">Đang tải lịch sử kho...</div>
      ) : danhSach.length === 0 ? (
        <div className="py-20 text-center text-ink-muted text-sm">
          {movements.length === 0
            ? 'Chưa có lịch sử biến động nào'
            : 'Không có dòng nào thuộc nhóm này'}
        </div>
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
              {danhSach.map((m) => (
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
