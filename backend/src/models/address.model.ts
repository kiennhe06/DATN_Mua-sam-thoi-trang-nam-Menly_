import { supabase } from '../config/supabase.js';

export interface AddressRow {
  id: string;
  user_id: string;
  full_name: string;
  phone: string;
  province: string;
  district: string;
  ward: string;
  detail: string;
  is_default: boolean;
  created_at?: string;
}

// Lop truy cap du lieu cho: So dia chi
export class AddressModel {
  protected db = supabase;

  async findByUser(userId: string): Promise<AddressRow[]> {
    const { data, error } = await this.db
      .from('addresses')
      .select('*')
      .eq('user_id', userId)
      .order('is_default', { ascending: false })
      .order('created_at', { ascending: false });
    if (error) throw new Error(error.message);
    return (data ?? []) as AddressRow[];
  }

  async create(userId: string, body: Omit<AddressRow, 'id' | 'user_id' | 'created_at'>): Promise<AddressRow> {
    // Nếu set làm mặc định, bỏ mặc định cũ trước
    if (body.is_default) {
      await this.db.from('addresses').update({ is_default: false }).eq('user_id', userId);
    }
    const { data, error } = await this.db
      .from('addresses')
      .insert({ ...body, user_id: userId })
      .select()
      .single();
    if (error || !data) throw new Error(error?.message ?? 'Không thể tạo địa chỉ');
    return data as AddressRow;
  }

  async update(id: string, userId: string, body: Partial<AddressRow>): Promise<AddressRow> {
    if (body.is_default) {
      await this.db.from('addresses').update({ is_default: false }).eq('user_id', userId);
    }
    const { data, error } = await this.db
      .from('addresses')
      .update(body)
      .eq('id', id)
      .eq('user_id', userId)
      .select()
      .single();
    if (error || !data) throw new Error(error?.message ?? 'Không tìm thấy địa chỉ');
    return data as AddressRow;
  }

  async delete(id: string, userId: string): Promise<void> {
    const { error } = await this.db
      .from('addresses')
      .delete()
      .eq('id', id)
      .eq('user_id', userId);
    if (error) throw new Error(error.message);
  }

  async setDefault(id: string, userId: string): Promise<AddressRow> {
    await this.db.from('addresses').update({ is_default: false }).eq('user_id', userId);
    const { data, error } = await this.db
      .from('addresses')
      .update({ is_default: true })
      .eq('id', id)
      .eq('user_id', userId)
      .select()
      .single();
    if (error || !data) throw new Error(error?.message ?? 'Không tìm thấy địa chỉ');
    return data as AddressRow;
  }
}
