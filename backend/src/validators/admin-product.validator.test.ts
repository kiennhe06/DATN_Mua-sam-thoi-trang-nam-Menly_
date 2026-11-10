import assert from 'node:assert/strict';
import test from 'node:test';
import {
  adminProductListSchema,
  adminProductSchema,
  updateAdminProductSchema,
} from './admin-product.validator.js';

const validProduct = {
  categoryId: '00000000-0000-4000-8000-000000000001',
  name: 'Áo sơ mi',
  slug: 'ao-so-mi',
  price: 250000,
};

test('chấp nhận thông tin sản phẩm hợp lệ', () => {
  assert.equal(adminProductSchema.safeParse(validProduct).success, true);
});

test('từ chối giá âm và slug không đúng định dạng', () => {
  assert.equal(adminProductSchema.safeParse({ ...validProduct, price: -1 }).success, false);
  assert.equal(adminProductSchema.safeParse({ ...validProduct, slug: 'Ao So Mi' }).success, false);
});

test('yêu cầu ít nhất một trường khi cập nhật', () => {
  assert.equal(updateAdminProductSchema.safeParse({}).success, false);
  assert.equal(updateAdminProductSchema.safeParse({ name: 'Áo mới' }).success, true);
});

test('chuyển bộ lọc trạng thái kinh doanh thành boolean', () => {
  const parsed = adminProductListSchema.safeParse({ isActive: 'false' });
  assert.equal(parsed.success, true);
  if (parsed.success) assert.equal(parsed.data.isActive, false);
});
