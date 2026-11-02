import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createPaymentUrlSchema } from './payment.validator.js';

const validUuid = '123e4567-e89b-12d3-a456-426614174000';

test('createPaymentUrlSchema: chấp nhận payload hợp lệ với orderId và amount', () => {
  const result = createPaymentUrlSchema.safeParse({
    orderId: validUuid,
    amount: 250000,
  });
  assert.equal(result.success, true);
  if (result.success) {
    assert.equal(result.data.orderId, validUuid);
    assert.equal(result.data.amount, 250000);
    assert.equal(result.data.locale, 'vn');
  }
});

test('createPaymentUrlSchema: chấp nhận payload hợp lệ với orderCode và amount', () => {
  const result = createPaymentUrlSchema.safeParse({
    orderCode: 'ORD_20261102_001',
    amount: 500000,
    bankCode: 'NCB',
    orderInfo: 'Thanh toan don hang',
  });
  assert.equal(result.success, true);
  if (result.success) {
    assert.equal(result.data.orderCode, 'ORD_20261102_001');
    assert.equal(result.data.amount, 500000);
    assert.equal(result.data.bankCode, 'NCB');
  }
});

test('createPaymentUrlSchema: từ chối khi thiếu cả orderId và orderCode', () => {
  const result = createPaymentUrlSchema.safeParse({
    amount: 100000,
  });
  assert.equal(result.success, false);
});

test('createPaymentUrlSchema: từ chối orderId không đúng định dạng UUID', () => {
  const result = createPaymentUrlSchema.safeParse({
    orderId: 'invalid-id-string',
    amount: 100000,
  });
  assert.equal(result.success, false);
});

test('createPaymentUrlSchema: từ chối số tiền nhỏ hơn 1.000 VNĐ', () => {
  const result = createPaymentUrlSchema.safeParse({
    orderCode: 'ORD_123',
    amount: 500,
  });
  assert.equal(result.success, false);
});

