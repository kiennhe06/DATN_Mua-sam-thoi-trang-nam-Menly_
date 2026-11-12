import type {
  Order,
  OrderStatus,
  Product,
  Category,
  InventoryMovement,
  AuditLog,
  UserAccount,
  Voucher,
  CreateVoucherInput,
} from './types';

import { adminFetch as apiFetch, getApiUrl } from './api-client';

// ========== HEALTH ==========
export async function checkServerHealth(): Promise<boolean> {
  try {
    const BASE = getApiUrl();
    const res = await fetch(`${BASE}/api/v1/health`, { method: 'GET' });
    return res.ok;
  } catch {
    return false;
  }
}

// ========== CATEGORIES ==========
export async function fetchCategories(): Promise<Category[]> {
  const data = await apiFetch<Category[] | { data?: Category[]; items?: Category[] }>(
    '/api/v1/categories',
  );
  if (Array.isArray(data)) return data;
  return data.data || data.items || [];
}

// ========== PRODUCTS ==========
// Backend tra ve snake_case (category_id, thumbnail_url...); admin dung camelCase.
// Chuan hoa de cac man hinh (dem/gom danh muc, hien thi) doc dung field. Dung any vi
// du lieu goc co the o ca hai dang snake/camel.
function normalizeProduct(p: any): Product {
  // Backend tra bien the o khoa snake_case `product_variants`; chuan hoa ve `variants`
  // (camelCase) de trang San pham / Kho tinh dung ton kho theo tung bien the.
  const rawVariants = p.variants ?? p.product_variants ?? [];
  const variants = Array.isArray(rawVariants)
    ? rawVariants.map((v: any) => ({
        id: v.id,
        productId: v.productId ?? v.product_id ?? p.id,
        size: v.size ?? '',
        color: v.color ?? '',
        sku: v.sku ?? '',
        stock: Number(v.stock ?? 0),
      }))
    : [];
  const rawImages = p.images ?? p.product_images ?? [];
  const images = Array.isArray(rawImages)
    ? rawImages
        .map((image: any, index: number) => ({
          id: image.id ?? '',
          productId: image.productId ?? image.product_id ?? p.id,
          url: typeof image === 'string' ? image : image.url,
          sortOrder: image.sortOrder ?? image.sort_order ?? index,
        }))
        .filter((image: { url?: string }) => Boolean(image.url))
    : [];

  return {
    ...p,
    id: p.id,
    categoryId: p.categoryId ?? p.category_id ?? '',
    name: p.name,
    slug: p.slug,
    description: p.description ?? null,
    price: Number(p.price ?? 0),
    thumbnailUrl: p.thumbnailUrl ?? p.thumbnail_url ?? null,
    categoryName: p.categoryName ?? p.category_name ?? p.categories?.name ?? '',
    images,
    isActive: p.isActive ?? p.is_active,
    approvalStatus: p.approvalStatus ?? p.approval_status,
    createdAt: p.createdAt ?? p.created_at,
    variants,
  };
}

export async function fetchAdminProducts(params?: {
  limit?: number;
  page?: number;
  categoryId?: string;
  search?: string;
}): Promise<{ items: Product[]; total: number }> {
  const query = new URLSearchParams();
  const effectiveLimit = params?.limit || 400;
  query.set('limit', String(effectiveLimit));
  if (params?.categoryId) query.set('categoryId', params.categoryId);
  if (params?.search) {
    query.set('q', params.search);
  }

  const qs = query.toString() ? `?${query.toString()}` : '';

  const data = await apiFetch<
    { items?: unknown[]; data?: unknown[]; total?: number; pageInfo?: { total?: number } } | unknown[]
  >(`/api/v1/admin/products${qs}`);
  const raw: unknown[] = Array.isArray(data) ? data : data.items || data.data || [];
  const items = raw.map((p) => normalizeProduct(p));
  const total = Array.isArray(data)
    ? items.length
    : data.total ?? data.pageInfo?.total ?? items.length;
  return { items, total };
}

export async function fetchProductDetail(id: string): Promise<Product | null> {
  const data = await apiFetch<any>(`/api/v1/admin/products/${id}`);
  const raw = data && data.data ? data.data : data;
  return raw && raw.id ? normalizeProduct(raw) : null;
}

