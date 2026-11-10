import assert from 'node:assert/strict';
import { after, test } from 'node:test';

process.env.SUPABASE_URL = process.env.SUPABASE_URL || 'http://127.0.0.1:54321';
process.env.SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'test-anon-key';
process.env.SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || 'test-service-role-key';

const { createApp } = await import('../app.js');
const server = createApp().listen(0);
const address = server.address();
if (!address || typeof address === 'string') throw new Error('Không lấy được cổng kiểm thử');
const baseUrl = `http://127.0.0.1:${address.port}`;

after(() => new Promise<void>((resolve, reject) => {
  server.close((error) => (error ? reject(error) : resolve()));
}));

test('POST /api/v1/payments/vnpay/create - tạo link thanh toán VNPay Sandbox', async () => {
  const response = await fetch(`${baseUrl}/api/v1/payments/vnpay/create`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      orderCode: 'ORD_TEST_999',
      amount: 350000,
      orderInfo: 'Thanh toan don hang test',
    }),
  });

  assert.equal(response.status, 200);
  const data = (await response.json()) as {
    message: string;
    paymentUrl: string;
    data: { txnRef: string; amount: number };
  };

  assert.ok(data.paymentUrl);
  assert.equal(data.data.amount, 350000);
  assert.ok(data.paymentUrl.includes('vnp_SecureHash'));
  assert.ok(data.paymentUrl.includes('sandbox.vnpayment.vn'));
});

test('POST /api/v1/payments/vnpay/create - từ chối khi payload thiếu thông tin đơn hàng', async () => {
  const response = await fetch(`${baseUrl}/api/v1/payments/vnpay/create`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      amount: 100000,
    }),
  });

  assert.equal(response.status, 400);
  const data = (await response.json()) as { error: string };
  assert.ok(data.error);
});

test('GET /api/v1/payments/vnpay/ipn - phản hồi RspCode 97 khi chữ ký sai', async () => {
  const response = await fetch(
    `${baseUrl}/api/v1/payments/vnpay/ipn?vnp_TxnRef=TXN_123&vnp_Amount=10000000&vnp_ResponseCode=00&vnp_SecureHash=fakehash`
  );

  assert.equal(response.status, 200);
  const data = (await response.json()) as { RspCode: string; Message: string };
  assert.equal(data.RspCode, '97');
  assert.equal(data.Message, 'Invalid Checksum');
});

test('GET /api/v1/payments/vnpay/return - trả về thông báo lỗi khi chữ ký không hợp lệ', async () => {
  const response = await fetch(
    `${baseUrl}/api/v1/payments/vnpay/return?vnp_TxnRef=TXN_123&vnp_Amount=10000000&vnp_ResponseCode=00&vnp_SecureHash=fakehash`,
    {
      headers: { Accept: 'application/json' },
    }
  );

  assert.equal(response.status, 200);
  const data = (await response.json()) as { data: { isValidChecksum: boolean; isSuccess: boolean } };
  assert.equal(data.data.isValidChecksum, false);
  assert.equal(data.data.isSuccess, false);
});

