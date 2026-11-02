import { Router } from 'express';
import { OrderModel } from '../../models/order.model.js';
import { validateBody } from '../../middlewares/validate.js';
import { calculateShippingFeeSchema } from '../../validators/shipping.validator.js';

// Dat hang routes
const router = Router();
const orderModel = new OrderModel();

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

// POST /api/v1/orders - tao don (tru kho)
router.post('/', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// GET /api/v1/orders - don cua toi
router.get('/', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// GET /api/v1/orders/track - tra cuu don cho khach vang lai
router.get('/track', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// GET /api/v1/orders/:id - chi tiet don
router.get('/:id', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

// PUT /api/v1/orders/:id/cancel - huy don
router.put('/:id/cancel', (_req, res) => {
  // TODO: implement
  res.status(501).json({ message: 'Chua duoc cai dat' });
});

export default router;
