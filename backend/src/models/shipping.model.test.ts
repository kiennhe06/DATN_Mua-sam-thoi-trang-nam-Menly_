import assert from 'node:assert/strict';
import { test } from 'node:test';
import { OrderModel } from './order.model.js';
import { calculateShippingFeeSchema } from '../validators/shipping.validator.js';
import { docSoTien } from '../config/env.js';

test('1. Đơn dưới 399.000 đ tính phí chuẩn đồng giá 25.000 đ', () => {
  const orderModel = new OrderModel();
  const result = orderModel.calculateShippingFee({
    subtotal: 200000,
    province: 'Hà Nội',
  });

  assert.equal(result.shippingFee, 25000);
  assert.equal(result.originalFee, 25000);
  assert.equal(result.discount, 0);
  assert.equal(result.isFreeShipping, false);
  assert.equal(result.amountNeededForFreeShipping, 199000);
  assert.ok(result.estimatedDays.includes('1–2'));
});

test('2. Đơn từ 399.000 đ trở lên được MIỄN PHÍ VẬN CHUYỂN (0 đ)', () => {
  const orderModel = new OrderModel();
  const result = orderModel.calculateShippingFee({
    subtotal: 420000,
    province: 'Hải Phòng',
  });

  assert.equal(result.shippingFee, 0);
  assert.equal(result.originalFee, 25000);
  assert.equal(result.discount, 25000);
  assert.equal(result.isFreeShipping, true);
  assert.equal(result.amountNeededForFreeShipping, 0);
  assert.ok(result.note.includes('miễn phí vận chuyển'));
});

test('3. Áp dụng mã FREESHIP được miễn phí ship dù đơn hàng dưới 399.000 đ', () => {
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

test('5. Giao hàng hỏa tốc với đơn trên 399.000 đ được giảm 25.000 đ chỉ còn 20.000 đ', () => {
  const orderModel = new OrderModel();
  const result = orderModel.calculateShippingFee({
    subtotal: 450000,
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
  assert.equal(policy.freeShippingThreshold, 399000);
  assert.ok(policy.supportedMethods.length >= 2);
});

test('7. Validator từ chối subtotal âm', () => {
  const parseResult = calculateShippingFeeSchema.safeParse({
    subtotal: -5000,
  });
  assert.equal(parseResult.success, false);
});

test('8. Moi phuong thuc giao hang deu co phi va thoi gian du kien khop voi bang gia', () => {
  const orderModel = new OrderModel();
  const policy = orderModel.getShippingPolicy();

  const standard = policy.supportedMethods.find((method) => method.id === 'standard');
  const express = policy.supportedMethods.find((method) => method.id === 'express');

  assert.ok(standard, 'Thiếu phương thức giao tiêu chuẩn');
  assert.ok(express, 'Thiếu phương thức giao hỏa tốc');
  // App hien phi ngay duoi ten phuong thuc, nen hai con so nay phai bang
  // phi goc o bang gia, khong duoc lech nhau.
  assert.equal(standard.baseFee, policy.standardBaseFee);
  assert.equal(express.baseFee, policy.expressBaseFee);
  assert.ok(standard.estimatedDays.length > 0);
  assert.ok(express.estimatedDays.length > 0);
});

test('9. Bang gia doc tu bien moi truong, bo qua gia tri khong hop le', () => {
  assert.equal(docSoTien('30000', 25000), 30000);
  assert.equal(docSoTien(undefined, 25000), 25000);
  assert.equal(docSoTien('', 25000), 25000);
  assert.equal(docSoTien('ba muoi nghin', 25000), 25000);
  assert.equal(docSoTien('-1000', 25000), 25000);
});
