import assert from 'node:assert/strict';
import { after, test } from 'node:test';

process.env.SUPABASE_URL = 'http://127.0.0.1:1';
process.env.SUPABASE_ANON_KEY = 'test-anon-key';
process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-service-role-key';

const { batDauDonDonQuaHan, dungDonDonQuaHan } = await import('./order-expiry.scheduler.js');

after(() => dungDonDonQuaHan());

test('bật bộ đếm là dọn đơn quá hạn ngay, không chờ hết chu kỳ đầu tiên', async () => {
  dungDonDonQuaHan();
  let soLanGoi = 0;
  const nguoiDon = {
    expirePendingOrders: async () => {
      soLanGoi += 1;
      return true;
    },
  };

  batDauDonDonQuaHan(nguoiDon);
  // Cho mot vong event loop de lenh goi khong cho ket qua chay xong.
  await new Promise((resolve) => setImmediate(resolve));

  assert.equal(soLanGoi, 1, 'phải dọn ngay khi máy chủ khởi động');

  // Goi lai khong duoc tao them bo dem thu hai, neu khong moi lan nap lai code
  // se chong them mot bo dem nua.
  batDauDonDonQuaHan(nguoiDon);
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(soLanGoi, 1, 'bật lần hai không được chồng thêm bộ đếm');

  dungDonDonQuaHan();
});

test('dừng rồi bật lại thì bộ đếm chạy tiếp được', async () => {
  dungDonDonQuaHan();
  let soLanGoi = 0;
  const nguoiDon = {
    expirePendingOrders: async () => {
      soLanGoi += 1;
      return true;
    },
  };

  batDauDonDonQuaHan(nguoiDon);
  await new Promise((resolve) => setImmediate(resolve));
  dungDonDonQuaHan();
  batDauDonDonQuaHan(nguoiDon);
  await new Promise((resolve) => setImmediate(resolve));

  assert.equal(soLanGoi, 2);
  dungDonDonQuaHan();
});
