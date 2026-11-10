import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  registerSchema,
  loginSchema,
  changePasswordSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  refreshTokenSchema,
} from './auth.validator.js';

test('registerSchema: chấp nhận payload đăng ký hợp lệ', () => {
  const result = registerSchema.safeParse({
    email: 'test@example.com',
    password: 'password123',
    fullName: 'Nguyen Van A',
    phone: '0912345678',
  });
  assert.equal(result.success, true);
  if (result.success) {
    assert.equal(result.data.email, 'test@example.com');
    assert.equal(result.data.fullName, 'Nguyen Van A');
  }
});

test('registerSchema: bo qua role client tu gui len', () => {
  const result = registerSchema.safeParse({
    email: 'ke-gian@example.com',
    password: 'password123',
    fullName: 'Ke Gian',
    role: 'admin',
  });
  assert.equal(result.success, true);
  if (result.success) {
    assert.equal('role' in result.data, false);
  }
});

test('registerSchema: từ chối email sai định dạng và mật khẩu ngắn', () => {
  const result = registerSchema.safeParse({
    email: 'khong-phai-email',
    password: '123',
    fullName: '',
  });
  assert.equal(result.success, false);
  if (!result.success) {
    const errors = result.error.flatten().fieldErrors;
    assert.ok(errors.email);
    assert.ok(errors.password);
    assert.ok(errors.fullName);
  }
});

test('registerSchema: chấp nhận hoặc từ chối số điện thoại Việt Nam', () => {
  const validPhone = registerSchema.safeParse({
    email: 'user@example.com',
    password: 'password123',
    fullName: 'Nguyen Van A',
    phone: '+84987654321',
  });
  assert.equal(validPhone.success, true);

  const invalidPhone = registerSchema.safeParse({
    email: 'user@example.com',
    password: 'password123',
    fullName: 'Nguyen Van A',
    phone: '12345',
  });
  assert.equal(invalidPhone.success, false);
});

test('loginSchema: kiểm tra tính hợp lệ của email và mật khẩu', () => {
  const valid = loginSchema.safeParse({
    email: 'user@domain.com',
    password: 'secretPassword',
  });
  assert.equal(valid.success, true);

  const invalidEmail = loginSchema.safeParse({
    email: 'not-an-email',
    password: 'pwd',
  });
  assert.equal(invalidEmail.success, false);

  const emptyPassword = loginSchema.safeParse({
    email: 'user@domain.com',
    password: '',
  });
  assert.equal(emptyPassword.success, false);
});

test('changePasswordSchema: từ chối khi mật khẩu mới trùng mật khẩu cũ', () => {
  const result = changePasswordSchema.safeParse({
    currentPassword: 'samePassword123',
    newPassword: 'samePassword123',
  });
  assert.equal(result.success, false);
  if (!result.success) {
    const errors = result.error.flatten().fieldErrors;
    assert.ok(errors.newPassword);
  }
});

test('changePasswordSchema: chấp nhận mật khẩu mới hợp lệ khác mật khẩu cũ', () => {
  const result = changePasswordSchema.safeParse({
    currentPassword: 'oldPassword123',
    newPassword: 'newPassword456',
  });
  assert.equal(result.success, true);
});

test('forgotPasswordSchema: kiểm tra email', () => {
  assert.equal(forgotPasswordSchema.safeParse({ email: 'user@test.com' }).success, true);
  assert.equal(forgotPasswordSchema.safeParse({ email: 'abc' }).success, false);
});

test('resetPasswordSchema: kiểm tra token hoặc otp hợp lệ', () => {
  const withToken = resetPasswordSchema.safeParse({
    token: 'valid-token-xyz',
    newPassword: 'newPassword123',
  });
  assert.equal(withToken.success, true);

  const withOtp = resetPasswordSchema.safeParse({
    email: 'user@test.com',
    otp: '123456',
    newPassword: 'newPassword123',
  });
  assert.equal(withOtp.success, true);

  const missingAll = resetPasswordSchema.safeParse({
    newPassword: 'newPassword123',
  });
  assert.equal(missingAll.success, false);
});

test('refreshTokenSchema: từ chối chuỗi rỗng', () => {
  assert.equal(refreshTokenSchema.safeParse({ refreshToken: 'valid-refresh' }).success, true);
  assert.equal(refreshTokenSchema.safeParse({ refreshToken: '' }).success, false);
});
