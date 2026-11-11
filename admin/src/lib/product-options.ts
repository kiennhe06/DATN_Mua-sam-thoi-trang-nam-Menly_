/**
 * Danh sach size va mau co san cho form san pham.
 *
 * Truoc day hai o nay la o go tay, nen moi nguoi go mot kieu ("Den", "den",
 * "Màu đen") va app loc bien the theo chuoi nen cung mot mau lai thanh hai
 * dong khac nhau. Chon tu danh sach thi du lieu luon thong nhat.
 */

/** Size chu cho ao va do mac ngoai. */
export const SIZE_CHU = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', 'Freesize'];

/** Size so (vong eo, inch) cho quan. */
export const SIZE_SO = ['28', '29', '30', '31', '32', '33', '34', '36', '38'];

/**
 * Danh muc quan hay dung size so. Nhan dang qua slug hoac ten danh muc,
 * khong phai qua ma danh muc, de them danh muc quan moi la tu chay dung.
 */
export function laDanhMucQuan(danhMuc: string): boolean {
  const chuan = danhMuc
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase();
  return chuan.includes('quan');
}

/** Bang size dung cho mot danh muc. */
export function danhSachSize(danhMuc: string): string[] {
  return laDanhMucQuan(danhMuc) ? SIZE_SO : SIZE_CHU;
}

export interface MauSanPham {
  ten: string;
  /** Ma mau de ve o vuong xem truoc canh ten. */
  ma: string;
}

/** Bang mau co san, dat ten theo cach shop thoi trang nam thuong goi. */
export const MAU_SAN_PHAM: MauSanPham[] = [
  { ten: 'Đen', ma: '#1C1B17' },
  { ten: 'Trắng', ma: '#FFFFFF' },
  { ten: 'Kem', ma: '#F2EADF' },
  { ten: 'Be', ma: '#D9C9A3' },
  { ten: 'Xám', ma: '#9AA0A6' },
  { ten: 'Xám đậm', ma: '#4A4A4A' },
  { ten: 'Nâu', ma: '#6B4A2F' },
  { ten: 'Xanh navy', ma: '#1F3A5F' },
  { ten: 'Xanh dương', ma: '#3B6FB0' },
  { ten: 'Xanh rêu', ma: '#6B7A4F' },
  { ten: 'Xanh mint', ma: '#9FC5B5' },
  { ten: 'Đỏ đô', ma: '#7B2B2B' },
  { ten: 'Cam đất', ma: '#B5603B' },
  { ten: 'Vàng bò', ma: '#C8A560' },
];

/** Gia tri chon trong o mau de chuyen sang tu go ten mau khac. */
export const MAU_TU_NHAP = '__khac__';

/** Ma mau cua mot ten mau, null khi ten do khong co trong bang. */
export function maMau(ten: string): string | null {
  const found = MAU_SAN_PHAM.find((mau) => mau.ten === ten);
  return found ? found.ma : null;
}

/**
 * Tim cap size + mau chua dung, de nut "Them bien the" khong tao ra dong
 * trung voi dong da co (cap size + mau phai la duy nhat).
 */
export function capChuaDung(
  sizes: string[],
  daDung: Array<{ size: string; color: string }>,
): { size: string; color: string } {
  const khoa = new Set(
    daDung.map((v) => `${v.size.trim().toLowerCase()}|${v.color.trim().toLowerCase()}`),
  );
  for (const mau of MAU_SAN_PHAM) {
    for (const size of sizes) {
      if (!khoa.has(`${size.toLowerCase()}|${mau.ten.toLowerCase()}`)) {
        return { size, color: mau.ten };
      }
    }
  }
  return { size: sizes[0] ?? '', color: MAU_SAN_PHAM[0].ten };
}

/** Mot dong bien the trong form san pham (so luong de dang chuoi vi o nhap). */
export interface BienTheNhap {
  size: string;
  color: string;
  sku: string;
  stock: string;
}
