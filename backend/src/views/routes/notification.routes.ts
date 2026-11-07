import { Router } from 'express';
import { requireAuth } from '../../middlewares/auth.js';
import type { CreateNotificationInput } from '../../models/notification.model.js';
import { NotificationViewModel } from '../../viewmodels/notification.viewmodel.js';

// Thong bao routes (yeu cau dang nhap)
const router = Router();
const vm = new NotificationViewModel();
router.use(requireAuth);

// POST /api/v1/notifications - tao thong bao cho tai khoan hien tai
router.post('/', async (req, res) => {
  try {
    const requestedType = req.body?.type;
    const type: CreateNotificationInput['type'] =
      requestedType === 'order' || requestedType === 'promo' || requestedType === 'system'
        ? requestedType
        : 'promo';
    const payload = {
      userId: req.user!.id,
      title: String(req.body?.title ?? '').trim(),
      body: String(req.body?.body ?? '').trim(),
      type,
      data: req.body?.data ?? {},
    };

    if (!payload.title || !payload.body) {
      return res.status(400).json({ error: 'Tiêu đề và nội dung thông báo không được để trống' });
    }

    const data = await vm.create(payload);
    return res.status(201).json({ data });
  } catch (e) {
    return res.status(400).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

// GET /api/v1/notifications - danh sach thong bao cua toi
router.get('/', async (req, res) => {
  try {
    const [data, unreadCount] = await Promise.all([
      vm.list(req.user!.id),
      vm.unreadCount(req.user!.id),
    ]);
    return res.json({ data, unread_count: unreadCount });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

// GET /api/v1/notifications/unread-count - so thong bao chua doc
router.get('/unread-count', async (req, res) => {
  try {
    const unreadCount = await vm.unreadCount(req.user!.id);
    return res.json({ data: { unread_count: unreadCount } });
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
