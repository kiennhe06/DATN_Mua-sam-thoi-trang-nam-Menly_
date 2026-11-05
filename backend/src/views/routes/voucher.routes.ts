import { Router } from 'express';
import { VoucherViewModel } from '../../viewmodels/voucher.viewmodel.js';

// Ma giam gia routes
const router = Router();
const vm = new VoucherViewModel();

// GET /api/v1/vouchers - danh sach ma giam gia dang hoat dong
router.get('/', async (_req, res) => {
  try {
    const data = await vm.list();
    return res.json({ data });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

// POST /api/v1/vouchers/apply - ap dung ma giam gia { code, subtotal }
router.post('/apply', async (req, res) => {
  try {
    const { code, subtotal } = req.body ?? {};
    const result = await vm.apply(code, Number(subtotal ?? 0));
    if (!result.valid) {
      return res.status(400).json({ error: result.message, data: result });
    }
    return res.json({ data: result });
  } catch (e) {
    return res.status(400).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

export default router;

