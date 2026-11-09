import { OrderModel } from '../models/order.model.js';

/**
 * Don VNPay qua han cu 5 phut mot lan.
 *
 * Han tra tien la 30 phut (dat o ham create_order), nen chay 5 phut mot lan la
 * du sat de hang khong bi giu lau, ma khong lam phien co so du lieu.
 */
const CHU_KY_MS = 5 * 60 * 1000;

/** Phan viec ma bo dem can, tach ra de kiem thu khong phai goi co so du lieu. */
export interface NguoiDonDonQuaHan {
  expirePendingOrders(): Promise<boolean>;
}

let boDem: NodeJS.Timeout | null = null;

export function batDauDonDonQuaHan(model: NguoiDonDonQuaHan = new OrderModel()): void {
  if (boDem) return;

  // Chay ngay mot lan luc khoi dong, de cac don qua han trong luc may chu tat
  // duoc don ngay chu khong phai cho het chu ky dau tien.
  void model.expirePendingOrders();

  boDem = setInterval(() => {
    void model.expirePendingOrders();
  }, CHU_KY_MS);

  // Khong giu tien trinh song chi vi bo dem nay.
  boDem.unref();
}

export function dungDonDonQuaHan(): void {
  if (!boDem) return;
  clearInterval(boDem);
  boDem = null;
}
