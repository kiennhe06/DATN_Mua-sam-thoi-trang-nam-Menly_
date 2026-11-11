import assert from 'node:assert/strict';
import { createServer, type IncomingMessage } from 'node:http';
import { after, test } from 'node:test';

const yeuCau: Array<{ method: string; url: string; body: Record<string, unknown> }> = [];

async function docBody(request: IncomingMessage): Promise<string> {
  const phan: Buffer[] = [];
  for await (const mau of request) phan.push(Buffer.from(mau));
  return Buffer.concat(phan).toString('utf8');
}

const supabaseServer = createServer(async (request, response) => {
  const bodyText = await docBody(request);
  yeuCau.push({
    method: request.method ?? '',
    url: request.url ?? '',
    body: bodyText ? (JSON.parse(bodyText) as Record<string, unknown>) : {},
  });
  response.setHeader('Content-Type', 'application/json');
  response.end(JSON.stringify({ id: 'banner-1' }));
});

await new Promise<void>((resolve, reject) => {
  supabaseServer.once('error', reject);
  supabaseServer.listen(0, '127.0.0.1', resolve);
});
const address = supabaseServer.address();
if (!address || typeof address === 'string') throw new Error('Không lấy được cổng Supabase giả lập');

process.env.SUPABASE_URL = `http://127.0.0.1:${address.port}`;
process.env.SUPABASE_ANON_KEY = 'test-anon-key';
process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-service-role-key';

const { AdminModel } = await import('./admin.model.js');
const { adminBannerUpdateSchema } = await import('../validators/admin.validator.js');
const model = new AdminModel();

after(() => new Promise<void>((resolve, reject) => {
  supabaseServer.close((error) => error ? reject(error) : resolve());
}));

test('sửa banner chỉ ghi những trường được gửi lên', async () => {
  yeuCau.length = 0;

  await model.updateBanner('banner-1', { title: 'Thu Đông 2026', sortOrder: 3 });

  const patch = yeuCau.find((r) => r.method === 'PATCH');
  assert.ok(patch, 'phải gọi lệnh cập nhật');
  assert.deepEqual(patch.body, { title: 'Thu Đông 2026', sort_order: 3 });
  assert.match(decodeURIComponent(patch.url), /id=eq\.banner-1/);
});

test('bật tắt hiển thị chỉ đổi đúng cờ is_active', async () => {
  yeuCau.length = 0;

  await model.setBannerActive('banner-1', false);

  const patch = yeuCau.find((r) => r.method === 'PATCH');
  assert.ok(patch);
  assert.deepEqual(patch.body, { is_active: false });
});

test('xóa banner gọi đúng lệnh xóa theo id', async () => {
  yeuCau.length = 0;

  await model.deleteBanner('banner-1');

  const xoa = yeuCau.find((r) => r.method === 'DELETE');
  assert.ok(xoa, 'phải gọi lệnh xóa');
  assert.match(decodeURIComponent(xoa.url), /id=eq\.banner-1/);
});

test('luợc đồ sửa banner từ chối payload rỗng', () => {
  assert.equal(adminBannerUpdateSchema.safeParse({}).success, false);
  assert.equal(adminBannerUpdateSchema.safeParse({ isActive: false }).success, true);
  assert.equal(
    adminBannerUpdateSchema.safeParse({ imageUrl: 'khong-phai-dia-chi' }).success,
    false,
  );
});
