'use client';

import React, { useState } from 'react';
import { PlusCircle, CheckCircle2, AlertCircle } from 'lucide-react';
import { Product } from '../lib/types';
import { adjustInventory } from '../lib/api';

interface InventoryRestockFormProps {
  products: Product[];
  selectedVariantId: string;
  onVariantChange: (variantId: string) => void;
  onSuccess: () => void;
}

export function InventoryRestockForm({
  products,
  selectedVariantId,
  onVariantChange,
  onSuccess,
}: InventoryRestockFormProps) {
  const [delta, setDelta] = useState(20);
  const [reason, setReason] = useState<'admin_restock' | 'admin_correction'>('admin_restock');
  const [note, setNote] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const allVariants = products.flatMap((p) =>
    (p.variants || []).map((v) => ({
      ...v,
      productName: p.name,
    }))
  );

  async function handleAdjust(e: React.FormEvent) {
    e.preventDefault();
    if (!selectedVariantId) return;
    setSubmitting(true);
    setMessage(null);
    try {
      await adjustInventory(selectedVariantId, delta, reason, note);
      setMessage({ text: 'Đã cập nhật số lượng tồn kho thành công!', type: 'success' });
      setNote('');
      onSuccess();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Lỗi khi nhập kho';
      setMessage({ text: msg, type: 'error' });
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="bg-panel border border-line rounded-2xl p-6 shadow-panel">
      <div className="flex items-center gap-2 mb-4">
        <PlusCircle className="w-5 h-5 text-camel-dark" />
        <h3 className="font-bold text-base text-ink">Nhập / Hiệu chỉnh Tồn Kho</h3>
      </div>

      {message && (
        <div
          className={`p-3 mb-4 rounded-xl text-xs font-semibold flex items-center gap-2 ${
            message.type === 'success'
              ? 'bg-ok-bg text-ok border border-ok-line'
              : 'bg-danger-bg text-danger border border-danger-line'
          }`}
        >
          {message.type === 'success' ? <CheckCircle2 className="w-4 h-4 shrink-0" /> : <AlertCircle className="w-4 h-4 shrink-0" />}
          <span>{message.text}</span>
        </div>
      )}

      <form onSubmit={handleAdjust} className="space-y-4 text-xs">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="lg:col-span-2">
            <label className="text-ink-mid font-semibold block mb-1.5">Chọn Biến thể / SKU</label>
            <select
              value={selectedVariantId}
              onChange={(e) => onVariantChange(e.target.value)}
              className="w-full px-3 py-2 bg-panel border border-line rounded-xl text-ink text-xs truncate focus:outline-none focus:border-camel shadow-panel"
            >
              {allVariants.map((v) => (
                <option key={v.id} value={v.id}>
                  {v.productName} — [Size: {v.size} | Màu: {v.color || 'Tiêu chuẩn'}] (Tồn: {v.stock})
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="text-ink-mid font-semibold block mb-1.5">Số lượng (+/-)</label>
            <input
              type="number"
              value={delta}
              onChange={(e) => setDelta(Number(e.target.value))}
              className="w-full px-3 py-2 bg-panel border border-line rounded-xl text-ink text-xs font-mono font-bold focus:outline-none focus:border-camel shadow-panel"
            />
          </div>

          <div>
            <label className="text-ink-mid font-semibold block mb-1.5">Lý do</label>
            <select
              value={reason}
              onChange={(e) => setReason(e.target.value as 'admin_restock' | 'admin_correction')}
              className="w-full px-3 py-2 bg-panel border border-line rounded-xl text-ink text-xs focus:outline-none focus:border-camel shadow-panel"
            >
              <option value="admin_restock">Nhập kho mới</option>
              <option value="admin_correction">Hiệu chỉnh kiểm kê</option>
            </select>
            <p className="mt-1 text-[11px] leading-4 text-ink-muted">
              {reason === 'admin_restock'
                ? 'Hàng mới nhập về từ nhà cung cấp.'
                : 'Sửa cho khớp số đếm thực tế (hỏng, mất, đếm sai).'}
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 items-end">
          <div className="md:col-span-2">
            <label className="text-ink-mid font-semibold block mb-1.5">Ghi chú</label>
            <input
              type="text"
              placeholder="VD: Hóa đơn nhập đợt 2..."
              value={note}
              onChange={(e) => setNote(e.target.value)}
              className="w-full px-3 py-2 bg-panel border border-line rounded-xl text-ink text-xs placeholder:text-ink-muted focus:outline-none focus:border-camel shadow-panel"
            />
          </div>

          <div>
            <button
              type="submit"
              disabled={submitting}
              className="w-full py-2.5 bg-camel text-ink rounded-xl font-bold hover:bg-camel-hover transition-colors cursor-pointer disabled:opacity-50 text-xs shadow-md shadow-camel/20"
            >
              {submitting ? 'Đang cập nhật...' : 'Xác nhận thay đổi kho'}
            </button>
          </div>
        </div>
      </form>
    </div>
  );
}
