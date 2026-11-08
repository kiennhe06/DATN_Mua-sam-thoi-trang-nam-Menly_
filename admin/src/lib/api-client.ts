const DEFAULT_API_URL = 'http://localhost:5000';

export function getApiUrl(): string {
  if (typeof window !== 'undefined') {
    return (
      localStorage.getItem('menshop_api_url') ||
      process.env.NEXT_PUBLIC_API_URL ||
      DEFAULT_API_URL
    ).replace(/\/+$/, '');
  }

  return (process.env.NEXT_PUBLIC_API_URL || DEFAULT_API_URL).replace(/\/+$/, '');
}

function getAdminToken(): string {
  const token =
    typeof window !== 'undefined'
      ? localStorage.getItem('menshop_admin_token')?.trim()
      : undefined;

  if (!token) {
    throw new Error('Phiên quản trị đã hết hạn. Vui lòng đăng nhập lại.');
  }

  return token.replace(/^Bearer\s+/i, '');
}

export async function adminFetch<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const headers = new Headers(options.headers);
  headers.set('Accept', 'application/json');
  headers.set('Authorization', `Bearer ${getAdminToken()}`);

  if (options.body && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json');
  }

/** Gop cac loi theo tung truong thanh mot cau doc duoc. */
function describeFieldErrors(details: unknown): string | null {
  if (!details || typeof details !== 'object') return null;
  const parts: string[] = [];
  for (const [field, messages] of Object.entries(details as Record<string, unknown>)) {
    const text = Array.isArray(messages) ? messages.join(', ') : String(messages);
    if (text) parts.push(`${field}: ${text}`);
  }
  return parts.length ? parts.join(' | ') : null;
}

/**
 * Doc thong bao loi that su tu backend.
 *
 * Backend tra ve dang { error: 'Thong tin khong hop le', details: { truong: [...] } }.
 * Truoc day cho nay doc data.error.message, nhung error la mot CHUOI nen
 * .message luon undefined, khien moi loi deu hien thanh "Backend tra ve HTTP 400"
 * va nguoi dung khong biet minh thieu truong nao.
 */
function describeError(data: unknown, status: number): string {
  const body = (data ?? {}) as Record<string, unknown>;
  const rawError = body.error;
  const base =
    typeof rawError === 'string'
      ? rawError
      : typeof (rawError as { message?: unknown } | undefined)?.message === 'string'
        ? ((rawError as { message: string }).message)
        : typeof body.message === 'string'
          ? body.message
          : `Backend trả về HTTP ${status}`;

  const fields = describeFieldErrors(body.details);
  return fields ? `${base} — ${fields}` : base;
}



  let response: Response;
  try {
    response = await fetch(`${getApiUrl()}${path}`, { ...options, headers });
  } catch {
    throw new Error(
      `Không thể kết nối backend tại ${getApiUrl()}. Hãy kiểm tra backend và URL API trong Cài đặt.`,
    );
  }

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    if (response.status === 401 && typeof window !== 'undefined') {
      localStorage.removeItem('menshop_admin_token');
      localStorage.removeItem('menshop_admin_user');
      if (window.location.pathname !== '/login') {
        window.location.assign('/login');
      }
    }
    throw new Error(describeError(data, response.status));
  }

  return data as T;
}
