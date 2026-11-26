import {
  OrderReturnModel,
  type CreateOrderReturnInput,
  type OrderReturnRow,
} from '../models/order-return.model.js';

// Lop xu ly nghiep vu cho: Tra hang
export class OrderReturnViewModel {
  private model = new OrderReturnModel();

  async create(input: CreateOrderReturnInput): Promise<OrderReturnRow> {
    return this.model.createReturnRequest(input);
  }

  async listByUser(userId: string): Promise<OrderReturnRow[]> {
    return this.model.findByUser(userId);
  }

  async listAll(): Promise<OrderReturnRow[]> {
    return this.model.listAll();
  }

  async updateStatus(
    id: string,
    payload: {
      status: string;
      rejectionReason?: string | null;
      adminResolutionNote?: string | null;
      restock?: boolean;
      actorId?: string;
    }
  ): Promise<OrderReturnRow | null> {
    // Khong co gi them o day: luat nghiep vu nam trong model de hai duong
    // (nhan vien va quan tri) deu di qua cung mot cho.
    return this.model.updateStatus(id, payload);
  }
}
