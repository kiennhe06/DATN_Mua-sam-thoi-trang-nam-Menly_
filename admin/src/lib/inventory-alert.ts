/**
 * Nguong canh bao ton kho.
 *
 * Tren muc nay coi nhu con du hang; tu day tro xuong thu kho can nhap them
 * truoc khi het sach, vi tu luc dat hang nha cung cap den luc hang ve con mat
 * vai ngay. Doi nguong qua bien NEXT_PUBLIC_LOW_STOCK_THRESHOLD, khong phai
 * sua code.
 */
export const NGUONG_SAP_HET = docNguong(process.env.NEXT_PUBLIC_LOW_STOCK_THRESHOLD, 5);

/** Doc nguong tu bien moi truong, bo qua gia tri trong hoac khong hop le. */
function docNguong(bien: string | undefined, macDinh: number): number {
  const chuoi = (bien ?? '').trim();
  if (chuoi === '') return macDinh;
  const so = Number(chuoi);
  if (!Number.isFinite(so) || so < 0) return macDinh;
  return Math.round(so);
}

export type MucTonKho = 'het' | 'sap_het' | 'du';

/** Xep mot so luong ton vao ba muc de to mau va loc danh sach. */
export function mucTonKho(soLuong: number): MucTonKho {
  if (soLuong <= 0) return 'het';
  if (soLuong <= NGUONG_SAP_HET) return 'sap_het';
  return 'du';
}

/** Nhan chu hien canh ten so luong. */
export function nhanTonKho(muc: MucTonKho): string {
  if (muc === 'het') return 'Hết hàng';
  if (muc === 'sap_het') return 'Sắp hết';
  return '';
}
