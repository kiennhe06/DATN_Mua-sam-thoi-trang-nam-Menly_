import { supabase } from '../config/supabase.js';

// Lop truy cap du lieu cho: Banner
export class BannerModel {
  protected db = supabase;

  // Lay banner dang bat, sap theo thu tu
  async findActive() {
    const now = new Date().toISOString();
    const { data, error } = await this.db
      .from('banners')
      .select('*')
      .eq('is_active', true)
      .lte('start_date', now)
      .gte('end_date', now)
      .order('sort_order', { ascending: true });
    if (error) throw new Error(error.message);
    return data;
  }
}
