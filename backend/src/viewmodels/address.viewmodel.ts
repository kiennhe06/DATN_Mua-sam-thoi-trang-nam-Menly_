import { AddressModel, type AddressRow } from '../models/address.model.js';

// Lop xu ly nghiep vu cho: So dia chi
export class AddressViewModel {
  private model = new AddressModel();

  async list(userId: string): Promise<AddressRow[]> {
    return this.model.findByUser(userId);
  }

  async create(userId: string, body: Omit<AddressRow, 'id' | 'user_id' | 'created_at'>): Promise<AddressRow> {
    if (!body.full_name?.trim()) throw new Error('Vui lòng nhập tên người nhận');
    if (!body.phone?.trim()) throw new Error('Vui lòng nhập số điện thoại');
    if (!body.province?.trim()) throw new Error('Vui lòng nhập tỉnh/thành phố');
    if (!body.detail?.trim()) throw new Error('Vui lòng nhập địa chỉ chi tiết');
    return this.model.create(userId, body);
  }

  async update(id: string, userId: string, body: Partial<AddressRow>): Promise<AddressRow> {
    return this.model.update(id, userId, body);
  }

  async delete(id: string, userId: string): Promise<void> {
    return this.model.delete(id, userId);
  }

  async setDefault(id: string, userId: string): Promise<AddressRow> {
    return this.model.setDefault(id, userId);
  }
}
