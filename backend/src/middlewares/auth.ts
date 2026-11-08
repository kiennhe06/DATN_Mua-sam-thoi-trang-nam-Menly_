import type { Request, Response, NextFunction } from 'express';
import { supabase } from '../config/supabase.js';

export interface AuthenticatedUser {
  id: string;
  email: string | null;
  role: string;
  fullName: string | null;
  token: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}

function extractBearerToken(req: Request): string | null {
  const authorization = req.header('authorization');
  if (!authorization) return null;
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  return match ? match[1].trim() : null;
}

interface AuthProfile {
  id: string;
  email: string | null;
  full_name: string | null;
  role: string;
  is_active: boolean;
  is_locked: boolean;
}

/**
 * Bo nho dem ket qua xac thuc, theo tung token.
 *
 * Truoc day moi duong dan can dang nhap deu goi Supabase hai lan truoc khi chay
 * xu ly that: mot lan kiem tra token, mot lan doc bang profiles. Hai lan goi qua
 * mang nay cong khoang 350ms vao MOI request, nen man hinh nao goi vai API lien
 * tiep la nguoi dung thay giat.
 *
 * Doi lai: khoa tai khoan hoac doi vai tro co the cham hieu luc toi TTL giay.
 * Cac thao tac quan tri goi forgetAuthUser de xoa dem ngay, nen do tre chi xay ra
 * khi du lieu bi doi thang trong co so du lieu.
 */
const AUTH_CACHE_TTL_MS = 30_000;
const AUTH_CACHE_MAX_ENTRIES = 1000;

interface CachedAuth {
  profile: AuthProfile;
  expiresAt: number;
}

const authCache = new Map<string, CachedAuth>();

function rememberAuth(token: string, profile: AuthProfile) {
  // Map giu thu tu them vao, nen phan tu dau tien la cai cu nhat
  if (authCache.size >= AUTH_CACHE_MAX_ENTRIES) {
    const oldest = authCache.keys().next();
    if (!oldest.done) authCache.delete(oldest.value);
  }
  authCache.set(token, { profile, expiresAt: Date.now() + AUTH_CACHE_TTL_MS });
}

/** Xoa dem cua mot token (dung khi dang xuat hoac token khong con hop le). */
export function forgetAuthToken(token: string) {
  authCache.delete(token);
}

/** Xoa dem cua mot nguoi dung (dung khi quan tri khoa, doi vai tro hoac xoa). */
export function forgetAuthUser(userId: string) {
  for (const [token, cached] of authCache) {
    if (cached.profile.id === userId) authCache.delete(token);
  }
}

async function verifyTokenAndGetProfile(token: string) {
  const { data: authData, error: authError } = await supabase.auth.getUser(token);
  if (authError || !authData.user) {
    return { error: 'invalid_token', user: null, profile: null };
  }

  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('id, email, full_name, role, is_active, is_locked')
    .eq('id', authData.user.id)
    .maybeSingle();

  if (profileError) {
    throw new Error(profileError.message);
  }

  return {
    error: null,
    user: authData.user,
    profile: profile ?? {
      id: authData.user.id,
      email: authData.user.email ?? null,
      full_name: (authData.user.user_metadata?.full_name as string) ?? null,
      role: 'customer',
      is_active: true,
      is_locked: false,
    },
  };
}

/** Doc tu bo nho dem truoc, chi goi Supabase khi dem het han. */
async function resolveAuth(token: string): Promise<{ error: string | null; profile: AuthProfile | null }> {
  const cached = authCache.get(token);
  if (cached) {
    if (cached.expiresAt > Date.now()) {
      return { error: null, profile: cached.profile };
    }
    authCache.delete(token);
  }

  const { error, profile } = await verifyTokenAndGetProfile(token);
  if (error || !profile) {
    return { error: error ?? 'invalid_token', profile: null };
  }

  const resolved = profile as AuthProfile;
  rememberAuth(token, resolved);
  return { error: null, profile: resolved };
}

async function authenticate(req: Request, res: Response, next: NextFunction, allowedRoles?: string[]) {
  const token = extractBearerToken(req);
  if (!token) {
    return res.status(401).json({ error: 'Vui lòng đăng nhập' });
  }

  try {
    const { error, profile } = await resolveAuth(token);
    if (error || !profile) {
      return res.status(401).json({ error: 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn' });
    }

    if (profile.is_locked) {
      return res.status(403).json({ error: 'Tài khoản đã bị khóa' });
    }

    if (!profile.is_active) {
      return res.status(403).json({ error: 'Tài khoản không được phép truy cập hoặc chưa được kích hoạt' });
    }

    if (allowedRoles && !allowedRoles.includes(profile.role)) {
      return res.status(403).json({ error: 'Bạn không có quyền thực hiện thao tác này' });
    }

    req.user = {
      id: profile.id,
      email: profile.email,
      role: profile.role,
      fullName: profile.full_name,
      token,
    };

    return next();
  } catch (err) {
    return next(err);
  }
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  return authenticate(req, res, next);
}

export function requireStaffOrAdmin(req: Request, res: Response, next: NextFunction) {
  return authenticate(req, res, next, ['staff', 'admin']);
}

export function requireAdmin(req: Request, res: Response, next: NextFunction) {
  return authenticate(req, res, next, ['admin']);
}

export function requireRoles(...roles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    return authenticate(req, res, next, roles);
  };
}

export async function optionalAuth(req: Request, _res: Response, next: NextFunction) {
  const token = extractBearerToken(req);
  if (!token) return next();

  try {
    const { error, profile } = await resolveAuth(token);
    if (!error && profile && profile.is_active && !profile.is_locked) {
      req.user = {
        id: profile.id,
        email: profile.email,
        role: profile.role,
        fullName: profile.full_name,
        token,
      };
    }
    return next();
  } catch {
    return next();
  }
}
