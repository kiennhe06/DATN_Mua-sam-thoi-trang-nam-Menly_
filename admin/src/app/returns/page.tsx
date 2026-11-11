'use client';

import { useCallback, useEffect, useState } from 'react';
import Image from 'next/image';
import { Header } from '../../components/Header';
import { AlertCircle, CheckCircle2, PackageCheck, PackageX, Undo2 } from 'lucide-react';
import {
  OrderReturn,
  fetchOrderReturns,
  updateOrderReturn,
} from '../../lib/api';

/** Nhan tieng Viet cho tung trang thai yeu cau tra hang. */
const NHAN_TRANG_THAI: Record<string, { chu: string; lop: string }> = {
  requested: { chu: 'Chờ duyệt', lop: 'bg-warn-bg text-warn border-warn-line' },
  shop_approved: { chu: 'Đã duyệt, chờ hoàn tiền', lop: 'bg-camel/15 text-camel-dark border-camel/30' },
  shop_rejected: { chu: 'Đã từ chối', lop: 'bg-danger-bg text-danger border-danger-line' },
  admin_dispute_review: { chu: 'Đang khiếu nại', lop: 'bg-warn-bg text-warn border-warn-line' },
  refunded: { chu: 'Đã hoàn tiền', lop: 'bg-ok-bg text-ok border-ok-line' },
  rejected: { chu: 'Đã từ chối', lop: 'bg-danger-bg text-danger border-danger-line' },
};

function dinhDangNgay(iso: string): string {
  if (!iso) return '';
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? '' : d.toLocaleString('vi-VN');
}

