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

test('GET /api/v1/orders/track - thiếu mã đơn và SĐT thì trả về 400', async () => {
  const response = await fetch(`${baseUrl}/api/v1/orders/track`);
  assert.equal(response.status, 400);
  const data = await response.json() as { error: string };
  assert.match(data.error, /mã đơn|số điện thoại/i);
});

test('GET /api/v1/orders/track - trả về 404 khi không tìm thấy đơn hàng', async () => {
  const response = await fetch(`${baseUrl}/api/v1/orders/track?code=NOTFOUND-999&phone=0900000000`);
  assert.equal(response.status, 404);
  const data = await response.json() as { error: string };
  assert.match(data.error, /không tìm thấy đơn hàng/i);
});
