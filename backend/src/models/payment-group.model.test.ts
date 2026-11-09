import assert from 'node:assert/strict';
import { createServer, type IncomingMessage } from 'node:http';
import { after, test } from 'node:test';

// Mot lan dat hang sinh ba don: don goc va hai don con tro ve no.
const ID_GOC = '00000000-0000-4000-8000-000000000001';
const ID_CON_1 = '00000000-0000-4000-8000-000000000002';
const ID_CON_2 = '00000000-0000-4000-8000-000000000003';
const MA_DON = 'MENLY26110900001';

const trangThaiDon = new Map<string, string>([
  [ID_GOC, 'pending_payment'],
  [ID_CON_1, 'pending_payment'],
  [ID_CON_2, 'pending_payment'],
]);

let lichSuGhi: Array<Record<string, unknown>> = [];

async function docBody(request: IncomingMessage): Promise<string> {
  const phan: Buffer[] = [];
  for await (const mau of request) phan.push(Buffer.from(mau));
  return Buffer.concat(phan).toString('utf8');
}

const supabaseServer = createServer(async (request, response) => {
  const url = new URL(request.url ?? '/', 'http://localhost');
  const duongDan = url.pathname;
  const bodyText = await docBody(request);
  response.setHeader('Content-Type', 'application/json');

  if (duongDan.endsWith('/payments')) {
    if (request.method === 'PATCH') return response.end(JSON.stringify([]));
    return response.end(JSON.stringify({
      id: 'pay-1',
      order_id: ID_GOC,
      amount: 100000,
      status: 'pending',
    }));
  }

  if (duongDan.endsWith('/order_status_history')) {
    lichSuGhi = lichSuGhi.concat(JSON.parse(bodyText || '[]'));
    return response.end(JSON.stringify([]));
  }

  if (duongDan.endsWith('/orders')) {
    if (request.method === 'PATCH') {
      const than = JSON.parse(bodyText || '{}') as { status?: string };
      // id=in.(a,b,c) -> doi trang thai dung nhung don duoc liet ke
      const dieuKien = url.searchParams.get('id') ?? '';
      const ids = dieuKien.startsWith('in.')
        ? dieuKien.slice(4, -1).split(',').map((id) => id.replace(/"/g, ''))
        : [dieuKien.replace('eq.', '')];
      for (const id of ids) {
        if (trangThaiDon.has(id) && than.status) trangThaiDon.set(id, than.status);
      }
      return response.end(JSON.stringify([]));
    }

    // Tim theo ma don
    if (url.searchParams.get('code') === `eq.${MA_DON}`) {
      return response.end(JSON.stringify({
        id: ID_GOC,
        code: MA_DON,
        status: trangThaiDon.get(ID_GOC),
      }));
    }

    // Buoc 1 cua layIdCungLanDat: doc don de biet don goc
    const loc = url.searchParams.get('id') ?? '';
    if (loc.startsWith('eq.')) {
      const id = loc.slice(3);
      return response.end(JSON.stringify({
        id,
        parent_order_id: id === ID_GOC ? null : ID_GOC,
      }));
    }

    // Buoc 2: lay ca nhom theo or=(id.eq.goc,parent_order_id.eq.goc)
    if (url.searchParams.has('or')) {
      return response.end(JSON.stringify(
        [...trangThaiDon.keys()].map((id) => ({ id })),
      ));
    }

    // Loc nhung don con dang cho thanh toan
    if (loc.startsWith('in.')) {
      const ids = loc.slice(4, -1).split(',').map((id) => id.replace(/"/g, ''));
      return response.end(JSON.stringify(
        ids
          .filter((id) => trangThaiDon.get(id) === 'pending_payment')
          .map((id) => ({ id })),
      ));
    }
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
process.env.VNPAY_HASH_SECRET = 'TEST_HASH_SECRET';

const { PaymentModel, sortObject, createHmacSha512 } = await import('./payment.model.js');
const model = new PaymentModel();

after(() => new Promise<void>((resolve, reject) => {
  supabaseServer.close((error) => error ? reject(error) : resolve());
}));

/** Dung query VNPay co chu ky hop le nhu cong thanh toan that gui ve. */
function taoQueryVnpay(): Record<string, string> {
  const query: Record<string, string> = {
    vnp_Amount: '10000000',
    vnp_BankCode: 'NCB',
    vnp_ResponseCode: '00',
    vnp_TransactionNo: '14567890',
    vnp_TxnRef: `${MA_DON}_1700000000000`,
  };
  const chuoiKy = new URLSearchParams(sortObject(query) as Record<string, string>).toString();
  return { ...query, vnp_SecureHash: createHmacSha512(chuoiKy, 'TEST_HASH_SECRET') };
}

test('khách trả tiền xong thì CẢ NHÓM đơn tách đều thành đã thanh toán', async () => {
  const ketQua = await model.processReturn(taoQueryVnpay());

  assert.equal(ketQua.isValidChecksum, true, 'chữ ký phải hợp lệ');
  assert.equal(ketQua.isSuccess, true);

  // Day la loi that su can chan: truoc kia chi don goc duoc ghi nhan, hai don
  // con van "cho thanh toan" roi bi huy vi qua han du khach da tra du tien.
  assert.equal(trangThaiDon.get(ID_GOC), 'paid');
  assert.equal(trangThaiDon.get(ID_CON_1), 'paid');
  assert.equal(trangThaiDon.get(ID_CON_2), 'paid');

  const donDaGhiLichSu = lichSuGhi.map((dong) => dong.order_id);
  assert.deepEqual([...new Set(donDaGhiLichSu)].sort(), [ID_GOC, ID_CON_1, ID_CON_2].sort());
});
