import { Router } from 'express';
import type { Request, Response } from 'express';
import { requireAuth } from '../../middlewares/auth.js';
import { uploadMultipleImagesMiddleware } from '../../middlewares/upload.js';
import { ReviewViewModel } from '../../viewmodels/review.viewmodel.js';

const router = Router();
const vm = new ReviewViewModel();

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

// GET /api/v1/reviews/product/:productId - danh sach danh gia cua san pham (cong khai)
router.get('/product/:productId', async (req, res) => {
  try {
    const data = await vm.listByProduct(req.params.productId);
    res.json({ data });
  } catch (e) {
    res.status(500).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

// GET /api/v1/reviews/mine - danh sach danh gia cua toi
// GET /api/v1/reviews/can-review/:productId - toi co duoc danh gia san pham nay khong
router.get('/can-review/:productId', requireAuth, async (req, res) => {
  try {
    const canReview = await vm.canReview(req.user!.id, req.params.productId);
    return res.json({ data: { canReview } });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

router.get('/mine', requireAuth, async (req, res) => {
  try {
    const data = await vm.listMine(req.user!.id);
    res.json({ data });
  } catch (e) {
    res.status(500).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

async function createReview(req: Request, res: Response) {
  try {
    const { orderItemId, rating, comment } = req.body ?? {};
    const rawProductId = String(req.params.productId ?? req.body?.productId ?? '').trim();
    const productId = rawProductId || undefined;
    const cleanOrderItemId = orderItemId ? String(orderItemId).trim() : undefined;
    const images = parseImages(req.body?.images);

    const data = await vm.create({
      userId: req.user!.id,
      productId,
      orderItemId: cleanOrderItemId,
      rating: Number(rating),
      comment: typeof comment === 'string' ? comment : undefined,
      files: getUploadedFiles(req),
      images,
    });
    res.status(201).json({ data });
  } catch (e) {
    res.status(400).json({ error: e instanceof Error ? e.message : 'Loi tao danh gia' });
  }
}

// POST /api/v1/reviews - viet danh gia kem anh (multipart: orderItemId, rating, comment, images[])
router.post('/', requireAuth, uploadMultipleImagesMiddleware('images', 5), createReview);

// POST /api/v1/reviews/:productId - tuong thich cu, cung ho tro dinh kem anh
router.post('/:productId', requireAuth, uploadMultipleImagesMiddleware('images', 5), createReview);

// DELETE /api/v1/reviews/:reviewId - xoa danh gia cua minh
router.delete('/:reviewId', requireAuth, async (req, res) => {
  try {
    const removed = await vm.remove(req.params.reviewId, req.user!.id);
    if (!removed) return res.status(404).json({ error: 'Khong tim thay danh gia cua ban' });
    res.json({ message: 'Da xoa danh gia' });
  } catch (e) {
    res.status(500).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

export default router;
