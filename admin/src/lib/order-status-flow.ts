import { OrderStatus } from './types';

/**
 * Bản sao luật chuyển trạng thái đơn hàng, dùng để dựng danh sách lựa chọn.
 *
 * Nguồn sự thật là `backend/src/models/order-status-flow.ts` — máy chủ mới là
 * nơi chặn thật. File này chỉ để người dùng không nhìn thấy những lựa chọn
 * chắc chắn sẽ bị từ chối. Sửa luật thì phải sửa cả hai nơi.
 */

/** Thứ tự đơn đi từ đầu đến cuối. */
const THU_TU_TIEN: OrderStatus[] = [
  'pending_payment',
  'paid',
  'processing',
  'shipping',
  'delivered',
  'completed',
];

/** Đã chốt, không còn đường đi tiếp. */
const TRANG_THAI_KET_THUC: OrderStatus[] = ['completed', 'cancelled', 'expired'];

/** Chỉ hủy được khi hàng chưa rời kho. */
const DUOC_HUY_TU: OrderStatus[] = ['pending_payment', 'paid', 'processing'];

/** Chỉ hết hạn khi đơn chưa trả tiền. */
const DUOC_HET_HAN_TU: OrderStatus[] = ['pending_payment'];

export const NHAN_TRANG_THAI_DON: Record<OrderStatus, string> = {
  pending_payment: 'Chờ thanh toán',
  paid: 'Đã thanh toán',
  processing: 'Đang xử lý',
  shipping: 'Đang giao hàng',
  delivered: 'Đã giao hàng',
  completed: 'Đã hoàn tất',
  cancelled: 'Đã hủy',
  expired: 'Đã quá hạn thanh toán',
};

/** Đơn đang ở trạng thái này thì không đổi được nữa. */
export function laTrangThaiKetThuc(trangThai: OrderStatus): boolean {
  return TRANG_THAI_KET_THUC.includes(trangThai);
}

/**
 * Các trạng thái còn chuyển tới được từ trạng thái hiện tại.
 *
 * Cho phép nhảy cóc về phía trước vì đơn thật không phải lúc nào cũng đi đủ
 * các bước; chỉ cấm đi lùi và cấm rời khỏi trạng thái đã chốt.
 */
export function cacTrangThaiTiepTheo(tu: OrderStatus): OrderStatus[] {
  if (laTrangThaiKetThuc(tu)) return [];

  const viTriTu = THU_TU_TIEN.indexOf(tu);
  const diTiep = viTriTu < 0 ? [] : THU_TU_TIEN.slice(viTriTu + 1);

  const ketThucDuoc: OrderStatus[] = [];
  if (DUOC_HUY_TU.includes(tu)) ketThucDuoc.push('cancelled');
  if (DUOC_HET_HAN_TU.includes(tu)) ketThucDuoc.push('expired');

  return [...diTiep, ...ketThucDuoc];
}
