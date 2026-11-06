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
  server.close((error) => error ? reject(error) : resolve());
}));

test('POST /api/v1/notifications - cần đăng nhập', async () => {
  const response = await fetch(`${baseUrl}/api/v1/notifications`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title: 'Khuyến mãi', body: 'Sale 50%' }),
  });

  assert.equal(response.status, 401);
  const data = await response.json() as { error: string };
  assert.match(data.error, /đăng nhập|login/i);
});

test('POST /api/v1/order-returns - cần đăng nhập', async () => {
  const response = await fetch(`${baseUrl}/api/v1/order-returns`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      orderId: '123e4567-e89b-12d3-a456-426614174000',
      reason: 'Sản phẩm không đúng mô tả',
      proofImages: ['https://example.com/1.jpg'],
      refundAmount: 100000,
    }),
  });

  assert.equal(response.status, 401);
  const data = await response.json() as { error: string };
  assert.match(data.error, /đăng nhập|login/i);
});
