import { supabase } from '../config/supabase.js';
import type { CalculateShippingFeeInput } from '../validators/shipping.validator.js';

export interface ShippingPolicy {
  standardBaseFee: number;
  expressBaseFee: number;
  freeShippingThreshold: number;
  supportedMethods: Array<{
    id: 'standard' | 'express';
    name: string;
    description: string;
    baseFee: number;
  }>;
  provincesFastDelivery: string[];
}

export interface ShippingFeeCalculationResult {
  shippingFee: number;
  originalFee: number;
  discount: number;
  isFreeShipping: boolean;
  freeShippingThreshold: number;
  amountNeededForFreeShipping: number;
  shippingMethod: 'standard' | 'express';
  estimatedDays: string;
  note: string;
}

export const DEFAULT_SHIPPING_POLICY: ShippingPolicy = {
  standardBaseFee: 25000,
  expressBaseFee: 45000,
  freeShippingThreshold: 499000,
  supportedMethods: [
    {
      id: 'standard',
      name: 'Giao hàng tiêu chuẩn',
      description: 'Giao hàng tận nơi toàn quốc qua các đơn vị vận chuyển uy tín (GHN, GHTK, Viettel Post)',
      baseFee: 25000,
    },
    {
      id: 'express',
      name: 'Giao hàng hỏa tốc',
      description: 'Nhận hàng nhanh trong ngày hoặc tối đa 24h đối với khu vực nội thành',
      baseFee: 45000,
    },
  ],
  provincesFastDelivery: [
    'hà nội',
    'ha noi',
    'hồ chí minh',
    'ho chi minh',
    'tphcm',
    'sài gòn',
    'đà nẵng',
    'da nang',
  ],
};

export class OrderModel {
  protected db = supabase;

  /**
   * Lấy thông tin chính sách vận chuyển của shop
   */
  getShippingPolicy(): ShippingPolicy {
    return DEFAULT_SHIPPING_POLICY;
  }

  /**
   * Tính toán phí giao hàng (MC-DH3: Phí ship đồng giá hoặc Miễn phí Freeship)
   */
  calculateShippingFee(input: CalculateShippingFeeInput): ShippingFeeCalculationResult {
    const { subtotal, province = '', shippingMethod = 'standard', voucherCode = '' } = input;
    const policy = this.getShippingPolicy();

    const normalizedProvince = province.trim().toLowerCase();
    const isMajorCity = policy.provincesFastDelivery.some((city) =>
      normalizedProvince.includes(city)
    );

    // Xác định phí gốc dựa theo phương thức vận chuyển
    const originalFee = shippingMethod === 'express' ? policy.expressBaseFee : policy.standardBaseFee;

    // Kiểm tra điều kiện Freeship:
    // 1. Đơn hàng đạt giá trị tối thiểu (>= 499.000 VNĐ)
    // 2. Hoặc người dùng áp dụng mã Freeship hợp lệ (chứa 'FREESHIP' hoặc bắt đầu bằng 'FS')
    const isEligibleBySubtotal = subtotal >= policy.freeShippingThreshold;
    const normalizedVoucher = voucherCode.trim().toUpperCase();
    const isEligibleByVoucher =
      normalizedVoucher.includes('FREESHIP') || normalizedVoucher.startsWith('FS');

    const isFreeShipping = isEligibleBySubtotal || isEligibleByVoucher;

    let discount = 0;
    let shippingFee = originalFee;

    if (shippingMethod === 'standard') {
      if (isFreeShipping) {
        discount = originalFee;
        shippingFee = 0;
      }
    } else {
      // Đối với đơn Hỏa tốc, nếu đủ điều kiện freeship sẽ được trừ phí ship chuẩn (25.000đ)
      if (isFreeShipping) {
        discount = policy.standardBaseFee;
        shippingFee = Math.max(0, originalFee - discount);
      }
    }

    // Tính số tiền cần mua thêm để được Freeship (nếu chưa đạt)
    const amountNeededForFreeShipping = isFreeShipping
      ? 0
      : Math.max(0, policy.freeShippingThreshold - subtotal);

    // Dự kiến thời gian giao hàng
    let estimatedDays: string;
    if (shippingMethod === 'express') {
      estimatedDays = isMajorCity ? 'Trong ngày (4-8 giờ)' : '1–2 ngày';
    } else {
      estimatedDays = isMajorCity ? '1–2 ngày làm việc' : '2–4 ngày làm việc';
    }

    // Lời nhắn ghi chú hiển thị cho khách hàng
    let note = '';
    if (isFreeShipping) {
      if (isEligibleByVoucher) {
        note = `Bạn được miễn phí vận chuyển nhờ mã giảm giá ${normalizedVoucher}!`;
      } else {
        note = `Đơn hàng từ ${policy.freeShippingThreshold.toLocaleString('vi-VN')} đ được miễn phí vận chuyển toàn quốc!`;
      }
    } else {
      note = `Mua thêm ${amountNeededForFreeShipping.toLocaleString('vi-VN')} đ để được MIỄN PHÍ VẬN CHUYỂN toàn quốc!`;
    }

    return {
      shippingFee,
      originalFee,
      discount,
      isFreeShipping,
      freeShippingThreshold: policy.freeShippingThreshold,
      amountNeededForFreeShipping,
      shippingMethod,
      estimatedDays,
      note,
    };
  }
}