/**
 * Du lieu gui len khi sua san pham. Khac voi Product o cho 'images' la danh sach
 * duong dan, dung dang may chu nhan chu khong phai dang doc ve.
 */
export type UpdateProductInput = Partial<
  Omit<Product, 'id' | 'createdAt' | 'variants' | 'images'>
> & {
  images?: string[];
  /**
   * Danh sach bien the day du sau khi sua. May chu doi chieu theo cap size +
   * mau: cap moi thi them, cap cu thi cap nhat, cap khong con trong danh sach
   * thi xoa (tru khi da tung co don hang).
   */
  variants?: Array<{ size: string; color: string; sku: string; stock: number }>;
};

export async function updateProduct(
  id: string,
  payload: UpdateProductInput
): Promise<Product> {
  const res = await apiFetch<any>(`/api/v1/admin/products/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
  return normalizeProduct(res && res.data ? res.data : res);
}

/** Duyet san pham de no hien trong ung dung. */
export async function approveProduct(id: string): Promise<Product> {
  const res = await apiFetch<any>(`/api/v1/admin/products/${id}/approve`, {
    method: 'PATCH',
  });
  return normalizeProduct(res && res.data ? res.data : res);
}

export async function deleteProduct(id: string): Promise<void> {
  await apiFetch<{ message: string }>(`/api/v1/admin/products/${id}`, {
    method: 'DELETE',
  });
}

export interface CreateProductInput {
  categoryId: string;
  name: string;
  description: string | null;
  price: number;
  thumbnailUrl: string | null;
  images: string[];
  /** May chu luon tao san pham o trang thai cho duyet nen truong nay chi de tuong thich. */
  isActive?: boolean;
  variants: Array<{
    size: string;
    color: string;
    sku: string;
    stock: number;
  }>;
}

export async function createAdminProduct(payload: CreateProductInput): Promise<Product> {
  const res = await apiFetch<any>('/api/v1/admin/products', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  return normalizeProduct(res && res.data ? res.data : res);
}

// ========== ORDERS ==========
export interface AdminOrderQuery {
  status?: string;
  limit?: number;
  /** Moc dau khoang, dang ISO. Tinh san theo mui gio may admin. */
  from?: string;
  /** Moc cuoi khoang, dang ISO, KHONG tinh vao ket qua. */
  to?: string;
}

export async function fetchAdminOrders(
  params?: AdminOrderQuery | OrderStatus | string
): Promise<Order[]> {
  const statusFilter =
    typeof params === 'string'
      ? params === 'all'
        ? undefined
        : params
      : params?.status === 'all'
      ? undefined
      : params?.status;

  const query = new URLSearchParams();
  if (statusFilter) query.set('status', statusFilter);
  if (typeof params === 'object') {
    if (params.limit) query.set('limit', String(params.limit));
    if (params.from) query.set('from', params.from);
    if (params.to) query.set('to', params.to);
  }
  const qs = query.toString() ? `?${query.toString()}` : '';

  const data = await apiFetch<any>(`/api/v1/admin/orders${qs}`);

  let rawList: any[] = [];
  if (Array.isArray(data)) {
    rawList = data;
  } else if (data && Array.isArray(data.items)) {
    rawList = data.items;
  } else if (data && Array.isArray(data.data)) {
    rawList = data.data;
  }

  // Giữ nguyên lỗi API để trang quản trị phân biệt lỗi tải với danh sách không có đơn.
  return rawList.map((o: any) => ({
      id: o.id || `ord-${Math.random()}`,
      code: o.code || 'MS000',
      userId: o.userId || o.user_id || '',
      status: (o.status || 'pending_payment') as OrderStatus,
      refunded: o.refunded === true,
      paymentMethod: o.paymentMethod || o.payment_method || 'cod',
      subtotal: Number(o.subtotal || 0),
      shippingFee: Number(o.shippingFee || o.shipping_fee || 0),
      total: Number(o.total || 0),
      shipName: o.shipName || o.ship_name || o.ship?.name || '',
      shipPhone: o.shipPhone || o.ship_phone || o.ship?.phone || '',
      shipAddress: o.shipAddress || o.ship_address || o.ship?.address || '',
      voucherCode: o.voucherCode || o.voucher_code || null,
      discountAmount: Number(o.discountAmount ?? o.discount_amount ?? 0),
      createdAt: o.createdAt || o.created_at || new Date().toISOString(),
      shippingAddress: {
        name: o.shippingAddress?.name || o.shipName || o.ship_name || o.ship?.name || '',
        phone: o.shippingAddress?.phone || o.shipPhone || o.ship_phone || o.ship?.phone || '',
        address: o.shippingAddress?.address || o.shipAddress || o.ship_address || o.ship?.address || '',
        note: o.shippingAddress?.note || o.note || '',
      },
      items: (o.items || o.order_items || []).map((it: any) => ({
        id: it.id || `oi-${Math.random()}`,
        orderId: it.orderId || it.order_id || o.id,
        variantId: it.variantId || it.variant_id || '',
        productName: it.productName || it.product_name || 'Sản phẩm',
        size: it.size || 'M',
        color: it.color || 'Trắng',
        unitPrice: Number(it.unitPrice ?? it.unit_price ?? it.price ?? 0),
        quantity: Number(it.quantity || 1),
      })),
  }));
}

export async function updateOrderStatus(
  orderId: string,
  status: OrderStatus,
  note?: string
): Promise<void> {
  await apiFetch(`/api/v1/admin/orders/${orderId}/status`, {
    method: 'PUT',
    body: JSON.stringify({ status, note: note || '' }),
  });
}

// ========== INVENTORY ==========
export async function fetchInventoryMovements(): Promise<InventoryMovement[]> {
  const data = await apiFetch<{ data: InventoryMovement[] } | InventoryMovement[]>(
    '/api/v1/admin/inventory/movements'
  );
  if (Array.isArray(data)) return data;
  return (data as { data: InventoryMovement[] }).data || [];
}

export async function adjustInventory(
  variantIdOrParams: string | { variantId: string; change?: number; delta?: number; reason: string; note?: string },
  changeOrDelta?: number,
  reason?: string,
  note?: string
): Promise<void> {
  let bodyPayload: { variantId: string; delta: number; reason: string; note?: string };
  if (typeof variantIdOrParams === 'string') {
    bodyPayload = {
      variantId: variantIdOrParams,
      delta: changeOrDelta ?? 0,
      reason: reason || 'admin_restock',
      note: note || '',
    };
  } else {
    bodyPayload = {
      variantId: variantIdOrParams.variantId,
      delta: variantIdOrParams.delta ?? variantIdOrParams.change ?? 0,
      reason: variantIdOrParams.reason || 'admin_restock',
      note: variantIdOrParams.note || '',
    };
  }
  await apiFetch('/api/v1/admin/inventory/adjust', {
    method: 'POST',
    body: JSON.stringify(bodyPayload),
  });
}

// ========== AUDIT LOGS ==========
export async function fetchAuditLogs(): Promise<AuditLog[]> {
  const data = await apiFetch<{ data: AuditLog[] } | AuditLog[]>('/api/v1/admin/audit-log');
  if (Array.isArray(data)) return data;
  return (data as { data: AuditLog[] }).data || [];
}

// ========== USERS ==========
export async function fetchAdminUsers(): Promise<UserAccount[]> {
  const data = await apiFetch<{ data?: UserAccount[] } | UserAccount[]>('/api/v1/admin/users');
  return Array.isArray(data) ? data : data.data || [];
}

export async function updateUserRole(userId: string, role: 'admin' | 'customer'): Promise<void> {
  await apiFetch(`/api/v1/admin/users/${userId}`, {
    method: 'PUT',
    body: JSON.stringify({ role }),
  });
}

// ========== AUTH ==========
export interface AuthSession {
  user: {
    id: string;
    email: string;
    fullName?: string;
    role: string;
    accessToken?: string;
  };
  accessToken: string;
}

export async function loginUser(email: string, password: string): Promise<AuthSession> {
  const BASE = getApiUrl();
  const normalized = email.toLowerCase().trim();

  const res = await fetch(`${BASE}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: normalized, password }),
  }).catch(() => {
    throw new Error(`Không thể kết nối backend tại ${BASE}. Hãy khởi động backend rồi thử lại.`);
  });
  const raw = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(raw?.error?.message || raw?.error || raw?.message || 'Đăng nhập thất bại');
  }
  const payload = raw?.data || raw;
  if (!payload.accessToken || !payload.user?.id || !payload.user?.role) {
    throw new Error('Backend trả về phiên đăng nhập không hợp lệ.');
  }
  return {
    user: {
      id: payload.user.id,
      email: payload.user?.email || normalized,
      fullName: payload.user?.fullName || payload.user?.full_name || payload.user?.name || 'Admin MenShop',
      role: payload.user.role,
    },
    accessToken: payload.accessToken,
  };
}

