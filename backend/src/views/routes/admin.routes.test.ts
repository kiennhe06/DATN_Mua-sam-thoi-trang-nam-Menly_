import assert from 'node:assert/strict';
import { after, test } from 'node:test';

process.env.SUPABASE_URL = 'http://127.0.0.1:54321';
process.env.SUPABASE_ANON_KEY = 'test-anon-key';
process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-service-role-key';

const { createApp } = await import('../app.js');
const server = createApp().listen(0);
const address = server.address();
if (!address || typeof address === 'string') throw new Error('Không lấy được cổng kiểm thử');
const baseUrl = `http://127.0.0.1:${address.port}`;

after(() => new Promise<void>((resolve, reject) => {
  server.close((error) => error ? reject(error) : resolve());
}));

test('API quản trị từ chối yêu cầu không có token', async () => {
  const response = await fetch(`${baseUrl}/api/v1/admin/products`);
  assert.equal(response.status, 401);
  assert.deepEqual(await response.json(), { error: 'Vui lòng đăng nhập' });
});

test('đăng nhập từ chối payload sai trước khi gọi Supabase', async () => {
  const response = await fetch(`${baseUrl}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'khong-phai-email', password: '' }),
  });
  assert.equal(response.status, 400);
});
