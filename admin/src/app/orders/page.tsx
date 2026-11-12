'use client';

import { useState, useEffect, useCallback } from 'react';
import { Header } from '../../components/Header';
import { OrderStatusBadge } from '../../components/Badge';
import { ChangeOrderStatusModal } from '../../components/ChangeOrderStatusModal';
import { OrderInvoiceModal } from '../../components/OrderInvoiceModal';
import { fetchAdminOrders, updateOrderStatus } from '../../lib/api';
import {
  KhoangNgay,
  NHAN_KHOANG_NGAY,
  tinhMocLoc,
} from '../../lib/order-date-filter';
import { Order, OrderStatus } from '../../lib/types';
import {
  ShoppingBag,
  Filter,
  CheckCircle2,
  AlertCircle,
  Truck,
  CreditCard,
  User,
  MapPin,
  Calendar,
  Search,
  Printer,
} from 'lucide-react';

/** So don toi da tai ve mot lan. Cham nguong nay thi phai thu hep khoang ngay. */
const GIOI_HAN_TAI = 200;

const STATUS_TABS: { label: string; value: OrderStatus | 'all' }[] = [
  { label: 'Tất cả đơn', value: 'all' },
  { label: 'Chờ thanh toán', value: 'pending_payment' },
  { label: 'Đã thanh toán', value: 'paid' },
  { label: 'Đang xử lý', value: 'processing' },
  { label: 'Đang giao hàng', value: 'shipping' },
  { label: 'Đã giao hàng', value: 'delivered' },
  { label: 'Đã hoàn tất', value: 'completed' },
  { label: 'Đã hủy', value: 'cancelled' },
  { label: 'Hết hạn thanh toán', value: 'expired' },
];

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<OrderStatus | 'all'>('all');
  const [searchQuery, setSearchQuery] = useState('');

  const [khoangNgay, setKhoangNgay] = useState<KhoangNgay>('all');
  const [tuNgay, setTuNgay] = useState('');
  const [denNgay, setDenNgay] = useState('');

  // Updating status modal
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [newStatus, setNewStatus] = useState<OrderStatus>('processing');
  const [statusNote, setStatusNote] = useState('');
  const [updating, setUpdating] = useState(false);
  const [feedback, setFeedback] = useState<{ text: string; type: 'success' | 'error' } | null>(null);
  const [invoiceOrder, setInvoiceOrder] = useState<Order | null>(null);

  const loadOrders = useCallback(async () => {
    setLoading(true);
    setLoadError(null);
    try {
      // Loc ngay o may chu chu khong loc sau khi tai ve, vi khi don nhieu len
      // thi 200 don tai ve co the da khong con don nao trong khoang can xem.
      const moc = tinhMocLoc(khoangNgay, tuNgay, denNgay);
      const data = await fetchAdminOrders({
        status: activeTab,
        limit: GIOI_HAN_TAI,
        from: moc.from,
        to: moc.to,
      });
      setOrders(data);
    } catch (error) {
      setOrders([]);
      setLoadError(error instanceof Error ? error.message : 'Không thể tải danh sách đơn hàng.');
    } finally {
      setLoading(false);
    }
  }, [activeTab, khoangNgay, tuNgay, denNgay]);

  useEffect(() => {
    loadOrders();
  }, [loadOrders]);

  // Tìm trên danh sách tối đa 200 đơn vừa tải để tra cứu nhanh mà không gọi API mỗi phím.
  const normalizedSearch = searchQuery.trim().toLocaleLowerCase();
  const filteredOrders = normalizedSearch
    ? orders.filter((order) =>
        [
          order.code,
          order.id,
          order.shippingAddress.name,
          order.shippingAddress.phone,
        ].some((value) => value.toLocaleLowerCase().includes(normalizedSearch))
      )
    : orders;

  // Don da huy khong tinh vao doanh thu cua khoang dang xem.
  const doanhThu = filteredOrders
    .filter((order) => !['cancelled', 'expired'].includes(order.status))
    .reduce((tong, order) => tong + order.total, 0);
  const chamGioiHan = orders.length >= GIOI_HAN_TAI;

  async function handleUpdateStatus() {
    if (!selectedOrder) return;
    if (selectedOrder.status === 'cancelled') {
      setFeedback({ text: 'Đơn hàng đã ở trạng thái ĐÃ HUỶ, không thể chuyển sang trạng thái khác', type: 'error' });
      setSelectedOrder(null);
      return;
    }
    setUpdating(true);
    setFeedback(null);
    try {
      await updateOrderStatus(selectedOrder.id, newStatus, statusNote);
      setFeedback({ text: 'Cập nhật trạng thái đơn hàng thành công!', type: 'success' });
      setOrders((prev) =>
        (Array.isArray(prev) ? prev : []).map((o) =>
          o.id === selectedOrder.id ? { ...o, status: newStatus } : o
        )
      );
      setSelectedOrder(null);
      setStatusNote('');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Lỗi khi cập nhật trạng thái đơn hàng';
      setFeedback({ text: msg, type: 'error' });
    } finally {
      setUpdating(false);
    }
  }

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Quản lý Đơn hàng"
        subtitle="Theo dõi và chuyển đổi trạng thái quy trình đơn hàng MenShop"
        onRefresh={loadOrders}
      />

      <div className="flex-1 space-y-6 p-4 sm:p-6 xl:p-8">
        {/* Mot khoi loc duy nhat: trang thai, khoang ngay va o tim kiem.
            Truoc day la ba khoi xep chong, cao gan bang mot the don hang. */}
        <div className="rounded-2xl border border-line bg-panel shadow-panel">
          <div className="flex flex-wrap items-center gap-2 p-3">
            <Filter className="ml-1 h-4 w-4 shrink-0 text-ink-muted" />
            {STATUS_TABS.map((tab) => (
              <button
                key={tab.value}
                onClick={() => setActiveTab(tab.value)}
                className={`shrink-0 cursor-pointer rounded-xl px-3.5 py-1.5 text-xs font-semibold transition-all ${
                  activeTab === tab.value
                    ? 'bg-camel text-ink shadow-sm'
                    : 'bg-tint text-ink-mid hover:bg-tint-strong'
                }`}
              >
                {tab.label}
              </button>
            ))}

            <div className="ml-auto flex items-center gap-2">
              <Calendar className="h-4 w-4 shrink-0 text-ink-muted" />
              <select
                value={khoangNgay}
                onChange={(event) => {
                  const chon = event.target.value as KhoangNgay;
                  setKhoangNgay(chon);
                  if (chon !== 'custom') {
                    setTuNgay('');
                    setDenNgay('');
                  }
                }}
                className="cursor-pointer rounded-xl border border-line bg-tint px-3 py-1.5 text-xs font-semibold text-ink-mid outline-none hover:bg-tint-strong focus:border-camel"
              >
                {NHAN_KHOANG_NGAY.map((muc) => (
                  <option key={muc.value} value={muc.value}>
                    {muc.label}
                  </option>
                ))}
              </select>

              {khoangNgay === 'custom' && (
                <>
                  <input
                    type="date"
                    value={tuNgay}
                    max={denNgay || undefined}
                    onChange={(event) => setTuNgay(event.target.value)}
                    className="rounded-xl border border-line bg-panel px-2 py-1.5 text-xs text-ink outline-none focus:border-camel"
                  />
                  <span className="text-xs text-ink-muted">đến</span>
                  <input
                    type="date"
                    value={denNgay}
                    min={tuNgay || undefined}
                    onChange={(event) => setDenNgay(event.target.value)}
                    className="rounded-xl border border-line bg-panel px-2 py-1.5 text-xs text-ink outline-none focus:border-camel"
                  />
                </>
              )}
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-x-5 gap-y-2 border-t border-line px-4 py-2.5">
            <Search className="h-4 w-4 shrink-0 text-ink-muted" />
            <input
              type="search"
              value={searchQuery}
              onChange={(event) => setSearchQuery(event.target.value)}
              placeholder="Tìm theo mã đơn, tên hoặc số điện thoại người nhận..."
              className="min-w-[200px] flex-1 bg-transparent text-sm text-ink outline-none placeholder:text-ink-muted"
            />
            {!loading && !loadError && filteredOrders.length > 0 && (
              <span className="shrink-0 text-xs text-ink-muted">
                <strong className="text-ink">{filteredOrders.length}</strong> đơn ·{' '}
                <strong className="text-ink">{doanhThu.toLocaleString('vi-VN')} đ</strong>
                <span className="text-ink-muted"> (trừ đơn huỷ)</span>
                {chamGioiHan && (
                  <span className="ml-2 text-warn">
                    · mới nhất {GIOI_HAN_TAI} đơn, thu hẹp khoảng ngày để xem đủ
                  </span>
                )}
              </span>
            )}
          </div>
        </div>

        {/* Feedback message */}
        {feedback && (
          <div
            className={`p-3 rounded-xl text-xs font-semibold flex items-center gap-2 ${
              feedback.type === 'success'
                ? 'bg-ok-bg text-ok border border-ok-line'
                : 'bg-danger-bg text-danger border border-danger-line'
            }`}
          >
            {feedback.type === 'success' ? (
              <CheckCircle2 className="w-4 h-4" />
            ) : (
              <AlertCircle className="w-4 h-4" />
            )}
            <span>{feedback.text}</span>
          </div>
        )}

        {/* Orders list */}
        <div className="space-y-4">
          {loading ? (
            <div className="p-16 text-center text-ink-muted text-sm">Đang tải đơn hàng...</div>
          ) : loadError ? (
            <div role="alert" className="rounded-xl border border-danger-line bg-danger-bg p-6 text-center">
              <p className="text-sm text-danger">{loadError}</p>
              <button
                type="button"
                onClick={loadOrders}
                className="mt-3 rounded-lg border border-danger-line px-3 py-1.5 text-xs font-semibold text-danger hover:bg-danger-bg"
              >
                Thử tải lại
              </button>
            </div>
          ) : filteredOrders.length === 0 ? (
            <div className="p-16 text-center text-ink-muted text-sm">
              {orders.length > 0
                ? 'Không tìm thấy đơn hàng khớp với nội dung tìm kiếm'
                : khoangNgay === 'all'
                ? 'Không tìm thấy đơn hàng nào ở bộ lọc này'
                : 'Không có đơn hàng nào trong khoảng ngày đang chọn'}
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-4">
              {filteredOrders.map((ord) => (
                <div
                  key={ord.id}
                  className="bg-panel border border-line rounded-2xl p-5 hover:border-line-strong transition-all space-y-4 shadow-sm"
                >
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-line">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-camel-tint border border-camel/25 flex items-center justify-center text-camel-dark font-bold">
                        <ShoppingBag className="w-5 h-5" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-mono font-bold text-ink text-sm">#{ord.code}</span>
                          {ord.refunded ? (
                            <span className="inline-flex items-center rounded-full border border-danger-line bg-danger-bg px-2.5 py-0.5 text-[11px] font-bold text-danger">
                              Đã hoàn tiền
                            </span>
                          ) : (
                            <OrderStatusBadge status={ord.status} />
                          )}
                        </div>
                        <div className="flex items-center gap-3 text-[11px] text-ink-muted mt-0.5">
                          <span className="flex items-center gap-1">
                            <Calendar className="w-3 h-3" />
                            {new Date(ord.createdAt).toLocaleString('vi-VN')}
                          </span>
                          <span>•</span>
                          <span className="font-mono text-ink-mid">ID: {ord.id.slice(0, 8)}...</span>
                        </div>
                      </div>
                    </div>

                    <div className="flex flex-wrap items-center gap-3">
                      <span className="text-base font-extrabold text-ink font-mono">
                        {ord.total.toLocaleString('vi-VN')} đ
                      </span>
                      <button
                        type="button"
                        onClick={() => setInvoiceOrder(ord)}
                        className="px-3 py-1.5 rounded-xl text-xs font-semibold bg-tint hover:bg-tint-strong text-ink border border-line-strong transition-all flex items-center gap-1.5 cursor-pointer"
                      >
                        <Printer className="w-3.5 h-3.5" />
                        Xem / In hóa đơn
                      </button>
                      {ord.status === 'cancelled' ? (
                        <span className="px-3 py-1.5 rounded-xl text-xs font-semibold bg-danger-bg text-danger border border-danger-line flex items-center gap-1.5 cursor-not-allowed">
                          <AlertCircle className="w-3.5 h-3.5" />
                          Đã huỷ (Cố định)
                        </span>
                      ) : (
                        <button
                          onClick={() => {
                            setSelectedOrder(ord);
                            setNewStatus(ord.status);
                          }}
                          className="px-3 py-1.5 rounded-xl text-xs font-semibold bg-tint hover:bg-tint-strong text-camel-dark border border-line-strong transition-all flex items-center gap-1.5 cursor-pointer"
                        >
                          <Truck className="w-3.5 h-3.5" />
                          Đổi trạng thái
                        </button>
                      )}
                    </div>
                  </div>

                  {/* Customer info & Item list */}
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-3 border-t border-line text-xs">
                    <div className="space-y-1">
                      <span className="text-ink-muted font-semibold flex items-center gap-1">
                        <User className="w-3 h-3 text-ink-muted" /> Người nhận:
                      </span>
                      <p className="text-ink font-medium">{ord.shippingAddress.name}</p>
                      <p className="text-ink-muted">{ord.shippingAddress.phone}</p>
                    </div>

                    <div className="space-y-1">
                      <span className="text-ink-muted font-semibold flex items-center gap-1">
                        <MapPin className="w-3 h-3 text-ink-muted" /> Địa chỉ giao hàng:
                      </span>
                      <p className="text-ink-mid leading-relaxed">{ord.shippingAddress.address}</p>
                      {ord.shippingAddress.note && (
                        <p className="text-camel-dark text-[11px]">
                          * Ghi chú: {ord.shippingAddress.note}
                        </p>
                      )}
                    </div>

                    <div className="space-y-1">
                      <span className="text-ink-muted font-semibold flex items-center gap-1">
                        <CreditCard className="w-3 h-3 text-ink-muted" /> Thanh toán:
                      </span>
                      <p className="text-ink uppercase font-semibold">
                        {ord.paymentMethod === 'vnpay' ? 'Thanh toán trực tuyến VNPay' : 'Thanh toán khi nhận hàng (COD)'}
                      </p>
                      <p className="text-ink-muted text-[11px]">
                        Gồm {ord.items.length} mặt hàng trong giỏ
                      </p>
                    </div>
                  </div>

                  <div className="border-t border-line pt-3">
                    <h3 className="mb-2 text-xs font-semibold text-ink-mid">
                      Chi tiết sản phẩm ({ord.items.length})
                    </h3>
                    {ord.items.length === 0 ? (
                      <p className="text-xs text-ink-muted">Đơn hàng chưa có thông tin mặt hàng.</p>
                    ) : (
                      <ul className="divide-y divide-line">
                        {ord.items.map((item) => (
                          <li
                            key={item.id}
                            className="flex flex-col gap-1 py-2 text-xs sm:flex-row sm:items-center sm:justify-between"
                          >
                            <div>
                              <p className="font-medium text-ink">{item.productName}</p>
                              <p className="text-ink-muted">
                                Size {item.size} · Màu {item.color} · Số lượng {item.quantity}
                              </p>
                            </div>
                            <p className="font-mono text-ink-mid">
                              {item.unitPrice.toLocaleString('vi-VN')} đ × {item.quantity}
                              {' = '}
                              <span className="font-semibold text-camel-dark">
                                {(item.unitPrice * item.quantity).toLocaleString('vi-VN')} đ
                              </span>
                            </p>
                          </li>
                        ))}
                      </ul>
                    )}
                  </div>

                  <dl className="ml-auto w-full max-w-sm space-y-2 border-t border-line pt-3 text-xs">
                    <div className="flex justify-between gap-4 text-ink-muted">
                      <dt>Tạm tính sản phẩm</dt>
                      <dd className="font-mono text-ink">
                        {ord.subtotal.toLocaleString('vi-VN')} đ
                      </dd>
                    </div>
                    <div className="flex justify-between gap-4 text-ink-muted">
                      <dt>Phí vận chuyển</dt>
                      <dd className="font-mono text-ink">
                        {ord.shippingFee === 0
                          ? 'Miễn phí'
                          : `${ord.shippingFee.toLocaleString('vi-VN')} đ`}
                      </dd>
                    </div>
                    {(ord.discountAmount ?? 0) > 0 && (
                      <div className="flex justify-between gap-4 text-ink-muted">
                        <dt>
                          Giảm giá{ord.voucherCode ? ` (${ord.voucherCode})` : ''}
                        </dt>
                        <dd className="font-mono text-ok">
                          -{(ord.discountAmount ?? 0).toLocaleString('vi-VN')} đ
                        </dd>
                      </div>
                    )}
                    <div className="flex justify-between gap-4 border-t border-line pt-2 font-semibold">
                      <dt className="text-ink-mid">Tổng thanh toán</dt>
                      <dd className="font-mono text-sm text-camel-dark">
                        {ord.total.toLocaleString('vi-VN')} đ
                      </dd>
                    </div>
                  </dl>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Change Status Modal */}
      <ChangeOrderStatusModal
        selectedOrder={selectedOrder}
        newStatus={newStatus}
        statusNote={statusNote}
        updating={updating}
        onClose={() => setSelectedOrder(null)}
        onStatusChange={setNewStatus}
        onNoteChange={setStatusNote}
        onSave={handleUpdateStatus}
      />

      <OrderInvoiceModal order={invoiceOrder} onClose={() => setInvoiceOrder(null)} />
    </div>
  );
}
