import 'dotenv/config';

// Doc cau hinh tu bien moi truong (.env). Khong hardcode secret trong code.
const isProduction = (process.env.NODE_ENV ?? 'development') === 'production';

export const env = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  isProduction,
  port: Number(process.env.PORT ?? 5000),
  supabaseUrl: process.env.SUPABASE_URL ?? '',
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || '',
  supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY ?? '',
  // Che do dang nhap demo/local fallback (tai khoan mau, token demo-access/ui-preview).
  // Chi bat o moi truong khong phai production va co the tat tuong minh bang
  // DEMO_AUTH_ENABLED=false. Production luon tat de tranh backdoor.
  demoAuthEnabled: !isProduction && process.env.DEMO_AUTH_ENABLED !== 'false',
  vnpay: {
    // Secret thanh toan bat buoc cau hinh qua bien moi truong, khong hardcode gia tri that.
    tmnCode: process.env.VNPAY_TMN_CODE ?? '',
    hashSecret: process.env.VNPAY_HASH_SECRET ?? '',
    // Cac URL cong khai (khong phai secret) nen giu mac defaults sandbox/localhost cho tien.
    url: process.env.VNPAY_URL || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
    returnUrl: process.env.VNPAY_RETURN_URL || 'http://localhost:5000/api/v1/payments/vnpay/return',
  },
};
