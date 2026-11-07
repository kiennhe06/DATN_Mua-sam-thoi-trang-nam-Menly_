import { z } from 'zod';

export const registerSchema = z.object({
  email: z
    .string({ required_error: 'Vui lòng nhập email' })
    .trim()
    .toLowerCase()
    .email('Email không đúng định dạng'),
  password: z
    .string({ required_error: 'Vui lòng nhập mật khẩu' })
    .min(6, 'Mật khẩu phải có ít nhất 6 ký tự')
    .max(100, 'Mật khẩu tối đa 100 ký tự'),
  fullName: z
    .string({ required_error: 'Vui lòng nhập họ và tên' })
    .trim()
    .min(2, 'Họ tên phải có ít nhất 2 ký tự')
    .max(100, 'Họ tên tối đa 100 ký tự'),
  phone: z
    .string()
    .trim()
    .regex(/^(0|\+84)[3|5|7|8|9][0-9]{8}$/, 'Số điện thoại không hợp lệ (đầu số 03, 05, 07, 08, 09 và 10 số)')
    .optional()
    .or(z.literal('')),
  role: z.enum(['customer', 'seller', 'staff', 'admin']).default('customer'),
});

export const loginSchema = z.object({
  email: z
    .string({ required_error: 'Vui lòng nhập email' })
    .trim()
    .toLowerCase()
    .email('Email không đúng định dạng'),
  password: z
    .string({ required_error: 'Vui lòng nhập mật khẩu' })
    .min(1, 'Vui lòng nhập mật khẩu'),
});

export const changePasswordSchema = z
  .object({
    currentPassword: z
      .string({ required_error: 'Vui lòng nhập mật khẩu hiện tại' })
      .min(1, 'Vui lòng nhập mật khẩu hiện tại'),
    newPassword: z
      .string({ required_error: 'Vui lòng nhập mật khẩu mới' })
      .min(6, 'Mật khẩu mới phải có ít nhất 6 ký tự')
      .max(100, 'Mật khẩu tối đa 100 ký tự'),
  })
  .refine((data) => data.currentPassword !== data.newPassword, {
    message: 'Mật khẩu mới không được trùng với mật khẩu hiện tại',
    path: ['newPassword'],
  });

export const forgotPasswordSchema = z.object({
  email: z
    .string({ required_error: 'Vui lòng nhập email' })
    .trim()
    .toLowerCase()
    .email('Email không đúng định dạng'),
  redirectTo: z.string().url('URL điều hướng không hợp lệ').optional(),
});

export const resetPasswordSchema = z
  .object({
    token: z.string().trim().optional(),
    accessToken: z.string().trim().optional(),
    otp: z.string().trim().optional(),
    email: z.string().trim().toLowerCase().email('Email không đúng định dạng').optional(),
    newPassword: z
      .string({ required_error: 'Vui lòng nhập mật khẩu mới' })
      .min(6, 'Mật khẩu mới phải có ít nhất 6 ký tự')
      .max(100, 'Mật khẩu tối đa 100 ký tự'),
  })
  .refine((data) => Boolean(data.token || data.accessToken || (data.email && data.otp)), {
    message: 'Cần cung cấp token, accessToken hoặc cặp (email và otp)',
    path: ['token'],
  });

export const refreshTokenSchema = z.object({
  refreshToken: z
    .string({ required_error: 'Vui lòng cung cấp refresh token' })
    .min(1, 'Vui lòng cung cấp refresh token'),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;
export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>;
export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>;
