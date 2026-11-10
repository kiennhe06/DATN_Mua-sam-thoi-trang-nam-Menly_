import assert from 'node:assert/strict';
import { createServer, type IncomingMessage } from 'node:http';
import { after, test } from 'node:test';

type MockProduct = Record<string, unknown>;

async function readRequestBody(request: IncomingMessage): Promise<string> {
  const chunks: Buffer[] = [];
  for await (const chunk of request) chunks.push(Buffer.from(chunk));
  return Buffer.concat(chunks).toString('utf8');
}

let product: MockProduct | null = null;
const requests: Array<{ method: string; url: string; body: MockProduct }> = [];
const supabaseServer = createServer(async (request, response) => {
  const url = new URL(request.url ?? '/', 'http://localhost');
  const bodyText = await readRequestBody(request);
  const body = bodyText ? JSON.parse(bodyText) as MockProduct : {};
  requests.push({ method: request.method ?? '', url: url.pathname + url.search, body });

  response.setHeader('Content-Type', 'application/json');
  if (request.method === 'POST') {
    product = { id: '00000000-0000-4000-8000-000000000002', ...body };
    response.end(JSON.stringify(product));
    return;
  }
  if (request.method === 'PATCH') {
    product = { ...(product ?? {}), ...body };
    response.end(JSON.stringify(product));
    return;
  }
  if (url.searchParams.get('select')?.replaceAll(' ', '') === 'name,description' && product) {
    response.end(JSON.stringify({ name: product.name, description: product.description }));
    return;
  }
  if (request.method === 'GET' && url.searchParams.has('id') && product) {
    response.end(JSON.stringify(product));
    return;
  }
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

const { ProductModel } = await import('./product.model.js');
const model = new ProductModel();

after(() => new Promise<void>((resolve, reject) => {
  supabaseServer.close((error) => error ? reject(error) : resolve());
}));

test('sản phẩm mới chờ duyệt không được kích hoạt trước khi duyệt', async () => {
  requests.length = 0;
  product = null;
  await model.createAdminProduct({
    categoryId: '00000000-0000-4000-8000-000000000001',
    name: 'Áo sơ mi',
    slug: 'ao-so-mi',
    description: 'Áo nam',
    price: 250000,
  });

  assert.equal(requests[0].body.approval_status, 'pending');
  assert.equal(requests[0].body.is_active, false);

  await model.approveAdminProduct('00000000-0000-4000-8000-000000000002');
  const approvalUpdate = requests.find((request) => request.method === 'PATCH');
  assert.equal(approvalUpdate?.body.approval_status, 'approved');
  assert.equal(approvalUpdate?.body.is_active, true);
});

test('tìm kiếm sản phẩm công khai chỉ lấy sản phẩm đang bán đã duyệt', async () => {
  requests.length = 0;
  await model.findAll();
  assert.match(requests[0].url, /is_active=eq\.true/);
  assert.match(requests[0].url, /approval_status=eq\.approved/);
});

test('chi tiết sản phẩm quản trị gồm sản phẩm, biến thể và ảnh kể cả khi chưa duyệt', async () => {
  product = {
    id: '00000000-0000-4000-8000-000000000002',
    approval_status: 'pending',
    is_active: false,
  };
  requests.length = 0;

  const result = await model.findAdminById('00000000-0000-4000-8000-000000000002');

  assert.equal(result?.approval_status, 'pending');
  assert.equal(result?.is_active, false);
  const requestUrl = new URL(requests[0].url, 'http://localhost');
  assert.equal(requestUrl.searchParams.get('select'), '*,product_variants(*),product_images(*)');
  assert.match(requests[0].url, /id=eq\.00000000-0000-4000-8000-000000000002/);
});

test('cập nhật tên đồng bộ chỉ mục tìm kiếm và giữ mô tả cũ', async () => {
  product = {
    id: '00000000-0000-4000-8000-000000000002',
    name: 'Áo sơ mi',
    description: 'Áo nam',
  };
  requests.length = 0;

  await model.updateAdminProduct('00000000-0000-4000-8000-000000000002', { name: 'Áo mới' });

  const update = requests.find((request) => request.method === 'PATCH');
  assert.ok(update);
  assert.equal(update.body.search_text, 'Áo mới Áo nam');
});

test('sửa ảnh sản phẩm thì ghi đè gallery để không còn ảnh cũ nằm lại', async () => {
  product = {
    id: '00000000-0000-4000-8000-000000000002',
    name: 'Áo sơ mi',
    thumbnail_url: 'https://anh-cu.example.com/a.jpg',
  };
  requests.length = 0;

  await model.updateAdminProduct('00000000-0000-4000-8000-000000000002', {
    thumbnailUrl: 'https://anh-moi.example.com/b.jpg',
    images: ['https://anh-moi.example.com/b.jpg'],
  });

  const xoaAnhCu = requests.find(
    (request) => request.method === 'DELETE' && request.url.includes('product_images'),
  );
  assert.ok(xoaAnhCu, 'phải xóa ảnh cũ trước khi ghi ảnh mới');
  assert.match(xoaAnhCu.url, /product_id=eq\.00000000-0000-4000-8000-000000000002/);

  const ghiAnhMoi = requests.find(
    (request) => request.method === 'POST' && request.url.includes('product_images'),
  );
  assert.ok(ghiAnhMoi, 'phải ghi ảnh mới vào gallery');
  assert.deepEqual(ghiAnhMoi.body, [
    {
      product_id: '00000000-0000-4000-8000-000000000002',
      url: 'https://anh-moi.example.com/b.jpg',
      sort_order: 0,
    },
  ]);
});

test('chỉ đổi tên thì không đụng tới gallery', async () => {
  product = {
    id: '00000000-0000-4000-8000-000000000002',
    name: 'Áo sơ mi',
    description: 'Áo nam',
    thumbnail_url: 'https://anh-cu.example.com/a.jpg',
  };
  requests.length = 0;

  await model.updateAdminProduct('00000000-0000-4000-8000-000000000002', { name: 'Áo mới' });

  assert.equal(
    requests.filter((request) => request.url.includes('product_images')).length,
    0,
    'không được xóa hay ghi lại ảnh khi người dùng chỉ sửa tên',
  );
});
