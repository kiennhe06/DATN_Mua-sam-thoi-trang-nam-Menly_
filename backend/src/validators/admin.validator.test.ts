import assert from 'node:assert/strict';
import test from 'node:test';
import {
  adminProductSchema,
  updateAdminProductSchema,
} from './admin-product.validator.js';
import { adminVoucherSchema, adminBannerSchema } from './admin.validator.js';

const product = {
  categoryId: '00000000-0000-4000-8000-000000000001',
  name: 'Áo sơ mi',
  price: 250000,
  description: null,
  thumbnailUrl: null,
  images: [],
  isActive: true,
  variants: [{ size: 'M', color: 'Đen', sku: 'AO-M-DEN', stock: 5 }],
};

test('admin product create accepts the product modal payload without requiring a slug', () => {
  assert.equal(adminProductSchema.safeParse(product).success, true);
});

test('admin product updates accept a single supported field', () => {
  assert.equal(updateAdminProductSchema.safeParse({ isActive: false }).success, true);
});

test('admin voucher accepts date input values from HTML date controls', () => {
  const parsed = adminVoucherSchema.safeParse({
    code: 'sale10',
    title: 'Sale 10',
    discountType: 'percentage',
    discountValue: 10,
    startDate: '2026-11-01',
    endDate: '2026-11-30',
  });
  assert.equal(parsed.success, true);
  if (parsed.success) {
    assert.equal(parsed.data.code, 'SALE10');
    assert.equal(parsed.data.endDate, '2026-11-30T23:59:59.999Z');
  }
});

test('admin banner accepts the date values used by the admin form', () => {
  assert.equal(adminBannerSchema.safeParse({
    title: 'Trang chủ',
    imageUrl: 'https://example.com/banner.jpg',
    startDate: '2026-11-01',
    endDate: '2026-11-30',
  }).success, true);
});
