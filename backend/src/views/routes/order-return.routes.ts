import { Router } from 'express';
import type { Request } from 'express';
import { requireAuth, requireStaffOrAdmin } from '../../middlewares/auth.js';
import { uploadMultipleImagesMiddleware } from '../../middlewares/upload.js';
import { OrderReturnViewModel } from '../../viewmodels/order-return.viewmodel.js';

// Tra hang routes
const router = Router();
const vm = new OrderReturnViewModel();

function getUploadedFiles(req: Request): Express.Multer.File[] {
  return Array.isArray(req.files) ? (req.files as Express.Multer.File[]) : [];
}

function parseImages(value: unknown): string[] {
  if (Array.isArray(value)) return value.map(String).filter(Boolean);
  if (typeof value === 'string' && value.trim()) {
    try {
      const parsed = JSON.parse(value);
      if (Array.isArray(parsed)) return parsed.map(String).filter(Boolean);
    } catch {
      return [value];
    }
    return [value];
  }
  return [];
}

// POST /api/v1/order-returns - tao yeu cau tra hang (JSON hoac multipart anh)
router.post('/', requireAuth, uploadMultipleImagesMiddleware('images', 5), async (req, res) => {
  try {
    const orderId = String(req.body?.orderId ?? req.body?.order_id ?? '').trim();
    const reason = String(req.body?.reason ?? '').trim();
    const proofImages = [
      ...parseImages(req.body?.proofImages),
      ...parseImages(req.body?.proof_images),
    ];
    const refundAmount = Number(req.body?.refundAmount ?? req.body?.refund_amount ?? 0);

    if (!orderId) {
      return res.status(400).json({ error: 'Vui lòng cung cấp mã đơn hàng cần trả hàng' });
    }

    const data = await vm.create({
      orderId,
      userId: req.user!.id,
      reason,
      proofImages,
      files: getUploadedFiles(req),
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

    // Hang tra con ban duoc hay khong. Bat buoc khai bao khi hoan tien, vi
    // doan bua se hoac lam hut kho, hoac nhap nham hang loi vao kho.
    const restock = req.body?.restock;
    if (status === 'refunded' && typeof restock !== 'boolean') {
      return res.status(400).json({
        error: 'Vui lòng cho biết hàng trả có còn bán lại được không (restock: true hoặc false)',
      });
    }

    const data = await vm.updateStatus(req.params.id, {
      status,
      rejectionReason: req.body?.rejectionReason ?? req.body?.rejection_reason ?? null,
      adminResolutionNote: req.body?.adminResolutionNote ?? req.body?.admin_resolution_note ?? null,
      restock: typeof restock === 'boolean' ? restock : undefined,
      actorId: req.user?.id,
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
