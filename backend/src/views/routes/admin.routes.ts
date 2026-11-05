import { Router, type Response } from 'express';
import { requireAdmin } from '../../middlewares/auth.js';
import { ProductModel } from '../../models/product.model.js';
import { OrderModel } from '../../models/order.model.js';
import { VoucherModel } from '../../models/voucher.model.js';
import { AdminModel } from '../../models/admin.model.js';
import { ReviewModel } from '../../models/review.model.js';
import {
  adminProductListSchema,
  adminProductSchema,
  productIdSchema,
  updateAdminProductSchema,
} from '../../validators/admin-product.validator.js';
import {
  adminVoucherSchema,
  updateAdminVoucherSchema,
  voucherIdSchema,
} from '../../validators/admin-voucher.validator.js';
import {
  adminBannerSchema,
  adminNotificationSchema,
  inventoryAdjustmentSchema,
} from '../../validators/admin.validator.js';
import {
  adminCreateUserSchema,
  adminUpdateUserSchema,
  toggleLockSchema,
  userIdSchema,
} from '../../validators/admin-user.validator.js';

// Quan tri routes
const router = Router();
router.use(requireAdmin);
const productModel = new ProductModel();
const orderModel = new OrderModel();
const voucherModel = new VoucherModel();
const adminModel = new AdminModel();
const reviewModel = new ReviewModel();

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

// GET /api/v1/admin/products/:id - chi tiet san pham
router.get('/products/:id', async (req, res, next) => {
  const id = parseProductId(req.params.id, res);
  if (!id) return;

  try {
    const data = await productModel.findAdminById(id);
    if (!data) return res.status(404).json({ error: 'Không tìm thấy sản phẩm' });
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
    const data = await productModel.createAdminProduct(parsed.data, req.user?.id);
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
    if (error instanceof Error && error.message.includes('không thể hủy')) {
      return res.status(409).json({ error: error.message });
    }
    return next(error);
  }
});

// POST /api/v1/admin/inventory/adjust - điều chỉnh tồn kho
router.post('/inventory/adjust', async (req, res, next) => {
  const parsed = inventoryAdjustmentSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Thông tin điều chỉnh kho không hợp lệ', details: parsed.error.flatten().fieldErrors });
  try {
    const data = await adminModel.adjustInventory(parsed.data, req.user!.id);
    if (!data) return res.status(404).json({ error: 'Không tìm thấy biến thể sản phẩm' });
    return res.json({ data });
  } catch (error) {
    if (error instanceof Error && (error.message.includes('Tồn kho') || error.message.includes('được cập nhật'))) {
      return res.status(409).json({ error: error.message });
    }
    return next(error);
  }
});

// GET /api/v1/admin/inventory/movements - lịch sử kho
router.get('/inventory/movements', async (req, res, next) => {
  try {
    return res.json({ data: await adminModel.listInventoryMovements() });
  } catch (error) {
    return next(error);
  }
});

router.get('/audit-log', async (req, res, next) => {
  const limitRaw = typeof req.query.limit === 'string' ? Number.parseInt(req.query.limit, 10) : 200;
  if (!Number.isInteger(limitRaw) || limitRaw < 1 || limitRaw > 500) {
    return res.status(400).json({ error: 'Giới hạn nhật ký không hợp lệ' });
  }

  try {
    return res.json({ data: await adminModel.listAuditLogs(limitRaw) });
  } catch (error) {
    return next(error);
  }
});

// GET /api/v1/admin/users - DS nguoi dung
router.get('/users', async (_req, res, next) => {
  try {
    const data = await adminModel.listUsers();
    return res.json({ data });
  } catch (error) {
    return next(error);
  }
});

// POST /api/v1/admin/users - them nguoi dung
router.post('/users', async (req, res, next) => {
  const parsed = adminCreateUserSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: 'Thông tin người dùng không hợp lệ',
      details: parsed.error.flatten().fieldErrors,
    });
  }

  try {
    const data = await adminModel.createUser(parsed.data);
    return res.status(201).json({ data });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Không thể tạo người dùng';
    return res.status(400).json({ error: message });
  }
});

