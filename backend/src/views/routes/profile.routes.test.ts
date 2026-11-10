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

test('GET /api/v1/profile - từ chối khi chưa đăng nhập (không có Bearer token)', async () => {
  const response = await fetch(`${baseUrl}/api/v1/profile`);
  assert.equal(response.status, 401);
  const data = await response.json() as { error: string };
  assert.equal(data.error, 'Vui lòng đăng nhập');
});

test('PUT /api/v1/profile - từ chối khi chưa đăng nhập', async () => {
  const response = await fetch(`${baseUrl}/api/v1/profile`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ fullName: 'Ten Moi' }),
  });
  assert.equal(response.status, 401);
  const data = await response.json() as { error: string };
  assert.equal(data.error, 'Vui lòng đăng nhập');
});

test('POST /api/v1/profile/upload-avatar - từ chối khi chưa đăng nhập', async () => {
  const response = await fetch(`${baseUrl}/api/v1/profile/upload-avatar`, {
    method: 'POST',
  });
  assert.equal(response.status, 401);
  const data = await response.json() as { error: string };
  assert.equal(data.error, 'Vui lòng đăng nhập');
});

