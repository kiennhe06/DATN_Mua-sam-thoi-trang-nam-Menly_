import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  addToCartSchema,
  updateCartItemSchema,
  putCartItemBodySchema,
  variantIdParamSchema,
} from './cart.validator.js';

const validUuid = '123e4567-e89b-12d3-a456-426614174000';

test('addToCartSchema: chấp nhận payload hợp lệ với variantId và quantity', () => {
  const result = addToCartSchema.safeParse({
    variantId: validUuid,
    quantity: 2,
  });
  assert.equal(result.success, true);
  if (result.success) {
    assert.equal(result.data.variantId, validUuid);
    assert.equal(result.data.quantity, 2);
  }
});

test('addToCartSchema: chấp nhận variant_id và mặc định quantity là 1', () => {
  const result = addToCartSchema.safeParse({
    variant_id: validUuid,
  });
  assert.equal(result.success, true);
  if (result.success) {
    assert.equal(result.data.quantity, 1);
  }
});

test('addToCartSchema: từ chối khi thiếu variantId', () => {
  const result = addToCartSchema.safeParse({
    quantity: 2,
  });
  assert.equal(result.success, false);
});

test('addToCartSchema: từ chối variantId sai định dạng UUID', () => {
  const result = addToCartSchema.safeParse({
    variantId: 'invalid-uuid-string',
    quantity: 1,
  });
  assert.equal(result.success, false);
});

test('addToCartSchema: từ chối số lượng bé hơn 1 hoặc lớn hơn 20', () => {
  const tooLow = addToCartSchema.safeParse({
    variantId: validUuid,
    quantity: 0,
  });
  assert.equal(tooLow.success, false);

  const tooHigh = addToCartSchema.safeParse({
    variantId: validUuid,
    quantity: 21,
  });
  assert.equal(tooHigh.success, false);
});

test('updateCartItemSchema: chấp nhận số lượng từ 1 đến 20', () => {
  const valid = updateCartItemSchema.safeParse({ quantity: 5 });
  assert.equal(valid.success, true);

  const invalidZero = updateCartItemSchema.safeParse({ quantity: 0 });
  assert.equal(invalidZero.success, false);

  const invalidOver = updateCartItemSchema.safeParse({ quantity: 25 });
  assert.equal(invalidOver.success, false);
});

test('putCartItemBodySchema: yêu cầu có variantId và số lượng hợp lệ', () => {
  const valid = putCartItemBodySchema.safeParse({
    variantId: validUuid,
    quantity: 3,
  });
  assert.equal(valid.success, true);

  const missingQty = putCartItemBodySchema.safeParse({
    variantId: validUuid,
  });
  assert.equal(missingQty.success, false);
});

test('variantIdParamSchema: kiểm tra định dạng param UUID', () => {
  const valid = variantIdParamSchema.safeParse({ variantId: validUuid });
  assert.equal(valid.success, true);

  const invalid = variantIdParamSchema.safeParse({ variantId: '123' });
  assert.equal(invalid.success, false);
});

