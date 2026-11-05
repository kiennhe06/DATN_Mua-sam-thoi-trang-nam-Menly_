import { Router } from 'express';
import { requireAuth } from '../../middlewares/auth.js';
import { NotificationViewModel } from '../../viewmodels/notification.viewmodel.js';

// Thong bao routes (yeu cau dang nhap)
const router = Router();
const vm = new NotificationViewModel();
router.use(requireAuth);

// GET /api/v1/notifications - danh sach thong bao cua toi
router.get('/', async (req, res) => {
  try {
    const data = await vm.list(req.user!.id);
    return res.json({ data });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

// PATCH /api/v1/notifications/read-all - danh dau doc tat ca (phai truoc /:id/read)
router.patch('/read-all', async (req, res) => {
  try {
    await vm.markAllRead(req.user!.id);
    return res.json({ message: 'Đã đánh dấu tất cả thông báo là đã đọc' });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

// PATCH /api/v1/notifications/:id/read - danh dau da doc
router.patch('/:id/read', async (req, res) => {
  try {
    await vm.markRead(req.params.id, req.user!.id);
    return res.json({ message: 'Đã đánh dấu thông báo là đã đọc' });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

// DELETE /api/v1/notifications/:id - xoa thong bao
router.delete('/:id', async (req, res) => {
  try {
    await vm.delete(req.params.id, req.user!.id);
    return res.json({ message: 'Đã xóa thông báo' });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

export default router;

