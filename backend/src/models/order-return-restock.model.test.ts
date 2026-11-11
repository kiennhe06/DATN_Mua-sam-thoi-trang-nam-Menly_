import assert from 'node:assert/strict';
import { createServer, type IncomingMessage } from 'node:http';
import { after, test } from 'node:test';

interface YeuCau {
  method: string;
  url: string;
  body: Record<string, unknown>;
}

const yeuCau: YeuCau[] = [];
/** Trang thai hien tai cua yeu cau tra hang trong co so du lieu gia lap. */
let trangThaiHienTai = 'shop_approved';
/** Da co dong nhat ky 'return' cho don nay chua. */
let daNhapLaiKho = false;

async function docBody(request: IncomingMessage): Promise<string> {
  const phan: Buffer[] = [];
  for await (const mau of request) phan.push(Buffer.from(mau));
  return Buffer.concat(phan).toString('utf8');
}

const supabaseServer = createServer(async (request, response) => {
  const bodyText = await docBody(request);
  const url = request.url ?? '';
  const method = request.method ?? '';
  yeuCau.push({ method, url, body: bodyText ? JSON.parse(bodyText) : {} });

  response.setHeader('Content-Type', 'application/json');

  if (method === 'GET' && url.includes('order_returns')) {
    return response.end(
      JSON.stringify({ id: 'tra-1', order_id: 'don-1', status: trangThaiHienTai }),
    );
  }
  if (method === 'GET' && url.includes('order_items')) {
    return response.end(JSON.stringify([{ variant_id: 'v1', quantity: 2 }]));
  }
  if (method === 'GET' && url.includes('inventory_movements')) {
    return response.end(JSON.stringify(daNhapLaiKho ? [{ id: 'nk-1' }] : []));
  }
  if (method === 'GET' && url.includes('product_variants')) {
    return response.end(JSON.stringify({ stock: 10 }));
  }
  if (method === 'PATCH' && url.includes('product_variants')) {
    // Lenh ghi kem dieu kien ton kho con nguyen: tra ve dong da ghi.
    return response.end(JSON.stringify({ id: 'v1' }));
  }
  if (method === 'PATCH' && url.includes('order_returns')) {
    return response.end(
      JSON.stringify({
        id: 'tra-1',
        order_id: 'don-1',
        user_id: 'u1',
        reason: 'Lỗi đường may',
        proof_images: [],
        status: 'refunded',
        refund_amount: 100000,
        created_at: new Date().toISOString(),
      }),
    );
  }
  return response.end(JSON.stringify([]));
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

const { OrderReturnModel } = await import('./order-return.model.js');
const model = new OrderReturnModel();

after(() => new Promise<void>((resolve, reject) => {
  supabaseServer.close((error) => error ? reject(error) : resolve());
}));

function datLai(trangThai: string, daNhap = false) {
  trangThaiHienTai = trangThai;
  daNhapLaiKho = daNhap;
  yeuCau.length = 0;
}

const congKho = () =>
  yeuCau.find((r) => r.method === 'PATCH' && r.url.includes('product_variants'));
const nhatKyKho = () =>
  yeuCau.find((r) => r.method === 'POST' && r.url.includes('inventory_movements'));

test('hàng trả còn bán được thì cộng lại kho và ghi nhật ký lý do trả hàng', async () => {
  datLai('shop_approved');

  await model.updateStatus('tra-1', { status: 'refunded', restock: true, actorId: 'admin-1' });

  const cong = congKho();
  assert.ok(cong, 'phải cộng tồn kho');
  assert.deepEqual(cong.body, { stock: 12 });
  // Lenh ghi phai kem dieu kien ton kho van dung bang so vua doc.
  assert.match(decodeURIComponent(cong.url), /stock=eq\.10/);

  const nhatKy = nhatKyKho();
  assert.ok(nhatKy, 'phải ghi nhật ký kho');
  assert.equal(nhatKy.body.change, 2);
  assert.equal(nhatKy.body.reason, 'return');
});

test('hàng lỗi thì không cộng lại kho và không ghi nhật ký kho', async () => {
  datLai('shop_approved');

  await model.updateStatus('tra-1', { status: 'refunded', restock: false });

  assert.equal(congKho(), undefined);
  assert.equal(nhatKyKho(), undefined);
});

test('đơn đã hoàn tiền rồi thì bấm lại không cộng kho thêm lần nữa', async () => {
  datLai('refunded');

  await model.updateStatus('tra-1', { status: 'refunded', restock: true });

  assert.equal(congKho(), undefined);
  assert.equal(nhatKyKho(), undefined);
});

test('mới duyệt mà chưa hoàn tiền thì chưa đụng tới kho', async () => {
  datLai('requested');

  await model.updateStatus('tra-1', { status: 'shop_approved', restock: true });

  assert.equal(congKho(), undefined);
  assert.equal(nhatKyKho(), undefined);
});

test('ghi lại hàng có bán lại được hay không vào yêu cầu trả hàng', async () => {
  datLai('shop_approved');

  await model.updateStatus('tra-1', { status: 'refunded', restock: false });

  const luu = yeuCau.find((r) => r.method === 'PATCH' && r.url.includes('order_returns'));
  assert.ok(luu);
  assert.equal(luu.body.restocked, false);
  assert.equal(luu.body.status, 'refunded');
});

test('đơn đã có dòng nhật ký trả hàng thì không cộng kho lần nữa', async () => {
  datLai('shop_approved', true);

  await model.updateStatus('tra-1', { status: 'refunded', restock: true });

  assert.equal(congKho(), undefined);
  assert.equal(nhatKyKho(), undefined);
});