// PUT /api/v1/admin/users/:id - sua nguoi dung
router.put('/users/:id', async (req, res, next) => {
  const id = userIdSchema.safeParse(req.params.id);
  if (!id.success) return res.status(400).json({ error: 'Mã người dùng không hợp lệ' });

  const parsed = adminUpdateUserSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: 'Thông tin cập nhật không hợp lệ',
      details: parsed.error.flatten().fieldErrors,
    });
  }

  try {
    const data = await adminModel.updateUser(id.data, parsed.data);
    if (!data) return res.status(404).json({ error: 'Không tìm thấy người dùng' });
    return res.json({ data });
  } catch (error) {
    return next(error);
  }
});

// DELETE /api/v1/admin/users/:id - xoa nguoi dung
router.delete('/users/:id', async (req, res, next) => {
  const id = userIdSchema.safeParse(req.params.id);
  if (!id.success) return res.status(400).json({ error: 'Mã người dùng không hợp lệ' });

  try {
    await adminModel.deleteUser(id.data);
    return res.json({ message: 'Đã xóa người dùng' });
  } catch (error) {
    return next(error);
  }
});

// PATCH /api/v1/admin/users/:id/lock - khoa/mo nguoi dung
router.patch('/users/:id/lock', async (req, res, next) => {
  const id = userIdSchema.safeParse(req.params.id);
  if (!id.success) return res.status(400).json({ error: 'Mã người dùng không hợp lệ' });

  const parsed = toggleLockSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Giá trị khóa không hợp lệ' });
  }
  if (id.data === req.user?.id && parsed.data.isLocked) {
    return res.status(400).json({ error: 'Không thể tự khóa tài khoản đang đăng nhập' });
  }

  try {
    const user = await adminModel.setLock(id.data, parsed.data.isLocked);
    if (!user) return res.status(404).json({ error: 'Không tìm thấy người dùng' });
    return res.json({ user });
  } catch (error) {
    return next(error);
  }
});

// GET /api/v1/admin/stats - thống kê tổng quan
router.get('/stats', async (_req, res, next) => {
  try {
    const [orders, products, users] = await Promise.all([
      orderModel.adminListOrders({ limit: 500 }),
      productModel.findAdminAll({ search: undefined, limit: 500 }),
      adminModel.listUsers(),
    ]);
    const activeOrders = orders.filter((order) => !['cancelled', 'expired'].includes(order.status));
    return res.json({ data: {
      ordersCount: orders.length,
      productsCount: products.length,
      usersCount: users.length,
      revenue: activeOrders.reduce((sum, order) => sum + Number(order.total), 0),
    } });
  } catch (error) {
    return next(error);
  }
});

// POST /api/v1/admin/notifications - gửi thông báo
router.post('/notifications', async (req, res, next) => {
  const parsed = adminNotificationSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Thông tin thông báo không hợp lệ', details: parsed.error.flatten().fieldErrors });
  try {
    return res.status(201).json({ data: await adminModel.createNotification(parsed.data, req.user!.id) });
  } catch (error) {
    return next(error);
  }
});

// GET /api/v1/admin/banners - danh sách banner quản trị
router.get('/banners', async (_req, res, next) => {
  try {
    return res.json({ data: await adminModel.listBanners() });
  } catch (error) {
    return next(error);
  }
});

// POST /api/v1/admin/banners - tạo banner
router.post('/banners', async (req, res, next) => {
  const parsed = adminBannerSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Thông tin banner không hợp lệ', details: parsed.error.flatten().fieldErrors });
  try {
    return res.status(201).json({ data: await adminModel.createBanner(parsed.data) });
  } catch (error) {
    return next(error);
  }
});

// GET /api/v1/admin/returns - DS tra hang
router.get('/returns', async (_req, res) => {
  try {
    const { OrderReturnViewModel } = await import('../../viewmodels/order-return.viewmodel.js');
    const data = await new OrderReturnViewModel().listAll();
    return res.json({ data });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Lỗi khi tải danh sách trả hàng' });
  }
});

