import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  LoiChuyenTrangThai,
  cacTrangThaiTiepTheo,
  duocChuyenTrangThai,
  kiemTraChuyenTrangThai,
} from './order-status-flow.js';

test('đơn đi tiếp theo đúng thứ tự thì được', () => {
  assert.ok(duocChuyenTrangThai('pending_payment', 'paid'));
  assert.ok(duocChuyenTrangThai('paid', 'processing'));
  assert.ok(duocChuyenTrangThai('processing', 'shipping'));
  assert.ok(duocChuyenTrangThai('shipping', 'delivered'));
  assert.ok(duocChuyenTrangThai('delivered', 'completed'));
});

test('nhảy cóc về phía trước vẫn được', () => {
  // Don that trong he thong co cai nhay thang tu 'shipping' sang 'completed',
  // chan lai se lam nhan vien khong chot duoc don.
  assert.ok(duocChuyenTrangThai('shipping', 'completed'));
  assert.ok(duocChuyenTrangThai('paid', 'delivered'));
});

test('không lùi đơn về trạng thái cũ', () => {
  assert.equal(duocChuyenTrangThai('delivered', 'processing'), false);
  assert.equal(duocChuyenTrangThai('shipping', 'paid'), false);
  assert.equal(duocChuyenTrangThai('paid', 'pending_payment'), false);
});

test('đơn đã hủy không sống lại được', () => {
  // Day la cho hong that: luc huy, cancel_order da cong hang ve kho roi, nen
  // don song lai se vua duoc cong kho vua duoc giao di.
  assert.equal(duocChuyenTrangThai('cancelled', 'delivered'), false);
  assert.equal(duocChuyenTrangThai('cancelled', 'processing'), false);
  assert.equal(duocChuyenTrangThai('cancelled', 'completed'), false);
});

test('đơn đã hoàn tất và đã quá hạn cũng là trạng thái chốt', () => {
  assert.equal(duocChuyenTrangThai('completed', 'delivered'), false);
  assert.equal(duocChuyenTrangThai('completed', 'cancelled'), false);
  assert.equal(duocChuyenTrangThai('expired', 'paid'), false);
});

test('chỉ hủy được khi hàng chưa rời kho', () => {
  assert.ok(duocChuyenTrangThai('pending_payment', 'cancelled'));
  assert.ok(duocChuyenTrangThai('paid', 'cancelled'));
  assert.ok(duocChuyenTrangThai('processing', 'cancelled'));

  assert.equal(duocChuyenTrangThai('shipping', 'cancelled'), false);
  assert.equal(duocChuyenTrangThai('delivered', 'cancelled'), false);
});

test('chỉ đơn chờ thanh toán mới quá hạn được', () => {
  assert.ok(duocChuyenTrangThai('pending_payment', 'expired'));
  assert.equal(duocChuyenTrangThai('paid', 'expired'), false);
  assert.equal(duocChuyenTrangThai('shipping', 'expired'), false);
});

test('giữ nguyên trạng thái cũ thì không bị coi là sai', () => {
  assert.ok(duocChuyenTrangThai('shipping', 'shipping'));
  assert.ok(duocChuyenTrangThai('cancelled', 'cancelled'));
});

test('trạng thái lạ thì từ chối chứ không đoán bừa', () => {
  assert.equal(duocChuyenTrangThai('paid', 'refunded'), false);
  assert.equal(duocChuyenTrangThai('linh_tinh', 'paid'), false);
});

test('báo lỗi kèm lý do đọc được cho người dùng', () => {
  assert.throws(
    () => kiemTraChuyenTrangThai('cancelled', 'delivered'),
    (loi: unknown) =>
      loi instanceof LoiChuyenTrangThai && /đã kết thúc/.test((loi as Error).message),
  );

  assert.throws(
    () => kiemTraChuyenTrangThai('shipping', 'cancelled'),
    (loi: unknown) =>
      loi instanceof LoiChuyenTrangThai && /trả hàng/.test((loi as Error).message),
  );

  assert.throws(
    () => kiemTraChuyenTrangThai('delivered', 'processing'),
    (loi: unknown) =>
      loi instanceof LoiChuyenTrangThai && /không lùi đơn/i.test((loi as Error).message),
  );
});

test('bước đi hợp lệ thì không ném lỗi', () => {
  assert.doesNotThrow(() => kiemTraChuyenTrangThai('processing', 'shipping'));
});

test('danh sách bước tiếp theo khớp với luật', () => {
  assert.deepEqual(cacTrangThaiTiepTheo('cancelled'), []);
  assert.deepEqual(cacTrangThaiTiepTheo('completed'), []);
  assert.deepEqual(cacTrangThaiTiepTheo('delivered'), ['completed']);
  assert.deepEqual(cacTrangThaiTiepTheo('shipping'), ['delivered', 'completed']);
  assert.deepEqual(cacTrangThaiTiepTheo('pending_payment'), [
    'paid',
    'processing',
    'shipping',
    'delivered',
    'completed',
    'cancelled',
    'expired',
  ]);
});
