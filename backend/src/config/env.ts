import 'dotenv/config';

// Doc cau hinh tu bien moi truong (.env). Khong hardcode secret trong code.
export const env = {
  port: Number(process.env.PORT ?? 5000),
  supabaseUrl: process.env.SUPABASE_URL ?? '',
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || '',
  supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY ?? '',
  vnpay: {
    // Secret thanh toan bat buoc cau hinh qua bien moi truong, khong hardcode gia tri that.
    tmnCode: process.env.VNPAY_TMN_CODE ?? '',
    hashSecret: process.env.VNPAY_HASH_SECRET ?? '',
    // Cac URL cong khai (khong phai secret) nen giu mac defaults sandbox/localhost cho tien.
    url: process.env.VNPAY_URL || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
    returnUrl: process.env.VNPAY_RETURN_URL || 'http://localhost:5000/api/v1/payments/vnpay/return',
  },
};
