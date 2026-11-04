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

export class AuthModel {
  /**
   * Đăng ký tài khoản mới qua Supabase Auth
   */
  async register(input: RegisterInput) {
    const { email, password, fullName, phone, role } = input;
    const userRole = role ?? 'customer';
    const normalizedEmail = email.toLowerCase();

    // Dung Admin API (service_role) thay cho signUp de dang ky luon hoat dong:
    // - Khong bi chan boi cau hinh "Allow new users to sign up" cua Supabase
    // - email_confirm: true -> kich hoat ngay, khong gui email xac nhan
    //   nen khong vuong gioi han gui email (rate limit) cua Supabase
    const { data: created, error: authError } = await supabase.auth.admin.createUser({
      email: normalizedEmail,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: fullName,
        phone: phone || '',
        role: userRole,
      },
    });

    if (authError || !created?.user) {
      const message = authError?.message?.toLowerCase() ?? '';
      if (message.includes('already') || message.includes('registered') || message.includes('exists')) {
        throw new AuthError('Email này đã được đăng ký trong hệ thống', 409);
      }
      throw new AuthError(authError?.message ?? 'Không thể tạo tài khoản, vui lòng thử lại sau', 400);
    }

    // Đảm bảo thông tin hồ sơ được cập nhật đầy đủ trong bảng profiles
    const { error: profileError } = await supabase.from('profiles').upsert(
      {
        id: created.user.id,
        email: created.user.email ?? normalizedEmail,
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

    return {
      message: 'Đăng ký tài khoản thành công',
      accessToken: null,
      refreshToken: null,
      expiresAt: null,
      user: {
        id: created.user.id,
        email: created.user.email ?? normalizedEmail,
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
    const normalizedEmail = email.toLowerCase();

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
