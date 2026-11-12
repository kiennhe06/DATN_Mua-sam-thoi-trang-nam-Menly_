/**
 * Trang thai "dang soan tin" cua chat CSKH.
 *
 * Giu trong bo nho chu khong ghi xuong database: day la thong tin song trong
 * vai giay roi bo di, ghi xuong database se ton mot cau UPDATE moi lan go phim
 * va lam ban bang du lieu. Doi lai, khi may chu khoi dong lai thi moi nguoi
 * deu tro ve trang thai khong go - chap nhan duoc.
 */

/** Qua moc nay ma khong co tin hieu moi thi coi nhu da ngung go. */
const HAN_DANG_SOAN_MS = 6000;

/** Don rac khi bang vuot qua nguong nay, tranh phinh bo nho theo thoi gian. */
const NGUONG_DON_RAC = 500;

export type BenGui = 'customer' | 'staff';

export interface TrangThaiDangSoan {
  customer: boolean;
  staff: boolean;
}

interface MocThoiGian {
  customer?: number;
  staff?: number;
}

const bangDangSoan = new Map<string, MocThoiGian>();

/** Xoa cac hoi thoai da im lang tu lau ra khoi bang. */
function donRac(moc: number): void {
  if (bangDangSoan.size < NGUONG_DON_RAC) return;
  for (const [id, cacMoc] of bangDangSoan) {
    const moiNhat = Math.max(cacMoc.customer ?? 0, cacMoc.staff ?? 0);
    if (moc - moiNhat > HAN_DANG_SOAN_MS) bangDangSoan.delete(id);
  }
}

/** Ghi nhan mot ben vua go phim trong hoi thoai nay. */
export function ghiDangSoan(conversationId: string, ben: BenGui): void {
  const moc = Date.now();
  donRac(moc);
  const cacMoc = bangDangSoan.get(conversationId) ?? {};
  cacMoc[ben] = moc;
  bangDangSoan.set(conversationId, cacMoc);
}

/** Ben nao dang go trong hoi thoai nay, tinh tai thoi diem goi. */
export function docDangSoan(conversationId: string): TrangThaiDangSoan {
  const cacMoc = bangDangSoan.get(conversationId);
  if (!cacMoc) return { customer: false, staff: false };
  const moc = Date.now();
  return {
    customer: moc - (cacMoc.customer ?? 0) < HAN_DANG_SOAN_MS,
    staff: moc - (cacMoc.staff ?? 0) < HAN_DANG_SOAN_MS,
  };
}

/**
 * Ben vua gui tin thi coi nhu khong con go nua.
 *
 * Khong xoa thi tin da gui roi ma doi phuong van thay dong "dang soan" them
 * vai giay nua, nhin rat la.
 */
export function xoaDangSoan(conversationId: string, ben: BenGui): void {
  const cacMoc = bangDangSoan.get(conversationId);
  if (!cacMoc) return;
  delete cacMoc[ben];
  if (cacMoc.customer === undefined && cacMoc.staff === undefined) {
    bangDangSoan.delete(conversationId);
  }
}
