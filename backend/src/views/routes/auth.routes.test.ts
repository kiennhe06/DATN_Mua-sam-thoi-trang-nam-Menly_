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

test('POST /api/v1/auth/register - từ chối dữ liệu không hợp lệ', async () => {
  const response = await fetch(`${baseUrl}/api/v1/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'sai-email', password: '123', fullName: '' }),
  });
  assert.equal(response.status, 400);
  const data = await response.json() as { error: string; details: Record<string, string[]> };
  assert.ok(data.error);
  assert.ok(data.details.email);
  assert.ok(data.details.password);
  assert.ok(data.details.fullName);
});

test('POST /api/v1/auth/login - từ chối email hoặc password sai định dạng', async () => {
  const response = await fetch(`${baseUrl}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'not-an-email', password: '' }),
  });
  assert.equal(response.status, 400);
  const data = await response.json() as { error: string };
  assert.ok(data.error);
});

test('POST /api/v1/auth/change-password - từ chối khi chưa đăng nhập', async () => {
  const response = await fetch(`${baseUrl}/api/v1/auth/change-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ currentPassword: 'oldPassword1', newPassword: 'newPassword2' }),
  });
  assert.equal(response.status, 401);
  const data = await response.json() as { error: string };
  assert.equal(data.error, 'Vui lòng đăng nhập');
});

test('GET /api/v1/auth/me - từ chối khi không có Bearer token', async () => {
  const response = await fetch(`${baseUrl}/api/v1/auth/me`);
  assert.equal(response.status, 401);
  const data = await response.json() as { error: string };
  assert.equal(data.error, 'Vui lòng đăng nhập');
});

test('POST /api/v1/auth/forgot-password - từ chối email không hợp lệ', async () => {
  const response = await fetch(`${baseUrl}/api/v1/auth/forgot-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'invalid-email' }),
  });
  assert.equal(response.status, 400);
});

test('POST /api/v1/auth/reset-password - từ chối khi thiếu token/otp và mật khẩu quá ngắn', async () => {
  const response = await fetch(`${baseUrl}/api/v1/auth/reset-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ newPassword: '123' }),
  });
  assert.equal(response.status, 400);
});
