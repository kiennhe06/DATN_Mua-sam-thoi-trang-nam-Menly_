import { Router } from 'express';
import { requireAuth, requireStaffOrAdmin } from '../../middlewares/auth.js';
import { OrderModel } from '../../models/order.model.js';
import { OrderViewModel } from '../../viewmodels/order.viewmodel.js';
import { validateBody } from '../../middlewares/validate.js';
import { calculateShippingFeeSchema } from '../../validators/shipping.validator.js';

// Dat hang routes
const router = Router();
const orderModel = new OrderModel();
const vm = new OrderViewModel();

/**
 * GET /api/v1/orders/shipping-policy
 * Lấy chính sách vận chuyển của hệ thống Menly
 */
router.get('/shipping-policy', (_req, res) => {
  const policy = orderModel.getShippingPolicy();
  res.json({ data: policy });
});

/**
 * POST /api/v1/orders/shipping-fee
 * Tính toán phí giao hàng theo giá trị đơn hàng, địa chỉ và phương thức giao hàng
 */
router.post('/shipping-fee', validateBody(calculateShippingFeeSchema), (req, res) => {
  const result = orderModel.calculateShippingFee(req.body);
  res.json({ data: result });
});

// POST /api/v1/orders - Tao don hang moi (yeu cau dang nhap)
router.post('/', requireAuth, async (req, res) => {
  try {
    const order = await vm.createOrder({
      userId: req.user!.id,
      payment_method: req.body.payment_method ?? 'cod',
      ship_name: req.body.ship_name,
      ship_phone: req.body.ship_phone,
      ship_address: req.body.ship_address,
      subtotal: Number(req.body.subtotal ?? 0),
      discount_amount: Number(req.body.discount_amount ?? 0),
      total: Number(req.body.total ?? 0),
      shipping_fee: Number(req.body.shipping_fee ?? 0),
      voucher_code: req.body.voucher_code,
      idempotency_key: typeof req.body.idempotency_key === 'string' ? req.body.idempotency_key : undefined,
      items: req.body.items ?? [],
    });
    return res.status(201).json({ data: order });
  } catch (e) {
    return res.status(400).json({ error: e instanceof Error ? e.message : 'Loi tao don hang' });
  }
});

// GET /api/v1/orders - Danh sach don hang cua toi (yeu cau dang nhap)
router.get('/', requireAuth, async (req, res) => {
  try {
    const orders = await vm.getOrders(req.user!.id);
    return res.json({ data: orders });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

// GET /api/v1/orders/track - tra cuu don cho khach vang lai theo ma don / SĐT
router.get('/track', async (req, res) => {
  const code = typeof req.query.code === 'string' ? req.query.code : '';
  const phone = typeof req.query.phone === 'string' ? req.query.phone : '';

  if (!code.trim() && !phone.trim()) {
    return res.status(400).json({ error: 'Vui lòng nhập mã đơn hàng hoặc số điện thoại để tra cứu.' });
  }

  try {
    const order = await vm.trackPublicOrder({ code, phone });
    if (!order) {
      return res.status(404).json({ error: 'Không tìm thấy đơn hàng phù hợp với mã đơn / số điện thoại bạn nhập.' });
    }

    return res.json({ data: order });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Lỗi khi tra cứu đơn hàng' });
  }
});

// POST /api/v1/orders/track - tra cuu don cho khach vang lai theo ma don / SĐT (body)
router.post('/track', async (req, res) => {
  const code = typeof req.body?.code === 'string' ? req.body.code : '';
  const phone = typeof req.body?.phone === 'string' ? req.body.phone : '';

  if (!code.trim() && !phone.trim()) {
    return res.status(400).json({ error: 'Vui lòng nhập mã đơn hàng hoặc số điện thoại để tra cứu.' });
  }

  try {
    const order = await vm.trackPublicOrder({ code, phone });
    if (!order) {
      return res.status(404).json({ error: 'Không tìm thấy đơn hàng phù hợp với mã đơn / số điện thoại bạn nhập.' });
    }

    return res.json({ data: order });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Lỗi khi tra cứu đơn hàng' });
  }
});

router.get('/staff', requireStaffOrAdmin, async (_req, res, next) => {
  try {
    return res.json({ data: await orderModel.adminListOrders({ limit: 500 }) });
  } catch (error) {
    return next(error);
  }
});

router.put('/:id/status', requireStaffOrAdmin, async (req, res, next) => {
  const allowedStatuses = ['paid', 'processing', 'shipping', 'delivered', 'completed'];
  if (typeof req.body?.status !== 'string' || !allowedStatuses.includes(req.body.status)) {
    return res.status(400).json({ error: 'Trạng thái đơn hàng không hợp lệ' });
  }
  try {
    const data = await orderModel.staffUpdateOrderStatus(
      req.params.id,
      req.body.status,
      req.user!.id,
      typeof req.body.note === 'string' ? req.body.note : undefined,
    );
    if (!data) return res.status(404).json({ error: 'Không tìm thấy đơn hàng' });
    return res.json({ data });
  } catch (error) {
    if (error instanceof Error && error.message.includes('Không thể chuyển')) {
      return res.status(409).json({ error: error.message });
    }
    return next(error);
  }
});

// GET /api/v1/orders/:id - Chi tiet don hang (yeu cau dang nhap)
router.get('/:id', requireAuth, async (req, res) => {
  try {
    const order = await vm.getOrderById(req.params.id, req.user!.id);
    if (!order) return res.status(404).json({ error: 'Không tìm thấy đơn hàng' });
    return res.json({ data: order });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

// PUT /api/v1/orders/:id/cancel - Huy don hang (yeu cau dang nhap)
router.put('/:id/cancel', requireAuth, async (req, res) => {
  try {
    const reason = req.body?.reason ?? 'Khách hàng yêu cầu hủy';
    const order = await vm.cancelOrder(req.params.id, req.user!.id, reason);
    return res.json({ data: order });
  } catch (e) {
    return res.status(400).json({ error: e instanceof Error ? e.message : 'Loi huy don' });
  }
});

export default router;
