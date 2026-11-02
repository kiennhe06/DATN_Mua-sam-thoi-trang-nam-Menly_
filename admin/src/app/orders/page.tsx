'use client';

import { useState, useEffect, useCallback } from 'react';
import { Header } from '../../components/Header';
import { OrderStatusBadge } from '../../components/Badge';
import { ChangeOrderStatusModal } from '../../components/ChangeOrderStatusModal';
import { fetchAdminOrders, updateOrderStatus } from '../../lib/api';
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
} from 'lucide-react';

const STATUS_TABS: { label: string; value: OrderStatus | 'all' }[] = [
  { label: 'Tất cả đơn', value: 'all' },
  { label: 'Chờ thanh toán', value: 'pending_payment' },
  { label: 'Đã thanh toán', value: 'paid' },
  { label: 'Đang xử lý', value: 'processing' },
  { label: 'Đang giao hàng', value: 'shipping' },
  { label: 'Đã hoàn tất', value: 'completed' },
  { label: 'Đã hủy', value: 'cancelled' },
];

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<OrderStatus | 'all'>('all');
  const [searchQuery, setSearchQuery] = useState('');

  // Updating status modal
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [newStatus, setNewStatus] = useState<OrderStatus>('processing');
  const [statusNote, setStatusNote] = useState('');
  const [updating, setUpdating] = useState(false);
  const [feedback, setFeedback] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const loadOrders = useCallback(async () => {
    setLoading(true);
    setLoadError(null);
    try {
      const data = await fetchAdminOrders({ status: activeTab, limit: 200 });
      setOrders(data);
    } catch (error) {
      setOrders([]);
      setLoadError(error instanceof Error ? error.message : 'Không thể tải danh sách đơn hàng.');
    } finally {
      setLoading(false);
    }
  }, [activeTab]);

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

      <div className="p-8 space-y-6 flex-1">
        {/* Status Filter Tabs */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 bg-slate-900/60 p-3 rounded-2xl border border-slate-800">
          <Filter className="w-4 h-4 text-slate-400 ml-2 mr-1" />
          {STATUS_TABS.map((tab) => (
            <button
              key={tab.value}
              onClick={() => setActiveTab(tab.value)}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all shrink-0 cursor-pointer ${
                activeTab === tab.value
                  ? 'bg-amber-500 text-slate-950 shadow-sm'
                  : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        <label className="flex max-w-xl items-center gap-3 rounded-xl border border-slate-800 bg-slate-900/60 px-4 py-3">
          <Search className="h-4 w-4 shrink-0 text-slate-400" />
          <input
            type="search"
            value={searchQuery}
            onChange={(event) => setSearchQuery(event.target.value)}
            placeholder="Tìm theo mã đơn, tên hoặc số điện thoại người nhận..."
            className="w-full bg-transparent text-sm text-white outline-none placeholder:text-slate-500"
          />
        </label>

        {/* Feedback message */}
        {feedback && (
          <div
            className={`p-3 rounded-xl text-xs font-semibold flex items-center gap-2 ${
              feedback.type === 'success'
                ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30'
                : 'bg-rose-500/10 text-rose-400 border border-rose-500/30'
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
            <div className="p-16 text-center text-slate-500 text-sm">Đang tải đơn hàng...</div>
          ) : loadError ? (
            <div role="alert" className="rounded-xl border border-rose-500/30 bg-rose-500/10 p-6 text-center">
              <p className="text-sm text-rose-300">{loadError}</p>
              <button
                type="button"
                onClick={loadOrders}
                className="mt-3 rounded-lg border border-rose-400/30 px-3 py-1.5 text-xs font-semibold text-rose-200 hover:bg-rose-500/10"
              >
                Thử tải lại
              </button>
            </div>
          ) : filteredOrders.length === 0 ? (
            <div className="p-16 text-center text-slate-500 text-sm">
              {orders.length === 0
                ? 'Không tìm thấy đơn hàng nào ở bộ lọc này'
                : 'Không tìm thấy đơn hàng khớp với nội dung tìm kiếm'}
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-4">
              {filteredOrders.map((ord) => (
                <div
                  key={ord.id}
                  className="bg-slate-900/60 border border-slate-800 rounded-2xl p-5 hover:border-slate-700 transition-all space-y-4 shadow-sm"
                >
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-800/60">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center text-amber-400 font-bold">
                        <ShoppingBag className="w-5 h-5" />
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-mono font-bold text-white text-sm">#{ord.code}</span>
                          <OrderStatusBadge status={ord.status} />
                        </div>
                        <div className="flex items-center gap-3 text-[11px] text-slate-400 mt-0.5">
                          <span className="flex items-center gap-1">
                            <Calendar className="w-3 h-3" />
                            {new Date(ord.createdAt).toLocaleString('vi-VN')}
                          </span>
                          <span>•</span>
                          <span className="font-mono text-slate-300">ID: {ord.id.slice(0, 8)}...</span>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <span className="text-base font-extrabold text-white font-mono">
                        {ord.total.toLocaleString('vi-VN')} đ
                      </span>
                      {ord.status === 'cancelled' ? (
                        <span className="px-3 py-1.5 rounded-xl text-xs font-semibold bg-rose-500/10 text-rose-400 border border-rose-500/30 flex items-center gap-1.5 cursor-not-allowed">
                          <AlertCircle className="w-3.5 h-3.5" />
                          Đã huỷ (Cố định)
                        </span>
                      ) : (
                        <button
                          onClick={() => {
                            setSelectedOrder(ord);
                            setNewStatus(ord.status);
                          }}
                          className="px-3 py-1.5 rounded-xl text-xs font-semibold bg-slate-800 hover:bg-slate-700 text-amber-400 border border-slate-700 transition-all flex items-center gap-1.5 cursor-pointer"
                        >
                          <Truck className="w-3.5 h-3.5" />
                          Đổi trạng thái
                        </button>
                      )}
                    </div>
                  </div>

                  {/* Customer info & Item list */}
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-3 border-t border-slate-800/60 text-xs">
                    <div className="space-y-1">
                      <span className="text-slate-400 font-semibold flex items-center gap-1">
                        <User className="w-3 h-3 text-slate-500" /> Người nhận:
                      </span>
                      <p className="text-slate-200 font-medium">{ord.shippingAddress.name}</p>
                      <p className="text-slate-400">{ord.shippingAddress.phone}</p>
                    </div>

                    <div className="space-y-1">
                      <span className="text-slate-400 font-semibold flex items-center gap-1">
                        <MapPin className="w-3 h-3 text-slate-500" /> Địa chỉ giao hàng:
                      </span>
                      <p className="text-slate-300 leading-relaxed">{ord.shippingAddress.address}</p>
                      {ord.shippingAddress.note && (
                        <p className="text-amber-400 text-[11px]">
                          * Ghi chú: {ord.shippingAddress.note}
                        </p>
                      )}
                    </div>

                    <div className="space-y-1">
                      <span className="text-slate-400 font-semibold flex items-center gap-1">
                        <CreditCard className="w-3 h-3 text-slate-500" /> Thanh toán:
                      </span>
                      <p className="text-slate-200 uppercase font-semibold">
                        {ord.paymentMethod === 'vnpay' ? 'Thanh toán trực tuyến VNPay' : 'Thanh toán khi nhận hàng (COD)'}
                      </p>
                      <p className="text-slate-400 text-[11px]">
                        Gồm {ord.items.length} mặt hàng trong giỏ
                      </p>
                    </div>
                  </div>

                  <div className="border-t border-slate-800/60 pt-3">
                    <h3 className="mb-2 text-xs font-semibold text-slate-300">
                      Chi tiết sản phẩm ({ord.items.length})
                    </h3>
                    {ord.items.length === 0 ? (
                      <p className="text-xs text-slate-500">Đơn hàng chưa có thông tin mặt hàng.</p>
                    ) : (
                      <ul className="divide-y divide-slate-800/60">
                        {ord.items.map((item) => (
                          <li
                            key={item.id}
                            className="flex flex-col gap-1 py-2 text-xs sm:flex-row sm:items-center sm:justify-between"
                          >
                            <div>
                              <p className="font-medium text-slate-200">{item.productName}</p>
                              <p className="text-slate-400">
                                Size {item.size} · Màu {item.color} · Số lượng {item.quantity}
                              </p>
                            </div>
                            <p className="font-mono text-slate-300">
                              {item.unitPrice.toLocaleString('vi-VN')} đ × {item.quantity}
                              {' = '}
                              <span className="font-semibold text-amber-300">
                                {(item.unitPrice * item.quantity).toLocaleString('vi-VN')} đ
                              </span>
                            </p>
                          </li>
                        ))}
                      </ul>
                    )}
                  </div>

                  <dl className="ml-auto w-full max-w-sm space-y-2 border-t border-slate-800/60 pt-3 text-xs">
                    <div className="flex justify-between gap-4 text-slate-400">
                      <dt>Tạm tính sản phẩm</dt>
                      <dd className="font-mono text-slate-200">
                        {ord.subtotal.toLocaleString('vi-VN')} đ
                      </dd>
                    </div>
                    <div className="flex justify-between gap-4 text-slate-400">
                      <dt>Phí vận chuyển</dt>
                      <dd className="font-mono text-slate-200">
                        {ord.shippingFee === 0
                          ? 'Miễn phí'
                          : `${ord.shippingFee.toLocaleString('vi-VN')} đ`}
                      </dd>
                    </div>
                    {(ord.discountAmount ?? 0) > 0 && (
                      <div className="flex justify-between gap-4 text-slate-400">
                        <dt>
                          Giảm giá{ord.voucherCode ? ` (${ord.voucherCode})` : ''}
                        </dt>
                        <dd className="font-mono text-emerald-300">
                          -{(ord.discountAmount ?? 0).toLocaleString('vi-VN')} đ
                        </dd>
                      </div>
                    )}
                    <div className="flex justify-between gap-4 border-t border-slate-800 pt-2 font-semibold">
                      <dt className="text-slate-300">Tổng thanh toán</dt>
                      <dd className="font-mono text-sm text-amber-300">
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
    </div>
  );
}
