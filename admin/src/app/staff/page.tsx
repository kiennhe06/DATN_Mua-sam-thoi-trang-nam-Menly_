'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { Header } from '../../components/Header';
import {
  StaffActivityEntry,
  StaffSummaryRow,
  fetchStaffActivity,
  fetchStaffSummary,
  updateStaffSalary,
} from '../../lib/api';
import {
  AlertCircle,
  CheckCircle2,
  MessageSquare,
  Package,
  Pencil,
  ShoppingBag,
  X,
} from 'lucide-react';

const dong = (so: number) => `${so.toLocaleString('vi-VN')} đ`;

function nhanLoai(loai: StaffActivityEntry['loai']) {
  if (loai === 'order') return { chu: 'Đơn hàng', Icon: ShoppingBag, lop: 'text-blue-700 bg-blue-50' };
  if (loai === 'chat') return { chu: 'Chat', Icon: MessageSquare, lop: 'text-camel-dark bg-camel-tint' };
  return { chu: 'Kho', Icon: Package, lop: 'text-ok bg-ok-bg' };
}

export default function StaffPage() {
  const [summary, setSummary] = useState<StaffSummaryRow[]>([]);
  const [activity, setActivity] = useState<StaffActivityEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [msg, setMsg] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  // Bộ lọc
  const [staffId, setStaffId] = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');

  // Form sửa lương
  const [dangSua, setDangSua] = useState<StaffSummaryRow | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setLoadError(null);
    try {
      const loc = {
        staffId: staffId || undefined,
        from: from ? new Date(from).toISOString() : undefined,
        // Lấy đến hết ngày đã chọn.
        to: to ? new Date(`${to}T23:59:59.999`).toISOString() : undefined,
      };
      const [s, a] = await Promise.all([fetchStaffSummary(loc), fetchStaffActivity(loc)]);
      setSummary(s);
      setActivity(a);
    } catch (e) {
      setLoadError(e instanceof Error ? e.message : 'Không tải được dữ liệu nhân viên.');
    } finally {
      setLoading(false);
    }
  }, [staffId, from, to]);

  useEffect(() => {
    load();
  }, [load]);

  const tongLuongTatCa = useMemo(
    () => summary.reduce((acc, r) => acc + r.tongLuong, 0),
    [summary],
  );

  async function luuLuong(row: StaffSummaryRow, salary: StaffSummaryRow['salary']) {
    try {
      await updateStaffSalary(row.staffId, salary);
      setMsg({ text: `Đã lưu lương cho ${row.staffName}`, type: 'success' });
      setDangSua(null);
      await load();
    } catch (e) {
      setMsg({
        text: e instanceof Error ? e.message : 'Không lưu được lương',
        type: 'error',
      });
    }
  }

  return (
    <div className="flex flex-1 flex-col">
      <Header
        title="Nhân viên"
        subtitle="Nhật ký thao tác và lương theo số việc"
        onRefresh={load}
      />

      <div className="flex-1 space-y-5 p-4 sm:p-6 xl:p-8">
        {loadError && (
          <p className="rounded-2xl border border-danger-line bg-danger-bg px-4 py-3 text-sm text-danger">
            {loadError}
          </p>
        )}
        {msg && (
          <p
            className={`flex items-center gap-2 rounded-2xl border px-4 py-3 text-sm ${
              msg.type === 'success'
                ? 'border-ok-line bg-ok-bg text-ok'
                : 'border-danger-line bg-danger-bg text-danger'
            }`}
          >
            {msg.type === 'success' ? <CheckCircle2 className="h-4 w-4" /> : <AlertCircle className="h-4 w-4" />}
            {msg.text}
          </p>
        )}

        {/* Bộ lọc */}
        <div className="flex flex-wrap items-end gap-3 rounded-2xl border border-line bg-panel p-4 shadow-panel">
          <div>
            <label className="mb-1 block text-xs font-semibold text-ink-mid">Nhân viên</label>
            <select
              value={staffId}
              onChange={(e) => setStaffId(e.target.value)}
              className="rounded-xl border border-line bg-panel px-3 py-2 text-sm text-ink focus:border-camel focus:outline-none"
            >
              <option value="">Tất cả</option>
              {summary.map((r) => (
                <option key={r.staffId} value={r.staffId}>
                  {r.staffName}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="mb-1 block text-xs font-semibold text-ink-mid">Từ ngày</label>
            <input
              type="date"
              value={from}
              onChange={(e) => setFrom(e.target.value)}
              className="rounded-xl border border-line bg-panel px-3 py-2 text-sm text-ink focus:border-camel focus:outline-none"
            />
          </div>
          <div>
            <label className="mb-1 block text-xs font-semibold text-ink-mid">Đến ngày</label>
            <input
              type="date"
              value={to}
              onChange={(e) => setTo(e.target.value)}
              className="rounded-xl border border-line bg-panel px-3 py-2 text-sm text-ink focus:border-camel focus:outline-none"
            />
          </div>
          {(staffId || from || to) && (
            <button
              type="button"
              onClick={() => {
                setStaffId('');
                setFrom('');
                setTo('');
              }}
              className="inline-flex cursor-pointer items-center gap-1 rounded-xl border border-line px-3 py-2 text-xs font-semibold text-ink-muted hover:bg-tint"
            >
              <X className="h-3.5 w-3.5" />
              Xóa lọc
            </button>
          )}
        </div>

        {/* Bảng tổng theo người */}
        <div className="overflow-hidden rounded-2xl border border-line bg-panel shadow-panel">
          <div className="flex items-center justify-between border-b border-line p-4">
            <span className="text-sm font-bold text-ink">Bảng tổng theo nhân viên</span>
            <span className="text-xs text-ink-muted">
              Tổng lương: <strong className="text-ink">{dong(tongLuongTatCa)}</strong>
            </span>
          </div>
          {loading ? (
            <div className="py-16 text-center text-sm text-ink-muted">Đang tải...</div>
          ) : summary.length === 0 ? (
            <div className="py-16 text-center text-sm text-ink-muted">Chưa có nhân viên nào</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-line bg-tint text-xs uppercase tracking-wider text-ink-muted">
                    <th className="px-4 py-3">Nhân viên</th>
                    <th className="px-4 py-3 text-center">Đơn</th>
                    <th className="px-4 py-3 text-center">Chat</th>
                    <th className="px-4 py-3 text-center">Kho</th>
                    <th className="px-4 py-3 text-right">Lương cứng</th>
                    <th className="px-4 py-3 text-right">Tổng lương</th>
                    <th className="px-4 py-3" />
                  </tr>
                </thead>
                <tbody className="divide-y divide-line text-ink-mid">
                  {summary.map((r) => (
                    <tr key={r.staffId} className="text-xs hover:bg-tint">
                      <td className="px-4 py-3">
                        <p className="font-semibold text-ink">{r.staffName}</p>
                        <p className="text-ink-muted">{r.email}</p>
                      </td>
                      <td className="px-4 py-3 text-center font-mono">{r.counts.orders}</td>
                      <td className="px-4 py-3 text-center font-mono">{r.counts.chats}</td>
                      <td className="px-4 py-3 text-center font-mono">{r.counts.stock}</td>
                      <td className="px-4 py-3 text-right font-mono">{dong(r.salary.baseSalary)}</td>
                      <td className="px-4 py-3 text-right font-mono font-bold text-ink">
                        {dong(r.tongLuong)}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <button
                          type="button"
                          onClick={() => setDangSua(r)}
                          className="inline-flex cursor-pointer items-center gap-1 rounded-lg border border-line px-2.5 py-1.5 text-[11px] font-semibold text-camel-dark hover:bg-camel-tint"
                        >
                          <Pencil className="h-3 w-3" />
                          Sửa lương
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Nhật ký từng thao tác */}
        <div className="overflow-hidden rounded-2xl border border-line bg-panel shadow-panel">
          <div className="border-b border-line p-4 text-sm font-bold text-ink">
            Nhật ký thao tác
          </div>
          {loading ? (
            <div className="py-16 text-center text-sm text-ink-muted">Đang tải...</div>
          ) : activity.length === 0 ? (
            <div className="py-16 text-center text-sm text-ink-muted">
              Không có thao tác nào trong khoảng này
            </div>
          ) : (
            <ul className="divide-y divide-line">
              {activity.map((a, i) => {
                const { chu, Icon, lop } = nhanLoai(a.loai);
                return (
                  <li key={`${a.staffId}-${a.at}-${i}`} className="flex items-center gap-3 px-4 py-3 text-xs">
                    <span className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full ${lop}`}>
                      <Icon className="h-3.5 w-3.5" />
                    </span>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-ink">
                        <strong>{a.staffName}</strong> · {a.moTa}
                        {a.orderCode && <span className="font-mono text-ink-muted"> · {a.orderCode}</span>}
                      </p>
                      <p className="text-ink-muted">{new Date(a.at).toLocaleString('vi-VN')}</p>
                    </div>
                    <span className="shrink-0 rounded-full bg-tint px-2 py-0.5 text-[10px] font-semibold text-ink-muted">
                      {chu}
                    </span>
                  </li>
                );
              })}
            </ul>
          )}
        </div>
      </div>

      {dangSua && <FormSuaLuong row={dangSua} onClose={() => setDangSua(null)} onSave={luuLuong} />}
    </div>
  );
}

function FormSuaLuong({
  row,
  onClose,
  onSave,
}: {
  row: StaffSummaryRow;
  onClose: () => void;
  onSave: (row: StaffSummaryRow, salary: StaffSummaryRow['salary']) => void;
}) {
  const [baseSalary, setBaseSalary] = useState(row.salary.baseSalary);
  const [bonusPerOrder, setBonusPerOrder] = useState(row.salary.bonusPerOrder);
  const [bonusPerChat, setBonusPerChat] = useState(row.salary.bonusPerChat);
  const [bonusPerStock, setBonusPerStock] = useState(row.salary.bonusPerStock);

  // Xem trước lương với số việc hiện tại, để biết đặt mức này ra bao nhiêu.
  const thu =
    baseSalary +
    row.counts.orders * bonusPerOrder +
    row.counts.chats * bonusPerChat +
    row.counts.stock * bonusPerStock;

  const o = (
    nhan: string,
    giaTri: number,
    dat: (n: number) => void,
    phu?: string,
  ) => (
    <div>
      <label className="mb-1 block text-xs font-semibold text-ink-mid">{nhan}</label>
      <input
        type="number"
        min={0}
        value={giaTri || ''}
        onChange={(e) => dat(Math.max(0, Number(e.target.value)))}
        className="w-full rounded-xl border border-line bg-panel px-3 py-2 text-sm text-ink focus:border-camel focus:outline-none"
      />
      {phu && <p className="mt-1 text-[11px] text-ink-muted">{phu}</p>}
    </div>
  );

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div
        className="w-full max-w-md rounded-2xl border border-line bg-panel p-5 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mb-4 flex items-center justify-between">
          <h3 className="text-sm font-bold text-ink">Lương của {row.staffName}</h3>
          <button type="button" onClick={onClose} className="cursor-pointer text-ink-muted hover:text-ink">
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="space-y-3">
          {o('Lương cứng / tháng', baseSalary, setBaseSalary)}
          <div className="grid grid-cols-3 gap-3">
            {o('Thưởng / đơn', bonusPerOrder, setBonusPerOrder)}
            {o('Thưởng / chat', bonusPerChat, setBonusPerChat)}
            {o('Thưởng / kho', bonusPerStock, setBonusPerStock)}
          </div>

          <div className="rounded-xl border border-line bg-tint p-3 text-xs text-ink-mid">
            Với số việc hiện tại ({row.counts.orders} đơn, {row.counts.chats} chat, {row.counts.stock} kho),
            lương sẽ là <strong className="text-ink">{dong(thu)}</strong>.
          </div>
        </div>

        <div className="mt-5 flex justify-end gap-2">
          <button
            type="button"
            onClick={onClose}
            className="rounded-xl px-4 py-2 text-xs font-semibold text-ink-muted hover:text-ink"
          >
            Hủy
          </button>
          <button
            type="button"
            onClick={() => onSave(row, { baseSalary, bonusPerOrder, bonusPerChat, bonusPerStock })}
            className="rounded-xl bg-camel px-5 py-2 text-xs font-bold text-ink hover:bg-camel-hover"
          >
            Lưu lương
          </button>
        </div>
      </div>
    </div>
  );
}
