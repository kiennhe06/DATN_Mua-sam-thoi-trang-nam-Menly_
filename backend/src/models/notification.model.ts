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

export interface CreateNotificationInput {
  userId?: string;
  title: string;
  body: string;
  type?: 'order' | 'promo' | 'system';
  data?: Record<string, unknown>;
}

// Lop truy cap du lieu cho: Thong bao
export class NotificationModel {
  protected db = supabase;

  async createNotification(input: CreateNotificationInput): Promise<NotificationRow[]> {
    const title = input.title?.trim();
    const body = input.body?.trim();

    if (!title || !body) {
      throw new Error('Tiêu đề và nội dung thông báo không được để trống');
    }

    const type = input.type ?? 'promo';
    const data = input.data ?? {};

    if (input.userId) {
      const { data: inserted, error } = await this.db
        .from('notifications')
        .insert({
          user_id: input.userId,
          title,
          body,
          type,
          data,
        })
        .select()
        .single();

      if (error) throw new Error(error.message);
      return [inserted as NotificationRow];
    }

    const { data: users, error: profileError } = await this.db
      .from('profiles')
      .select('id')
      .eq('is_active', true);

    if (profileError) throw new Error(profileError.message);

    const rows = (users ?? []).map((user) => ({
      user_id: user.id,
      title,
      body,
      type,
      data,
    }));

    if (rows.length === 0) {
      return [];
    }

    const { data: inserted, error } = await this.db
      .from('notifications')
      .insert(rows)
      .select();

    if (error) throw new Error(error.message);
    return (inserted ?? []) as NotificationRow[];
  }

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

  async countUnread(userId: string): Promise<number> {
    const { count, error } = await this.db
      .from('notifications')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_read', false);
    if (error) throw new Error(error.message);
    return count ?? 0;
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
