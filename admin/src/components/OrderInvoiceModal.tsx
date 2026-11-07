'use client';

import { useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Printer, X } from 'lucide-react';
import { Order } from '../lib/types';

interface OrderInvoiceModalProps {
  order: Order | null;
  onClose: () => void;
}

const STATUS_LABELS: Record<string, string> = {
  pending_payment: 'Chờ thanh toán',
  paid: 'Đã thanh toán',
  processing: 'Đang xử lý',
  shipping: 'Đang giao hàng',
  delivered: 'Đã giao hàng',
  completed: 'Đã hoàn tất',
  cancelled: 'Đã hủy',
  expired: 'Hết hạn thanh toán',
  returned: 'Đã trả hàng',
};

function formatCurrency(value: number): string {
  return `${Math.round(Number(value) || 0).toLocaleString('vi-VN')} đ`;
}

function formatDate(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString('vi-VN', { hour12: false });
}

export function OrderInvoiceModal({ order, onClose }: OrderInvoiceModalProps) {
  useEffect(() => {
    if (!order) return;
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') onClose();
    }
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [order, onClose]);

  if (!order || typeof document === 'undefined') return null;

  const discountAmount =
    order.discountAmount ?? Math.max(0, order.subtotal + order.shippingFee - order.total);
  const paymentLabel =
    order.paymentMethod === 'vnpay'
      ? 'Thanh toán trực tuyến VNPay'
      : 'Thanh toán khi nhận hàng (COD)';

  const content = (
    <div
      id="invoice-print-overlay"
      className="fixed inset-0 z-[60] overflow-y-auto bg-slate-950/90 p-4 sm:p-6"
      role="dialog"
      aria-modal="true"
      aria-label={`Hóa đơn đơn hàng ${order.code}`}
    >
      <div id="invoice-print-wrapper" className="mx-auto w-full max-w-3xl">
        <div className="invoice-print-hide mb-3 flex items-center justify-end gap-2">
          <button
            type="button"
            onClick={onClose}
            className="inline-flex items-center gap-1.5 rounded-xl border border-slate-700 bg-slate-900 px-3 py-2 text-xs font-semibold text-slate-300 transition hover:bg-slate-800 hover:text-white"
          >
            <X className="h-4 w-4" />
            Đóng
          </button>
          <button
            type="button"
            onClick={() => window.print()}
            className="inline-flex items-center gap-1.5 rounded-xl bg-amber-500 px-3 py-2 text-xs font-bold text-slate-950 transition hover:bg-amber-400"
          >
            <Printer className="h-4 w-4" />
            In hóa đơn
          </button>
        </div>

        <div
          id="invoice-print-area"
          className="rounded-xl bg-white px-6 py-8 text-slate-900 shadow-2xl sm:px-10"
        >
          <header className="flex flex-col gap-6 border-b border-slate-200 pb-6 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <p className="text-2xl font-black tracking-[0.2em] text-slate-900">MENLY</p>
              <p className="mt-1 text-xs font-semibold uppercase tracking-widest text-amber-600">
                Thời trang nam
              </p>
              <div className="mt-3 space-y-0.5 text-xs text-slate-600">
                <p>12 Nguyễn Trãi, Quận 5, TP. Hồ Chí Minh</p>
                <p>Hotline: 1900 6868 · Email: support@menly.vn</p>
              </div>
            </div>

            <div className="sm:text-right">
              <p className="text-lg font-extrabold uppercase tracking-wide text-slate-900">
                Hóa đơn bán hàng
              </p>
              <p className="mt-1 font-mono text-sm font-semibold text-slate-700">
                #{order.code}
              </p>
              <p className="mt-1 text-xs text-slate-500">Ngày lập: {formatDate(order.createdAt)}</p>
              <p className="mt-2 inline-flex rounded-full border border-slate-300 px-3 py-1 text-[11px] font-bold uppercase tracking-wide text-slate-700">
                {STATUS_LABELS[order.status] ?? order.status}
              </p>
            </div>
          </header>

          <section className="grid grid-cols-1 gap-6 border-b border-slate-200 py-6 text-xs sm:grid-cols-2">
            <div>
              <p className="mb-2 text-[11px] font-bold uppercase tracking-wider text-slate-500">
                Người nhận hàng
              </p>
              <p className="text-sm font-semibold text-slate-900">{order.shippingAddress.name}</p>
              <p className="mt-1 text-slate-600">{order.shippingAddress.phone}</p>
              <p className="mt-1 leading-relaxed text-slate-600">{order.shippingAddress.address}</p>
              {order.shippingAddress.note && (
                <p className="mt-1 text-slate-500">Ghi chú: {order.shippingAddress.note}</p>
              )}
            </div>

            <div className="sm:text-right">
              <p className="mb-2 text-[11px] font-bold uppercase tracking-wider text-slate-500">
                Thanh toán
              </p>
              <p className="text-sm font-semibold text-slate-900">{paymentLabel}</p>
              <p className="mt-1 text-slate-600">
                Số mặt hàng: {order.items.length}
              </p>
              {discountAmount > 0 && (
                <p className="mt-1 text-slate-600">
                  Giảm giá{order.voucherCode ? ` (${order.voucherCode})` : ''}:{' '}
                  {formatCurrency(discountAmount)}
                </p>
              )}
            </div>
          </section>

          <section className="py-6">
            <table className="w-full border-collapse text-left text-xs">
              <thead>
                <tr className="border-b border-slate-300 text-[11px] uppercase tracking-wide text-slate-500">
                  <th className="py-2 pr-2 font-semibold">STT</th>
                  <th className="py-2 pr-2 font-semibold">Sản phẩm</th>
                  <th className="py-2 pr-2 font-semibold">Size</th>
                  <th className="py-2 pr-2 font-semibold">Màu</th>
                  <th className="py-2 pr-2 text-right font-semibold">Đơn giá</th>
                  <th className="py-2 pr-2 text-right font-semibold">SL</th>
                  <th className="py-2 text-right font-semibold">Thành tiền</th>
                </tr>
              </thead>
              <tbody>
                {order.items.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="py-4 text-center text-slate-500">
                      Đơn hàng chưa có thông tin mặt hàng.
                    </td>
                  </tr>
                ) : (
                  order.items.map((item, index) => (
                    <tr key={item.id} className="border-b border-slate-100 text-slate-700">
                      <td className="py-2.5 pr-2">{index + 1}</td>
                      <td className="py-2.5 pr-2 font-medium text-slate-900">{item.productName}</td>
                      <td className="py-2.5 pr-2">{item.size}</td>
                      <td className="py-2.5 pr-2">{item.color}</td>
                      <td className="py-2.5 pr-2 text-right font-mono">
                        {formatCurrency(item.unitPrice)}
                      </td>
                      <td className="py-2.5 pr-2 text-right">{item.quantity}</td>
                      <td className="py-2.5 text-right font-mono font-semibold text-slate-900">
                        {formatCurrency(item.unitPrice * item.quantity)}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </section>

          <section className="ml-auto w-full max-w-xs space-y-2 border-t border-slate-200 pt-4 text-xs">
            <div className="flex justify-between gap-4 text-slate-600">
              <span>Tạm tính sản phẩm</span>
              <span className="font-mono">{formatCurrency(order.subtotal)}</span>
            </div>
            <div className="flex justify-between gap-4 text-slate-600">
              <span>Phí vận chuyển</span>
              <span className="font-mono">
                {order.shippingFee === 0 ? 'Miễn phí' : formatCurrency(order.shippingFee)}
              </span>
            </div>
            {discountAmount > 0 && (
              <div className="flex justify-between gap-4 text-slate-600">
                <span>Giảm giá{order.voucherCode ? ` (${order.voucherCode})` : ''}</span>
                <span className="font-mono">-{formatCurrency(discountAmount)}</span>
              </div>
            )}
            <div className="flex justify-between gap-4 border-t border-slate-300 pt-2 text-sm font-bold text-slate-900">
              <span>Tổng thanh toán</span>
              <span className="font-mono">{formatCurrency(order.total)}</span>
            </div>
          </section>

          <footer className="mt-8 border-t border-slate-200 pt-4 text-center text-[11px] text-slate-500">
            <p>Cảm ơn quý khách đã mua sắm tại Menly!</p>
            <p className="mt-1">
              Hóa đơn được lập tự động từ dữ liệu đơn hàng #{order.code}.
            </p>
          </footer>
        </div>
      </div>
    </div>
  );

  return createPortal(content, document.body);
}
