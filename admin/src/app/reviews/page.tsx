'use client';

import { useState, useEffect, useCallback, Fragment } from 'react';
import { Header } from '../../components/Header';
import {
  fetchAdminReviews,
  deleteAdminReview,
  replyToAdminReview,
  Review,
} from '../../lib/review-api';
import { Star, Trash2, CheckCircle2, AlertCircle, MessageSquare } from 'lucide-react';

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<Review[]>([]);
  /// Danh gia dang mo o tra loi; chi mo mot cai mot luc.
  const [replyingId, setReplyingId] = useState<string | null>(null);
  const [replyText, setReplyText] = useState('');
  const [replySaving, setReplySaving] = useState(false);
  const [loading, setLoading] = useState(true);
  const [msg, setMsg] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const loadReviews = useCallback(async () => {
    setLoading(true);
    try {
      const data = await fetchAdminReviews(1, 50);
      setReviews(data.items);
    } catch (e: any) {
      setMsg({ text: e.message || 'Lỗi tải đánh giá', type: 'error' });
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadReviews();
  }, [loadReviews]);

  const handleDelete = async (id: string) => {
    if (!confirm('Bạn có chắc chắn muốn xóa đánh giá này?')) return;
    try {
      await deleteAdminReview(id);
      setReviews((prev) => prev.filter((r) => r.id !== id));
      setMsg({ text: 'Đã xóa đánh giá vi phạm', type: 'success' });
    } catch (e: any) {
      setMsg({ text: e.message || 'Lỗi khi xóa đánh giá', type: 'error' });
    }
  };

  const handleReply = async (id: string) => {
    const noiDung = replyText.trim();
    if (!noiDung) return;
    setReplySaving(true);
    try {
      const saved = await replyToAdminReview(id, noiDung);
      setReviews((prev) =>
        prev.map((r) =>
          r.id === id
            ? { ...r, replyComment: saved.replyComment ?? noiDung, replyAt: saved.replyAt }
            : r,
        ),
      );
      setReplyingId(null);
      setReplyText('');
      setMsg({ text: 'Đã gửi trả lời tới khách', type: 'success' });
    } catch (e: any) {
      setMsg({ text: e.message || 'Không gửi được trả lời', type: 'error' });
    } finally {
      setReplySaving(false);
    }
  };

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Quản lý Đánh giá"
        subtitle="Xem danh sách đánh giá của khách hàng và xóa các đánh giá vi phạm"
        onRefresh={loadReviews}
      />

      <div className="flex-1 space-y-6 p-4 sm:p-6 xl:p-8">
        {msg && (
          <div
            className={`p-3.5 rounded-xl text-xs font-semibold flex items-center gap-2 ${
              msg.type === 'success'
                ? 'bg-ok-bg text-ok border border-ok-line'
                : 'bg-danger-bg text-danger border border-danger-line'
            }`}
          >
            {msg.type === 'success' ? <CheckCircle2 className="w-4 h-4" /> : <AlertCircle className="w-4 h-4" />}
            <span>{msg.text}</span>
          </div>
        )}

        <div className="bg-panel rounded-2xl border border-line overflow-hidden shadow-panel">
          {loading ? (
            <div className="p-8 flex justify-center">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-camel"></div>
            </div>
          ) : reviews.length === 0 ? (
            <div className="p-12 text-center text-ink-muted">Không có đánh giá nào</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-panel border-b border-line text-xs font-semibold text-ink-muted uppercase tracking-wider">
                    <th className="p-4 pl-6">Khách hàng</th>
                    <th className="p-4">Đánh giá</th>
                    <th className="p-4">Nội dung</th>
                    <th className="p-4">Ngày đăng</th>
                    <th className="p-4 pr-6 text-right">Thao tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-line">
                  {reviews.map((r) => (
                    <Fragment key={r.id}>
                    <tr className="hover:bg-tint/60 transition-colors">
                      <td className="p-4 pl-6">
                        <div className="text-sm font-semibold text-ink">
                          {r.user?.name || 'Khách'}
                        </div>
                        <div className="text-xs text-ink-muted">{r.user?.email || 'N/A'}</div>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center gap-1">
                          {Array.from({ length: 5 }).map((_, i) => (
                            <Star
                              key={i}
                              className={`w-4 h-4 ${
                                i < r.rating ? 'text-camel-dark fill-camel' : 'text-ink-mid'
                              }`}
                            />
                          ))}
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="max-w-md space-y-1.5">
                          <div className="truncate text-sm text-ink-mid">
                            {r.comment || (
                              <span className="italic text-ink-muted">Không có nhận xét</span>
                            )}
                          </div>

                          {r.images && r.images.length > 0 && (
                            <div className="flex gap-1.5">
                              {r.images.map((url) => (
                                <a key={url} href={url} target="_blank" rel="noreferrer" title="Mở ảnh gốc">
                                  {/* eslint-disable-next-line @next/next/no-img-element */}
                                  <img
                                    src={url}
                                    alt="Ảnh khách gửi kèm"
                                    className="h-9 w-9 rounded border border-line object-cover hover:opacity-75"
                                  />
                                </a>
                              ))}
                            </div>
                          )}

                          {r.replyComment && (
                            <div className="truncate text-xs text-ink-muted">
                              <span className="font-semibold text-camel-dark">↳ Menly: </span>
                              {r.replyComment}
                            </div>
                          )}
                        </div>
                      </td>
                      <td className="p-4">
                        <div className="text-sm text-ink-muted">
                          {new Date(r.createdAt).toLocaleDateString('vi-VN')}
                        </div>
                      </td>
                      <td className="p-4 pr-6 text-right">
                        <div className="flex items-center justify-end gap-1">
                          {!r.replyComment && (
                            <button
                              onClick={() => {
                                setReplyingId(replyingId === r.id ? null : r.id);
                                setReplyText('');
                              }}
                              className="rounded-lg p-2 text-ink-muted transition-colors hover:bg-tint hover:text-camel-dark"
                              title="Trả lời đánh giá"
                            >
                              <MessageSquare className="h-4 w-4" />
                            </button>
                          )}
                          <button
                            onClick={() => handleDelete(r.id)}
                            className="rounded-lg p-2 text-danger transition-colors hover:bg-danger-bg"
                            title="Xóa đánh giá vi phạm"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      </td>
                    </tr>

                    {/* O soan tra loi nam o hang rieng ben duoi, khong lam phinh
                        cac cot san co cua bang. */}
                    {replyingId === r.id && (
                      <tr key={`${r.id}-reply`} className="bg-tint/40">
                        <td colSpan={5} className="px-6 pb-4 pt-0">
                          <div className="flex items-center gap-2">
                            <input
                              value={replyText}
                              onChange={(event) => setReplyText(event.target.value)}
                              onKeyDown={(event) => {
                                if (event.key === 'Enter') handleReply(r.id);
                              }}
                              autoFocus
                              placeholder="Cảm ơn bạn đã tin tưởng Menly..."
                              className="flex-1 rounded-lg border border-line bg-panel px-3 py-2 text-sm text-ink placeholder:text-ink-muted focus:border-camel focus:outline-none"
                            />
                            <button
                              type="button"
                              disabled={replySaving}
                              onClick={() => handleReply(r.id)}
                              className="shrink-0 rounded-lg bg-camel px-3.5 py-2 text-xs font-bold text-ink hover:bg-camel-hover disabled:opacity-50"
                            >
                              {replySaving ? 'Đang gửi...' : 'Gửi'}
                            </button>
                            <button
                              type="button"
                              onClick={() => setReplyingId(null)}
                              className="shrink-0 rounded-lg px-2.5 py-2 text-xs font-semibold text-ink-muted hover:bg-tint"
                            >
                              Hủy
                            </button>
                          </div>
                        </td>
                      </tr>
                    )}
                    </Fragment>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
