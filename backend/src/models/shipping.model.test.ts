import assert from 'node:assert/strict';
import { test } from 'node:test';
import { OrderModel } from './order.model.js';
import { calculateShippingFeeSchema } from '../validators/shipping.validator.js';

test('1. Đơn dưới 499.000 đ tính phí chuẩn đồng giá 25.000 đ', () => {
  const orderModel = new OrderModel();
  const result = orderModel.calculateShippingFee({
    subtotal: 200000,
    province: 'Hà Nội',
  });

  assert.equal(result.shippingFee, 25000);
  assert.equal(result.originalFee, 25000);
  assert.equal(result.discount, 0);
  assert.equal(result.isFreeShipping, false);
  assert.equal(result.amountNeededForFreeShipping, 299000);
  assert.ok(result.estimatedDays.includes('1–2'));
});

test('2. Đơn từ 499.000 đ trở lên được MIỄN PHÍ VẬN CHUYỂN (0 đ)', () => {
  const orderModel = new OrderModel();
  const result = orderModel.calculateShippingFee({
    subtotal: 550000,
    province: 'Hải Phòng',
  });

  assert.equal(result.shippingFee, 0);
  assert.equal(result.originalFee, 25000);
  assert.equal(result.discount, 25000);
  assert.equal(result.isFreeShipping, true);
  assert.equal(result.amountNeededForFreeShipping, 0);
  assert.ok(result.note.includes('miễn phí vận chuyển'));
});

test('3. Áp dụng mã FREESHIP được miễn phí ship dù đơn hàng dưới 499.000 đ', () => {
  const orderModel = new OrderModel();
  const result = orderModel.calculateShippingFee({
    subtotal: 150000,
    voucherCode: 'FREESHIP50K',
  });

  assert.equal(result.shippingFee, 0);
  assert.equal(result.isFreeShipping, true);
  assert.ok(result.note.includes('FREESHIP50K'));
});

test('4. Giao hàng hỏa tốc (Express) có phí gốc 45.000 đ', () => {
  const orderModel = new OrderModel();
  const result = orderModel.calculateShippingFee({
    subtotal: 200000,
    province: 'Hồ Chí Minh',
    shippingMethod: 'express',
  });

  assert.equal(result.originalFee, 45000);
  assert.equal(result.shippingFee, 45000);
  assert.equal(result.isFreeShipping, false);
  assert.ok(result.estimatedDays.includes('Trong ngày'));
});

test('5. Giao hàng hỏa tốc với đơn trên 499.000 đ được giảm 25.000 đ chỉ còn 20.000 đ', () => {
  const orderModel = new OrderModel();
  const result = orderModel.calculateShippingFee({
    subtotal: 600000,
    province: 'Hồ Chí Minh',
    shippingMethod: 'express',
  });

  assert.equal(result.originalFee, 45000);
  assert.equal(result.discount, 25000);
  assert.equal(result.shippingFee, 20000);
  assert.equal(result.isFreeShipping, true);
});

test('6. Lấy chính sách vận chuyển của shop thành công', () => {
  const orderModel = new OrderModel();
  const policy = orderModel.getShippingPolicy();
  assert.equal(policy.standardBaseFee, 25000);
  assert.equal(policy.freeShippingThreshold, 499000);
  assert.ok(policy.supportedMethods.length >= 2);
});

test('7. Validator từ chối subtotal âm', () => {
  const parseResult = calculateShippingFeeSchema.safeParse({
    subtotal: -5000,
  });
  assert.equal(parseResult.success, false);
});
