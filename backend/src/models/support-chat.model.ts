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

  async listMessages(conversationId: string): Promise<SupportMessage[]> {
    const { data, error } = await this.db
      .from('support_messages')
      .select('*')
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: true })
      .limit(500);

    if (error) throw new Error(error.message);
    return (data ?? []) as SupportMessage[];
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
