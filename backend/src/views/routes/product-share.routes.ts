import { Router } from 'express';
import { ProductViewModel } from '../../viewmodels/product.viewmodel.js';
import {
  renderProductNotFoundPage,
  renderProductSharePage,
} from '../pages/product-share.page.js';

// Trang san pham cong khai dung cho lien ket chia se.
const router = Router();
const vm = new ProductViewModel();

router.get('/:id', async (req, res) => {
  // Cho phep anh san pham tu Supabase/Unsplash nhung chan script la.
  res.setHeader(
    'Content-Security-Policy',
    "default-src 'self'; img-src * data:; style-src 'self' 'unsafe-inline'; script-src 'none'; base-uri 'self'; form-action 'self'",
  );

  const id = req.params.id;
  try {
    const product = await vm.getProductById(id);
    if (!product) {
      res.status(404).type('html').send(renderProductNotFoundPage());
      return;
    }

    const canonicalUrl = `${req.protocol}://${req.get('host')}/san-pham/${encodeURIComponent(id)}`;
    res.type('html').send(renderProductSharePage(product, canonicalUrl));
  } catch {
    res.status(404).type('html').send(renderProductNotFoundPage());
  }
});

export default router;
