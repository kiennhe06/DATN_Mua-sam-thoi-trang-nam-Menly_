import { OrderStatus } from '../lib/types';

export function OrderStatusBadge({ status }: { status: OrderStatus }) {
  const configs: Record<OrderStatus, { label: string; bg: string; text: string; dot: string }> = {
    pending_payment: {
      label: 'Chờ thanh toán',
      bg: 'bg-warn-bg border-warn-line',
      text: 'text-warn',
      dot: 'bg-warn',
    },
    paid: {
      label: 'Đã thanh toán',
      bg: 'bg-blue-50 border-blue-200',
      text: 'text-blue-700',
      dot: 'bg-blue-600',
    },
    delivered: {
      label: 'Đã giao hàng',
      bg: 'bg-ok-bg border-ok-line',
      text: 'text-ok',
      dot: 'bg-ok',
    },
    expired: {
      label: 'Hết hạn thanh toán',
      bg: 'bg-danger-bg border-danger-line',
      text: 'text-danger',
      dot: 'bg-danger',
    },
    processing: {
      label: 'Đang xử lý',
      bg: 'bg-indigo-50 border-indigo-200',
      text: 'text-indigo-700',
      dot: 'bg-indigo-600',
    },
    shipping: {
      label: 'Đang giao hàng',
      bg: 'bg-cyan-50 border-cyan-200',
      text: 'text-cyan-700',
      dot: 'bg-cyan-600',
    },
    completed: {
      label: 'Hoàn tất',
      bg: 'bg-ok-bg border-ok-line',
      text: 'text-ok',
      dot: 'bg-ok',
    },
    cancelled: {
      label: 'Đã hủy',
      bg: 'bg-danger-bg border-danger-line',
      text: 'text-danger',
      dot: 'bg-danger',
    },
  };

  const c = configs[status] || configs.pending_payment;

  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold border ${c.bg} ${c.text}`}
    >
      <span className={`w-1.5 h-1.5 rounded-full ${c.dot}`} />
      {c.label}
    </span>
  );
}

export function ReasonBadge({ reason }: { reason: string }) {
  // Khoa o day phai dung bang gia tri database luu trong inventory_movements
  // (order, cancel, restock, adjust, return). Truoc day bang nay dung ten
  // admin_restock / order_created - khong khop voi gia tri nao - nen moi dong
  // nhat ky deu roi xuong nhanh du phong va hien chu tieng Anh tho.
  const mapping: Record<string, { label: string; color: string }> = {
    restock: { label: 'Nhập kho mới', color: 'text-ok bg-ok-bg border-ok-line' },
    adjust: { label: 'Hiệu chỉnh kiểm kê', color: 'text-warn bg-warn-bg border-warn-line' },
    order: { label: 'Khách đặt hàng', color: 'text-blue-700 bg-blue-50 border-blue-200' },
    cancel: { label: 'Hủy đơn, hoàn kho', color: 'text-purple-700 bg-purple-50 border-purple-200' },
    return: { label: 'Trả hàng, nhập lại kho', color: 'text-camel-dark bg-camel-tint border-camel/30' },
  };

  const item = mapping[reason] || { label: reason, color: 'text-ink-muted bg-tint border-line-strong' };

  return (
    <span className={`px-2 py-0.5 rounded-md text-[11px] font-medium border ${item.color}`}>
      {item.label}
    </span>
  );
}
