import assert from 'node:assert/strict';
import { createServer, type IncomingMessage } from 'node:http';
import { after, test } from 'node:test';

const yeuCau: string[] = [];

const supabaseServer = createServer((request: IncomingMessage, response) => {
  yeuCau.push(request.url ?? '');
  response.setHeader('Content-Type', 'application/json');
  response.end(JSON.stringify([]));
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

const { OrderModel } = await import('./order.model.js');
const model = new OrderModel();

after(() => new Promise<void>((resolve, reject) => {
  supabaseServer.close((error) => error ? reject(error) : resolve());
}));

test('lọc đơn theo khoảng ngày được đẩy xuống truy vấn, không lọc sau khi tải về', async () => {
  yeuCau.length = 0;

  await model.adminListOrders({
    from: '2026-11-01T00:00:00.000Z',
    to: '2026-12-01T00:00:00.000Z',
    limit: 200,
  });

  const url = decodeURIComponent(yeuCau[0] ?? '');
  assert.match(url, /created_at=gte\.2026-11-01T00:00:00\.000Z/);
  assert.match(url, /created_at=lt\.2026-12-01T00:00:00\.000Z/);
  assert.match(url, /limit=200/);
});

test('không truyền khoảng ngày thì truy vấn không kèm điều kiện thời gian', async () => {
  yeuCau.length = 0;

  await model.adminListOrders({ status: 'paid' });

  const url = decodeURIComponent(yeuCau[0] ?? '');
  assert.match(url, /status=eq\.paid/);
  assert.doesNotMatch(url, /created_at=gte/);
  assert.doesNotMatch(url, /created_at=lt/);
});
