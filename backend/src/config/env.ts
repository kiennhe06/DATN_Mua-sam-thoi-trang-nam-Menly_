import 'dotenv/config';

/**
 * Doc mot so tien tu bien moi truong. Tra ve gia tri mac dinh khi bien trong,
 * khong phai so hoac so am, de mot dong .env go nham khong lam sap bang gia.
 */
export function docSoTien(bien: string | undefined, macDinh: number): number {
  // Number('') tra ve 0 chu khong phai NaN, nen phai loai chuoi rong truoc,
  // khong thi mot dong SHIPPING_STANDARD_FEE= bo trong se thanh phi 0 dong.
  const chuoi = (bien ?? '').trim();
  if (chuoi === '') return macDinh;
  const so = Number(chuoi);
  if (!Number.isFinite(so) || so < 0) return macDinh;
  return Math.round(so);
}

// Doc cau hinh tu bien moi truong (.env). Khong hardcode secret trong code.
export const env = {
  port: Number(process.env.PORT ?? 5000),
  supabaseUrl: process.env.SUPABASE_URL ?? '',
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || '',
  supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY ?? '',
  GEMINI_API_KEY: process.env.GEMINI_API_KEY ?? '',
  vnpay: {
    // Secret thanh toan bat buoc cau hinh qua bien moi truong, khong hardcode gia tri that.
    tmnCode: process.env.VNPAY_TMN_CODE ?? '',
    hashSecret: process.env.VNPAY_HASH_SECRET ?? '',
    // Cac URL cong khai (khong phai secret) nen giu mac defaults sandbox/localhost cho tien.
    url: process.env.VNPAY_URL || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
    returnUrl: process.env.VNPAY_RETURN_URL || 'http://localhost:5000/api/v1/payments/vnpay/return',
  },
  // Bang gia giao hang. Doi gia chi can sua .env roi khoi dong lai may chu,
  // khong phai sua code va cung khong phai phat hanh lai app: ca app lan web
  // admin deu doc bang gia nay qua API /orders/shipping-policy.
  shipping: {
    standardBaseFee: docSoTien(process.env.SHIPPING_STANDARD_FEE, 25000),
    expressBaseFee: docSoTien(process.env.SHIPPING_EXPRESS_FEE, 45000),
    freeShippingThreshold: docSoTien(process.env.SHIPPING_FREE_THRESHOLD, 399000),
  },
};
