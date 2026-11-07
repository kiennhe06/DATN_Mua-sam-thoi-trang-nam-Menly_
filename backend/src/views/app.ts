import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { errorHandler } from '../middlewares/error-handler.js';
import authRoutes from './routes/auth.routes.js';
import profileRoutes from './routes/profile.routes.js';
import categoryRoutes from './routes/category.routes.js';
import productRoutes from './routes/product.routes.js';
import productShareRoutes from './routes/product-share.routes.js';
import cartRoutes from './routes/cart.routes.js';
import orderRoutes from './routes/order.routes.js';
import paymentRoutes from './routes/payment.routes.js';
import voucherRoutes from './routes/voucher.routes.js';
import wishlistRoutes from './routes/wishlist.routes.js';
import reviewRoutes from './routes/review.routes.js';
import notificationRoutes from './routes/notification.routes.js';
import addressRoutes from './routes/address.routes.js';
import order_returnRoutes from './routes/order-return.routes.js';
import bannerRoutes from './routes/banner.routes.js';
import adminRoutes from './routes/admin.routes.js';

export function createApp() {
  const app = express();
  app.use(helmet());
  app.use(cors());
  app.use(express.json());

  // Kiem tra may chu song hay khong
  app.get('/api/v1/health', (_req, res) => res.json({ ok: true }));

  app.use('/api/v1/auth', authRoutes);
  app.use('/api/v1/profile', profileRoutes);
  app.use('/api/v1/categories', categoryRoutes);
  app.use('/api/v1/products', productRoutes);
  app.use('/san-pham', productShareRoutes);
  app.use('/api/v1/cart', cartRoutes);
  app.use('/api/v1/orders', orderRoutes);
  app.use('/api/v1/payments', paymentRoutes);
  app.use('/api/v1/vouchers', voucherRoutes);
  app.use('/api/v1/wishlist', wishlistRoutes);
  app.use('/api/v1/reviews', reviewRoutes);
  app.use('/api/v1/notifications', notificationRoutes);
  app.use('/api/v1/addresses', addressRoutes);
  app.use('/api/v1/order-returns', order_returnRoutes);
  app.use('/api/v1/banners', bannerRoutes);
  app.use('/api/v1/admin', adminRoutes);

  app.use(errorHandler);
  return app;
}
