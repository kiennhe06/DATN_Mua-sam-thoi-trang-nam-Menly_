import { Router } from 'express';
import {
  askMenlyStylistWithProducts,
  type ChatHistoryItem,
} from '../../services/gemini/gemini.service.js';

const router = Router();

// POST /api/v1/ai-chat/message
// Nhan tin nhan tu nguoi dung, goi Gemini AI voi MENLY_SYSTEM_PROMPT va tra ve cau tra loi kem san pham goi y
router.post('/message', async (req, res, next) => {
  const message = typeof req.body?.message === 'string' ? req.body.message.trim() : '';
  if (!message) {
    return res.status(400).json({ error: 'Nội dung tin nhắn không được để trống' });
  }

  const rawHistory = Array.isArray(req.body?.history) ? req.body.history : [];
  const history: ChatHistoryItem[] = rawHistory
    .filter(
      (item: any) =>
        item &&
        (item.role === 'user' || item.role === 'model') &&
        typeof item.content === 'string'
    )
    .map((item: any) => ({
      role: item.role,
      content: String(item.content).trim(),
    }));

  try {
    const data = await askMenlyStylistWithProducts(message, history);
    return res.json({ data });
  } catch (error) {
    return next(error);
  }
});

export default router;

