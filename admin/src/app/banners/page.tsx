'use client';

import { useCallback, useEffect, useState } from 'react';
import Image from 'next/image';
import { Header } from '../../components/Header';
import {
  AlertCircle,
  CheckCircle2,
  Eye,
  EyeOff,
  Pencil,
  Plus,
  Trash2,
  Upload,
} from 'lucide-react';
import {
  Banner,
  BannerInput,
  createBanner,
  deleteBanner,
  fetchAdminBanners,
  setBannerActive,
  updateBanner,
  uploadBannerImage,
} from '../../lib/api';

/** Doi chuoi ISO cua may chu thanh gia tri cho input type="date". */
function toDateInput(iso: string): string {
  if (!iso) return '';
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? '' : d.toISOString().slice(0, 10);
}

const EMPTY_FORM: BannerInput = {
  title: '',
  imageUrl: '',
  linkUrl: '',
  sortOrder: 0,
  isActive: true,
  endDate: '',
};

export default function BannersPage() {
  const [banners, setBanners] = useState<Banner[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [msg, setMsg] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const [editing, setEditing] = useState<Banner | null>(null);
  const [creating, setCreating] = useState(false);
  const [form, setForm] = useState<BannerInput>(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);

  /**
   * Nhan file anh nguoi dung chon tren may, day len may chu roi dien dia chi
   * anh vua nhan duoc vao form. Khong doc file thanh base64 de nhet thang vao
   * database: anh banner nang, de luu trong kho anh roi chi luu dia chi.
   */
  async function handleChonAnh(file: File | undefined) {
    if (!file) return;
    setUploading(true);
    try {
      const url = await uploadBannerImage(file);
      setForm((prev) => ({ ...prev, imageUrl: url }));
      setMsg({ text: 'Đã tải ảnh lên', type: 'success' });
    } catch (e) {
      setMsg({
        text: e instanceof Error ? e.message : 'Không tải được ảnh lên',
        type: 'error',
      });
    } finally {
      setUploading(false);
    }
  }

  const load = useCallback(async () => {
    setLoading(true);
    setLoadError(null);
    try {
      setBanners(await fetchAdminBanners());
    } catch (e) {
      setBanners([]);
      setLoadError(e instanceof Error ? e.message : 'Không tải được danh sách banner.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  function openCreate() {
    setEditing(null);
    setCreating(true);
    setForm(EMPTY_FORM);
  }

  function openEdit(b: Banner) {
    setCreating(false);
    setEditing(b);
    setForm({
      title: b.title,
      imageUrl: b.imageUrl,
      linkUrl: b.linkUrl ?? '',
      sortOrder: b.sortOrder,
      isActive: b.isActive,
      startDate: b.startDate,
      endDate: b.endDate,
    });
  }

  function closeForm() {
    setCreating(false);
    setEditing(null);
  }

  async function handleSave() {
    if (!form.title.trim() || !form.imageUrl.trim() || !form.endDate) {
      setMsg({ text: 'Cần nhập tiêu đề, đường dẫn ảnh và ngày kết thúc.', type: 'error' });
      return;
    }
    setSaving(true);
    try {
      const payload: BannerInput = {
        ...form,
        linkUrl: form.linkUrl?.trim() ? form.linkUrl.trim() : null,
        endDate: new Date(form.endDate).toISOString(),
      };
      if (editing) {
        const saved = await updateBanner(editing.id, payload);
        setBanners((prev) => prev.map((b) => (b.id === saved.id ? saved : b)));
        setMsg({ text: 'Đã cập nhật banner', type: 'success' });
      } else {
        const saved = await createBanner(payload);
        setBanners((prev) => [...prev, saved]);
        setMsg({ text: 'Đã thêm banner mới', type: 'success' });
      }
      closeForm();
    } catch (e) {
      setMsg({ text: e instanceof Error ? e.message : 'Không lưu được banner', type: 'error' });
    } finally {
      setSaving(false);
    }
  }

  async function handleToggle(b: Banner) {
    try {
      const saved = await setBannerActive(b.id, !b.isActive);
      setBanners((prev) => prev.map((x) => (x.id === saved.id ? saved : x)));
      setMsg({
        text: saved.isActive ? 'Banner đã bật hiển thị' : 'Banner đã tắt hiển thị',
        type: 'success',
      });
    } catch (e) {
      setMsg({ text: e instanceof Error ? e.message : 'Không đổi được trạng thái', type: 'error' });
    }
  }

  async function handleDelete(b: Banner) {
    if (!confirm(`Xóa banner "${b.title}"? Thao tác này không hoàn tác được.`)) return;
    try {
      await deleteBanner(b.id);
      setBanners((prev) => prev.filter((x) => x.id !== b.id));
      setMsg({ text: 'Đã xóa banner', type: 'success' });
    } catch (e) {
      setMsg({ text: e instanceof Error ? e.message : 'Không xóa được banner', type: 'error' });
    }
  }

  const dangBat = banners.filter((b) => b.isActive).length;
  const formOpen = creating || editing !== null;
  const fieldClass =
    'w-full rounded-xl border border-line bg-panel px-3 py-2 text-sm text-ink outline-none focus:border-camel';

  return (
    <div className="flex flex-1 flex-col">
      <Header
        title="Banner quảng cáo"
        subtitle="Thêm, sửa, xóa và bật tắt banner hiển thị trên trang chủ ứng dụng"
        onRefresh={load}
      />

      <div className="flex-1 space-y-6 p-4 sm:p-6 xl:p-8">
        {msg && (
          <div
            className={`flex items-center gap-2 rounded-xl p-3.5 text-xs font-semibold ${
              msg.type === 'success'
                ? 'border border-ok-line bg-ok-bg text-ok'
                : 'border border-danger-line bg-danger-bg text-danger'
            }`}
          >
            {msg.type === 'success' ? (
              <CheckCircle2 className="h-4 w-4" />
            ) : (
              <AlertCircle className="h-4 w-4" />
            )}
            <span>{msg.text}</span>
          </div>
        )}

        <div className="flex flex-wrap items-center justify-between gap-3">
          <p className="text-xs text-ink-muted">
            <strong className="text-ink">{banners.length}</strong> banner ·{' '}
            <strong className="text-ink">{dangBat}</strong> đang hiển thị
          </p>
          <button
            type="button"
            onClick={openCreate}
            className="flex cursor-pointer items-center gap-2 rounded-xl bg-camel px-4 py-2.5 text-xs font-bold text-ink hover:bg-camel-hover"
          >
            <Plus className="h-4 w-4" />
            Thêm banner
          </button>
        </div>

        {formOpen && (
          <div className="space-y-3 rounded-2xl border border-line bg-panel p-5 shadow-panel">
            <h2 className="text-sm font-bold text-ink">
              {editing ? 'Sửa banner' : 'Thêm banner mới'}
            </h2>
            <div className="grid gap-3 sm:grid-cols-2">
              <label className="text-xs font-semibold text-ink-mid">
                Tiêu đề
                <input
                  className={fieldClass}
                  value={form.title}
                  onChange={(e) => setForm({ ...form, title: e.target.value })}
                  placeholder="Bộ sưu tập Thu Đông"
                />
              </label>
              <div className="text-xs font-semibold text-ink-mid sm:col-span-2">
                Ảnh banner
                <div className="mt-1 flex flex-col gap-2 sm:flex-row sm:items-start">
                  <input
                    className={`${fieldClass} mt-0 flex-1`}
                    value={form.imageUrl}
                    onChange={(e) => setForm({ ...form, imageUrl: e.target.value })}
                    placeholder="Dán link ảnh, hoặc tải ảnh từ máy →"
                  />
                  <label
                    className={`flex shrink-0 cursor-pointer items-center justify-center gap-1.5 rounded-xl border border-line px-3.5 py-2 text-xs font-semibold text-ink hover:bg-tint ${
                      uploading ? 'pointer-events-none opacity-60' : ''
                    }`}
                  >
                    <Upload size={14} />
                    {uploading ? 'Đang tải...' : 'Tải ảnh từ máy'}
                    <input
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={(e) => {
                        handleChonAnh(e.target.files?.[0]);
                        // Xoa gia tri de chon lai dung file do van chay onChange.
                        e.target.value = '';
                      }}
                    />
                  </label>
                </div>
                {form.imageUrl ? (
                  <div className="mt-2">
                    <p className="mb-1 text-[11px] font-normal text-ink-muted">
                      Ảnh sẽ hiện trên trang chủ ứng dụng như thế này:
                    </p>
                    <div className="relative h-[120px] w-[240px] overflow-hidden rounded-xl border border-line bg-tint">
                      <Image
                        src={form.imageUrl}
                        alt="Xem trước banner"
                        fill
                        unoptimized
                        className="object-contain"
                      />
                    </div>
                  </div>
                ) : null}
              </div>
              <label className="text-xs font-semibold text-ink-mid">
                Liên kết khi bấm (không bắt buộc)
                <input
                  className={fieldClass}
                  value={form.linkUrl ?? ''}
                  onChange={(e) => setForm({ ...form, linkUrl: e.target.value })}
                  placeholder="https://..."
                />
              </label>
              <label className="text-xs font-semibold text-ink-mid">
                Thứ tự hiển thị
                <input
                  type="number"
                  min={0}
                  className={fieldClass}
                  value={form.sortOrder}
                  onChange={(e) =>
                    setForm({ ...form, sortOrder: Number(e.target.value) || 0 })
                  }
                />
              </label>
              <label className="text-xs font-semibold text-ink-mid">
                Ngày kết thúc
                <input
                  type="date"
                  className={fieldClass}
                  value={toDateInput(form.endDate)}
                  onChange={(e) => setForm({ ...form, endDate: e.target.value })}
                />
              </label>
              <label className="flex items-center gap-2 self-end text-xs font-semibold text-ink-mid">
                <input
                  type="checkbox"
                  checked={form.isActive}
                  onChange={(e) => setForm({ ...form, isActive: e.target.checked })}
                />
                Hiển thị ngay trên trang chủ
              </label>
            </div>
            <div className="flex justify-end gap-2 pt-1">
              <button
                type="button"
                onClick={closeForm}
                className="cursor-pointer rounded-xl px-3.5 py-2 text-xs font-semibold text-ink-muted hover:bg-tint"
              >
                Hủy
              </button>
              <button
                type="button"
                disabled={saving}
                onClick={handleSave}
                className="cursor-pointer rounded-xl bg-camel px-4 py-2 text-xs font-bold text-ink hover:bg-camel-hover disabled:opacity-50"
              >
                {saving ? 'Đang lưu...' : editing ? 'Lưu thay đổi' : 'Thêm banner'}
              </button>
            </div>
          </div>
        )}

        <div className="overflow-hidden rounded-2xl border border-line bg-panel shadow-panel">
          {loading ? (
            <div className="flex justify-center p-8">
              <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-camel"></div>
            </div>
          ) : loadError ? (
            <div role="alert" className="p-6 text-center">
              <p className="text-sm text-danger">{loadError}</p>
              <button
                type="button"
                onClick={load}
                className="mt-3 cursor-pointer rounded-lg border border-danger-line px-3 py-1.5 text-xs font-semibold text-danger hover:bg-danger-bg"
              >
                Thử tải lại
              </button>
            </div>
          ) : banners.length === 0 ? (
            <div className="p-12 text-center text-sm text-ink-muted">
              Chưa có banner nào
            </div>
          ) : (
            <table className="w-full border-collapse text-left">
              <thead>
                <tr className="border-b border-line bg-panel text-xs font-semibold uppercase tracking-wider text-ink-muted">
                  <th className="p-4 pl-6">Ảnh</th>
                  <th className="p-4">Tiêu đề</th>
                  <th className="p-4">Thứ tự</th>
                  <th className="p-4">Kết thúc</th>
                  <th className="p-4">Hiển thị</th>
                  <th className="p-4 pr-6 text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line">
                {banners.map((b) => (
                  <tr key={b.id} className="transition-colors hover:bg-tint/60">
                    <td className="p-4 pl-6">
                      {b.imageUrl ? (
                        <Image
                          src={b.imageUrl}
                          alt={b.title}
                          width={96}
                          height={54}
                          unoptimized
                          className="h-[54px] w-24 rounded-lg border border-line bg-tint object-contain"
                        />
                      ) : (
                        <div className="h-[54px] w-24 rounded-lg border border-line bg-tint" />
                      )}
                    </td>
                    <td className="p-4">
                      <div className="text-sm font-semibold text-ink">{b.title}</div>
                      {b.linkUrl && (
                        <div className="max-w-xs truncate text-xs text-ink-muted">
                          {b.linkUrl}
                        </div>
                      )}
                    </td>
                    <td className="p-4 text-sm text-ink-mid">{b.sortOrder}</td>
                    <td className="p-4 text-sm text-ink-muted">
                      {b.endDate ? new Date(b.endDate).toLocaleDateString('vi-VN') : '—'}
                    </td>
                    <td className="p-4">
                      <span
                        className={`rounded-full px-2.5 py-1 text-xs font-bold ${
                          b.isActive
                            ? 'bg-ok-bg text-ok'
                            : 'bg-tint text-ink-muted'
                        }`}
                      >
                        {b.isActive ? 'Đang hiện' : 'Đang tắt'}
                      </span>
                    </td>
                    <td className="p-4 pr-6 text-right">
                      <div className="flex items-center justify-end gap-1">
                        <button
                          type="button"
                          onClick={() => handleToggle(b)}
                          title={b.isActive ? 'Tắt hiển thị' : 'Bật hiển thị'}
                          className="cursor-pointer rounded-lg p-2 text-ink-muted transition-colors hover:bg-tint hover:text-camel-dark"
                        >
                          {b.isActive ? (
                            <EyeOff className="h-4 w-4" />
                          ) : (
                            <Eye className="h-4 w-4" />
                          )}
                        </button>
                        <button
                          type="button"
                          onClick={() => openEdit(b)}
                          title="Sửa banner"
                          className="cursor-pointer rounded-lg p-2 text-ink-muted transition-colors hover:bg-tint hover:text-camel-dark"
                        >
                          <Pencil className="h-4 w-4" />
                        </button>
                        <button
                          type="button"
                          onClick={() => handleDelete(b)}
                          title="Xóa banner"
                          className="cursor-pointer rounded-lg p-2 text-danger transition-colors hover:bg-danger-bg"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}
