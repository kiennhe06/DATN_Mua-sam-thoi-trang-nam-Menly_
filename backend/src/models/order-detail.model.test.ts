import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { after, test } from 'node:test';

// Don hang gia lap de kiem tra buoc lam giau du lieu truoc khi tra ve app.
const donGiaLap = {
  id: '00000000-0000-4000-8000-000000000010',
  code: 'MENLY26110874010',
  status: 'pending_payment',
  subtotal: 299000,
  shipping_fee: 25000,
  total: 274000,
  order_items: [
    {
      id: '00000000-0000-4000-8000-000000000011',
      order_id: '00000000-0000-4000-8000-000000000010',
      variant_id: '00000000-0000-4000-8000-000000000012',
      product_name: 'Áo sơ mi trắng công sở',
      unit_price: 299000,
      quantity: 1,
      product_variants: {
        size: 'S',
        color: 'Trắng',
        products: {
          name: 'Áo sơ mi trắng công sở',
          thumbnail_url: 'https://images.unsplash.com/photo-123?w=600',
        },
      },
    },
    {
      id: '00000000-0000-4000-8000-000000000013',
      order_id: '00000000-0000-4000-8000-000000000010',
      variant_id: '00000000-0000-4000-8000-000000000014',
      product_name: 'Quần âu',
      unit_price: 0,
      quantity: 1,
      product_variants: {
        size: 'M',
        color: 'Đen',
        products: { name: 'Quần âu', thumbnail_url: 'https://picsum.photos/seed/1/600' },
      },
    },
  ],
  order_status_history: [],
};

const supabaseServer = createServer((_request, response) => {
  response.setHeader('Content-Type', 'application/json');
  response.end(JSON.stringify(donGiaLap));
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

test('chi tiết đơn trả về số tiền đã giảm để tạm tính cộng phí ship ra đúng tổng', async () => {
  const don = await model.getOrderById(
    '00000000-0000-4000-8000-000000000010',
    '00000000-0000-4000-8000-000000000001',
  );

  assert.ok(don);
  assert.equal(don.discount_amount, 50000);
  assert.equal(don.subtotal + don.shipping_fee - (don.discount_amount ?? 0), don.total);
});

test('chi tiết đơn giữ ảnh thật của sản phẩm và chỉ bỏ ảnh sinh ngẫu nhiên', async () => {
  const don = await model.getOrderById(
    '00000000-0000-4000-8000-000000000010',
    '00000000-0000-4000-8000-000000000001',
  );

  assert.ok(don);
  const mon = don.items ?? [];
  assert.equal(mon[0].thumbnail_url, 'https://images.unsplash.com/photo-123?w=600');
  assert.equal(mon[1].thumbnail_url, '');
});
