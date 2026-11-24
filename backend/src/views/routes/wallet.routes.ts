import { Router } from 'express';
import { requireAuth } from '../../middlewares/auth.js';
import { WalletViewModel } from '../../viewmodels/wallet.viewmodel.js';

const router = Router();
const vm = new WalletViewModel();

router.use(requireAuth);

router.get('/', async (req, res, next) => {
  try {
    return res.json({ data: await vm.getForUser(req.user!.id) });
  } catch (error) {
    return next(error);
  }
});

export default router;
