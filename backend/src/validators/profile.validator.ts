import { z } from 'zod';

const avatarUrlSchema = z
  .string()
  .trim()
  .url('URL ảnh không hợp lệ')
  .or(z.enum([
    'menly-avatar:classic',
    'menly-avatar:bright',
    'menly-avatar:calm',
    'menly-avatar:urban',
    'menly-avatar:classic-light',
    'menly-avatar:night',
  ]))
  .or(z.literal(''));

export const updateProfileSchema = z
  .object({
    fullName: z
      .string()
      .trim()
      .min(2, 'Họ tên phải có ít nhất 2 ký tự')
      .max(100, 'Họ tên tối đa 100 ký tự')
      .optional(),
    full_name: z
      .string()
      .trim()
      .min(2, 'Họ tên phải có ít nhất 2 ký tự')
      .max(100, 'Họ tên tối đa 100 ký tự')
      .optional(),
    phone: z
      .string()
      .trim()
      .regex(/^(0|\+84)[3|5|7|8|9][0-9]{8}$/, 'Số điện thoại không hợp lệ (đầu số 03, 05, 07, 08, 09 và 10 số)')
      .optional()
      .or(z.literal('')),
    avatarUrl: avatarUrlSchema.optional(),
    avatar_url: avatarUrlSchema.optional(),
  })
  .refine(
    (data) => Boolean(data.fullName || data.full_name || data.phone || data.avatarUrl || data.avatar_url),
    {
      message: 'Cần cung cấp ít nhất một trường thông tin để cập nhật (họ tên, số điện thoại hoặc ảnh đại diện)',
    }
  );

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
