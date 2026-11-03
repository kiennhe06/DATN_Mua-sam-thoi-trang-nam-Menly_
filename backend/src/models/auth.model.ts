import { createClient } from '@supabase/supabase-js';
import { env } from '../config/env.js';
import { supabase } from '../config/supabase.js';
import type { RegisterInput } from '../validators/auth.validator.js';

export class AuthError extends Error {
  statusCode: number;
  constructor(message: string, statusCode = 400) {
    super(message);
    this.name = 'AuthError';
    this.statusCode = statusCode;
  }
}

export class LoginCredentialsError extends AuthError {
  constructor(message = 'Thông tin đăng nhập không chính xác') {
    super(message, 401);
    this.name = 'LoginCredentialsError';
  }
}

export class AccountLockedError extends AuthError {
  constructor(message = 'Tài khoản của bạn đã bị khóa') {
    super(message, 403);
    this.name = 'AccountLockedError';
  }
}

export class AccountInactiveError extends AuthError {
  constructor(message = 'Tài khoản chưa được kích hoạt hoặc đã bị vô hiệu hóa') {
    super(message, 403);
    this.name = 'AccountInactiveError';
  }
}

export class InvalidPasswordError extends AuthError {
  constructor(message = 'Mật khẩu hiện tại không chính xác') {
    super(message, 400);
    this.name = 'InvalidPasswordError';
  }
}

