import { Router } from 'express';
import { requireAuth } from '../../middlewares/auth.js';
import { AddressViewModel } from '../../viewmodels/address.viewmodel.js';

// So dia chi routes (yeu cau dang nhap)
const router = Router();
const vm = new AddressViewModel();
router.use(requireAuth);

// GET /api/v1/addresses - danh sach dia chi
router.get('/', async (req, res) => {
  try {
    const data = await vm.list(req.user!.id);
    return res.json({ data });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

// POST /api/v1/addresses - them dia chi moi
router.post('/', async (req, res) => {
  try {
    const data = await vm.create(req.user!.id, req.body);
    return res.status(201).json({ data });
  } catch (e) {
    return res.status(400).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

// PUT /api/v1/addresses/:id - cap nhat dia chi
router.put('/:id', async (req, res) => {
  try {
    const data = await vm.update(req.params.id, req.user!.id, req.body);
    return res.json({ data });
  } catch (e) {
    return res.status(400).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

// DELETE /api/v1/addresses/:id - xoa dia chi
router.delete('/:id', async (req, res) => {
  try {
    await vm.delete(req.params.id, req.user!.id);
    return res.json({ message: 'Đã xóa địa chỉ' });
  } catch (e) {
    return res.status(400).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

// PATCH /api/v1/addresses/:id/default - dat lam mac dinh
router.patch('/:id/default', async (req, res) => {
  try {
    const data = await vm.setDefault(req.params.id, req.user!.id);
    return res.json({ data });
  } catch (e) {
    return res.status(400).json({ error: e instanceof Error ? e.message : 'Loi' });
  }
});

export default router;

