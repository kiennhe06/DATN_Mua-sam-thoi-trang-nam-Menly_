import { Router } from 'express';
import { requireAuth } from '../../middlewares/auth.js';
import { AddressViewModel } from '../../viewmodels/address.viewmodel.js';
import { VietnamAddressService } from '../../services/address/vietnam-address.service.js';

// So dia chi routes
const router = Router();
const vm = new AddressViewModel();

// ==========================================
// Public routes: Co so du lieu dia chi 34 Tinh thanh (Resolution 202/2025/QH15)
// ==========================================

// GET /api/v1/addresses/provinces - Danh sach 34 Tinh / Thanh pho moi
router.get('/provinces', (_req, res) => {
  try {
    const provinces = VietnamAddressService.getProvinces();
    return res.json({ data: provinces });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Lỗi hệ thống' });
  }
});

// GET /api/v1/addresses/wards - Danh sach Phuong / Xa theo ma tinh hoac ten tinh
router.get('/wards', (req, res) => {
  try {
    const code = req.query.province_code as string | undefined;
    const name = req.query.province_name as string | undefined;

    if (code) {
      return res.json({ data: VietnamAddressService.getWardsByProvinceCode(code) });
    }
    if (name) {
      return res.json({ data: VietnamAddressService.getWardsByProvinceName(name) });
    }
    return res.json({ data: VietnamAddressService.getWards() });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Lỗi hệ thống' });
  }
});

// GET /api/v1/addresses/convert - Chuyen doi dia chi cu sang dia chi moi theo 10.977 quy tac mapping
router.get('/convert', (req, res) => {
  try {
    const oldWard = req.query.old_ward as string | undefined;
    const oldDistrict = req.query.old_district as string | undefined;
    const oldProvince = req.query.old_province as string | undefined;

    const result = VietnamAddressService.convertOldAddress({
      oldWard,
      oldDistrict,
      oldProvince,
    });

    if (!result) {
      return res.status(404).json({ message: 'Không tìm thấy ánh xạ phù hợp' });
    }
    return res.json({ data: result });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Lỗi hệ thống' });
  }
});

// GET /api/v1/addresses/search - Tim kiem don vi hanh chinh thong minh
router.get('/search', (req, res) => {
  try {
    const q = (req.query.q as string | undefined) ?? '';
    const limit = Number(req.query.limit) || 20;
    const results = VietnamAddressService.search(q, limit);
    return res.json({ data: results });
  } catch (e) {
    return res.status(500).json({ error: e instanceof Error ? e.message : 'Lỗi hệ thống' });
  }
});

// ==========================================
// Private routes: So dia chi ca nhan cua user (Yeu cau dang nhap)
// ==========================================
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

