import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, requireStaffOrAdmin } from '../../middlewares/auth.js';
import {
  SupportChatError,
  SupportChatModel,
  type SupportRole,
} from '../../models/support-chat.model.js';
import {
  docDangSoan,
  ghiDangSoan,
  xoaDangSoan,
  type BenGui,
} from '../../services/support-typing.store.js';

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

/** Nguoi dang goi la ben khach hay ben shop, dung cho trang thai dang soan. */
function benGuiCua(role: string): BenGui {
  return isStaffRole(role) ? 'staff' : 'customer';
}

/**
 * Tham so phan doan cho duong lay tin nhan.
 *
 * 'tuMoc' de vong lam moi chi keo ve tin moi, 'truocMoc' de bam xem tin cu hon.
 * Mac dinh 50 tin la vua mot man hinh, toi da 200 de khong ai keo ve ca hoi
 * thoai bang mot cu goi.
 */
const thamSoTinNhanSchema = z.object({
  tuMoc: z.string().datetime({ offset: true }).optional(),
  truocMoc: z.string().datetime({ offset: true }).optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
});

function parseConversationId(value: string): string | null {
  return uuidPattern.test(value) ? value : null;
}

/**
 * Danh dau da doc o nen. Nguoi dung khong can doi hai cau UPDATE nay xong moi
 * thay tin nhan, nen khong await de khoi cong them do tre vao moi lan tai.
 */
function danhDauDaDocNen(
  conversation: Parameters<SupportChatModel['markReadIfNeeded']>[0],
  userId: string,
  role: string
): void {
  void model.markReadIfNeeded(conversation, userId, role).catch((error) => {
    console.error('Khong danh dau duoc tin nhan da doc:', error);
  });
}

// Tra ve ca hoi thoai lan tin nhan trong mot lan goi. Truoc day man chat phai
// goi /mine roi moi goi /:id/messages, hai request noi duoi nhau nen moi lan mo
// man la cong them mot vong di ve mang.
router.get('/mine', requireAuth, async (req, res, next) => {
  try {
    const conversation = await model.getOrCreateOpenConversation(req.user!.id);
    // Chi lay cac tin moi nhat; tin cu hon doi nguoi dung bam xem them.
    const messages = await model.listMessages(conversation.id, { limit: 50 });
    danhDauDaDocNen(conversation, req.user!.id, req.user!.role);
    return res.json({
      data: { ...conversation, messages },
      typing: docDangSoan(conversation.id),
      conTinCu: messages.length === 50,
    });
  } catch (error) {
    return handleChatError(error, res, next);
  }
});

router.get('/staff/conversations', requireStaffOrAdmin, async (_req, res, next) => {
  try {
    const conversations = await model.listOpenConversations();
    // Kem luon trang thai go phim de danh sach ben trai hien duoc "dang soan"
    // ma khong phai goi them mot vong nua.
    return res.json({
      data: conversations.map((conversation) => ({
        ...conversation,
        typing: docDangSoan(conversation.id),
      })),
    });
  } catch (error) {
    return handleChatError(error, res, next);
  }
});

router.get('/:id/messages', requireAuth, async (req, res, next) => {
  const conversationId = parseConversationId(req.params.id);
  if (!conversationId) return res.status(400).json({ error: 'Mã hội thoại không hợp lệ' });

  const thamSo = thamSoTinNhanSchema.safeParse(req.query);
  if (!thamSo.success) {
    return res.status(400).json({ error: 'Tham số lấy tin nhắn không hợp lệ' });
  }

  try {
    const conversation = await model.assertCanAccess(conversationId, req.user!.id, req.user!.role);
    const data = await model.listMessages(conversationId, thamSo.data);
    danhDauDaDocNen(conversation, req.user!.id, req.user!.role);
    return res.json({
      data,
      typing: docDangSoan(conversationId),
      // Tra ve du so da xin nghia la nhieu kha nang con tin cu hon nua.
      conTinCu: !thamSo.data.tuMoc && data.length === thamSo.data.limit,
    });
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
    // Gui xong thi khong con dang go nua, xoa ngay de doi phuong khong thay
    // dong "dang soan" treo lai sau khi tin da hien.
    xoaDangSoan(conversationId, benGuiCua(req.user!.role));
    return res.status(201).json({ data });
  } catch (error) {
    return handleChatError(error, res, next);
  }
});

/**
 * Ket thuc mot hoi thoai. Chi nhan vien va quan tri duoc lam.
 *
 * Tin nhan van giu nguyen trong database, hoi thoai chi roi khoi danh sach
 * dang mo.
 */
router.patch('/:id/close', requireStaffOrAdmin, async (req, res, next) => {
  const conversationId = parseConversationId(req.params.id);
  if (!conversationId) return res.status(400).json({ error: 'Mã hội thoại không hợp lệ' });

  try {
    await model.assertCanAccess(conversationId, req.user!.id, req.user!.role);
    await model.closeConversation(conversationId);
    return res.json({ data: { id: conversationId, status: 'closed' } });
  } catch (error) {
    return handleChatError(error, res, next);
  }
});

/**
 * Bao rang minh dang go phim trong hoi thoai nay.
 *
 * Khong tra ve du lieu gi, phia goi cung khong can doi. Cot de ben kia thay
 * dong "dang soan" o lan tu lam moi ke tiep.
 */
router.post('/:id/typing', requireAuth, async (req, res, next) => {
  const conversationId = parseConversationId(req.params.id);
  if (!conversationId) return res.status(400).json({ error: 'Mã hội thoại không hợp lệ' });

  try {
    await model.assertCanAccess(conversationId, req.user!.id, req.user!.role);
    ghiDangSoan(conversationId, benGuiCua(req.user!.role));
    return res.status(204).end();
  } catch (error) {
    return handleChatError(error, res, next);
  }
});

export default router;
