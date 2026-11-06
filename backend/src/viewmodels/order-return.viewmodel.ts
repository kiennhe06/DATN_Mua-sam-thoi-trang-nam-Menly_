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
    }
  ): Promise<OrderReturnRow | null> {
    return this.model.updateStatus(id, payload);
  }
}
