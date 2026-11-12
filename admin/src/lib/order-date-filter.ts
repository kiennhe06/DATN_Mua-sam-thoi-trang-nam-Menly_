/** Cac khoang ngay chon nhanh o trang quan ly don hang. */
export type KhoangNgay = 'all' | 'today' | 'last7' | 'last30' | 'thisMonth' | 'custom';

export const NHAN_KHOANG_NGAY: { value: KhoangNgay; label: string }[] = [
  { value: 'all', label: 'Tất cả thời gian' },
  { value: 'today', label: 'Hôm nay' },
  { value: 'last7', label: '7 ngày qua' },
  { value: 'last30', label: '30 ngày qua' },
  { value: 'thisMonth', label: 'Tháng này' },
  { value: 'custom', label: 'Chọn khoảng ngày…' },
];

/** Moc dau va cuoi gui len may chu; `to` la moc KHONG tinh vao ket qua. */
export interface MocLoc {
  from?: string;
  to?: string;
}

/** Dau ngay theo gio may dang dung, tra ve dang ISO. */
function dauNgay(nam: number, thang: number, ngay: number): string {
  return new Date(nam, thang, ngay).toISOString();
}

/** Doi chuoi 'YYYY-MM-DD' tu o chon ngay thanh moc dau ngay do. */
export function dauNgayTuChuoi(chuoi: string): string | undefined {
  const khop = /^(\d{4})-(\d{2})-(\d{2})$/.exec(chuoi.trim());
  if (!khop) return undefined;
  return dauNgay(Number(khop[1]), Number(khop[2]) - 1, Number(khop[3]));
}

/** Dau ngay hom sau cua 'YYYY-MM-DD', de bao tron ca ngay duoc chon. */
export function sauNgayTuChuoi(chuoi: string): string | undefined {
  const khop = /^(\d{4})-(\d{2})-(\d{2})$/.exec(chuoi.trim());
  if (!khop) return undefined;
  return dauNgay(Number(khop[1]), Number(khop[2]) - 1, Number(khop[3]) + 1);
}

/**
 * Doi lua chon tren giao dien thanh moc thoi gian gui len may chu.
 *
 * Moc tinh theo gio may dang dung chu khong theo UTC, de "hom nay" o Viet Nam
 * dung la tu 00:00 den 24:00 gio Viet Nam.
 */
export function tinhMocLoc(
  khoang: KhoangNgay,
  tuNgay: string,
  denNgay: string,
  bayGio: Date = new Date(),
): MocLoc {
  const nam = bayGio.getFullYear();
  const thang = bayGio.getMonth();
  const ngay = bayGio.getDate();
  const dauHomNay = dauNgay(nam, thang, ngay);
  const dauNgayMai = dauNgay(nam, thang, ngay + 1);

  switch (khoang) {
    case 'today':
      return { from: dauHomNay, to: dauNgayMai };
    case 'last7':
      return { from: dauNgay(nam, thang, ngay - 6), to: dauNgayMai };
    case 'last30':
      return { from: dauNgay(nam, thang, ngay - 29), to: dauNgayMai };
    case 'thisMonth':
      return { from: dauNgay(nam, thang, 1), to: dauNgay(nam, thang + 1, 1) };
    case 'custom':
      return {
        from: tuNgay ? dauNgayTuChuoi(tuNgay) : undefined,
        to: denNgay ? sauNgayTuChuoi(denNgay) : undefined,
      };
    default:
      return {};
  }
}
