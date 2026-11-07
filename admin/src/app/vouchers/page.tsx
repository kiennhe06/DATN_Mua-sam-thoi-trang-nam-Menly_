'use client';

import { useState, useEffect, useCallback } from 'react';
import { Header } from '../../components/Header';
import {
  fetchAdminVouchers,
  createVoucher,
  updateVoucher,
  deleteVoucher,
} from '../../lib/api';
import { Voucher, CreateVoucherInput, DiscountType } from '../../lib/types';
import {
  Ticket,
  Plus,
  Search,
  CheckCircle2,
  AlertCircle,
  Percent,
  DollarSign,
  Calendar,
  Layers,
  Trash2,
  Edit2,
  X,
  Sparkles,
  ToggleLeft,
  ToggleRight,
} from 'lucide-react';

function formatLocalDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export default function VouchersPage() {
  const [vouchers, setVouchers] = useState<Voucher[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState<'all' | DiscountType>('all');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingVoucher, setEditingVoucher] = useState<Voucher | null>(null);
  const [msg, setMsg] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  // Form states
  const [formData, setFormData] = useState<CreateVoucherInput>({
    code: '',
    title: '',
    discountType: 'percentage',
    discountValue: 10,
    minOrderValue: 0,
    maxDiscount: null,
    usageLimit: 100,
    startDate: '',
    endDate: '',
    isActive: true,
  });
  const [submitting, setSubmitting] = useState(false);

  const loadVouchers = useCallback(async () => {
    setLoading(true);
    try {
      const data = await fetchAdminVouchers();
      setVouchers(data);
    } catch (e: unknown) {
      setMsg({ text: (e as Error).message || 'Không thể tải danh sách voucher', type: 'error' });
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadVouchers();
  }, [loadVouchers]);

  const openCreateModal = () => {
    const startDate = new Date();
    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + 30);
    setEditingVoucher(null);
    setFormData({
      code: '',
      title: '',
      discountType: 'percentage',
      discountValue: 10,
      minOrderValue: 200000,
      maxDiscount: 50000,
      usageLimit: 100,
      startDate: formatLocalDate(startDate),
      endDate: formatLocalDate(endDate),
      isActive: true,
    });
    setIsModalOpen(true);
  };

  const openEditModal = (v: Voucher) => {
    setEditingVoucher(v);
    setFormData({
      code: v.code,
      title: v.title,
      discountType: v.discountType,
      discountValue: v.discountValue,
      minOrderValue: v.minOrderValue,
      maxDiscount: v.maxDiscount ?? null,
      usageLimit: v.usageLimit,
      startDate: v.startDate.slice(0, 10),
      endDate: v.endDate.slice(0, 10),
      isActive: v.isActive,
    });
    setIsModalOpen(true);
  };

  const handleToggleActive = async (v: Voucher) => {
    try {
      const nextActive = !v.isActive;
      await updateVoucher(v.id, { isActive: nextActive });
      setVouchers((prev) =>
        prev.map((item) => (item.id === v.id ? { ...item, isActive: nextActive } : item))
      );
      setMsg({
        text: `Đã ${nextActive ? 'kích hoạt' : 'tạm dừng'} mã "${v.code}"!`,
        type: 'success',
      });
    } catch (e: unknown) {
      setMsg({ text: (e as Error).message || 'Lỗi khi cập nhật trạng thái', type: 'error' });
    }
  };

  const handleDelete = async (v: Voucher) => {
    if (!confirm(`Bạn có chắc chắn muốn xóa mã giảm giá "${v.code}"?`)) return;
    try {
      await deleteVoucher(v.id);
      setVouchers((prev) => prev.filter((item) => item.id !== v.id));
      setMsg({ text: `Đã xóa mã "${v.code}" thành công!`, type: 'success' });
    } catch (e: unknown) {
      setMsg({ text: (e as Error).message || 'Lỗi khi xóa mã giảm giá', type: 'error' });
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      if (editingVoucher) {
        const updated = await updateVoucher(editingVoucher.id, {
          ...formData,
          code: formData.code.trim().toUpperCase(),
        });
        setVouchers((prev) =>
          prev.map((item) => (item.id === editingVoucher.id ? { ...item, ...updated } : item))
        );
        setMsg({ text: `Đã cập nhật mã "${formData.code}" thành công!`, type: 'success' });
      } else {
        const created = await createVoucher({
          ...formData,
          code: formData.code.trim().toUpperCase(),
        });
        setVouchers((prev) => [created, ...prev]);
        setMsg({ text: `Đã tạo mã giảm giá "${formData.code}" thành công!`, type: 'success' });
      }
      setIsModalOpen(false);
    } catch (err: unknown) {
      setMsg({ text: (err as Error).message || 'Có lỗi xảy ra', type: 'error' });
    } finally {
      setSubmitting(false);
    }
  };

  // Stats
  const totalCount = vouchers.length;
  const activeCount = vouchers.filter((v) => v.isActive).length;
  const totalUsed = vouchers.reduce((acc, cur) => acc + (cur.usedCount || 0), 0);

  // Filters
  const filteredVouchers = vouchers.filter((v) => {
    const matchesSearch =
      v.code.toLowerCase().includes(search.toLowerCase()) ||
      v.title.toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || v.discountType === typeFilter;
    const matchesStatus =
      statusFilter === 'all' ||
      (statusFilter === 'active' && v.isActive) ||
      (statusFilter === 'inactive' && !v.isActive);
    return matchesSearch && matchesType && matchesStatus;
  });

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Quản lý Mã giảm giá (Vouchers)"
        subtitle="Thiết lập các chương trình khuyến mãi, mã giảm giá % hoặc tiền mặt cho khách hàng"
        onRefresh={loadVouchers}
      />

      <div className="flex-1 space-y-6 p-4 sm:p-6 xl:p-8">
        {msg && (
          <div
            className={`p-3.5 rounded-xl text-xs font-semibold flex items-center justify-between gap-2 shadow-sm ${
              msg.type === 'success'
                ? 'bg-ok-bg text-ok border border-ok-line'
                : 'bg-danger-bg text-danger border border-danger-line'
            }`}
          >
            <div className="flex items-center gap-2">
              {msg.type === 'success' ? (
                <CheckCircle2 className="w-4 h-4 shrink-0" />
              ) : (
                <AlertCircle className="w-4 h-4 shrink-0" />
              )}
              <span>{msg.text}</span>
            </div>
            <button
              onClick={() => setMsg(null)}
              className="text-ink-muted hover:text-ink"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        )}

        {/* Overview Stats Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="bg-panel border border-line rounded-2xl p-5 flex items-center gap-4 shadow-panel">
            <div className="w-12 h-12 rounded-xl bg-camel-tint border border-camel/25 flex items-center justify-center text-camel-dark">
              <Ticket className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs text-ink-muted font-medium">Tổng số voucher</p>
              <h3 className="text-2xl font-bold text-ink mt-0.5">{totalCount}</h3>
            </div>
          </div>

          <div className="bg-panel border border-line rounded-2xl p-5 flex items-center gap-4 shadow-panel">
            <div className="w-12 h-12 rounded-xl bg-ok-bg border border-ok-line flex items-center justify-center text-ok">
              <Sparkles className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs text-ink-muted font-medium">Đang hiệu lực</p>
              <h3 className="text-2xl font-bold text-ink mt-0.5">{activeCount}</h3>
            </div>
          </div>

          <div className="bg-panel border border-line rounded-2xl p-5 flex items-center gap-4 shadow-panel">
            <div className="w-12 h-12 rounded-xl bg-sky-50 border border-sky-200 flex items-center justify-center text-sky-700">
              <Layers className="w-6 h-6" />
            </div>
            <div>
              <p className="text-xs text-ink-muted font-medium">Lượt đã sử dụng</p>
              <h3 className="text-2xl font-bold text-ink mt-0.5">{totalUsed}</h3>
            </div>
          </div>
        </div>

        {/* Filter and Actions Bar */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 bg-panel p-4 rounded-2xl border border-line shadow-panel">
          <div className="flex flex-wrap items-center gap-3 w-full sm:w-auto flex-1">
            <div className="relative flex-1 sm:w-64">
              <Search className="w-4 h-4 text-ink-muted absolute left-3 top-2.5" />
              <input
                type="text"
                placeholder="Tìm mã hoặc tiêu đề..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-9 pr-3 py-1.5 bg-panel border border-line rounded-xl text-xs text-ink placeholder:text-ink-muted focus:outline-none focus:border-camel transition-colors shadow-panel"
              />
            </div>

            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value as 'all' | DiscountType)}
              className="px-3 py-1.5 bg-panel border border-line rounded-xl text-xs text-ink-mid focus:outline-none focus:border-camel shadow-panel"
            >
              <option value="all">Tất cả loại giảm</option>
              <option value="percentage">Phần trăm (%)</option>
              <option value="fixed_amount">Số tiền cố định (đ)</option>
            </select>

            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as 'all' | 'active' | 'inactive')}
              className="px-3 py-1.5 bg-panel border border-line rounded-xl text-xs text-ink-mid focus:outline-none focus:border-camel shadow-panel"
            >
              <option value="all">Tất cả trạng thái</option>
              <option value="active">Đang kích hoạt</option>
              <option value="inactive">Đã tạm dừng</option>
            </select>
          </div>

          <button
            onClick={openCreateModal}
            className="w-full sm:w-auto px-4 py-2 bg-camel text-ink rounded-xl font-bold text-xs hover:bg-camel-hover transition-colors flex items-center justify-center gap-2 cursor-pointer shadow-md shrink-0"
          >
            <Plus className="w-4 h-4" />
            Tạo mã giảm giá mới
          </button>
        </div>

        {/* Vouchers Table */}
        <div className="bg-panel border border-line rounded-2xl overflow-hidden shadow-sm">
          {loading ? (
            <div className="p-12 text-center text-ink-muted text-sm">Đang tải danh sách mã giảm giá...</div>
          ) : filteredVouchers.length === 0 ? (
            <div className="p-12 text-center text-ink-muted text-sm">
              Không tìm thấy mã giảm giá nào phù hợp.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-line bg-tint text-[11px] font-semibold uppercase tracking-wider text-ink-muted">
                    <th className="py-3.5 px-4">Mã Voucher</th>
                    <th className="py-3.5 px-4">Chương trình / Tiêu đề</th>
                    <th className="py-3.5 px-4">Mức giảm</th>
                    <th className="py-3.5 px-4">Đơn tối thiểu</th>
                    <th className="py-3.5 px-4">Lượt dùng</th>
                    <th className="py-3.5 px-4">Thời hạn</th>
                    <th className="py-3.5 px-4 text-center">Trạng thái</th>
                    <th className="py-3.5 px-4 text-right">Thao tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-line text-xs text-ink-mid">
                  {filteredVouchers.map((v) => (
                    <tr key={v.id} className="hover:bg-tint/60 transition-colors">
                      <td className="py-3.5 px-4">
                        <div className="flex items-center gap-2">
                          <span className="font-mono font-bold text-camel-dark bg-camel-tint border border-camel/25 px-2.5 py-1 rounded-lg">
                            {v.code}
                          </span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4 font-medium text-ink max-w-xs">
                        {v.title}
                      </td>

                      <td className="py-3.5 px-4">
                        {v.discountType === 'percentage' ? (
                          <div className="flex items-center gap-1.5 text-danger font-semibold">
                            <Percent className="w-3.5 h-3.5" />
                            <span>{v.discountValue}%</span>
                            {v.maxDiscount && (
                              <span className="text-[10px] text-ink-muted font-normal">
                                (Tối đa {v.maxDiscount.toLocaleString('vi-VN')}đ)
                              </span>
                            )}
                          </div>
                        ) : (
                          <div className="flex items-center gap-1.5 text-ok font-semibold">
                            <DollarSign className="w-3.5 h-3.5" />
                            <span>-{v.discountValue.toLocaleString('vi-VN')}đ</span>
                          </div>
                        )}
                      </td>

                      <td className="py-3.5 px-4 text-ink-mid">
                        {v.minOrderValue > 0
                          ? `${v.minOrderValue.toLocaleString('vi-VN')}đ`
                          : '0đ (Không giới hạn)'}
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="flex items-center gap-2">
                          <div className="w-16 bg-tint rounded-full h-1.5 overflow-hidden">
                            <div
                              className="bg-camel h-1.5 rounded-full"
                              style={{
                                width: `${Math.min(100, ((v.usedCount || 0) / v.usageLimit) * 100)}%`,
                              }}
                            />
                          </div>
                          <span className="text-[11px] text-ink-muted font-mono">
                            {v.usedCount || 0}/{v.usageLimit}
                          </span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4 text-ink-muted text-[11px]">
                        <div className="flex items-center gap-1">
                          <Calendar className="w-3 h-3 text-ink-muted shrink-0" />
                          <span>
                            {new Date(v.startDate).toLocaleDateString('vi-VN')} -{' '}
                            {new Date(v.endDate).toLocaleDateString('vi-VN')}
                          </span>
                        </div>
                      </td>

                      <td className="py-3.5 px-4 text-center">
                        <button
                          onClick={() => handleToggleActive(v)}
                          title={v.isActive ? 'Bấm để tạm dừng' : 'Bấm để kích hoạt'}
                          className="inline-flex items-center justify-center cursor-pointer transition-transform active:scale-95"
                        >
                          {v.isActive ? (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-ok-bg text-ok border border-ok-line">
                              <ToggleRight className="w-4 h-4 text-ok" />
                              Đang bật
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-tint text-ink-muted border border-line-strong">
                              <ToggleLeft className="w-4 h-4 text-ink-muted" />
                              Tạm dừng
                            </span>
                          )}
                        </button>
                      </td>

                      <td className="py-3.5 px-4 text-right">
                        <div className="flex items-center justify-end gap-1.5">
                          <button
                            onClick={() => openEditModal(v)}
                            className="p-1.5 rounded-lg text-ink-muted hover:text-camel-dark hover:bg-tint transition-colors"
                            title="Sửa voucher"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleDelete(v)}
                            className="p-1.5 rounded-lg text-ink-muted hover:text-danger hover:bg-tint transition-colors"
                            title="Xóa voucher"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {/* Modal Add / Edit Voucher */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-ink/50 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-panel border border-line rounded-2xl w-full max-w-lg shadow-panel-lg overflow-hidden flex flex-col max-h-[90vh]">
            <div className="px-6 py-4 border-b border-line flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Ticket className="w-5 h-5 text-camel-dark" />
                <h3 className="font-bold text-ink text-base">
                  {editingVoucher ? 'Cập nhật mã giảm giá' : 'Tạo mã giảm giá mới'}
                </h3>
              </div>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-ink-muted hover:text-ink p-1 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-4 overflow-y-auto flex-1">
              <div>
                <label className="block text-xs font-semibold text-ink-mid mb-1.5 uppercase tracking-wider">
                  Mã Voucher (Code) <span className="text-danger">*</span>
                </label>
                <input
                  type="text"
                  required
                  placeholder="VD: MENLY20, FREESHIP, TET2026"
                  value={formData.code}
                  onChange={(e) => setFormData({ ...formData, code: e.target.value.toUpperCase() })}
                  className="w-full px-3.5 py-2 bg-panel border border-line rounded-xl text-sm font-mono font-bold text-camel-dark placeholder:text-ink-muted focus:outline-none focus:border-camel shadow-panel"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-ink-mid mb-1.5 uppercase tracking-wider">
                  Tiêu đề / Mô tả chương trình <span className="text-danger">*</span>
                </label>
                <input
                  type="text"
                  required
                  placeholder="VD: Giảm ngay 50.000đ cho đơn hàng từ 300.000đ"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  className="w-full px-3.5 py-2 bg-panel border border-line rounded-xl text-sm text-ink placeholder:text-ink-muted focus:outline-none focus:border-camel shadow-panel"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-ink-mid mb-1.5 uppercase tracking-wider">
                    Loại khuyến mãi
                  </label>
                  <select
                    value={formData.discountType}
                    onChange={(e) =>
                      setFormData({ ...formData, discountType: e.target.value as DiscountType })
                    }
                    className="w-full px-3.5 py-2 bg-panel border border-line rounded-xl text-sm text-ink focus:outline-none focus:border-camel shadow-panel"
                  >
                    <option value="percentage">Phần trăm (%)</option>
                    <option value="fixed_amount">Số tiền cố định (đ)</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-ink-mid mb-1.5 uppercase tracking-wider">
                    Mức giảm {formData.discountType === 'percentage' ? '(%)' : '(VNĐ)'}{' '}
                    <span className="text-danger">*</span>
                  </label>
                  <input
                    type="number"
                    min={1}
                    required
                    value={formData.discountValue || ''}
                    onChange={(e) =>
                      setFormData({ ...formData, discountValue: Number(e.target.value) })
                    }
                    className="w-full px-3.5 py-2 bg-panel border border-line rounded-xl text-sm text-ink focus:outline-none focus:border-camel shadow-panel"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-ink-mid mb-1.5 uppercase tracking-wider">
                    Đơn hàng tối thiểu (đ)
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={formData.minOrderValue}
                    onChange={(e) =>
                      setFormData({ ...formData, minOrderValue: Number(e.target.value) })
                    }
                    className="w-full px-3.5 py-2 bg-panel border border-line rounded-xl text-sm text-ink focus:outline-none focus:border-camel shadow-panel"
                  />
                </div>

                {formData.discountType === 'percentage' ? (
                  <div>
                    <label className="block text-xs font-semibold text-ink-mid mb-1.5 uppercase tracking-wider">
                      Giảm tối đa (đ)
                    </label>
                    <input
                      type="number"
                      min={0}
                      placeholder="Không giới hạn"
                      value={formData.maxDiscount ?? ''}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          maxDiscount: e.target.value ? Number(e.target.value) : null,
                        })
                      }
                      className="w-full px-3.5 py-2 bg-panel border border-line rounded-xl text-sm text-ink focus:outline-none focus:border-camel shadow-panel"
                    />
                  </div>
                ) : (
                  <div>
                    <label className="block text-xs font-semibold text-ink-mid mb-1.5 uppercase tracking-wider">
                      Giới hạn lượt dùng
                    </label>
                    <input
                      type="number"
                      min={1}
                      value={formData.usageLimit || 100}
                      onChange={(e) =>
                        setFormData({ ...formData, usageLimit: Number(e.target.value) })
                      }
                      className="w-full px-3.5 py-2 bg-panel border border-line rounded-xl text-sm text-ink focus:outline-none focus:border-camel shadow-panel"
                    />
                  </div>
                )}
              </div>

              {formData.discountType === 'percentage' && (
                <div>
                  <label className="block text-xs font-semibold text-ink-mid mb-1.5 uppercase tracking-wider">
                    Giới hạn lượt dùng
                  </label>
                  <input
                    type="number"
                    min={1}
                    value={formData.usageLimit || 100}
                    onChange={(e) =>
                      setFormData({ ...formData, usageLimit: Number(e.target.value) })
                    }
                    className="w-full px-3.5 py-2 bg-panel border border-line rounded-xl text-sm text-ink focus:outline-none focus:border-camel shadow-panel"
                  />
                </div>
              )}

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-ink-mid mb-1.5 uppercase tracking-wider">
                    Ngày bắt đầu
                  </label>
                  <input
                    type="date"
                    required
                    value={formData.startDate}
                    onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                    className="w-full px-3.5 py-2 bg-panel border border-line rounded-xl text-sm text-ink focus:outline-none focus:border-camel shadow-panel"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-ink-mid mb-1.5 uppercase tracking-wider">
                    Ngày kết thúc
                  </label>
                  <input
                    type="date"
                    required
                    value={formData.endDate}
                    onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
                    className="w-full px-3.5 py-2 bg-panel border border-line rounded-xl text-sm text-ink focus:outline-none focus:border-camel shadow-panel"
                  />
                </div>
              </div>

              <div className="flex items-center gap-2 pt-2">
                <input
                  type="checkbox"
                  id="isActiveCheck"
                  checked={formData.isActive}
                  onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                  className="w-4 h-4 rounded-md border-line bg-panel text-camel-dark focus:ring-0 focus:ring-offset-0"
                />
                <label htmlFor="isActiveCheck" className="text-xs font-semibold text-ink">
                  Kích hoạt mã voucher ngay lập tức
                </label>
              </div>

              <div className="pt-4 flex items-center justify-end gap-3 border-t border-line">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 bg-tint text-ink-mid rounded-xl text-xs font-medium hover:bg-tint-strong transition-colors"
                >
                  Hủy bỏ
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-5 py-2 bg-camel text-ink rounded-xl text-xs font-bold hover:bg-camel-hover transition-colors disabled:opacity-50 flex items-center gap-1.5"
                >
                  {submitting ? 'Đang lưu...' : editingVoucher ? 'Lưu thay đổi' : 'Tạo voucher'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
