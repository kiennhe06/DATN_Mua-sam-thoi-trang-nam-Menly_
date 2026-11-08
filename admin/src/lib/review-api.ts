export interface Review {
  id: string;
  userId: string;
  productId: string;
  rating: number;
  comment: string | null;
  /** Anh thuc te khach gui kem danh gia. */
  images?: string[];
  /** Noi dung cua hang tra loi, null neu chua tra loi. */
  replyComment?: string | null;
  replyAt?: string | null;
  createdAt: string;
  user?: {
    id: string;
    email: string;
    name: string;
  };
}

export interface ReviewPageResult {
  items: Review[];
  pageInfo?: {
    limit: number;
    hasNext: boolean;
    nextCursor: string | null;
  };
}
import { adminFetch } from './api-client';

export async function fetchAdminReviews(page: number = 1, limit: number = 50): Promise<ReviewPageResult> {
  const data = await adminFetch<ReviewPageResult | { data?: ReviewPageResult }>(
    `/api/v1/admin/reviews?page=${page}&limit=${limit}`
  );
  if ('items' in data) return data;
  if ('data' in data && data.data) return data.data;
  return { items: [] };
}

export async function deleteAdminReview(id: string): Promise<void> {
  await adminFetch(`/api/v1/admin/reviews/${id}`, {
    method: 'DELETE',
  });
}

/** Tra loi mot danh gia cua khach (POST /api/v1/admin/reviews/:id/reply). */
export async function replyToAdminReview(id: string, reply: string): Promise<Review> {
  const res = await adminFetch<{ data?: Review } | Review>(
    `/api/v1/admin/reviews/${id}/reply`,
    {
      method: 'POST',
      body: JSON.stringify({ reply }),
    },
  );
  return (res as { data?: Review }).data ?? (res as Review);
}
