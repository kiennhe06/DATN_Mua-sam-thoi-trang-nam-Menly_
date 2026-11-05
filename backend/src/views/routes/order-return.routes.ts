import { Router } from 'express';
import { requireAdmin, requireAuth, requireStaffOrAdmin } from '../../middlewares/auth.js';
import { OrderReturnViewModel } from '../../viewmodels/order-return.viewmodel.js';

// Tra hang routes
const router = Router();
const vm = new OrderReturnViewModel();

// POST /api/v1/order-returns - tao yeu cau tra hang
router.post('/', requireAuth, async (req, res) => {
  try {
    const orderId = String(req.body?.orderId ?? req.body?.order_id ?? '').trim();
    const reason = String(req.body?.reason ?? '').trim();
    const proofImages = Array.isArray(req.body?.proofImages)
      ? req.body.proofImages.map((v: unknown) => String(v))
      : Array.isArray(req.body?.proof_images)
        ? req.body.proof_images.map((v: unknown) => String(v))
        : [];
    const refundAmount = Number(req.body?.refundAmount ?? req.body?.refund_amount ?? 0);

    if (!orderId) {
      return res.status(400).json({ error: 'Vui lòng cung cấp mã đơn hàng cần trả hàng' });
    }

    const data = await vm.create({
      orderId,
      userId: req.user!.id,
      reason,
      proofImages,
      refundAmount,
    });

    return res.status(201).json({ data });
  } catch (e) {
    return res.status(400).json({ error: e instanceof Error ? e.message : 'Không thể tạo yêu cầu trả hàng' });
  }
});

// GET /api/v1/order-returns - danh sach yeu cau cua toi
router.get('/', requireAuth, async (req, res) => {
  try {
    const data = await vm.listByUser(req.user!.id);
    return res.json({ data });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Lỗi khi tải danh sách trả hàng' });
  }
});

// GET /api/v1/order-returns/admin - toàn bộ yêu cầu cho admin
router.get('/admin', requireStaffOrAdmin, async (_req, res) => {
  try {
    const data = await vm.listAll();
    return res.json({ data });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Lỗi khi tải danh sách trả hàng' });
  }
});

// PATCH /api/v1/order-returns/:id - admin duyet/tu choi
router.patch('/:id', requireStaffOrAdmin, async (req, res) => {
  try {
    const status = String(req.body?.status ?? '').trim();
    if (!status) {
      return res.status(400).json({ error: 'Vui lòng chọn trạng thái mới cho yêu cầu trả hàng' });
    }

    const data = await vm.updateStatus(req.params.id, {
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

export default router;
