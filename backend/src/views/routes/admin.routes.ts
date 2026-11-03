import { Router, type Response } from 'express';
import { requireAdmin } from '../../middlewares/auth.js';
import { ProductModel } from '../../models/product.model.js';
import { OrderModel } from '../../models/order.model.js';
import {
  adminProductListSchema,
  adminProductSchema,
  productIdSchema,
  updateAdminProductSchema,
} from '../../validators/admin-product.validator.js';

// Quan tri routes
const router = Router();
router.use(requireAdmin);
const productModel = new ProductModel();
const orderModel = new OrderModel();

// Cac trang thai don hang hop le (khop enum order_status trong DB)
const ORDER_STATUSES = [
  'pending_payment',
  'paid',
  'processing',
  'shipping',
  'delivered',
  'completed',
  'cancelled',
  'expired',
];

function parseProductId(id: string, res: Response) {
  const parsed = productIdSchema.safeParse(id);
  if (!parsed.success) {
    res.status(400).json({ error: 'Mã sản phẩm không hợp lệ' });
    return null;
  }
  return parsed.data;
}

// GET /api/v1/admin/products - DS san pham
router.get('/products', async (req, res, next) => {
  const parsed = adminProductListSchema.safeParse(req.query);
  if (!parsed.success) {
    return res.status(400).json({
      error: 'Bộ lọc sản phẩm không hợp lệ',
      details: parsed.error.flatten().fieldErrors,
    });
  }

  try {
    const data = await productModel.findAdminAll(parsed.data);
    return res.json({ data });
  } catch (error) {
    return next(error);
  }
});

// POST /api/v1/admin/products - them SP
router.post('/products', async (req, res, next) => {
  const parsed = adminProductSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: 'Thông tin sản phẩm không hợp lệ',
      details: parsed.error.flatten().fieldErrors,
    });
  }

  try {
    const data = await productModel.createAdminProduct(parsed.data);
    return res.status(201).json({ data });
  } catch (error) {
    return next(error);
  }
});

// PUT /api/v1/admin/products/:id - sua SP
router.put('/products/:id', async (req, res, next) => {
  const id = parseProductId(req.params.id, res);
  if (!id) return;

  const parsed = updateAdminProductSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: 'Thông tin cập nhật không hợp lệ',
      details: parsed.error.flatten().fieldErrors,
    });
  }

  try {
    const data = await productModel.updateAdminProduct(id, parsed.data);
    if (!data) return res.status(404).json({ error: 'Không tìm thấy sản phẩm' });
    return res.json({ data });
  } catch (error) {
    return next(error);
  }
});

// DELETE /api/v1/admin/products/:id - xoa SP
router.delete('/products/:id', async (req, res, next) => {
  const id = parseProductId(req.params.id, res);
  if (!id) return;

  try {
    const data = await productModel.deactivateAdminProduct(id);
    if (!data) return res.status(404).json({ error: 'Không tìm thấy sản phẩm' });
    return res.json({ data, message: 'Đã ngừng kinh doanh sản phẩm' });
  } catch (error) {
    return next(error);
  }
});

// PATCH /api/v1/admin/products/:id/activate - mo lai kinh doanh
router.patch('/products/:id/activate', async (req, res, next) => {
  const id = parseProductId(req.params.id, res);
  if (!id) return;

  try {
    const data = await productModel.activateAdminProduct(id);
    if (!data) return res.status(404).json({ error: 'Không tìm thấy sản phẩm' });
    return res.json({ data, message: 'Đã mở bán lại sản phẩm' });
  } catch (error) {
    return next(error);
  }
});

// PATCH /api/v1/admin/products/:id/approve - duyet SP
router.patch('/products/:id/approve', async (req, res, next) => {
  const id = parseProductId(req.params.id, res);
  if (!id) return;

  try {
    const data = await productModel.approveAdminProduct(id);
    if (!data) return res.status(404).json({ error: 'Không tìm thấy sản phẩm' });
    return res.json({ data, message: 'Đã duyệt sản phẩm' });
  } catch (error) {
    return next(error);
  }
});

// GET /api/v1/admin/orders - DS don (loc theo status, gioi han limit)
router.get('/orders', async (req, res, next) => {
  const statusRaw = typeof req.query.status === 'string' ? req.query.status : undefined;
  if (statusRaw && !ORDER_STATUSES.includes(statusRaw)) {
    return res.status(400).json({ error: 'Trạng thái đơn hàng không hợp lệ' });
  }

  const limitRaw = typeof req.query.limit === 'string' ? Number.parseInt(req.query.limit, 10) : NaN;
  const limit = Number.isInteger(limitRaw) && limitRaw > 0 ? limitRaw : undefined;

  try {
    const data = await orderModel.adminListOrders({ status: statusRaw, limit });
    return res.json({ data });
  } catch (error) {
    return next(error);
  }
});

// PUT /api/v1/admin/orders/:id/status - doi trang thai don
router.put('/orders/:id/status', async (req, res, next) => {
  const { status, note } = (req.body ?? {}) as { status?: unknown; note?: unknown };
  if (typeof status !== 'string' || !ORDER_STATUSES.includes(status)) {
    return res.status(400).json({ error: 'Trạng thái đơn hàng không hợp lệ' });
  }

  try {
    const data = await orderModel.adminUpdateOrderStatus(
      req.params.id,
      status,
      req.user?.id ?? '',
      typeof note === 'string' ? note : undefined,
    );
    if (!data) return res.status(404).json({ error: 'Không tìm thấy đơn hàng' });
    return res.json({ data, message: 'Đã cập nhật trạng thái đơn hàng' });
  } catch (error) {
    return next(error);
  }
});

// POST /api/v1/admin/inventory/adjust - dieu chinh kho
router.post('/inventory/adjust', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// GET /api/v1/admin/inventory/movements - lich su kho
router.get('/inventory/movements', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// GET /api/v1/admin/users - DS nguoi dung
router.get('/users', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// POST /api/v1/admin/users - them
router.post('/users', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// PUT /api/v1/admin/users/:id - sua
router.put('/users/:id', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// DELETE /api/v1/admin/users/:id - xoa
router.delete('/users/:id', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// PATCH /api/v1/admin/users/:id/lock - khoa/mo
router.patch('/users/:id/lock', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// GET /api/v1/admin/stats - thong ke tong quan
router.get('/stats', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// GET /api/v1/admin/audit-log - nhat ky
router.get('/audit-log', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// POST /api/v1/admin/notifications - gui thong bao
router.post('/notifications', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// POST /api/v1/admin/banners - them banner
router.post('/banners', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// PUT /api/v1/admin/banners/:id - sua banner
router.put('/banners/:id', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// DELETE /api/v1/admin/banners/:id - xoa banner
router.delete('/banners/:id', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// GET /api/v1/admin/returns - DS tra hang
router.get('/returns', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// PATCH /api/v1/admin/returns/:id - duyet tra hang
router.patch('/returns/:id', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// GET /api/v1/admin/reviews - DS danh gia
router.get('/reviews', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// DELETE /api/v1/admin/reviews/:id - xoa danh gia
router.delete('/reviews/:id', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// POST /api/v1/admin/reviews/:id/reply - tra loi danh gia
router.post('/reviews/:id/reply', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

export default router;
