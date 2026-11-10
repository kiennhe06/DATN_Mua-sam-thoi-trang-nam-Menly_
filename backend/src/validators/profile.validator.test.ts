import assert from 'node:assert/strict';
import { test } from 'node:test';
import { updateProfileSchema } from './profile.validator.js';

test('updateProfileSchema: chấp nhận cập nhật họ tên hợp lệ', () => {
  const result = updateProfileSchema.safeParse({
    fullName: 'Nguyen Van B',
  });
  assert.equal(result.success, true);
  if (result.success) {
    assert.equal(result.data.fullName, 'Nguyen Van B');
  }
});

test('updateProfileSchema: chấp nhận cập nhật qua full_name (snake_case)', () => {
  const result = updateProfileSchema.safeParse({
    full_name: 'Tran Thi C',
  });
  assert.equal(result.success, true);
  if (result.success) {
    assert.equal(result.data.full_name, 'Tran Thi C');
  }
});

test('updateProfileSchema: chấp nhận số điện thoại hợp lệ và từ chối số không hợp lệ', () => {
  const valid = updateProfileSchema.safeParse({
    phone: '0987654321',
  });
  assert.equal(valid.success, true);

  const invalid = updateProfileSchema.safeParse({
    phone: '12345',
  });
  assert.equal(invalid.success, false);
});

test('updateProfileSchema: chấp nhận avatarUrl hợp lệ và từ chối URL sai', () => {
  const valid = updateProfileSchema.safeParse({
    avatarUrl: 'https://example.com/avatar.png',
  });
  assert.equal(valid.success, true);

  const invalid = updateProfileSchema.safeParse({
    avatarUrl: 'not-a-valid-url',
  });
  assert.equal(invalid.success, false);
});

test('updateProfileSchema: chấp nhận các avatar có sẵn của Menly', () => {
  const presets = [
    'menly-avatar:classic',
    'menly-avatar:bright',
    'menly-avatar:calm',
    'menly-avatar:urban',
    'menly-avatar:classic-light',
    'menly-avatar:night',
  ];

  for (const avatar_url of presets) {
    assert.equal(updateProfileSchema.safeParse({ avatar_url }).success, true);
  }
});

test('updateProfileSchema: từ chối khi không có trường nào được cung cấp', () => {
  const result = updateProfileSchema.safeParse({});
  assert.equal(result.success, false);
  if (!result.success) {
    assert.ok(result.error.errors.length > 0);
  }
});

test('updateProfileSchema: từ chối họ tên dưới 2 ký tự', () => {
  const result = updateProfileSchema.safeParse({
    fullName: 'A',
  });
  assert.equal(result.success, false);
});
