import assert from 'node:assert/strict';
import { createServer, type IncomingMessage } from 'node:http';
import { after, test } from 'node:test';

interface YeuCau {
  method: string;
  url: string;
  body: unknown;
}

const yeuCau: YeuCau[] = [];

/** Bien the dang co trong kho gia lap, moi bai test tu dat lai. */
let bienTheHienCo: Array<Record<string, unknown>> = [];
/** Cac variant_id tung nam trong don hang. */
let idDaBan: Array<{ variant_id: string }> = [];

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

  if (method === 'GET' && url.includes('product_variants')) {
    return response.end(JSON.stringify(bienTheHienCo));
  }
  if (method === 'GET' && url.includes('order_items')) {
    return response.end(JSON.stringify(idDaBan));
  }
  if (method === 'POST' && url.includes('product_variants')) {
    return response.end(JSON.stringify({ id: 'bien-the-moi' }));
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

const { ProductModel } = await import('./product.model.js');
const model = new ProductModel();

after(() => new Promise<void>((resolve, reject) => {
  supabaseServer.close((error) => error ? reject(error) : resolve());
}));

function datLai(hienCo: Array<Record<string, unknown>>, daBan: string[] = []) {
  bienTheHienCo = hienCo;
  idDaBan = daBan.map((variant_id) => ({ variant_id }));
  yeuCau.length = 0;
}

test('thêm cặp size màu mới thì tạo biến thể và ghi nhật ký kho', async () => {
  datLai([{ id: 'v1', size: 'M', color: 'Đen', sku: 'SKU-M-DEN', stock: 10 }]);

  await model.dongBoBienThe(
    'sp-1',
    [
      { size: 'M', color: 'Đen', sku: 'SKU-M-DEN', stock: 10 },
      { size: 'L', color: 'Đen', sku: 'SKU-L-DEN', stock: 7 },
    ],
    'admin-1',
  );

  const themBienThe = yeuCau.find((r) => r.method === 'POST' && r.url.includes('product_variants'));
  assert.ok(themBienThe, 'phải thêm biến thể mới');
  assert.deepEqual(themBienThe.body, {
    product_id: 'sp-1',
    size: 'L',
    color: 'Đen',
    sku: 'SKU-L-DEN',
    stock: 7,
  });

  const nhatKy = yeuCau.find((r) => r.method === 'POST' && r.url.includes('inventory_movements'));
  assert.ok(nhatKy, 'phải ghi nhật ký tồn kho ban đầu');
  assert.equal((nhatKy.body as { change: number }).change, 7);
  assert.equal((nhatKy.body as { reason: string }).reason, 'restock');
});

test('form sản phẩm không được ghi đè tồn kho của biến thể đã có', async () => {
  datLai([{ id: 'v1', size: 'M', color: 'Đen', sku: 'SKU-M-DEN', stock: 10 }]);

  // Form gui len con so cu (4) doc tu luc mo form. Neu luu xuong thi cac don
  // ban trong luc do bi mat, nen may chu phai lo di truong stock nay.
  await model.dongBoBienThe(
    'sp-1',
    [{ size: 'M', color: 'Đen', sku: 'SKU-M-DEN', stock: 4 }],
    'admin-1',
  );

  assert.equal(yeuCau.some((r) => r.method === 'PATCH'), false);
  assert.equal(
    yeuCau.some((r) => r.method === 'POST' && r.url.includes('inventory_movements')),
    false,
  );
});

test('đổi SKU của biến thể cũ thì chỉ ghi SKU, không đụng tồn kho', async () => {
  datLai([{ id: 'v1', size: 'M', color: 'Đen', sku: 'SKU-CU', stock: 10 }]);

  await model.dongBoBienThe('sp-1', [{ size: 'M', color: 'Đen', sku: 'SKU-MOI', stock: 4 }]);

  const sua = yeuCau.find((r) => r.method === 'PATCH');
  assert.ok(sua, 'phải cập nhật SKU');
  assert.deepEqual(sua.body, { sku: 'SKU-MOI' });
});

test('không đổi gì thì không gửi lệnh cập nhật nào', async () => {
  datLai([{ id: 'v1', size: 'M', color: 'Đen', sku: 'SKU-M-DEN', stock: 10 }]);

  await model.dongBoBienThe('sp-1', [{ size: 'M', color: 'Đen', sku: 'SKU-M-DEN', stock: 10 }]);

  assert.equal(yeuCau.some((r) => r.method === 'PATCH'), false);
  assert.equal(yeuCau.some((r) => r.method === 'POST'), false);
  assert.equal(yeuCau.some((r) => r.method === 'DELETE'), false);
});

test('bỏ biến thể chưa từng bán thì xóa được', async () => {
  datLai([
    { id: 'v1', size: 'M', color: 'Đen', sku: 'SKU-M-DEN', stock: 10 },
    { id: 'v2', size: 'L', color: 'Đen', sku: 'SKU-L-DEN', stock: 2 },
  ]);

  await model.dongBoBienThe('sp-1', [{ size: 'M', color: 'Đen', sku: 'SKU-M-DEN', stock: 10 }]);

  const xoa = yeuCau.find((r) => r.method === 'DELETE');
  assert.ok(xoa, 'phải xóa biến thể bị bỏ');
  assert.match(decodeURIComponent(xoa.url), /v2/);
});

test('biến thể đã từng có đơn hàng thì từ chối xóa và không gửi lệnh xóa', async () => {
  datLai(
    [
      { id: 'v1', size: 'M', color: 'Đen', sku: 'SKU-M-DEN', stock: 10 },
      { id: 'v2', size: 'L', color: 'Đen', sku: 'SKU-L-DEN', stock: 2 },
    ],
    ['v2'],
  );

  await assert.rejects(
    () => model.dongBoBienThe('sp-1', [{ size: 'M', color: 'Đen', sku: 'SKU-M-DEN', stock: 10 }]),
    /đã từng có đơn hàng/,
  );
  assert.equal(yeuCau.some((r) => r.method === 'DELETE'), false);
});
