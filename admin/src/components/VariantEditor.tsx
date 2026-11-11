'use client';

import { useState } from 'react';
import { Plus, Trash2 } from 'lucide-react';
import { MAU_SAN_PHAM, maMau, type BienTheNhap } from '../lib/product-options';

interface VariantEditorProps {
  /** Bang size hop le cua danh muc dang chon. */
  sizes: string[];
  variants: BienTheNhap[];
  onChange: (variants: BienTheNhap[]) => void;
  /**
   * Cac cap size + mau da ton tai tren may chu (dang "m|den"). O ton kho cua
   * nhung dong nay bi khoa: sua ton kho phai qua man Kho, vi con so trong form
   * la so doc luc mo form, luu xuong se ghi de mat cac don ban trong luc do.
   */
  bienTheDaCo?: Set<string>;
}

const fieldClass =
  'w-full rounded-lg border border-line-strong bg-panel px-3 py-2.5 text-sm text-ink placeholder:text-ink-muted focus:border-camel focus:outline-none';

const khoaCua = (size: string, color: string) =>
  `${size.trim().toLowerCase()}|${color.trim().toLowerCase()}`;

/**
 * Khoi chon size va mau cho san pham.
 *
 * Nguoi dung bat nhieu size va nhieu mau, component tu ghep thanh tung bien
 * the thay vi bat khai bao tung cap mot. Dung chung cho ca man them moi lan
 * man chinh sua de hai noi khong lech nhau.
 */
