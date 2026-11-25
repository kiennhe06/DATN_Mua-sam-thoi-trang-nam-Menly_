import assert from 'node:assert/strict';
import { test } from 'node:test';

// order.model.ts tao client Supabase ngay khi import nen phai co bien moi truong,
// du bai test nay chi goi ham tinh thoi diem chu khong cham vao mang.
process.env.SUPABASE_URL ??= 'http://127.0.0.1:1';
process.env.SUPABASE_ANON_KEY ??= 'test-anon-key';
process.env.SUPABASE_SERVICE_ROLE_KEY ??= 'test-service-role-key';

const { thoiDiemNhanHang, SO_NGAY_DUOC_TRA_HANG } = await import('./order.model.js');

test('lấy mốc giao hàng từ lịch sử trạng thái', () => {
  const moc = thoiDiemNhanHang([
    { to_status: 'shipping', created_at: '2026-11-01T00:00:00Z' },
    { to_status: 'delivered', created_at: '2026-11-03T00:00:00Z' },
  ]);

  assert.equal(moc, '2026-11-03T00:00:00Z');
});

test('đơn nhảy thẳng sang hoàn tất vẫn có mốc nhận hàng', () => {
  // Du lieu that co don khong di qua 'delivered'. Chi tim 'delivered' thi nhung
  // don nay se khong bao gio co han tra hang, tuc la tra hang duoc mai mai.
  const moc = thoiDiemNhanHang([
    { to_status: 'shipping', created_at: '2026-11-01T00:00:00Z' },
    { to_status: 'completed', created_at: '2026-11-02T00:00:00Z' },
  ]);

  assert.equal(moc, '2026-11-02T00:00:00Z');
});

test('có cả hai mốc thì lấy mốc sớm hơn', () => {
  const moc = thoiDiemNhanHang([
    { to_status: 'completed', created_at: '2026-11-05T00:00:00Z' },
    { to_status: 'delivered', created_at: '2026-11-03T00:00:00Z' },
  ]);

  assert.equal(moc, '2026-11-03T00:00:00Z', 'tính hạn từ lúc khách nhận hàng');
});

test('đơn chưa giao thì chưa có mốc nhận hàng', () => {
  assert.equal(
    thoiDiemNhanHang([{ to_status: 'shipping', created_at: '2026-11-01T00:00:00Z' }]),
    null,
  );
});

test('không có lịch sử thì trả về null chứ không lỗi', () => {
  assert.equal(thoiDiemNhanHang([]), null);
  assert.equal(thoiDiemNhanHang(undefined), null);
  assert.equal(thoiDiemNhanHang(null), null);
});

test('số ngày được trả hàng là một con số dương hợp lý', () => {
  assert.ok(SO_NGAY_DUOC_TRA_HANG > 0 && SO_NGAY_DUOC_TRA_HANG <= 30);
});
