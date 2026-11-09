import { env } from './config/env.js';
import { batDauDonDonQuaHan } from './services/order-expiry.scheduler.js';
import { createApp } from './views/app.js';

createApp().listen(env.port, () => {
  console.log(`Server chay o http://localhost:${env.port}`);
  batDauDonDonQuaHan();
});
