import { z } from 'zod';

// Form admin gui ngay dang 'YYYY-MM-DD' hoac ISO day du -> chuan hoa thanh ISO.
// endOfDay = true: ngay chi co dang 'YYYY-MM-DD' se lay cuoi ngay (voucher con hieu luc het ngay do).
function dateString(label: string, endOfDay = false) {
  return z
    .string()
    .trim()
    .min(1, label)
    .refine((value) => !Number.isNaN(new Date(value).getTime()), label)
    .transform((value) => {
      // Dang 'YYYY-MM-DD' -> them gio de tranh lech mui gio
      if (/^\d{4}-\d{2}-\d{2}$/.test(value)) {
        return new Date(`${value}T${endOfDay ? '23:59:59.999' : '00:00:00.000'}Z`).toISOString();
      }
      return new Date(value).toISOString();
    });
}

// Admin gui du lieu dang camelCase; validate roi chuyen sang snake_case cho DB o model.
export const adminVoucherSchema = z
  .object({
    code: z
      .string()
      .trim()
      .min(3, 'Mã giảm giá tối thiểu 3 ký tự')
      .max(50)
      .transform((value) => value.toUpperCase()),
    title: z.string().trim().min(1, 'Vui lòng nhập tiêu đề').max(200),
    discountType: z.enum(['percentage', 'fixed_amount']),
    discountValue: z.coerce.number().int().positive('Giá trị giảm phải lớn hơn 0'),
    minOrderValue: z.coerce.number().int().min(0).default(0),
    maxDiscount: z.coerce.number().int().positive().nullable().optional(),
    usageLimit: z.coerce.number().int().min(1).default(100),
    startDate: dateString('Ngày bắt đầu không hợp lệ').optional(),
    endDate: dateString('Ngày kết thúc không hợp lệ', true),
    isActive: z.boolean().default(true),
  })
  .strict();

export const updateAdminVoucherSchema = adminVoucherSchema
  .partial()
  .refine((value) => Object.keys(value).length > 0, 'Cần có ít nhất một trường để cập nhật');

export const voucherIdSchema = z.string().uuid('Mã voucher không hợp lệ');

export type AdminVoucherInput = z.infer<typeof adminVoucherSchema>;
export type AdminVoucherUpdate = z.infer<typeof updateAdminVoucherSchema>;
