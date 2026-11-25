/**
 * Luat chuyen trang thai don hang.
 *
 * Truoc day man quan tri cho doi tu trang thai nay sang trang thai bat ky.
 * Hai cho hong that su:
 *   - Don da huy chuyen lai thanh "da giao": luc huy, ham cancel_order da cong
 *     hang ve kho roi, nen hang vua duoc cong lai vua duoc giao di.
 *   - Don da giao day nguoc ve "dang xu ly" rot cuoc sinh them mot moc
 *     'delivered' moi, keo dai han tra hang cua khach.
 *
 * File nay la noi duy nhat giu luat o may chu. Man quan tri co ban sao rieng
 * de an bot lua chon trong o chon, nhung cho chan that su la o day.
 */

/** Trang thai don, xep theo thu tu don di tu dau den cuoi. */
const THU_TU_TIEN: readonly string[] = [
  'pending_payment',
  'paid',
  'processing',
  'shipping',
  'delivered',
  'completed',
];

/** Da chot, khong con duong di tiep. */
const TRANG_THAI_KET_THUC: readonly string[] = ['completed', 'cancelled', 'expired'];

/** Chi huy duoc khi hang chua roi kho. */
const DUOC_HUY_TU: readonly string[] = ['pending_payment', 'paid', 'processing'];

/** Chi het han khi don chua tra tien. */
const DUOC_HET_HAN_TU: readonly string[] = ['pending_payment'];

/** Loi rieng cho viec chuyen trang thai sai, de route tra ve dung ma 409. */
export class LoiChuyenTrangThai extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'LoiChuyenTrangThai';
  }
}

/** Nhan tieng Viet cua trang thai, dung trong cau bao loi. */
export function tenTrangThai(trangThai: string): string {
  switch (trangThai) {
    case 'pending_payment': return 'Chờ thanh toán';
    case 'paid': return 'Đã thanh toán';
    case 'processing': return 'Đang xử lý';
    case 'shipping': return 'Đang giao hàng';
    case 'delivered': return 'Đã giao hàng';
    case 'completed': return 'Đã hoàn tất';
    case 'cancelled': return 'Đã hủy';
    case 'expired': return 'Đã quá hạn thanh toán';
    default: return trangThai;
  }
}

/**
 * Tu trang thai hien tai co chuyen sang trang thai moi duoc khong.
 *
 * Cho phep nhay coc ve phia truoc (vi du 'paid' thang sang 'completed'), vi
 * don that trong he thong von co truong hop khong di qua du cac buoc. Chi cam
 * di lui va cam roi khoi trang thai da chot.
 */
export function duocChuyenTrangThai(tu: string, den: string): boolean {
  if (tu === den) return true;

  if (TRANG_THAI_KET_THUC.includes(tu)) return false;

  if (den === 'cancelled') return DUOC_HUY_TU.includes(tu);
  if (den === 'expired') return DUOC_HET_HAN_TU.includes(tu);

  const viTriTu = THU_TU_TIEN.indexOf(tu);
  const viTriDen = THU_TU_TIEN.indexOf(den);
  // Trang thai la ngoai danh sach thi khong doan bua, cu tu choi.
  if (viTriTu < 0 || viTriDen < 0) return false;

  return viTriDen > viTriTu;
}

/**
 * Nem loi neu buoc chuyen khong hop le, kem cau giai thich cho nguoi dung.
 */
export function kiemTraChuyenTrangThai(tu: string, den: string): void {
  if (duocChuyenTrangThai(tu, den)) return;

  if (TRANG_THAI_KET_THUC.includes(tu)) {
    throw new LoiChuyenTrangThai(
      `Đơn đang ở trạng thái "${tenTrangThai(tu)}" và đã kết thúc, không chuyển sang trạng thái khác được nữa`,
    );
  }

  if (den === 'cancelled') {
    throw new LoiChuyenTrangThai(
      `Đơn đã ở trạng thái "${tenTrangThai(tu)}" nên không hủy được nữa; hàng đã rời kho thì xử lý bằng yêu cầu trả hàng`,
    );
  }

  if (den === 'expired') {
    throw new LoiChuyenTrangThai(
      'Chỉ đơn đang chờ thanh toán mới chuyển sang quá hạn được',
    );
  }

  throw new LoiChuyenTrangThai(
    `Không lùi đơn từ "${tenTrangThai(tu)}" về "${tenTrangThai(den)}" được`,
  );
}

/** Cac trang thai con di tiep duoc, dung de dung danh sach cho nguoi chon. */
export function cacTrangThaiTiepTheo(tu: string): string[] {
  const tatCa = [...THU_TU_TIEN, 'cancelled', 'expired'];
  return tatCa.filter((den) => den !== tu && duocChuyenTrangThai(tu, den));
}