export default function ReturnsPage() {
  const [returns, setReturns] = useState<OrderReturn[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [msg, setMsg] = useState<{ text: string; type: 'success' | 'error' } | null>(null);
  const [dangLuu, setDangLuu] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setLoadError(null);
    try {
      setReturns(await fetchOrderReturns());
    } catch (e) {
      setReturns([]);
      setLoadError(e instanceof Error ? e.message : 'Không tải được danh sách trả hàng.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function doiTrangThai(
    yeuCau: OrderReturn,
    status: string,
    thongBao: string,
    them: { restock?: boolean; rejectionReason?: string | null } = {},
  ) {
    setDangLuu(yeuCau.id);
    try {
      const saved = await updateOrderReturn(yeuCau.id, { status, ...them });
      setReturns((prev) => prev.map((item) => (item.id === saved.id ? saved : item)));
      setMsg({ text: thongBao, type: 'success' });
    } catch (e) {
      setMsg({
        text: e instanceof Error ? e.message : 'Không cập nhật được yêu cầu trả hàng',
        type: 'error',
      });
    } finally {
      setDangLuu(null);
    }
  }

  function tuChoi(yeuCau: OrderReturn) {
    const lyDo = window.prompt('Lý do từ chối yêu cầu trả hàng này?');
    if (lyDo === null) return;
    doiTrangThai(yeuCau, 'shop_rejected', 'Đã từ chối yêu cầu', { rejectionReason: lyDo.trim() || null });
  }

  const dangCho = returns.filter((item) =>
    ['requested', 'shop_approved', 'admin_dispute_review'].includes(item.status),
  ).length;

  return (
    <div className="flex flex-1 flex-col">
      <Header
        title="Yêu cầu trả hàng"
        subtitle="Duyệt, từ chối và hoàn tiền cho yêu cầu trả hàng của khách"
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
            {msg.type === 'success' ? (
              <CheckCircle2 className="h-4 w-4" />
            ) : (
              <AlertCircle className="h-4 w-4" />
            )}
            {msg.text}
          </p>
        )}

        <p className="text-xs text-ink-muted">
          {returns.length} yêu cầu · <span className="font-semibold text-ink">{dangCho} đang chờ xử lý</span>
        </p>

        {loading ? (
          <p className="py-20 text-center text-sm text-ink-muted">Đang tải yêu cầu trả hàng...</p>
        ) : returns.length === 0 ? (
          <p className="py-20 text-center text-sm text-ink-muted">Chưa có yêu cầu trả hàng nào</p>
        ) : (
          <div className="space-y-4">
            {returns.map((yeuCau) => {
              const nhan = NHAN_TRANG_THAI[yeuCau.status] ?? {
                chu: yeuCau.status,
                lop: 'bg-tint text-ink-mid border-line',
              };
              const choHoanTien = ['requested', 'shop_approved', 'admin_dispute_review'].includes(
                yeuCau.status,
              );
              const dangBan = dangLuu === yeuCau.id;

              return (
                <article
                  key={yeuCau.id}
                  className="space-y-3 rounded-2xl border border-line bg-panel p-5 shadow-panel"
                >
                  <div className="flex flex-wrap items-start justify-between gap-3">
                    <div>
                      <p className="font-mono text-xs text-ink-muted">Đơn {yeuCau.orderId}</p>
                      <p className="mt-1 text-sm font-semibold text-ink">{yeuCau.reason}</p>
                      <p className="mt-1 text-[11px] text-ink-muted">
                        Gửi lúc {dinhDangNgay(yeuCau.createdAt)} · Hoàn{' '}
                        {yeuCau.refundAmount.toLocaleString('vi-VN')} đ
                      </p>
                    </div>
                    <span className={`rounded-full border px-3 py-1 text-[11px] font-semibold ${nhan.lop}`}>
                      {nhan.chu}
                    </span>
                  </div>

                  {yeuCau.proofImages.length > 0 && (
                    <div className="flex flex-wrap gap-2">
                      {yeuCau.proofImages.map((url) => (
                        <div
                          key={url}
                          className="relative h-20 w-20 overflow-hidden rounded-lg border border-line bg-tint"
                        >
                          <Image src={url} alt="Ảnh khách gửi kèm" fill unoptimized className="object-contain" />
                        </div>
                      ))}
                    </div>
                  )}

                  {yeuCau.rejectionReason && (
                    <p className="text-xs text-danger">Lý do từ chối: {yeuCau.rejectionReason}</p>
                  )}

                  {yeuCau.status === 'refunded' && (
                    <p className="text-xs text-ink-mid">
                      {yeuCau.restocked === true
                        ? 'Hàng còn bán được, đã nhập lại kho.'
                        : yeuCau.restocked === false
                          ? 'Hàng lỗi, không nhập lại kho.'
                          : 'Chưa ghi nhận hàng có nhập lại kho hay không.'}
                    </p>
                  )}

                  {choHoanTien && (
                    <div className="flex flex-wrap gap-2 border-t border-line pt-3">
                      <button
                        type="button"
                        disabled={dangBan}
                        onClick={() =>
                          doiTrangThai(yeuCau, 'refunded', 'Đã hoàn tiền và nhập lại kho', {
                            restock: true,
                          })
                        }
                        className="inline-flex cursor-pointer items-center gap-1.5 rounded-xl border border-ok-line bg-ok-bg px-3.5 py-2 text-xs font-semibold text-ok hover:brightness-95 disabled:opacity-50"
                      >
                        <PackageCheck className="h-3.5 w-3.5" />
                        Hoàn tiền · hàng còn bán được
                      </button>
                      <button
                        type="button"
                        disabled={dangBan}
                        onClick={() =>
                          doiTrangThai(yeuCau, 'refunded', 'Đã hoàn tiền, không nhập lại kho', {
                            restock: false,
                          })
                        }
                        className="inline-flex cursor-pointer items-center gap-1.5 rounded-xl border border-line-strong bg-panel px-3.5 py-2 text-xs font-semibold text-ink-mid hover:bg-tint disabled:opacity-50"
                      >
                        <PackageX className="h-3.5 w-3.5" />
                        Hoàn tiền · hàng lỗi
                      </button>
                      {yeuCau.status === 'requested' && (
                        <button
                          type="button"
                          disabled={dangBan}
                          onClick={() =>
                            doiTrangThai(yeuCau, 'shop_approved', 'Đã duyệt, chờ nhận hàng về')
                          }
                          className="inline-flex cursor-pointer items-center gap-1.5 rounded-xl border border-camel/30 bg-camel-tint px-3.5 py-2 text-xs font-semibold text-camel-dark hover:bg-camel/15 disabled:opacity-50"
                        >
                          <Undo2 className="h-3.5 w-3.5" />
                          Duyệt, chờ nhận hàng
                        </button>
                      )}
                      <button
                        type="button"
                        disabled={dangBan}
                        onClick={() => tuChoi(yeuCau)}
                        className="inline-flex cursor-pointer items-center gap-1.5 rounded-xl border border-danger-line bg-danger-bg px-3.5 py-2 text-xs font-semibold text-danger hover:brightness-95 disabled:opacity-50"
                      >
                        Từ chối
                      </button>
                    </div>
                  )}
                </article>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