function getAuthClient() {
  const clientKey = env.supabaseServiceRoleKey || env.supabaseAnonKey;
  if (!env.supabaseUrl || !clientKey) {
    throw new Error('Thiếu cấu hình SUPABASE_URL hoặc SUPABASE_SERVICE_ROLE_KEY');
  }
  return createClient(env.supabaseUrl, clientKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export type LocalUserRecord = {
  id: string;
  email: string;
  fullName: string;
  phone: string | null;
  role: string;
  password: string;
  isActive: boolean;
  isLocked: boolean;
  createdAt: string;
};

const localUsers = new Map<string, LocalUserRecord>();
const DEMO_ACCOUNT_EMAIL = 'demo@menly.local';
const DEMO_ACCOUNT_PASSWORD = '123456';
const ADMIN_ACCOUNT_EMAIL = 'admin@gmail.com';
const ADMIN_ACCOUNT_PASSWORD = '123456';

export function ensureDemoUser() {
  const email = DEMO_ACCOUNT_EMAIL.toLowerCase();
  if (!localUsers.has(email)) {
    localUsers.set(email, {
      id: 'd0000000-0000-0000-0000-000000000001',
      email,
      fullName: 'Demo User',
      phone: '0900000000',
      role: 'customer',
      password: DEMO_ACCOUNT_PASSWORD,
      isActive: true,
      isLocked: false,
      createdAt: new Date().toISOString(),
    });
  }

  const adminEmail = ADMIN_ACCOUNT_EMAIL.toLowerCase();
  if (!localUsers.has(adminEmail)) {
    localUsers.set(adminEmail, {
      id: 'a0000000-0000-0000-0000-000000000001',
      email: adminEmail,
      fullName: 'Quản trị viên MenShop',
      phone: '0988888888',
      role: 'admin',
      password: ADMIN_ACCOUNT_PASSWORD,
      isActive: true,
      isLocked: false,
      createdAt: new Date().toISOString(),
    });
  }

  const kienEmail = 'kien@gmail.com';
  if (!localUsers.has(kienEmail)) {
    localUsers.set(kienEmail, {
      id: 'c0000000-0000-0000-0000-000000000001',
      email: kienEmail,
      fullName: 'Phạm Đức Kiên',
      phone: '0973735876',
      role: 'customer',
      password: 'kiennhe',
      isActive: true,
      isLocked: false,
      createdAt: new Date().toISOString(),
    });
  }
}

export function getLocalUserById(id: string): LocalUserRecord | undefined {
  ensureDemoUser();
  for (const user of localUsers.values()) {
    if (user.id === id) return user;
  }
  return undefined;
}

export function getLocalUserByEmail(email: string): LocalUserRecord | undefined {
  ensureDemoUser();
  return localUsers.get(email.toLowerCase());
}

function isSupabaseTemporaryAuthFailure(error: unknown) {
  if (!error) return false;
  const message = String((error as { message?: string })?.message ?? error);
  return /rate limit|too many requests|email rate limit|email_address_invalid|is invalid|invalid|temporar|fetch failed/i.test(message);
}

export class AuthModel {
  /**
   * Đăng ký tài khoản mới qua Supabase Auth
   */
  async register(input: RegisterInput) {
    const authClient = getAuthClient();
    const { email, password, fullName, phone, role } = input;
    const userRole = role ?? 'customer';
    const normalizedEmail = email.toLowerCase();

    ensureDemoUser();

    const { data: authData, error: authError } = await authClient.auth.signUp({
      email: normalizedEmail,
      password,
      options: {
        data: {
          full_name: fullName,
          phone: phone || '',
          role: userRole,
        },
      },
    });

    if (authError) {
      if (authError.message.includes('already registered')) {
        throw new AuthError('Email này đã được đăng ký trong hệ thống', 409);
      }

      if (isSupabaseTemporaryAuthFailure(authError)) {
        const existingLocal = localUsers.get(normalizedEmail);
        if (existingLocal) {
          throw new AuthError('Email này đã được đăng ký trong hệ thống', 409);
        }

        const localUser: LocalUserRecord = {
          id: `local-user-${Date.now()}`,
          email: normalizedEmail,
          fullName,
          phone: phone || null,
          role: userRole,
          password,
          isActive: true,
          isLocked: false,
          createdAt: new Date().toISOString(),
        };

        localUsers.set(normalizedEmail, localUser);

        return {
          message: 'Đăng ký tài khoản demo thành công. Chế độ local fallback đang được bật.',
          accessToken: `demo-access-${localUser.id}`,
          refreshToken: `demo-refresh-${localUser.id}`,
          expiresAt: Date.now() + 86400000,
          user: {
            id: localUser.id,
            email: localUser.email,
            fullName: localUser.fullName,
            phone: localUser.phone,
            role: localUser.role,
          },
        };
      }

      throw new AuthError(authError.message, 400);
    }

    if (!authData.user) {
      throw new AuthError('Không thể tạo tài khoản, vui lòng thử lại sau', 500);
    }

    // Đảm bảo thông tin hồ sơ được cập nhật trong bảng profiles
    const { error: profileError } = await supabase.from('profiles').upsert(
      {
        id: authData.user.id,
        email: authData.user.email ?? email,
        full_name: fullName,
        phone: phone || null,
        role: userRole,
        is_active: true,
        is_locked: false,
      },
      { onConflict: 'id' }
    );

    if (profileError) {
      console.error('Lỗi cập nhật hồ sơ người dùng mới:', profileError.message);
    }

    const hasSession = Boolean(authData.session);

    return {
      message: hasSession
        ? 'Đăng ký tài khoản thành công'
        : 'Đăng ký thành công. Vui lòng kiểm tra email để xác nhận tài khoản.',
      accessToken: authData.session?.access_token ?? null,
      refreshToken: authData.session?.refresh_token ?? null,
      expiresAt: authData.session?.expires_at ?? null,
      user: {
        id: authData.user.id,
        email: authData.user.email ?? email,
        fullName,
        phone: phone || null,
        role: userRole,
      },
    };
  }

  /**
   * Đăng nhập qua Supabase Auth và kiểm tra trạng thái hồ sơ người dùng
   */
  async login(email: string, password: string, requiredRole?: string) {
    ensureDemoUser();
    const normalizedEmail = email.toLowerCase();
    const localUser = localUsers.get(normalizedEmail);

    if (localUser && localUser.password === password) {
      if (requiredRole && localUser.role !== requiredRole) {
        throw new LoginCredentialsError('Tài khoản không có quyền truy cập');
      }
      return {
        accessToken: `demo-access-${localUser.id}`,
        refreshToken: `demo-refresh-${localUser.id}`,
        expiresAt: Date.now() + 86400000,
        user: {
          id: localUser.id,
          email: localUser.email,
          fullName: localUser.fullName,
          phone: localUser.phone,
          role: localUser.role,
          avatarUrl: null,
        },
      };
    }

    const authClient = getAuthClient();
    const { data: authData, error: authError } = await authClient.auth.signInWithPassword({
      email: normalizedEmail,
      password,
    });

    if (authError || !authData.user || !authData.session) {
      throw new LoginCredentialsError();
    }

    // Lấy thông tin hồ sơ từ bảng profiles
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('id, email, full_name, phone, role, avatar_url, is_active, is_locked')
      .eq('id', authData.user.id)
      .maybeSingle();

    if (profileError) {
      throw new Error(profileError.message);
    }

    // Trường hợp hồ sơ chưa có do trigger chưa tạo, tạo mới bản ghi mặc định
    let currentProfile = profile;
    if (!currentProfile) {
      const defaultRole = (authData.user.user_metadata?.role as string) || 'customer';
      const defaultFullName = (authData.user.user_metadata?.full_name as string) || '';
      const { data: newProfile, error: createProfileError } = await supabase
        .from('profiles')
        .insert({
          id: authData.user.id,
          email: authData.user.email ?? email,
          full_name: defaultFullName,
          role: defaultRole,
          is_active: true,
          is_locked: false,
        })
        .select('id, email, full_name, phone, role, avatar_url, is_active, is_locked')
        .single();

      if (createProfileError) {
        throw new Error(createProfileError.message);
      }
      currentProfile = newProfile;
    }

    if (currentProfile.is_locked) {
      throw new AccountLockedError('Tài khoản đã bị khóa');
    }

    if (!currentProfile.is_active) {
      throw new AccountInactiveError('Tài khoản chưa được kích hoạt hoặc đã bị vô hiệu hóa');
    }

    if (requiredRole && currentProfile.role !== requiredRole) {
      throw new LoginCredentialsError('Tài khoản không có quyền truy cập');
    }

    return {
      accessToken: authData.session.access_token,
      refreshToken: authData.session.refresh_token,
      expiresAt: authData.session.expires_at,
      user: {
        id: currentProfile.id,
        email: currentProfile.email,
        fullName: currentProfile.full_name,
        phone: currentProfile.phone,
        role: currentProfile.role,
        avatarUrl: currentProfile.avatar_url,
      },
    };
  }

  /**
   * Đổi mật khẩu cho người dùng hiện tại (yêu cầu mật khẩu cũ)
   */
  async changePassword(userId: string, email: string, currentPassword: string, newPassword: string) {
    ensureDemoUser();

    // 1. Kiểm tra tài khoản local fallback
    const localUser = (email ? getLocalUserByEmail(email) : undefined) || (userId ? getLocalUserById(userId) : undefined);
    if (localUser) {
      if (localUser.password !== currentPassword) {
        throw new InvalidPasswordError('Mật khẩu hiện tại không chính xác');
      }
      localUser.password = newPassword;
      return { success: true, message: 'Đổi mật khẩu thành công' };
    }

    const authClient = getAuthClient();

    // Xác thực lại mật khẩu hiện tại với Supabase
    const { error: verifyError } = await authClient.auth.signInWithPassword({
      email,
      password: currentPassword,
    });

    if (verifyError) {
      throw new InvalidPasswordError('Mật khẩu hiện tại không chính xác');
    }

    // Cập nhật mật khẩu mới qua Supabase Admin API
    const { error: updateError } = await supabase.auth.admin.updateUserById(userId, {
      password: newPassword,
    });

    if (updateError) {
      throw new AuthError(`Không thể cập nhật mật khẩu: ${updateError.message}`, 400);
    }

    return { success: true, message: 'Đổi mật khẩu thành công' };
  }

  /**
   * Yêu cầu gửi email đặt lại mật khẩu
   */
  async forgotPassword(email: string, redirectTo?: string) {
    ensureDemoUser();
    const localUser = getLocalUserByEmail(email);
    if (localUser) {
      return {
        success: true,
        message: 'Nếu email tồn tại trong hệ thống, hướng dẫn đặt lại mật khẩu đã được gửi đến email của bạn.',
      };
    }

    const authClient = getAuthClient();
    const { error } = await authClient.auth.resetPasswordForEmail(email, {
      redirectTo: redirectTo || undefined,
    });

    if (error) {
      // Nếu lỗi rate limit thì báo lỗi rõ ràng
      if (error.status === 429) {
        throw new AuthError('Bạn đã yêu cầu quá nhiều lần. Vui lòng thử lại sau ít phút.', 429);
      }
      throw new AuthError(error.message, 400);
    }

    return {
      success: true,
      message: 'Nếu email tồn tại trong hệ thống, hướng dẫn đặt lại mật khẩu đã được gửi đến email của bạn.',
    };
  }

  /**
   * Đặt lại mật khẩu mới bằng OTP hoặc accessToken
   */
  async resetPassword(params: {
    token?: string;
    accessToken?: string;
    otp?: string;
    email?: string;
    newPassword: string;
  }) {
    const { token, accessToken, otp, email, newPassword } = params;

    if (email) {
      ensureDemoUser();
      const localUser = getLocalUserByEmail(email);
      if (localUser) {
        localUser.password = newPassword;
        return { success: true, message: 'Đặt lại mật khẩu thành công. Vui lòng đăng nhập với mật khẩu mới.' };
      }
    }

    const authClient = getAuthClient();

    // 1. Trường hợp xác nhận qua Email + OTP (Code)
    if (email && otp) {
      const { data: verifyData, error: verifyError } = await authClient.auth.verifyOtp({
        email,
        token: otp,
        type: 'recovery',
      });

      if (verifyError || !verifyData.user) {
        throw new AuthError('Mã OTP xác thực không hợp lệ hoặc đã hết hạn', 400);
      }

      const { error: updateError } = await supabase.auth.admin.updateUserById(verifyData.user.id, {
        password: newPassword,
      });

      if (updateError) {
        throw new AuthError(`Không thể đặt lại mật khẩu: ${updateError.message}`, 400);
      }

      return { success: true, message: 'Đặt lại mật khẩu thành công' };
    }

    // 2. Trường hợp token hoặc accessToken được cung cấp
    const activeToken = accessToken || token;
    if (activeToken) {
      const { data: authData, error: getUserError } = await supabase.auth.getUser(activeToken);
      if (getUserError || !authData.user) {
        throw new AuthError('Token đặt lại mật khẩu không hợp lệ hoặc đã hết hạn', 400);
      }

      const { error: updateError } = await supabase.auth.admin.updateUserById(authData.user.id, {
        password: newPassword,
      });

      if (updateError) {
        throw new AuthError(`Không thể đặt lại mật khẩu: ${updateError.message}`, 400);
      }

      return { success: true, message: 'Đặt lại mật khẩu thành công' };
    }

    throw new AuthError('Thiếu thông tin để đặt lại mật khẩu', 400);
  }

  /**
   * Cấp lại accessToken mới từ refreshToken
   */
  async refreshToken(refreshToken: string) {
    if (refreshToken.startsWith('demo-refresh-')) {
      const rawId = refreshToken.replace('demo-refresh-', '');
      const localUser = getLocalUserById(rawId);
      const id = localUser ? localUser.id : rawId;
      return {
        accessToken: `demo-access-${id}`,
        refreshToken: `demo-refresh-${id}`,
        expiresAt: Date.now() + 86400000,
      };
    }

    const authClient = getAuthClient();
    const { data, error } = await authClient.auth.refreshSession({ refresh_token: refreshToken });

    if (error || !data.session) {
      throw new AuthError('Phiên đăng nhập đã hết hạn hoặc refresh token không hợp lệ', 401);
    }

    return {
      accessToken: data.session.access_token,
      refreshToken: data.session.refresh_token,
      expiresAt: data.session.expires_at,
    };
  }

  /**
   * Lấy thông tin hồ sơ tài khoản hiện tại
   */
  async getProfile(userId: string) {
    ensureDemoUser();
    const localUser = getLocalUserById(userId);
    if (localUser) {
      return {
        id: localUser.id,
        email: localUser.email,
        full_name: localUser.fullName,
        phone: localUser.phone,
        avatar_url: null,
        role: localUser.role,
        is_active: localUser.isActive,
        is_locked: localUser.isLocked,
        created_at: localUser.createdAt,
      };
    }

    const { data: profile, error } = await supabase
      .from('profiles')
      .select('id, email, full_name, phone, avatar_url, role, is_active, is_locked, created_at')
      .eq('id', userId)
      .maybeSingle();

    if (error) {
      throw new Error(error.message);
    }
    if (!profile) {
      throw new AuthError('Không tìm thấy thông tin hồ sơ người dùng', 404);
    }

    return profile;
  }

  /**
   * Kiểm tra trạng thái tài khoản (khóa / kích hoạt)
   */
  async checkAccountStatus(emailOrId: string) {
    ensureDemoUser();
    const localUser = getLocalUserById(emailOrId) || getLocalUserByEmail(emailOrId);
    if (localUser) {
      return {
        id: localUser.id,
        email: localUser.email,
        role: localUser.role,
        is_active: localUser.isActive,
        is_locked: localUser.isLocked,
      };
    }

    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(emailOrId);
    let query = supabase.from('profiles').select('id, email, role, is_active, is_locked');

    if (isUuid) {
      query = query.eq('id', emailOrId);
    } else {
      query = query.eq('email', emailOrId.toLowerCase().trim());
    }

    const { data, error } = await query.maybeSingle();
    if (error) {
      throw new Error(error.message);
    }

    if (!data) {
      return { exists: false };
    }

    return {
      exists: true,
      isActive: data.is_active,
      isLocked: data.is_locked,
      role: data.role,
    };
  }
}
