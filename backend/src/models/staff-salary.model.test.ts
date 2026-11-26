import assert from 'node:assert/strict';
import { test } from 'node:test';

// Chỉ kiểm hai hàm tính thuần, không cần giả lập cơ sở dữ liệu. Vẫn phải có
// biến môi trường vì import module kéo theo config supabase.
process.env.SUPABASE_URL ??= 'http://127.0.0.1:1';
process.env.SUPABASE_ANON_KEY ??= 'test-anon-key';
process.env.SUPABASE_SERVICE_ROLE_KEY ??= 'test-service-role-key';

const { tinhLuong, chuanHoaLuong } = await import('./staff-activity.model.js');

test('lương = lương cứng + thưởng từng loại việc', () => {
  const tong = tinhLuong(
    { orders: 10, chats: 20, stock: 3 },
    { baseSalary: 5_000_000, bonusPerOrder: 5_000, bonusPerChat: 2_000, bonusPerStock: 10_000 },
  );
  // 5.000.000 + 10*5.000 + 20*2.000 + 3*10.000
  assert.equal(tong, 5_000_000 + 50_000 + 40_000 + 30_000);
});

test('không làm việc nào thì chỉ còn lương cứng', () => {
  const tong = tinhLuong(
    { orders: 0, chats: 0, stock: 0 },
    { baseSalary: 4_000_000, bonusPerOrder: 5_000, bonusPerChat: 2_000, bonusPerStock: 10_000 },
  );
  assert.equal(tong, 4_000_000);
});

test('chưa đặt lương thì tổng bằng 0', () => {
  const tong = tinhLuong(
    { orders: 100, chats: 100, stock: 100 },
    { baseSalary: 0, bonusPerOrder: 0, bonusPerChat: 0, bonusPerStock: 0 },
  );
  assert.equal(tong, 0);
});

test('số âm và số lẻ do form gửi sai đều bị nắn về nguyên dương', () => {
  const sach = chuanHoaLuong({
    baseSalary: -5000,
    bonusPerOrder: 5000.9,
    bonusPerChat: NaN as unknown as number,
    bonusPerStock: 2000,
  });
  assert.equal(sach.baseSalary, 0, 'số âm về 0');
  assert.equal(sach.bonusPerOrder, 5000, 'số lẻ bị cắt');
  assert.equal(sach.bonusPerChat, 0, 'không phải số thì về 0');
  assert.equal(sach.bonusPerStock, 2000);
});

test('thiếu trường thì coi như 0, không văng lỗi', () => {
  const sach = chuanHoaLuong({ baseSalary: 3_000_000 });
  assert.deepEqual(sach, {
    baseSalary: 3_000_000,
    bonusPerOrder: 0,
    bonusPerChat: 0,
    bonusPerStock: 0,
  });
});
