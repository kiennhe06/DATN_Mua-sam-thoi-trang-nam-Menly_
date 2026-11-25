'use client';

import React from 'react';
import { AlertTriangle } from 'lucide-react';
import { Modal } from './Modal';
import { Order, OrderStatus } from '../lib/types';
import {
  NHAN_TRANG_THAI_DON,
  cacTrangThaiTiepTheo,
  laTrangThaiKetThuc,
} from '../lib/order-status-flow';

/** Ly do huy duoc gui cho khach nen phai viet du y, khong nhan mot hai chu. */
const DO_DAI_LY_DO_HUY_TOI_THIEU = 10;

/** Gioi han cua o nhap, de ghi chu khong tran ra ngoai man lich su don. */
const DO_DAI_GHI_CHU_TOI_DA = 500;

/**
 * Kiem rieng phan ghi chu.
 *
 * Luat chuyen trang thai nam o order-status-flow.ts va duoc may chu chan that;
 * con hai quy tac duoi day chi la rang buoc cua man hinh, may chu khong ep.
 * De o day de khong lan vao ban sao luat kia.
 */
function kiemTraGhiChu(huyDon: boolean, ghiChu: string): string | null {
  const daCat = ghiChu.trim();
  if (huyDon && daCat.length < DO_DAI_LY_DO_HUY_TOI_THIEU) {
    return `Hủy đơn phải ghi rõ lý do (ít nhất ${DO_DAI_LY_DO_HUY_TOI_THIEU} ký tự). Lý do này được gửi cho khách hàng và lưu vào lịch sử đơn.`;
  }
  if (daCat.length > DO_DAI_GHI_CHU_TOI_DA) {
    return `Ghi chú tối đa ${DO_DAI_GHI_CHU_TOI_DA} ký tự, hiện đang ${daCat.length}.`;
  }
  return null;
}

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
  // Modal tu tra ve null khi dong, nen khong co don thi khong can dung gi ca.
  if (!selectedOrder) return null;

  const hienTai = selectedOrder.status;
  const ketThuc = laTrangThaiKetThuc(hienTai);
  const trangThaiChonDuoc = cacTrangThaiTiepTheo(hienTai);
  const huyDon = newStatus === 'cancelled';

  // Tinh ngay trong luc go chu khong doi den luc bam Luu, de nguoi quan tri
  // thay sai o dau tu truoc.
  const loi = ketThuc ? null : kiemTraGhiChu(huyDon, statusNote);

  const soKyTu = statusNote.trim().length;
  const quaDai = soKyTu > DO_DAI_GHI_CHU_TOI_DA;

  return (
    <Modal
      isOpen
      onClose={onClose}
      title={`Cập nhật trạng thái đơn hàng #${selectedOrder.code}`}
    >
      <div className="space-y-4">
        {ketThuc ? (
          <div className="p-4 rounded-xl bg-danger-bg border border-danger-line text-danger text-sm">
            Đơn hàng này đang ở trạng thái{' '}
            <strong>{NHAN_TRANG_THAI_DON[hienTai].toUpperCase()}</strong> và là trạng thái
            kết thúc. Không thể chuyển sang trạng thái nào khác.
          </div>
        ) : trangThaiChonDuoc.length === 0 ? (
          <div className="p-4 rounded-xl bg-danger-bg border border-danger-line text-danger text-sm">
            Không có trạng thái nào đi tiếp được từ{' '}
            <strong>{NHAN_TRANG_THAI_DON[hienTai]}</strong>.
          </div>
        ) : (
          <>
            <div className="flex items-center gap-2 text-xs">
              <span className="text-ink-mid font-semibold">Trạng thái hiện tại:</span>
              <span className="px-2.5 py-1 rounded-lg bg-tint text-camel-dark font-bold border border-line-strong">
                {NHAN_TRANG_THAI_DON[hienTai]}
              </span>
            </div>

            <div>
              <label
                htmlFor="trang-thai-moi"
                className="text-xs text-ink-mid font-semibold"
              >
                Chọn trạng thái mới
              </label>
              <select
                id="trang-thai-moi"
                value={newStatus}
                onChange={(e) => onStatusChange(e.target.value as OrderStatus)}
                className="w-full mt-1.5 px-3 py-2 bg-panel border border-line rounded-xl text-sm text-ink focus:outline-none focus:border-camel shadow-panel"
              >
                {/* Chi liet ke trang thai that su di tiep duoc, thay vi do ca 7
                    trang thai roi de may chu tu choi sau. */}
                {trangThaiChonDuoc.map((status) => (
                  <option key={status} value={status}>
                    {NHAN_TRANG_THAI_DON[status]} ({status})
                  </option>
                ))}
              </select>
              <p className="mt-1 text-[11px] leading-4 text-ink-muted">
                Đơn hàng đi theo thứ tự: Chờ thanh toán → Đang xử lý → Đang giao hàng →
                Đã giao hàng → Đã hoàn tất.
              </p>
            </div>

            {huyDon && (
              <div className="p-3 rounded-xl bg-danger-bg border border-danger-line text-danger text-xs flex gap-2">
                <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
                <span>
                  Hủy đơn sẽ cộng trả toàn bộ hàng về kho và gửi thông báo cho khách.
                  <strong> Đã hủy là trạng thái kết thúc, không hoàn tác được.</strong>
                </span>
              </div>
            )}

            <div>
              <label
                htmlFor="ghi-chu-trang-thai"
                className="text-xs text-ink-mid font-semibold"
              >
                {huyDon ? 'Lý do hủy đơn (bắt buộc)' : 'Ghi chú hành động (tùy chọn)'}
              </label>
              <textarea
                id="ghi-chu-trang-thai"
                rows={3}
                maxLength={DO_DAI_GHI_CHU_TOI_DA + 50}
                placeholder={
                  huyDon
                    ? 'VD: Khách báo đặt nhầm size, đã xác nhận hủy qua điện thoại'
                    : 'VD: Đã gửi mã vận đơn qua đối tác vận chuyển GHTK...'
                }
                value={statusNote}
                onChange={(e) => onNoteChange(e.target.value)}
                className={`w-full mt-1.5 px-3 py-2 bg-panel border rounded-xl text-sm text-ink placeholder:text-ink-muted focus:outline-none shadow-panel ${
                  quaDai ? 'border-danger-line focus:border-danger' : 'border-line focus:border-camel'
                }`}
              />
              <div className="mt-1 flex justify-between gap-2 text-[11px] leading-4">
                <span className="text-ink-muted">
                  {huyDon
                    ? 'Lý do này được gửi cho khách hàng và lưu vào lịch sử đơn.'
                    : 'Ghi chú được lưu vào lịch sử đơn để đối chiếu về sau.'}
                </span>
                <span className={quaDai ? 'text-danger font-semibold' : 'text-ink-muted'}>
                  {soKyTu}/{DO_DAI_GHI_CHU_TOI_DA}
                </span>
              </div>
            </div>

            {loi && (
              <div
                role="alert"
                className="p-3 rounded-xl bg-danger-bg border border-danger-line text-danger text-xs flex gap-2"
              >
                <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
                <span>{loi}</span>
              </div>
            )}
          </>
        )}

        <div className="flex justify-end gap-2 pt-2">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-xl text-xs font-semibold text-ink-muted hover:text-ink cursor-pointer"
          >
            {ketThuc ? 'Đóng' : 'Hủy bỏ'}
          </button>
          {!ketThuc && trangThaiChonDuoc.length > 0 && (
            <button
              type="button"
              disabled={updating || loi !== null}
              onClick={onSave}
              className="px-5 py-2 rounded-xl text-xs font-bold bg-camel text-ink hover:bg-camel-hover transition-colors disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
            >
              {updating ? 'Đang cập nhật...' : huyDon ? 'Xác nhận hủy đơn' : 'Lưu trạng thái'}
            </button>
          )}
        </div>
      </div>
    </Modal>
  );
}
