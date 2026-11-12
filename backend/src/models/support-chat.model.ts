import { supabase } from '../config/supabase.js';

export type SupportRole = 'customer' | 'staff' | 'admin';

export interface SupportConversation {
  id: string;
  user_id: string;
  assigned_staff_id: string | null;
  status: 'open' | 'closed';
  last_message: string | null;
  last_message_at: string;
  unread_user_count: number;
  unread_staff_count: number;
  created_at: string;
  customer?: {
    full_name: string | null;
    email: string | null;
  };
}

export interface SupportMessage {
  id: string;
  conversation_id: string;
  sender_id: string;
  sender_role: SupportRole;
  content: string;
  is_read: boolean;
  created_at: string;
}

export class SupportChatError extends Error {
  constructor(
    message: string,
    readonly statusCode: number,
  ) {
    super(message);
    this.name = 'SupportChatError';
  }
}

export class SupportChatModel {
  protected db = supabase;

  async getOrCreateOpenConversation(userId: string): Promise<SupportConversation> {
    const { data: existing, error: findError } = await this.db
      .from('support_conversations')
      .select('*')
      .eq('user_id', userId)
      .eq('status', 'open')
      .maybeSingle();

    if (findError) throw new Error(findError.message);
    if (existing) return existing as SupportConversation;

    const { data: created, error: createError } = await this.db
      .from('support_conversations')
      .insert({ user_id: userId })
      .select('*')
      .single();

    if (!createError && created) return created as SupportConversation;

    // Another request may have created this user's open conversation concurrently.
    const { data: concurrent, error: retryError } = await this.db
      .from('support_conversations')
      .select('*')
      .eq('user_id', userId)
      .eq('status', 'open')
      .maybeSingle();

    if (retryError || !concurrent) {
      throw new Error(createError?.message ?? retryError?.message ?? 'Không thể tạo hội thoại CSKH');
    }
    return concurrent as SupportConversation;
  }

  /**
   * Dong mot hoi thoai.
   *
   * Khong xoa tin nhan: lich su van con de tra cuu sau nay, chi la hoi thoai
   * khong con nam trong danh sach dang mo. Khach nhan tiep thi
   * getOrCreateOpenConversation se tu mo mot hoi thoai moi.
   */
  async closeConversation(conversationId: string): Promise<void> {
    const { error } = await this.db
      .from('support_conversations')
      .update({ status: 'closed' })
      .eq('id', conversationId);

    if (error) throw new Error(error.message);
  }

  async listOpenConversations(): Promise<SupportConversation[]> {
    const { data, error } = await this.db
      .from('support_conversations')
      .select('*')
      .eq('status', 'open')
      .order('last_message_at', { ascending: false })
      .limit(200);

    if (error) throw new Error(error.message);
    const conversations = (data ?? []) as SupportConversation[];
    if (conversations.length === 0) return conversations;

    const userIds = [...new Set(conversations.map((conversation) => conversation.user_id))];
    const { data: profiles, error: profileError } = await this.db
      .from('profiles')
      .select('id, full_name, email')
      .in('id', userIds);

    if (profileError) throw new Error(profileError.message);
    const profilesById = new Map((profiles ?? []).map((profile) => [profile.id, profile]));
    return conversations.map((conversation) => {
      const profile = profilesById.get(conversation.user_id);
      return {
        ...conversation,
        customer: {
          full_name: profile?.full_name ?? null,
          email: profile?.email ?? null,
        },
      };
    });
  }

  async assertCanAccess(conversationId: string, userId: string, role: string): Promise<SupportConversation> {
    const { data, error } = await this.db
      .from('support_conversations')
      .select('*')
      .eq('id', conversationId)
      .maybeSingle();

    if (error) throw new Error(error.message);
    if (!data) throw new SupportChatError('Không tìm thấy hội thoại CSKH', 404);

    const conversation = data as SupportConversation;
    const isStaff = role === 'staff' || role === 'admin';
    if (!isStaff && conversation.user_id !== userId) {
      throw new SupportChatError('Bạn không có quyền truy cập hội thoại này', 403);
    }
    return conversation;
  }

