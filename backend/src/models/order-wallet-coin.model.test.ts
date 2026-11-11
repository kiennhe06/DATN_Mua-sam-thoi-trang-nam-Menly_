import assert from 'node:assert/strict';
import { createServer, type IncomingMessage } from 'node:http';
import { after, test } from 'node:test';

interface YeuCau {
  method: string;
  url: string;
  body: Record<string, unknown>;
}

const yeuCau: YeuCau[] = [];

/** Tien hang cua tung don gia lap, theo thu tu duoc tao. */
let tienHangMoiDon: number[] = [];
/** So don da tao trong bai test dang chay. */
let soDonDaTao = 0;
/** Vi va xu ham create_order gia lap da "tru" cho tung don. */
let daTruMoiDon: Array<{ wallet_amount: number; coin_amount: number }> = [];

async function docBody(request: IncomingMessage): Promise<string> {
  const phan: Buffer[] = [];
  for await (const mau of request) phan.push(Buffer.from(mau));
  return Buffer.concat(phan).toString('utf8');
}

const supabaseServer = createServer(async (request, response) => {
  const bodyText = await docBody(request);
  const url = request.url ?? '';
  const method = request.method ?? '';
  const body = bodyText ? JSON.parse(bodyText) : {};
  yeuCau.push({ method, url, body });

  response.setHeader('Content-Type', 'application/json');

  // Ham create_order gia lap: tru vi va xu dung nhu ban that, tuc la chi tru
  // duoc toi da bang tong tien cua chinh don do.
  if (method === 'POST' && url.includes('rpc/create_order')) {
    const viXin = Number(body.p_wallet_amount ?? 0);
    const xuXin = Number(body.p_coin_amount ?? 0);
    const tienHang = tienHangMoiDon[soDonDaTao] ?? 0;
    const phiShip = Number(body.p_shipping_fee ?? 0);
    const tong = tienHang + phiShip;

    const xuTru = Math.min(xuXin, Math.floor((tienHang * 20) / 100), Math.max(0, tong - phiShip));
    const viTru = Math.min(viXin, Math.max(0, tong - xuTru));

    daTruMoiDon.push({ wallet_amount: viTru, coin_amount: xuTru });
    const don = {
      id: `don-${soDonDaTao + 1}`,
      code: `MENLY-${soDonDaTao + 1}`,
      subtotal: tienHang,
      shipping_fee: phiShip,
      total: tong - viTru - xuTru,
      status: 'processing',
    };
    soDonDaTao += 1;
    return response.end(JSON.stringify(don));
  }

  // Doc lai so vi va xu da tru cua don vua tao.
  if (method === 'GET' && url.includes('orders') && url.includes('wallet_amount')) {
    const cuoi = daTruMoiDon[daTruMoiDon.length - 1] ?? { wallet_amount: 0, coin_amount: 0 };
    return response.end(JSON.stringify(cuoi));
  }
  if (method === 'GET' && url.includes('orders')) {
    return response.end(JSON.stringify({ subtotal: tienHangMoiDon[soDonDaTao - 1] ?? 0 }));
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

const { OrderModel } = await import('./order.model.js');
const model = new OrderModel();

after(() => new Promise<void>((resolve, reject) => {
  supabaseServer.close((error) => error ? reject(error) : resolve());
}));

function datLai(tienHang: number[]) {
  tienHangMoiDon = tienHang;
  soDonDaTao = 0;
  daTruMoiDon = [];
  yeuCau.length = 0;
}

function cacLanGoiTaoDon() {
  return yeuCau.filter((r) => r.url.includes('rpc/create_order'));
}

function monHang(ten: string, gia: number) {
  return { variant_id: `v-${ten}`, product_name: ten, size: 'S', color: 'Đen', unit_price: gia, quantity: 1 };
}

test('mỗi sản phẩm tách một đơn thì ví chỉ bị trừ một lần, không lặp lại', async () => {
  datLai([100_000, 100_000]);

  await model.createOrder({
    userId: 'khach-1',
    payment_method: 'cod',
    ship_name: 'A', ship_phone: '0900000000', ship_address: 'HN',
    subtotal: 200_000, shipping_fee: 0, total: 200_000,
    wallet_amount: 200_000,
    items: [monHang('ao', 100_000), monHang('quan', 100_000)],
  });

  const goi = cacLanGoiTaoDon();
  assert.equal(goi.length, 2, 'hai sản phẩm thì tạo hai đơn');
  assert.equal(goi[0].body.p_wallet_amount, 200_000, 'đơn đầu xin cả số ví');
  assert.equal(
    goi[1].body.p_wallet_amount,
    100_000,
    'đơn sau chỉ được xin phần ví còn lại, không xin lại từ đầu',
  );
});

test('tổng ví xin không bao giờ vượt quá số tiền phải trả', async () => {
  datLai([100_000]);

  await model.createOrder({
    userId: 'khach-1',
    payment_method: 'cod',
    ship_name: 'A', ship_phone: '0900000000', ship_address: 'HN',
    // Khach co 500k trong vi nhung don chi phai tra 100k
    subtotal: 100_000, shipping_fee: 0, total: 100_000,
    wallet_amount: 500_000,
    items: [monHang('ao', 100_000)],
  });

  const goi = cacLanGoiTaoDon();
  assert.equal(goi[0].body.p_wallet_amount, 100_000, 'chỉ xin đúng số phải trả');
});

test('dùng cả xu và ví thì xu tính trước, ví chỉ bù phần còn thiếu', async () => {
  datLai([100_000]);

  await model.createOrder({
    userId: 'khach-1',
    payment_method: 'cod',
    ship_name: 'A', ship_phone: '0900000000', ship_address: 'HN',
    subtotal: 100_000, shipping_fee: 0, total: 100_000,
    coin_amount: 30_000,
    wallet_amount: 500_000,
    items: [monHang('ao', 100_000)],
  });

  const goi = cacLanGoiTaoDon();
  assert.equal(goi[0].body.p_coin_amount, 30_000);
  assert.equal(goi[0].body.p_wallet_amount, 70_000, 'ví chỉ bù 70k còn lại');
});

test('không dùng ví và xu thì vẫn gửi 0, không ảnh hưởng đơn thường', async () => {
  datLai([100_000]);

  await model.createOrder({
    userId: 'khach-1',
    payment_method: 'cod',
    ship_name: 'A', ship_phone: '0900000000', ship_address: 'HN',
    subtotal: 100_000, shipping_fee: 0, total: 100_000,
    items: [monHang('ao', 100_000)],
  });

  const goi = cacLanGoiTaoDon();
  assert.equal(goi[0].body.p_wallet_amount, 0);
  assert.equal(goi[0].body.p_coin_amount, 0);
});

test('số âm hoặc số lẻ do app gửi sai đều bị nắn lại', async () => {
  datLai([100_000]);

  await model.createOrder({
    userId: 'khach-1',
    payment_method: 'cod',
    ship_name: 'A', ship_phone: '0900000000', ship_address: 'HN',
    subtotal: 100_000, shipping_fee: 0, total: 100_000,
    wallet_amount: -50_000,
    coin_amount: 1234.9,
    items: [monHang('ao', 100_000)],
  });

  const goi = cacLanGoiTaoDon();
  assert.equal(goi[0].body.p_wallet_amount, 0, 'số âm về 0');
  assert.equal(goi[0].body.p_coin_amount, 1234, 'số lẻ bị cắt');
});
