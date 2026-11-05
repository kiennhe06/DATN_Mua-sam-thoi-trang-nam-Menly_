import { z } from 'zod';

const roleEnum = z.enum(['customer', 'admin', 'user', 'seller', 'staff']);

// Tao nguoi dung moi tu trang quan tri
export const adminCreateUserSchema = z
  .object({
    name: z.string().trim().min(1, 'Vui lòng nhập tên người dùng').max(120),
    email: z.string().trim().email('Email không hợp lệ').transform((v) => v.toLowerCase()),
    password: z.string().min(6, 'Mật khẩu tối thiểu 6 ký tự').max(100).optional(),
    role: roleEnum.default('customer'),
  })
  .strict();

// Cap nhat thong tin nguoi dung (ten / role)
export const adminUpdateUserSchema = z
  .object({
    name: z.string().trim().min(1).max(120).optional(),
    fullName: z.string().trim().min(1).max(120).optional(),
    email: z.string().trim().email('Email không hợp lệ').transform((v) => v.toLowerCase()).optional(),
    role: roleEnum.optional(),
    phone: z.string().trim().max(20).nullable().optional(),
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0, 'Cần có ít nhất một trường để cập nhật');

export const toggleLockSchema = z
  .object({
    isLocked: z.boolean(),
  })
  .strict();

export const userIdSchema = z.string().uuid('Mã người dùng không hợp lệ');

export type AdminCreateUserInput = z.infer<typeof adminCreateUserSchema>;
export type AdminUpdateUserInput = z.infer<typeof adminUpdateUserSchema>;