export async function getLockoutStatus(email: string): Promise<unknown> {
  const BASE = getApiUrl();
  const res = await fetch(`${BASE}/api/v1/auth/status?email=${encodeURIComponent(email)}`);
  return res.json();
}

// ========== BANNERS ==========
export interface Banner {
  id: string;
  title: string;
  imageUrl: string;
  linkUrl: string | null;
  sortOrder: number;
  isActive: boolean;
  startDate: string;
  endDate: string;
}

/** May chu tra ve snake_case; trang quan tri dung camelCase. */
function normalizeBanner(raw: Record<string, unknown>): Banner {
  return {
    id: String(raw.id ?? ''),
    title: String(raw.title ?? ''),
    imageUrl: String(raw.image_url ?? raw.imageUrl ?? ''),
    linkUrl: (raw.link_url ?? raw.linkUrl ?? null) as string | null,
    sortOrder: Number(raw.sort_order ?? raw.sortOrder ?? 0),
    isActive: (raw.is_active ?? raw.isActive ?? true) as boolean,
    startDate: String(raw.start_date ?? raw.startDate ?? ''),
    endDate: String(raw.end_date ?? raw.endDate ?? ''),
  };
}

export interface BannerInput {
  title: string;
  imageUrl: string;
  linkUrl?: string | null;
  sortOrder: number;
  isActive: boolean;
  startDate?: string;
  endDate: string;
}

