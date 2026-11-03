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

async function authenticate(req: Request, res: Response, next: NextFunction, allowedRoles?: string[]) {
  const token = extractBearerToken(req);
  if (!token) {
    return res.status(401).json({ error: 'Vui lòng đăng nhập' });
  }

  try {
    const { error, profile } = await verifyTokenAndGetProfile(token);
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
    const { error, profile } = await verifyTokenAndGetProfile(token);
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
