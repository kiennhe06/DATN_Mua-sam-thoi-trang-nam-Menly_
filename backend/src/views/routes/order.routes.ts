import { Router } from 'express';
import { requireAuth } from '../../middlewares/auth.js';
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
      shipping_fee: Number(req.body.shipping_fee ?? 0),
      discount_amount: Number(req.body.discount_amount ?? 0),
      total: Number(req.body.total ?? 0),
      voucher_code: req.body.voucher_code,
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

// GET /api/v1/orders/track - tra cuu don cho khach vang lai
router.get('/track', (_req, res) => {
  res.status(501).json({ message: 'Tinh nang tra cuu don se duoc cap nhat sau' });
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