// PATCH /api/v1/admin/returns/:id - duyet tra hang
router.patch('/returns/:id', async (req, res) => {
  try {
    const status = String(req.body?.status ?? '').trim();
    if (!status) {
      return res.status(400).json({ error: 'Vui lòng chọn trạng thái mới cho yêu cầu trả hàng' });
    }

    const { OrderReturnViewModel } = await import('../../viewmodels/order-return.viewmodel.js');
    const data = await new OrderReturnViewModel().updateStatus(req.params.id, {
      status,
      rejectionReason: req.body?.rejectionReason ?? req.body?.rejection_reason ?? null,
      adminResolutionNote: req.body?.adminResolutionNote ?? req.body?.admin_resolution_note ?? null,
    });

    if (!data) {
      return res.status(404).json({ error: 'Không tìm thấy yêu cầu trả hàng' });
    }

    return res.json({ data });
  } catch (e) {
    return res.status(400).json({ error: e instanceof Error ? e.message : 'Lỗi khi cập nhật yêu cầu trả hàng' });
  }
});

// GET /api/v1/admin/reviews - DS danh gia
router.get('/reviews', async (req, res, next) => {
  const limitRaw = typeof req.query.limit === 'string' ? Number.parseInt(req.query.limit, 10) : NaN;
  const limit = Number.isInteger(limitRaw) && limitRaw > 0 ? limitRaw : undefined;

  try {
    const items = await reviewModel.adminList({ limit });
    return res.json({ data: { items } });
  } catch (error) {
    return next(error);
  }
});

// DELETE /api/v1/admin/reviews/:id - xoa danh gia
router.delete('/reviews/:id', async (req, res, next) => {
  try {
    await reviewModel.adminDelete(req.params.id);
    return res.json({ message: 'Đã xóa đánh giá' });
  } catch (error) {
    return next(error);
  }
});

// POST /api/v1/admin/reviews/:id/reply - tra loi danh gia
router.post('/reviews/:id/reply', async (req, res, next) => {
  const { reply } = (req.body ?? {}) as { reply?: unknown };
  if (typeof reply !== 'string' || reply.trim().length === 0) {
    return res.status(400).json({ error: 'Nội dung trả lời không được để trống' });
  }

  try {
    const data = await reviewModel.adminReply(req.params.id, reply.trim());
    if (!data) return res.status(404).json({ error: 'Không tìm thấy đánh giá' });
    return res.json({ data, message: 'Đã trả lời đánh giá' });
  } catch (error) {
    return next(error);
  }
});

// =========== QUAN LY MA GIAM GIA (VOUCHER) ===========

// GET /api/v1/admin/vouchers - DS voucher (ca het han / da tat)
router.get('/vouchers', async (_req, res, next) => {
  try {
    const data = await voucherModel.adminList();
    return res.json({ data });
  } catch (error) {
    return next(error);
  }
});

// POST /api/v1/admin/vouchers - them voucher
router.post('/vouchers', async (req, res, next) => {
  const parsed = adminVoucherSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: 'Thông tin mã giảm giá không hợp lệ',
      details: parsed.error.flatten().fieldErrors,
    });
  }

  try {
    const data = await voucherModel.adminCreate(parsed.data);
    return res.status(201).json({ data });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Không thể tạo mã giảm giá';
    return res.status(400).json({ error: message });
  }
});

// PUT /api/v1/admin/vouchers/:id - sua voucher
router.put('/vouchers/:id', async (req, res, next) => {
  const id = voucherIdSchema.safeParse(req.params.id);
  if (!id.success) return res.status(400).json({ error: 'Mã voucher không hợp lệ' });

  const parsed = updateAdminVoucherSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: 'Thông tin cập nhật không hợp lệ',
      details: parsed.error.flatten().fieldErrors,
    });
  }

  try {
    const data = await voucherModel.adminUpdate(id.data, parsed.data);
    if (!data) return res.status(404).json({ error: 'Không tìm thấy mã giảm giá' });
    return res.json({ data });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Không thể cập nhật mã giảm giá';
    return res.status(400).json({ error: message });
  }
});

// DELETE /api/v1/admin/vouchers/:id - xoa voucher
router.delete('/vouchers/:id', async (req, res, next) => {
  const id = voucherIdSchema.safeParse(req.params.id);
  if (!id.success) return res.status(400).json({ error: 'Mã voucher không hợp lệ' });

  try {
    await voucherModel.adminRemove(id.data);
    return res.json({ success: true, message: 'Đã xóa mã giảm giá' });
  } catch (error) {
    return next(error);
  }
});

export default router;
