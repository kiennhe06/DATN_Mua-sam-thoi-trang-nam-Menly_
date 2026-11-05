import { supabase } from '../config/supabase.js';

export interface NotificationRow {
  id: string;
  user_id: string;
  title: string;
  body: string;
  type: string;
  is_read: boolean;
  data?: Record<string, unknown>;
  created_at: string;
}

// Lop truy cap du lieu cho: Thong bao
export class NotificationModel {
  protected db = supabase;

  async findByUser(userId: string): Promise<NotificationRow[]> {
    const { data, error } = await this.db
      .from('notifications')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(50);
    if (error) throw new Error(error.message);
    return (data ?? []) as NotificationRow[];
  }

  async markRead(id: string, userId: string): Promise<void> {
    await this.db
      .from('notifications')
      .update({ is_read: true })
      .eq('id', id)
      .eq('user_id', userId);
  }

  async markAllRead(userId: string): Promise<void> {
    await this.db
      .from('notifications')
      .update({ is_read: true })
      .eq('user_id', userId)
      .eq('is_read', false);
  }

  async delete(id: string, userId: string): Promise<void> {
    await this.db
      .from('notifications')
      .delete()
      .eq('id', id)
      .eq('user_id', userId);
  }
}
