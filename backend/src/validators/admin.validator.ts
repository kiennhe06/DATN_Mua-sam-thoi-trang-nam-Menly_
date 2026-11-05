import { z } from 'zod';

const userRoleSchema = z.enum(['admin', 'staff', 'customer', 'user', 'seller']);
const startDateSchema = z.string().refine((value) => !Number.isNaN(Date.parse(value)), 'Ngày bắt đầu không hợp lệ')
  .transform((value) => /^\d{4}-\d{2}-\d{2}$/.test(value) ? `${value}T00:00:00.000Z` : value);
const endDateSchema = z.string().refine((value) => !Number.isNaN(Date.parse(value)), 'Ngày kết thúc không hợp lệ')
  .transform((value) => /^\d{4}-\d{2}-\d{2}$/.test(value) ? `${value}T23:59:59.999Z` : value);

export const adminUserCreateSchema = z.object({
  name: z.string().trim().min(2).max(120),
  email: z.string().trim().email().max(320),
  password: z.string().min(6).max(72),
  role: userRoleSchema.default('customer'),
});

export const adminUserUpdateSchema = z.object({
  name: z.string().trim().min(2).max(120).optional(),
  email: z.string().trim().email().max(320).optional(),
  role: userRoleSchema.optional(),
}).refine((value) => Object.keys(value).length > 0, 'Cần có ít nhất một trường để cập nhật');

export const inventoryAdjustmentSchema = z.object({
  variantId: z.string().uuid(),
  delta: z.number().int().min(-100000).max(100000).refine((value) => value !== 0),
  reason: z.enum(['admin_restock', 'admin_correction']),
  note: z.string().trim().max(500).optional(),
});

export const adminVoucherSchema = z.object({
  code: z.string().trim().min(3).max(40).regex(/^[A-Za-z0-9_-]+$/).transform((value) => value.toUpperCase()),
  title: z.string().trim().min(2).max(200),
  discountType: z.enum(['percentage', 'fixed_amount']),
  discountValue: z.number().int().positive(),
  minOrderValue: z.number().int().min(0).default(0),
  maxDiscount: z.number().int().positive().nullable().optional(),
  usageLimit: z.number().int().positive().default(100),
  startDate: startDateSchema.optional(),
  endDate: endDateSchema,
  isActive: z.boolean().default(true),
});

export const adminBannerSchema = z.object({
  title: z.string().trim().min(2).max(200),
  imageUrl: z.string().url(),
  linkUrl: z.union([z.string().url(), z.literal('')]).nullable().optional(),
  sortOrder: z.number().int().min(0).default(0),
  isActive: z.boolean().default(true),
  startDate: startDateSchema.optional(),
  endDate: endDateSchema,
});

export const adminReturnResolutionSchema = z.object({
  status: z.enum(['shop_approved', 'shop_rejected', 'refunded', 'rejected']),
  note: z.string().trim().max(2000).optional(),
  rejectionReason: z.string().trim().max(2000).optional(),
});

export const adminNotificationSchema = z.object({
  title: z.string().trim().min(2).max(200),
  body: z.string().trim().min(1).max(4000),
  type: z.enum(['order', 'promo', 'system']),
  userId: z.string().uuid().optional(),
});
