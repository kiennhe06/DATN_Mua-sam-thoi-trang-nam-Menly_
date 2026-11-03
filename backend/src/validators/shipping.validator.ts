import { z } from 'zod';

export const calculateShippingFeeSchema = z.object({
  subtotal: z.coerce
    .number({ required_error: 'Vui lòng cung cấp tổng tiền hàng (subtotal)' })
    .int('Tổng tiền hàng phải là số nguyên')
    .min(0, 'Tổng tiền hàng không được âm'),
  province: z.string().trim().optional(),
  district: z.string().trim().optional(),
  shippingMethod: z.enum(['standard', 'express']).default('standard').optional(),
  voucherCode: z.string().trim().optional(),
});

export type CalculateShippingFeeInput = z.infer<typeof calculateShippingFeeSchema>;
