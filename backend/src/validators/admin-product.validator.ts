import { z } from 'zod';

export const adminProductListSchema = z.object({
  search: z.string().trim().optional(),
  q: z.string().trim().optional(),
  categoryId: z.string().uuid().optional(),
  approvalStatus: z.enum(['pending', 'approved', 'rejected']).optional(),
  isActive: z.enum(['true', 'false']).transform((value) => value === 'true').optional(),
  limit: z.coerce.number().int().min(1).max(500).default(100),
}).transform((data) => ({
  ...data,
  search: data.search || data.q,
}));

export const adminProductSchema = z
  .object({
    categoryId: z.string().uuid(),
    name: z.string().trim().min(1).max(200),
    slug: z
      .string()
      .trim()
      .min(1)
      .max(220)
      .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, 'Slug chỉ gồm chữ thường, số và dấu gạch ngang')
      .optional(),
    description: z.string().trim().max(5000).nullable().optional(),
    price: z.number().int().min(0),
    thumbnailUrl: z.union([z.string().url(), z.literal('')]).nullable().optional(),
    images: z.array(z.string().url()).max(20).optional(),
    isActive: z.boolean().optional(),
    variants: z.array(z.object({
      size: z.string().trim().min(1).max(30),
      color: z.string().trim().min(1).max(60),
      sku: z.string().trim().min(1).max(100),
      stock: z.number().int().min(0),
    }).strict()).min(1).max(100).optional(),
  })
  .strict();

// Giu lai 'images' de khi sua anh thi gallery duoc cap nhat theo, neu bo di
// thi anh cu van nam lai trong product_images va hien thanh o anh trong.
//
// Giu ca 'variants': truoc day truong nay bi bo nen man sua san pham khong the
// them size hay mau moi, phai xoa san pham tao lai tu dau.
export const updateAdminProductSchema = adminProductSchema
  .partial()
  .refine((value) => Object.keys(value).length > 0, 'Cần có ít nhất một trường để cập nhật');

export const productIdSchema = z.string().uuid();

export type AdminProductInput = z.infer<typeof adminProductSchema>;
export type AdminProductUpdate = z.infer<typeof updateAdminProductSchema>;
export type AdminProductListOptions = z.infer<typeof adminProductListSchema>;
