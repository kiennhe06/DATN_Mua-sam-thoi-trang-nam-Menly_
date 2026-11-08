import { GoogleGenAI } from '@google/genai';
import { env } from '../../config/env.js';
import { MENLY_SYSTEM_PROMPT } from './gemini.prompt.js';
import { REAL_MENLY_PRODUCTS, RealProductItem } from './real-products.js';

export interface ChatHistoryItem {
  role: 'user' | 'model';
  content: string;
}

export interface SuggestedProductItem {
  id: string;
  name: string;
  price: number;
  thumbnailUrl: string | null;
  slug: string;
}

export interface StylistResponse {
  reply: string;
  suggestedProducts: SuggestedProductItem[];
}

let aiClient: GoogleGenAI | null = null;

function getAiClient(): GoogleGenAI | null {
  const apiKey = env.GEMINI_API_KEY || process.env.GEMINI_API_KEY;
  if (!apiKey) return null;
  if (!aiClient) {
    aiClient = new GoogleGenAI({ apiKey });
  }
  return aiClient;
}

function cleanPlainChatText(text: string): string {
  return text
    .replace(/\*\*(.*?)\*\*/g, '$1')
    .replace(/\*(.*?)\*/g, '$1')
    .replace(/^#+\s*/gm, '')
    .replace(/\[Mã:\s*[^\]]+\]/gi, '')
    .replace(/[ ]{2,}/g, ' ')
    .trim();
}

/**
 * Tra cứu sản phẩm thật trong catalog dự án Menly theo slug, id hoặc tên
 */
function findRealProduct(identifier: string): RealProductItem | undefined {
  const query = identifier.trim().toLowerCase();

  // 1. Khớp chính xác theo slug
  let found = REAL_MENLY_PRODUCTS.find((p) => p.slug.toLowerCase() === query);
  if (found) return found;

  // 2. Khớp chính xác theo ID (UUID)
  found = REAL_MENLY_PRODUCTS.find((p) => p.id.toLowerCase() === query);
  if (found) return found;

  // 3. Khớp tương đối qua tên hoặc slug không dấu
  const normalizedQuery = query.replace(/[^a-z0-9]/g, '');
  found = REAL_MENLY_PRODUCTS.find(
    (p) =>
      p.slug.replace(/[^a-z0-9]/g, '').includes(normalizedQuery) ||
      p.name.toLowerCase().includes(query)
  );

  return found;
}

/**
 * Tìm kiếm thông tin chi tiết sản phẩm thật theo danh sách mã/slug
 */
function findProductsByIds(identifiers: string[]): SuggestedProductItem[] {
  const result: SuggestedProductItem[] = [];
  const seenIds = new Set<string>();

  for (const rawCode of identifiers) {
    const code = rawCode.trim();
    if (!code) continue;

    const product = findRealProduct(code);
    if (product && !seenIds.has(product.id)) {
      seenIds.add(product.id);
      result.push({
        id: product.id,
        name: product.name,
        price: product.price,
        thumbnailUrl: product.thumbnailUrl || null,
        slug: product.slug,
      });
    }
  }

  return result;
}

/**
 * Fallback thông minh: Chọn đúng combo sản phẩm thật từ kho Menly khi AI không đính kèm tag
 */
function fallbackSuggestedProducts(userMessage: string, aiReply: string): SuggestedProductItem[] {
  const text = (userMessage + ' ' + aiReply).toLowerCase();
  const sampleSlugs: string[] = [];

  if (text.includes('tiệc') || text.includes('hẹn hò') || text.includes('sang trọng')) {
    sampleSlugs.push('ao-so-mi-tay-dai-den', 'quan-tay-di-tiec', 'ao-blazer-xam');
  } else if (text.includes('công sở') || text.includes('đi làm') || text.includes('sơ mi')) {
    sampleSlugs.push('ao-so-mi-oxford-xanh', 'quan-tay-cong-so-den', 'ao-khoac-blazer-cong-so');
  } else if (text.includes('đi chơi') || text.includes('dạo phố') || text.includes('polo')) {
    sampleSlugs.push('ao-polo-pique', 'quan-jeans-slimfit', 'ao-khoac-bomber');
  } else if (text.includes('hè') || text.includes('mát') || text.includes('du lịch')) {
    sampleSlugs.push('ao-so-mi-linen-be', 'quan-kaki-xanh-reu', 'ao-khoac-gio-the-thao');
  } else if (text.includes('đông') || text.includes('lạnh') || text.includes('ấm')) {
    sampleSlugs.push('ao-so-mi-flannel-ke-soc', 'quan-jeans-den-skinny', 'ao-khoac-phao-mua-dong');
  }

  return sampleSlugs.length > 0 ? findProductsByIds(sampleSlugs) : [];
}

/**
 * Gọi Gemini AI tư vấn phong cách & kèm sản phẩm thật của Menly
 */
export async function askMenlyStylistWithProducts(
  userMessage: string,
  history: ChatHistoryItem[] = []
): Promise<StylistResponse> {
  const client = getAiClient();
  if (!client) {
    return {
      reply: 'Dạ hiện tại kênh AI tư vấn đang tạm ngắt kết nối cấu hình khóa API. Anh vui lòng thử lại sau nhé!',
      suggestedProducts: [],
    };
  }

  try {
    const recentHistory = history.slice(-10).map((item) => ({
      role: item.role === 'model' ? 'model' : 'user',
      parts: [{ text: item.content }],
    }));

    const chat = client.chats.create({
      model: 'gemini-3.5-flash-lite',
      config: {
        systemInstruction: MENLY_SYSTEM_PROMPT,
        temperature: 0.7,
      },
      history: recentHistory,
    });

    const result = await chat.sendMessage({ message: userMessage });
    let rawText = result.text || '';

    // Trích xuất cú pháp [GOI_Y: ao-so-mi-oxford-xanh, quan-tay-cong-so, ...]
    const tagMatch = rawText.match(/\[GOI_Y:\s*([^\]]+)\]/i);
    let suggestedProducts: SuggestedProductItem[] = [];

    if (tagMatch) {
      const rawCodes = tagMatch[1].split(',').map((s) => s.trim());
      suggestedProducts = findProductsByIds(rawCodes);
      // Xóa thẻ [GOI_Y: ...] khỏi câu trả lời hiển thị cho khách
      rawText = rawText.replace(/\[GOI_Y:\s*([^\]]+)\]/gi, '').trim();
    }

    // Nếu không có tag nhưng câu chuyện xoay quanh phối đồ, kích hoạt gợi ý thông minh
    if (suggestedProducts.length === 0) {
      suggestedProducts = fallbackSuggestedProducts(userMessage, rawText);
    }

    const cleanReply = cleanPlainChatText(rawText);

    return {
      reply: cleanReply || 'Dạ em có thể tư vấn mẫu phù hợp với vóc dáng của anh ngay ạ!',
      suggestedProducts,
    };
  } catch (error: any) {
    console.error('[GeminiService] Lỗi khi tạo câu trả lời:', error?.message || error);
    return {
      reply: 'Dạ hiện tại hệ thống tư vấn đang bận một chút, anh đợi em vài giây rồi thử nhắn lại giúp em nhé! 🙏',
      suggestedProducts: [],
    };
  }
}
