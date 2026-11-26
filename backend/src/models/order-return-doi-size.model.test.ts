import assert from 'node:assert/strict';
import { createServer, type IncomingMessage } from 'node:http';
import { after, test } from 'node:test';

interface YeuCau {
  method: string;
  url: string;
  body: Record<string, unknown>;
}

const yeuCau: YeuCau[] = [];

/** Ton kho gia lap cua tung bien the. */
let tonKho: Record<string, number> = {};
/** Cac dong nhat ky kho da duoc ghi. */
let nhatKy: Array<Record<string, unknown>> = [];
/** Yeu cau tra hang dang duoc duyet. */
let yeuCauTraHang: Record<string, unknown> = {};
/** Cac dong san pham cua don. */
let dongTrongDon: Array<Record<string, unknown>> = [];

async function docBody(request: IncomingMessage): Promise<string> {
  const phan: Buffer[] = [];
  for await (const mau of request) phan.push(Buffer.from(mau));
  return Buffer.concat(phan).toString('utf8');
}

function bienTheTuUrl(url: string): string | null {
  const khop = url.match(/id=eq\.([^&]+)/);
  return khop ? decodeURIComponent(khop[1]) : null;
}

const supabaseServer = createServer(async (request, response) => {
  const bodyText = await docBody(request);
  const url = request.url ?? '';
  const method = request.method ?? '';
  const body = bodyText ? JSON.parse(bodyText) : {};
  yeuCau.push({ method, url, body });

  response.setHeader('Content-Type', 'application/json');

  if (url.includes('/order_returns')) {
    return response.end(JSON.stringify(method === 'GET' ? yeuCauTraHang : yeuCauTraHang));
  }

  if (url.includes('/order_items')) {
    return response.end(JSON.stringify(dongTrongDon));
  }

  if (url.includes('/inventory_movements')) {
    if (method === 'POST') {
      nhatKy.push(body);
      return response.end(JSON.stringify([body]));
    }
    // Kiem tra da chuyen kho lan nao chua.
    const lyDo = url.match(/reason=eq\.([^&]+)/)?.[1];
    const daCo = nhatKy.filter((dong) => dong.reason === lyDo);
    return response.end(JSON.stringify(daCo.map(() => ({ id: 'co-roi' }))));
  }

  if (url.includes('/product_variants')) {
    const id = bienTheTuUrl(url);
    if (method === 'PATCH') {
      if (id) tonKho[id] = Number(body.stock);
      return response.end(JSON.stringify({ id }));
    }
    if (!id) return response.end(JSON.stringify([]));
    return response.end(
      JSON.stringify({ id, stock: tonKho[id] ?? 0, product_id: 'sp-1', size: 'M', color: 'Đen' }),
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

function datLai() {
  tonKho = { 'size-M': 5, 'size-L': 3 };
  nhatKy = [];
  dongTrongDon = [{ variant_id: 'size-M', quantity: 1, product_variants: { product_id: 'sp-1' } }];
  yeuCauTraHang = {
    id: 'yc-1',
    order_id: 'don-1',
    status: 'shop_approved',
    request_type: 'exchange',
    exchange_variant_id: 'size-L',
    returned_variant_id: 'size-M',
  };
  yeuCau.length = 0;
}

test('duyệt đổi size thì lấy size mới ra và nhận size cũ về', async () => {
  datLai();

  await model.updateStatus('yc-1', { status: 'exchanged', restock: true, actorId: 'nv-1' });

  assert.equal(tonKho['size-L'], 2, 'size mới giảm 1 vì đã lấy ra giao');
  assert.equal(tonKho['size-M'], 6, 'size cũ tăng 1 vì nhận lại được');

  const dongDoiSize = nhatKy.filter((dong) => dong.reason === 'exchange');
  assert.equal(dongDoiSize.length, 2, 'ghi đủ hai dòng nhật ký cho một lần đổi');
  assert.ok(
    dongDoiSize.every((dong) => dong.order_id === 'don-1'),
    'hai dòng cùng mã đơn để biết chúng thuộc cùng một việc',
  );
});

test('size cũ bị lỗi thì không cộng vào kho nhưng vẫn ghi nhật ký', async () => {
  datLai();

  await model.updateStatus('yc-1', { status: 'exchanged', restock: false, actorId: 'nv-1' });

  assert.equal(tonKho['size-L'], 2, 'vẫn lấy size mới ra giao cho khách');
  assert.equal(tonKho['size-M'], 5, 'size cũ hỏng nên tồn kho không đổi');

  const dongHong = nhatKy.filter((dong) => dong.reason === 'damaged');
  assert.equal(dongHong.length, 1, 'hàng hỏng phải để lại đúng một dấu vết');
  assert.equal(dongHong[0].change, 0, 'ghi nhận nhưng không đổi số lượng tồn');
});

test('bấm duyệt hai lần không trừ kho hai lần', async () => {
  datLai();

  await model.updateStatus('yc-1', { status: 'exchanged', restock: true, actorId: 'nv-1' });
  const tonSauLan1 = { ...tonKho };

  yeuCauTraHang.status = 'shop_approved'; // giả lập người dùng bấm lại
  await model.updateStatus('yc-1', { status: 'exchanged', restock: true, actorId: 'nv-1' });

  assert.deepEqual(tonKho, tonSauLan1, 'lần duyệt thứ hai không đụng vào kho nữa');
});

test('yêu cầu đòi hoàn tiền thì không duyệt thành đổi size được', async () => {
  datLai();
  yeuCauTraHang.request_type = 'refund';

  await assert.rejects(
    () => model.updateStatus('yc-1', { status: 'exchanged', restock: true }),
    /không phải đổi size/,
  );
});

test('thiếu size muốn đổi thì báo lỗi chứ không đụng vào kho', async () => {
  datLai();
  yeuCauTraHang.exchange_variant_id = null;

  await assert.rejects(
    () => model.updateStatus('yc-1', { status: 'exchanged', restock: true }),
    /không ghi size muốn đổi sang/,
  );
  assert.equal(tonKho['size-L'], 3, 'tồn kho giữ nguyên');
});
