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

export async function updateProduct(
  id: string,
  payload: Partial<Product>
): Promise<Product> {
  const res = await apiFetch<any>(`/api/v1/admin/products/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
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
  isActive: boolean;
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
export async function fetchAdminOrders(
  params?: { status?: string; limit?: number } | OrderStatus | string
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
  if (typeof params === 'object' && params.limit) {
    query.set('limit', String(params.limit));
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
      paymentMethod: o.paymentMethod || o.payment_method || 'cod',
      subtotal: Number(o.subtotal || 0),
      shippingFee: Number(o.shippingFee || o.shipping_fee || 0),
      total: Number(o.total || 0),
      shipName: o.shipName || o.ship_name || o.ship?.name || '',
      shipPhone: o.shipPhone || o.ship_phone || o.ship?.phone || '',
      shipAddress: o.shipAddress || o.ship_address || o.ship?.address || '',
      shippingAddress: o.shippingAddress || {
        name: o.shipName || o.ship_name || o.ship?.name || '',
        phone: o.shipPhone || o.ship_phone || o.ship?.phone || '',
        address: o.shipAddress || o.ship_address || o.ship?.address || '',
        note: o.note || '',
      },
      createdAt: o.createdAt || o.created_at || new Date().toISOString(),
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
