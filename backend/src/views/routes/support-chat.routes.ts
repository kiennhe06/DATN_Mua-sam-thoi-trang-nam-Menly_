import { Router } from 'express';
import { requireAuth, requireStaffOrAdmin } from '../../middlewares/auth.js';
import {
  SupportChatError,
  SupportChatModel,
  type SupportRole,
} from '../../models/support-chat.model.js';

const router = Router();
const model = new SupportChatModel();
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function handleChatError(error: unknown, res: import('express').Response, next: import('express').NextFunction) {
  if (error instanceof SupportChatError) {
    return res.status(error.statusCode).json({ error: error.message });
  }
  return next(error);
}

function isStaffRole(role: string): role is 'staff' | 'admin' {
  return role === 'staff' || role === 'admin';
}

function parseConversationId(value: string): string | null {
  return uuidPattern.test(value) ? value : null;
}

router.get('/mine', requireAuth, async (req, res, next) => {
  try {
    const data = await model.getOrCreateOpenConversation(req.user!.id);
    return res.json({ data });
  } catch (error) {
    return handleChatError(error, res, next);
  }
});

router.get('/staff/conversations', requireStaffOrAdmin, async (_req, res, next) => {
  try {
    return res.json({ data: await model.listOpenConversations() });
  } catch (error) {
    return handleChatError(error, res, next);
  }
});

router.get('/:id/messages', requireAuth, async (req, res, next) => {
  const conversationId = parseConversationId(req.params.id);
  if (!conversationId) return res.status(400).json({ error: 'Mã hội thoại không hợp lệ' });

  try {
    await model.assertCanAccess(conversationId, req.user!.id, req.user!.role);
    const data = await model.listMessages(conversationId);
    await model.markRead(conversationId, req.user!.id, req.user!.role);
    return res.json({ data });
  } catch (error) {
    return handleChatError(error, res, next);
  }
});

router.post('/:id/messages', requireAuth, async (req, res, next) => {
  const conversationId = parseConversationId(req.params.id);
  if (!conversationId) return res.status(400).json({ error: 'Mã hội thoại không hợp lệ' });

  const content = typeof req.body?.content === 'string' ? req.body.content.trim() : '';
  if (!content || content.length > 2000) {
    return res.status(400).json({ error: 'Tin nhắn phải có từ 1 đến 2000 ký tự' });
  }

  try {
    const conversation = await model.assertCanAccess(conversationId, req.user!.id, req.user!.role);
    if (conversation.status !== 'open') {
      return res.status(409).json({ error: 'Hội thoại đã đóng, không thể gửi tin nhắn' });
    }

    const role: SupportRole = isStaffRole(req.user!.role) ? req.user!.role : 'customer';
    const data = await model.sendMessage(conversationId, req.user!.id, role, content);
    return res.status(201).json({ data });
  } catch (error) {
    return handleChatError(error, res, next);
  }
});

export default router;