  /**
   * Lay tin nhan theo tung doan thay vi ca hoi thoai.
   *
   * Man chat tu lam moi 2 giay mot lan. Neu lan nao cung keo ve toan bo doan
   * chat thi hoi thoai cang dai, moi vong lam moi cang nang - 500 tin nhan moi
   * 2 giay la vo ly. Gio:
   *   - khong co moc    -> lay 'limit' tin moi nhat (man vua mo)
   *   - co 'tuMoc'      -> chi lay tin tu moc do tro di (vong lam moi)
   *   - co 'truocMoc'   -> lay tin cu hon moc do (bam "xem tin cu hon")
   *
   * Dung >= va <= chu khong phai > va < de khong bo sot tin trung dung mot
   * moc thoi gian; phia goi tu loai trung theo id.
   */
  async listMessages(
    conversationId: string,
    tuyChon: { tuMoc?: string; truocMoc?: string; limit?: number } = {},
  ): Promise<SupportMessage[]> {
    const limit = Math.min(Math.max(tuyChon.limit ?? 50, 1), 200);
    let truyVan = this.db
      .from('support_messages')
      .select('*')
      .eq('conversation_id', conversationId);

    if (tuyChon.tuMoc) {
      // Tin moi: lay xuoi tu moc tro di.
      truyVan = truyVan
        .gte('created_at', tuyChon.tuMoc)
        .order('created_at', { ascending: true })
        .limit(limit);
      const { data, error } = await truyVan;
      if (error) throw new Error(error.message);
      return (data ?? []) as SupportMessage[];
    }

    // Tin cu: lay nguoc tu moc lui ve, hoac lay nhung tin moi nhat khi chua co
    // moc nao. Ca hai deu phai dao lai cho dung thu tu thoi gian.
    if (tuyChon.truocMoc) {
      truyVan = truyVan.lte('created_at', tuyChon.truocMoc);
    }
    const { data, error } = await truyVan
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw new Error(error.message);
    return ((data ?? []) as SupportMessage[]).reverse();
  }

  async sendMessage(
    conversationId: string,
    senderId: string,
    senderRole: SupportRole,
    content: string,
  ): Promise<SupportMessage> {
    const { data, error } = await this.db
      .from('support_messages')
      .insert({
        conversation_id: conversationId,
        sender_id: senderId,
        sender_role: senderRole,
        content,
      })
      .select('*')
      .single();

    if (error) throw new Error(error.message);
    return data as SupportMessage;
  }

  /**
   * Danh dau da doc nhung chi khi that su con tin chua doc. Man chat tu tai lai
   * moi 5 giay, neu lan nao cung chay hai cau UPDATE thi phan lon la chay khong.
   * Tra ve true khi co ghi xuong database.
   */
  async markReadIfNeeded(
    conversation: SupportConversation,
    userId: string,
    role: string
  ): Promise<boolean> {
    const isStaff = role === 'staff' || role === 'admin';
    const chuaDoc = isStaff ? conversation.unread_staff_count : conversation.unread_user_count;
    if (!chuaDoc || chuaDoc <= 0) return false;
    await this.markRead(conversation.id, userId, role);
    return true;
  }

  async markRead(conversationId: string, userId: string, role: string): Promise<void> {
    const isStaff = role === 'staff' || role === 'admin';
    const { error: messageError } = await this.db
      .from('support_messages')
      .update({ is_read: true })
      .eq('conversation_id', conversationId)
      .neq('sender_id', userId)
      .eq('is_read', false);

    if (messageError) throw new Error(messageError.message);

    const { error: conversationError } = await this.db
      .from('support_conversations')
      .update(isStaff ? { unread_staff_count: 0 } : { unread_user_count: 0 })
      .eq('id', conversationId);

    if (conversationError) throw new Error(conversationError.message);
  }
}
