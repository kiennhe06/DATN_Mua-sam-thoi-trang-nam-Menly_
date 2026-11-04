import { OrderModel, type CreateOrderInput, type OrderRow } from '../models/order.model.js';

// Lop xu ly nghiep vu cho: Dat hang
export class OrderViewModel {
  private model = new OrderModel();

  /** Lay danh sach don hang cua user */
  async getOrders(userId: string): Promise<OrderRow[]> {
    return this.model.getOrdersByUser(userId);
  }

  /** Tao don hang moi */
  async createOrder(input: CreateOrderInput): Promise<OrderRow> {
    if (!input.ship_name?.trim()) throw new Error('Vui lòng nhập tên người nhận');
    if (!input.ship_phone?.trim()) throw new Error('Vui lòng nhập số điện thoại');
    if (!input.ship_address?.trim()) throw new Error('Vui lòng nhập địa chỉ giao hàng');
    if (!input.items?.length) throw new Error('Đơn hàng không có sản phẩm');
    return this.model.createOrder(input);
  }

  /** Tra cuu don hang cho khach hang thuong theo ma don hoac SDT */
  async trackPublicOrder(input: { code?: string; phone?: string }): Promise<OrderRow | null> {
    const code = input.code?.trim();
    const phone = input.phone?.trim();
    if (!code && !phone) return null;
    return this.model.findPublicOrderByCodeOrPhone(code, phone);
  }

  /** Lay chi tiet 1 don hang */
  async getOrderById(orderId: string, userId: string): Promise<OrderRow | null> {
    return this.model.getOrderById(orderId, userId);
  }

  /** Huy don hang */
  async cancelOrder(orderId: string, userId: string, reason: string): Promise<OrderRow> {
    return this.model.cancelOrder(orderId, userId, reason);
  }
}