export function VariantEditor({
  sizes,
  variants,
  onChange,
  bienTheDaCo,
}: VariantEditorProps) {
  /** Dong nay da co tren may chu chua. */
  const daCoTrenMayChu = (variant: BienTheNhap) =>
    bienTheDaCo?.has(khoaCua(variant.size, variant.color)) ?? false;
  const [mauMoi, setMauMoi] = useState('');
  const [tonChung, setTonChung] = useState('');

  const sizeDangChon = Array.from(new Set(variants.map((variant) => variant.size)));

  // San pham cu co the dang dung size nam ngoai bang chuan cua danh muc (vi du
  // quan luu size "M"). Hien them nhung size do thay vi lang le doi chung,
  // neu khong mo man sua roi bam luu la mat du lieu bien the.
  const sizeHienThi = [...sizes, ...sizeDangChon.filter((size) => !sizes.includes(size))];
  const mauDangChon = Array.from(
    new Set(variants.map((variant) => variant.color).filter(Boolean)),
  );

  const toggleSize = (size: string) => {
    if (variants.some((variant) => variant.size === size)) {
      const conLai = variants.filter((variant) => variant.size !== size);
      if (conLai.length > 0) onChange(conLai);
      return;
    }
    const mau = Array.from(new Set(variants.map((variant) => variant.color).filter(Boolean)));
    const danhSachMau = mau.length > 0 ? mau : [MAU_SAN_PHAM[0].ten];
    onChange([...variants, ...danhSachMau.map((color) => ({ size, color, sku: '', stock: '0' }))]);
  };

  const toggleMau = (color: string) => {
    if (variants.some((variant) => variant.color === color)) {
      const conLai = variants.filter((variant) => variant.color !== color);
      if (conLai.length > 0) onChange(conLai);
      return;
    }
    const size = Array.from(new Set(variants.map((variant) => variant.size)));
    const danhSachSizeDangDung = size.length > 0 ? size : [sizes[0]];
    onChange([...variants, ...danhSachSizeDangDung.map((s) => ({ size: s, color, sku: '', stock: '0' }))]);
  };

  /** Them mot mau ngoai bang mau co san. */
  const themMauTuNhap = () => {
    const ten = mauMoi.trim();
    if (!ten) return;
    // So khong phan biet hoa thuong: "Đen" va "đen" la mot mau, them ca hai
    // se tao hai dong trung cap size + mau.
    const daCo = [...mauDangChon, ...MAU_SAN_PHAM.map((mau) => mau.ten)].some(
      (coSan) => coSan.toLocaleLowerCase() === ten.toLocaleLowerCase(),
    );
    if (!daCo) toggleMau(ten);
    setMauMoi('');
  };

  /** Dien cung mot so luong cho moi bien the, khoi go lai tung dong. */
  const dienTonChoTatCa = () => {
    const so = tonChung.trim();
    if (!so) return;
    // Chi dien cho bien the moi; bien the cu co o ton kho bi khoa.
    onChange(
      variants.map((variant) =>
        daCoTrenMayChu(variant) ? variant : { ...variant, stock: so },
      ),
    );
  };

  const setO = (index: number, key: 'sku' | 'stock', value: string) => {
    onChange(variants.map((variant, i) => (i === index ? { ...variant, [key]: value } : variant)));
  };

  const nutChon = (dangChon: boolean) =>
    `inline-flex cursor-pointer items-center gap-1.5 rounded-lg border px-3 py-1.5 text-xs font-semibold transition-colors ${
      dangChon
        ? 'border-camel bg-camel text-white'
        : 'border-line-strong bg-panel text-ink-mid hover:border-camel'
    }`;

  return (
    <div className="space-y-3">
      <div className="space-y-3 rounded-xl border border-line bg-tint p-3">
        <div>
          <p className="mb-1.5 text-[11px] font-semibold text-ink-mid">Size (chọn nhiều)</p>
          <div className="flex flex-wrap gap-1.5">
            {sizeHienThi.map((size) => {
              const dangChon = sizeDangChon.includes(size);
              return (
                <button
                  key={size}
                  type="button"
                  aria-pressed={dangChon}
                  onClick={() => toggleSize(size)}
                  className={nutChon(dangChon)}
                >
                  {size}
                </button>
              );
            })}
          </div>
        </div>

        <div>
          <p className="mb-1.5 text-[11px] font-semibold text-ink-mid">Màu (chọn nhiều)</p>
          <div className="flex flex-wrap gap-1.5">
            {MAU_SAN_PHAM.map((mau) => {
              const dangChon = mauDangChon.includes(mau.ten);
              return (
                <button
                  key={mau.ten}
                  type="button"
                  aria-pressed={dangChon}
                  onClick={() => toggleMau(mau.ten)}
                  className={nutChon(dangChon)}
                >
                  <span
                    className="h-3 w-3 shrink-0 rounded-full border border-line-strong"
                    style={{ background: mau.ma }}
                  />
                  {mau.ten}
                </button>
              );
            })}
            {mauDangChon
              .filter((ten) => maMau(ten) === null)
              .map((ten) => (
                <button
                  key={ten}
                  type="button"
                  aria-pressed
                  onClick={() => toggleMau(ten)}
                  className={nutChon(true)}
                >
                  {ten}
                </button>
              ))}
          </div>
          <div className="mt-2 flex gap-2">
            <input
              className={`${fieldClass} flex-1 py-1.5 text-xs`}
              value={mauMoi}
              onChange={(event) => setMauMoi(event.target.value)}
              onKeyDown={(event) => {
                // Enter trong form se gui form, nen chan lai va coi nhu bam
                // nut them mau.
                if (event.key === 'Enter') {
                  event.preventDefault();
                  themMauTuNhap();
                }
              }}
              maxLength={60}
              placeholder="Màu khác, ví dụ: Xanh pastel"
              aria-label="Tên màu tự nhập"
            />
            <button
              type="button"
              onClick={themMauTuNhap}
              className="shrink-0 cursor-pointer rounded-lg border border-camel/30 bg-camel-tint px-3 py-1.5 text-xs font-semibold text-camel-dark hover:bg-camel/15"
            >
              <Plus className="mr-1 inline h-3.5 w-3.5" />
              Thêm màu
            </button>
          </div>
        </div>
      </div>

      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-xs font-semibold text-ink-mid">{variants.length} biến thể</p>
        <div className="flex items-center gap-2">
          <input
            className={`${fieldClass} w-28 py-1.5 text-xs`}
            type="number"
            min="0"
            step="1"
            value={tonChung}
            onChange={(event) => setTonChung(event.target.value)}
            placeholder="Tồn kho"
            aria-label="Tồn kho điền cho tất cả biến thể"
          />
          <button
            type="button"
            onClick={dienTonChoTatCa}
            className="shrink-0 cursor-pointer rounded-lg border border-line-strong bg-panel px-3 py-1.5 text-xs font-semibold text-ink-mid hover:border-camel"
          >
            Điền cho tất cả
          </button>
        </div>
      </div>

      {variants.map((variant, index) => (
          <div
            key={khoaCua(variant.size, variant.color)}
            className="grid items-end gap-3 rounded-xl border border-line bg-tint p-3 md:grid-cols-[1.2fr_1.3fr_0.7fr_auto]"
          >
            <div className="space-y-1 text-[11px] font-semibold text-ink-mid">
              Biến thể
              <div className="flex items-center gap-2 rounded-lg border border-line-strong bg-panel px-3 py-2.5 text-sm text-ink">
                <span
                  className="h-4 w-4 shrink-0 rounded-full border border-line-strong"
                  style={{ background: maMau(variant.color) ?? 'transparent' }}
                />
                <span className="font-semibold">{variant.size}</span>
                <span className="text-ink-muted">·</span>
                <span className="font-normal">{variant.color}</span>
              </div>
            </div>
            <label className="space-y-1 text-[11px] font-semibold text-ink-mid">
              SKU
              <input
                className={fieldClass}
                aria-label={`SKU biến thể ${index + 1}`}
                value={variant.sku}
                onChange={(event) => setO(index, 'sku', event.target.value)}
                maxLength={100}
                placeholder="Để trống sẽ tự tạo"
              />
            </label>
            <label className="space-y-1 text-[11px] font-semibold text-ink-mid">
              Tồn kho
              <input
                className={`${fieldClass} ${
                  daCoTrenMayChu(variant) ? 'cursor-not-allowed bg-tint text-ink-muted' : ''
                }`}
                aria-label={`Tồn kho biến thể ${index + 1}`}
                type="number"
                min="0"
                step="1"
                value={variant.stock}
                onChange={(event) => setO(index, 'stock', event.target.value)}
                readOnly={daCoTrenMayChu(variant)}
                title={
                  daCoTrenMayChu(variant)
                    ? 'Sửa tồn kho ở mục Kho để được ghi nhật ký và không ghi đè đơn vừa bán'
                    : undefined
                }
                required
              />
            </label>
            <button
              type="button"
              aria-label={`Xóa biến thể ${index + 1}`}
              disabled={variants.length === 1}
              onClick={() => onChange(variants.filter((_, i) => i !== index))}
              className="flex h-[42px] items-center justify-center rounded-lg px-2 text-ink-muted hover:bg-danger-bg hover:text-danger disabled:cursor-not-allowed disabled:opacity-30"
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </div>
      ))}
    </div>
  );
}
