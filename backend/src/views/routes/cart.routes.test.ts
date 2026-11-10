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

const sampleVariantId = '123e4567-e89b-12d3-a456-426614174000';

test('GET /api/v1/cart - từ chối khi chưa đăng nhập (không có Bearer token)', async () => {
  const response = await fetch(`${baseUrl}/api/v1/cart`);
  assert.equal(response.status, 401);
  const data = await response.json() as { error: string };
  assert.equal(data.error, 'Vui lòng đăng nhập');
});

test('POST /api/v1/cart/items - từ chối khi chưa đăng nhập', async () => {
  const response = await fetch(`${baseUrl}/api/v1/cart/items`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ variantId: sampleVariantId, quantity: 1 }),
  });
  assert.equal(response.status, 401);
  const data = await response.json() as { error: string };
  assert.equal(data.error, 'Vui lòng đăng nhập');
});

test('PUT /api/v1/cart/items - từ chối khi chưa đăng nhập', async () => {
  const response = await fetch(`${baseUrl}/api/v1/cart/items`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ variantId: sampleVariantId, quantity: 2 }),
  });
  assert.equal(response.status, 401);
  const data = await response.json() as { error: string };
  assert.equal(data.error, 'Vui lòng đăng nhập');
});

test('DELETE /api/v1/cart/items/:variantId - từ chối khi chưa đăng nhập', async () => {
  const response = await fetch(`${baseUrl}/api/v1/cart/items/${sampleVariantId}`, {
    method: 'DELETE',
  });
  assert.equal(response.status, 401);
  const data = await response.json() as { error: string };
  assert.equal(data.error, 'Vui lòng đăng nhập');
});

test('DELETE /api/v1/cart - từ chối khi chưa đăng nhập', async () => {
  const response = await fetch(`${baseUrl}/api/v1/cart`, {
    method: 'DELETE',
  });
  assert.equal(response.status, 401);
  const data = await response.json() as { error: string };
  assert.equal(data.error, 'Vui lòng đăng nhập');
});

