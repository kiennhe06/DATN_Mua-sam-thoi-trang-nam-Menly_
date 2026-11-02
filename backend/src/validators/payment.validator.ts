import { z } from 'zod';

export const createPaymentUrlSchema = z
  .object({
    orderId: z.string().uuid('Mã đơn hàng (orderId) không đúng định dạng UUID').optional(),
    orderCode: z.string().trim().min(1, 'Mã đơn hàng (orderCode) không được để trống').optional(),
    amount: z.coerce
      .number({ required_error: 'Vui lòng cung cấp số tiền thanh toán (amount)' })
      .int('Số tiền thanh toán phải là số nguyên')
      .min(1000, 'Số tiền thanh toán tối thiểu là 1.000 VNĐ'),
    orderInfo: z.string().trim().max(255, 'Nội dung thanh toán tối đa 255 ký tự').optional(),
    bankCode: z.string().trim().optional(),
    locale: z.enum(['vn', 'en']).default('vn'),
  })
  .refine((data) => Boolean(data.orderId || data.orderCode), {
    message: 'Cần cung cấp mã đơn hàng (orderId hoặc orderCode)',
    path: ['orderId'],
  });

export type CreatePaymentUrlInput = z.infer<typeof createPaymentUrlSchema>;