export async function fetchAdminBanners(): Promise<Banner[]> {
  const res = await apiFetch<any>('/api/v1/admin/banners');
  const rows = Array.isArray(res) ? res : res?.data ?? [];
  return rows.map(normalizeBanner);
}

export async function createBanner(payload: BannerInput): Promise<Banner> {
  const res = await apiFetch<any>('/api/v1/admin/banners', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  return normalizeBanner(res?.data ?? res);
}

export async function updateBanner(
  id: string,
  payload: Partial<BannerInput>
): Promise<Banner> {
  const res = await apiFetch<any>(`/api/v1/admin/banners/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
  return normalizeBanner(res?.data ?? res);
}

/** Bat tat hien thi banner tren trang chu cua ung dung. */
export async function setBannerActive(id: string, isActive: boolean): Promise<Banner> {
  const res = await apiFetch<any>(`/api/v1/admin/banners/${id}/active`, {
    method: 'PATCH',
    body: JSON.stringify({ isActive }),
  });
  return normalizeBanner(res?.data ?? res);
}

/**
 * Tai mot anh banner tu may len may chu, tra ve dia chi cong khai cua anh.
 * Dung cho nut "Tai anh tu may" o form banner, thay vi bat nguoi dung tu di
 * tim link anh tren mang.
 */
export async function uploadBannerImage(file: File): Promise<string> {
  const form = new FormData();
  form.append('image', file);
  const res = await apiFetch<any>('/api/v1/admin/banners/upload', {
    method: 'POST',
    body: form,
  });
  const url = res?.data?.imageUrl ?? res?.imageUrl;
  if (typeof url !== 'string' || !url) {
    throw new Error('Máy chủ không trả về đường dẫn ảnh sau khi tải lên');
  }
  return url;
}

export async function deleteBanner(id: string): Promise<void> {
  await apiFetch<any>(`/api/v1/admin/banners/${id}`, { method: 'DELETE' });
}

// ========== VOUCHERS ==========
export async function fetchAdminVouchers(): Promise<Voucher[]> {
  const data = await apiFetch<Voucher[] | { data?: Voucher[] }>('/api/v1/admin/vouchers');
  return Array.isArray(data) ? data : data.data || [];
}

export async function createVoucher(data: CreateVoucherInput): Promise<Voucher> {
  const result = await apiFetch<Voucher | { data: Voucher }>('/api/v1/admin/vouchers', {
    method: 'POST',
    body: JSON.stringify(data),
  });
  return 'data' in result ? result.data : result;
}

export async function updateVoucher(id: string, data: Partial<CreateVoucherInput>): Promise<Voucher> {
  const result = await apiFetch<Voucher | { data: Voucher }>(`/api/v1/admin/vouchers/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
  return 'data' in result ? result.data : result;
}

export async function deleteVoucher(id: string): Promise<boolean> {
  return apiFetch<{ success: boolean }>(`/api/v1/admin/vouchers/${id}`, {
    method: 'DELETE',
  }).then((r) => r.success);
}

// ========== TRẢ HÀNG ==========

export interface OrderReturn {
  id: string;
  orderId: string;
  userId: string;
  reason: string;
  proofImages: string[];
  status: string;
  refundAmount: number;
  rejectionReason: string | null;
  adminResolutionNote: string | null;
  /** true: hàng còn bán được và đã nhập lại kho; false: hàng lỗi. */
  restocked: boolean | null;
  createdAt: string;
  resolvedAt: string | null;
}

function normalizeReturn(raw: Record<string, unknown>): OrderReturn {
  const lay = <T>(camel: string, snake: string, macDinh: T): T => {
    const giaTri = raw[camel] ?? raw[snake];
    return (giaTri === undefined || giaTri === null ? macDinh : giaTri) as T;
  };
  return {
    id: String(raw.id ?? ''),
    orderId: lay('orderId', 'order_id', ''),
    userId: lay('userId', 'user_id', ''),
    reason: lay('reason', 'reason', ''),
    proofImages: lay<string[]>('proofImages', 'proof_images', []),
    status: lay('status', 'status', 'requested'),
    refundAmount: Number(lay('refundAmount', 'refund_amount', 0)),
    rejectionReason: lay<string | null>('rejectionReason', 'rejection_reason', null),
    adminResolutionNote: lay<string | null>('adminResolutionNote', 'admin_resolution_note', null),
    restocked: lay<boolean | null>('restocked', 'restocked', null),
    createdAt: lay('createdAt', 'created_at', ''),
    resolvedAt: lay<string | null>('resolvedAt', 'resolved_at', null),
  };
}

export async function fetchOrderReturns(): Promise<OrderReturn[]> {
  const res = await apiFetch<any>('/api/v1/order-returns/admin');
  const rows = Array.isArray(res?.data) ? res.data : Array.isArray(res) ? res : [];
  return rows.map(normalizeReturn);
}

/**
 * Doi trang thai mot yeu cau tra hang.
 *
 * Khi chuyen sang 'refunded' bat buoc phai noi hang con ban lai duoc khong:
 * con ban duoc thi may chu cong lai kho, hang loi thi khong.
 */
export async function updateOrderReturn(
  id: string,
  payload: {
    status: string;
    restock?: boolean;
    rejectionReason?: string | null;
    adminResolutionNote?: string | null;
  },
): Promise<OrderReturn> {
  const res = await apiFetch<any>(`/api/v1/order-returns/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(payload),
  });
  return normalizeReturn(res?.data ?? res);
}

// ---------------------------------------------------------------------------
// Chat CSKH: nhan vien va quan tri tra loi tin nhan cua khach ngay trong admin
//
// Cac ham normalize* duoi day nhan 'any' vi do la JSON tho backend tra ve, dat
// ten theo snake_case va co the thieu truong. Giong het cach cac normalize*
// khac trong file nay lam, de ca file mot kieu.
// ---------------------------------------------------------------------------

export interface SupportConversation {
  id: string;
  userId: string;
  customerName: string | null;
  customerEmail: string | null;
  lastMessage: string | null;
  lastMessageAt: string;
  unreadStaffCount: number;
  status: string;
  typing: SupportTyping;
}

export interface SupportMessage {
  id: string;
  conversationId: string;
  senderId: string;
  senderRole: string;
  content: string;
  createdAt: string;
  /** Doi phuong da doc chua. Chi co y nghia voi tin do minh gui. */
  isRead: boolean;
}

/** Ai dang go phim trong mot hoi thoai. */
export interface SupportTyping {
  customer: boolean;
  staff: boolean;
}

/** Mot lan tai tin nhan: danh sach tin kem trang thai go phim. */
export interface SupportChatLoad {
  messages: SupportMessage[];
  typing: SupportTyping;
  /** Con tin cu hon chua tai ve hay khong. */
  conTinCu: boolean;
}

/** Tham so phan doan khi lay tin nhan. */
export interface ThamSoTaiTin {
  /** Chi lay tin tu moc nay tro di - dung cho vong tu lam moi. */
  tuMoc?: string;
  /** Lay tin cu hon moc nay - dung cho nut xem tin cu. */
  truocMoc?: string;
  limit?: number;
}

function normalizeTyping(raw: any): SupportTyping {
  return {
    customer: raw?.customer === true,
    staff: raw?.staff === true,
  };
}

function normalizeConversation(row: any): SupportConversation {
  const customer = row?.customer ?? {};
  return {
    id: String(row?.id ?? ''),
    userId: String(row?.user_id ?? ''),
    customerName: customer?.full_name ?? null,
    customerEmail: customer?.email ?? null,
    lastMessage: row?.last_message ?? null,
    lastMessageAt: String(row?.last_message_at ?? ''),
    unreadStaffCount: Number(row?.unread_staff_count ?? 0),
    status: String(row?.status ?? 'open'),
    typing: normalizeTyping(row?.typing),
  };
}

function normalizeSupportMessage(row: any): SupportMessage {
  return {
    id: String(row?.id ?? ''),
    conversationId: String(row?.conversation_id ?? ''),
    senderId: String(row?.sender_id ?? ''),
    senderRole: String(row?.sender_role ?? ''),
    content: String(row?.content ?? ''),
    createdAt: String(row?.created_at ?? ''),
    isRead: row?.is_read === true,
  };
}

/** Danh sach hoi thoai dang mo, moi nhat len dau. */
export async function fetchSupportConversations(): Promise<SupportConversation[]> {
  const res = await apiFetch<any>('/api/v1/support-chat/staff/conversations');
  const rows = Array.isArray(res?.data) ? res.data : [];
  return rows.map(normalizeConversation);
}

export async function fetchSupportMessages(
  conversationId: string,
  thamSo: ThamSoTaiTin = {},
): Promise<SupportChatLoad> {
  const query = new URLSearchParams();
  if (thamSo.tuMoc) query.set('tuMoc', thamSo.tuMoc);
  if (thamSo.truocMoc) query.set('truocMoc', thamSo.truocMoc);
  if (thamSo.limit) query.set('limit', String(thamSo.limit));
  const duoi = query.toString() ? `?${query}` : '';

  const res = await apiFetch<any>(`/api/v1/support-chat/${conversationId}/messages${duoi}`);
  const rows = Array.isArray(res?.data) ? res.data : [];
  return {
    messages: rows.map(normalizeSupportMessage),
    typing: normalizeTyping(res?.typing),
    conTinCu: res?.conTinCu === true,
  };
}

/**
 * Ket thuc mot hoi thoai.
 *
 * Tin nhan khong bi xoa, hoi thoai chi roi khoi danh sach dang mo. Khach nhan
 * tiep thi he thong tu mo mot hoi thoai moi.
 */
export async function closeSupportConversation(conversationId: string): Promise<void> {
  await apiFetch<unknown>(`/api/v1/support-chat/${conversationId}/close`, {
    method: 'PATCH',
  });
}

/**
 * Bao len may chu rang minh dang go phim.
 *
 * Goi roi quen: tin hieu chi song vai giay, hong mot lan khong anh huong gi.
 */
export async function pingSupportTyping(conversationId: string): Promise<void> {
  try {
    await apiFetch<unknown>(`/api/v1/support-chat/${conversationId}/typing`, {
      method: 'POST',
    });
  } catch {
    // Bo qua co y: bao dang soan that bai khong duoc lam phien nguoi dung.
  }
}

export async function sendSupportMessage(
  conversationId: string,
  content: string,
): Promise<SupportMessage> {
  const res = await apiFetch<any>(`/api/v1/support-chat/${conversationId}/messages`, {
    method: 'POST',
    body: JSON.stringify({ content }),
  });
  return normalizeSupportMessage(res?.data ?? res);
}
