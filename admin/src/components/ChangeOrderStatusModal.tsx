'use client';

import React from 'react';
import { Modal } from './Modal';
import { Order, OrderStatus } from '../lib/types';

interface ChangeOrderStatusModalProps {
  selectedOrder: Order | null;
  newStatus: OrderStatus;
  statusNote: string;
  updating: boolean;
  onClose: () => void;
  onStatusChange: (status: OrderStatus) => void;
  onNoteChange: (note: string) => void;
  onSave: () => void;
}

export function ChangeOrderStatusModal({
  selectedOrder,
  newStatus,
  statusNote,
  updating,
  onClose,
  onStatusChange,
  onNoteChange,
  onSave,
}: ChangeOrderStatusModalProps) {
  return (
    <Modal
      isOpen={Boolean(selectedOrder)}
      onClose={onClose}
      title={`Cập nhật trạng thái đơn hàng #${selectedOrder?.code}`}
    >
      {selectedOrder && (
        <div className="space-y-4">
          {selectedOrder.status === 'cancelled' ? (
            <div className="p-4 rounded-xl bg-danger-bg border border-danger-line text-danger text-sm">
              Đơn hàng này đã ở trạng thái <strong>ĐÃ HUỶ</strong> và là trạng thái kết thúc. Không thể chuyển sang trạng thái nào khác.
            </div>
          ) : (
            <>
              <div>
                <label className="text-xs text-ink-mid font-semibold">Chọn trạng thái mới</label>
                <select
                  value={newStatus}
                  onChange={(e) => onStatusChange(e.target.value as OrderStatus)}
                  className="w-full mt-1.5 px-3 py-2 bg-panel border border-line rounded-xl text-sm text-ink focus:outline-none focus:border-camel shadow-panel"
                >
                  <option value="pending_payment">Chờ thanh toán (pending_payment)</option>
                  <option value="paid">Đã thanh toán (paid)</option>
                  <option value="processing">Đang xử lý (processing)</option>
                  <option value="shipping">Đang giao hàng (shipping)</option>
                  <option value="delivered">Đã giao hàng (delivered)</option>
                  <option value="completed">Đã hoàn tất (completed)</option>
                  <option value="cancelled">Hủy đơn hàng (cancelled)</option>
                </select>
              </div>

              <div>
                <label className="text-xs text-ink-mid font-semibold">Ghi chú hành động (Tùy chọn)</label>
                <textarea
                  rows={3}
                  placeholder="VD: Đã gửi mã vận đơn qua đối tác vận chuyển GHTK..."
                  value={statusNote}
                  onChange={(e) => onNoteChange(e.target.value)}
                  className="w-full mt-1.5 px-3 py-2 bg-panel border border-line rounded-xl text-sm text-ink placeholder:text-ink-muted focus:outline-none focus:border-camel shadow-panel"
                />
              </div>
            </>
          )}

          <div className="flex justify-end gap-2 pt-2">
            <button
              onClick={onClose}
              className="px-4 py-2 rounded-xl text-xs font-semibold text-ink-muted hover:text-ink cursor-pointer"
            >
              {selectedOrder.status === 'cancelled' ? 'Đóng' : 'Hủy bỏ'}
            </button>
            {selectedOrder.status !== 'cancelled' && (
              <button
                disabled={updating}
                onClick={onSave}
                className="px-5 py-2 rounded-xl text-xs font-bold bg-camel text-ink hover:bg-camel-hover transition-colors disabled:opacity-50 cursor-pointer"
              >
                {updating ? 'Đang cập nhật...' : 'Lưu trạng thái'}
              </button>
            )}
          </div>
        </div>
      )}
    </Modal>
  );
}
