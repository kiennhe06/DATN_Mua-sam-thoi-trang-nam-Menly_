/**
 * Phien dang nhap cua trang quan tri va quyen vao tung trang.
 *
 * Gom mot cho de ca thanh ben, chot bao ve va trang dang nhap dung chung mot
 * danh sach quyen, tranh canh moi noi tu kiem tra role mot kieu roi lech nhau.
 */

export type VaiTroQuanTri = 'admin' | 'staff';

export interface NguoiDangNhap {
  id?: string;
  email?: string;
  fullName?: string;
  role: VaiTroQuanTri;
}

const KHOA_TOKEN = 'menshop_admin_token';
const KHOA_NGUOI_DUNG = 'menshop_admin_user';

/** Cac trang nhan vien duoc vao. */
export const TRANG_CUA_NHAN_VIEN = ['/orders', '/chat'] as const;

/**
 * Trang chi danh rieng cho nhan vien, admin khong vao.
 *
 * Tra loi tin nhan khach la viec cua nhan vien truc, admin khong lam nen de
 * trong thanh ben chi tho. Admin can doc hoi thoai thi van vao duoc tu ung
 * dung Menly.
 */
export const TRANG_CHI_NHAN_VIEN = ['/chat'] as const;

/** Trang nhan vien thay dau tien sau khi dang nhap. */
export const TRANG_MAC_DINH_NHAN_VIEN = '/orders';

/** Trang dau tien cua tung vai tro sau khi dang nhap. */
export function trangMacDinh(role: VaiTroQuanTri): string {
  return role === 'admin' ? '/' : TRANG_MAC_DINH_NHAN_VIEN;
}

/** Chi hai vai tro nay dang nhap duoc vao trang quan tri. */
export function laVaiTroQuanTri(role: unknown): role is VaiTroQuanTri {
  return role === 'admin' || role === 'staff';
}

/** Doc nguoi dang dang nhap tu localStorage, tra ve null neu chua co hoac hong. */
export function docNguoiDangNhap(): NguoiDangNhap | null {
  if (typeof window === 'undefined') return null;
  const chuoi = localStorage.getItem(KHOA_NGUOI_DUNG);
  if (!chuoi) return null;
  try {
    const dulieu = JSON.parse(chuoi) as { role?: unknown } & Record<string, unknown>;
    if (!laVaiTroQuanTri(dulieu.role)) return null;
    return {
      id: typeof dulieu.id === 'string' ? dulieu.id : undefined,
      email: typeof dulieu.email === 'string' ? dulieu.email : undefined,
      fullName: typeof dulieu.fullName === 'string' ? dulieu.fullName : undefined,
      role: dulieu.role,
    };
  } catch {
    return null;
  }
}

export function docToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(KHOA_TOKEN);
}

export function xoaPhien(): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(KHOA_TOKEN);
  localStorage.removeItem(KHOA_NGUOI_DUNG);
}

/**
 * Vai tro nay co duoc vao duong dan nay khong.
 *
 * Nhan vien chi vao duoc nhung trang trong TRANG_CUA_NHAN_VIEN, ke ca duong
 * dan con ben trong (vi du /orders/abc). Admin vao duoc moi trang tru nhung
 * trang nam trong TRANG_CHI_NHAN_VIEN.
 */
export function duocVaoTrang(role: VaiTroQuanTri, duongDan: string): boolean {
  const thuoc = (danhSach: readonly string[]) =>
    danhSach.some((trang) => duongDan === trang || duongDan.startsWith(`${trang}/`));

  // Xet truoc ca admin: day la nhung trang admin cung khong vao.
  if (thuoc(TRANG_CHI_NHAN_VIEN)) return role === 'staff';
  if (role === 'admin') return true;
  return thuoc(TRANG_CUA_NHAN_VIEN);
}

/** Ten vai tro de hien cho nguoi dung doc. */
export function tenVaiTro(role: VaiTroQuanTri): string {
  return role === 'admin' ? 'Quản trị viên' : 'Nhân viên';
}
