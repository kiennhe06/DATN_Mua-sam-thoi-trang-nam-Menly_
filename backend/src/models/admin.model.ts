import { supabase } from '../config/supabase.js';
import type {
  AdminCreateUserInput,
  AdminUpdateUserInput,
} from '../validators/admin-user.validator.js';

// Dong profiles trong DB (snake_case)
interface ProfileRow {
  id: string;
  email: string | null;
  full_name: string | null;
  phone: string | null;
  avatar_url: string | null;
  role: string;
  is_active: boolean;
  is_locked: boolean;
  created_at: string;
}

// Dang camelCase tra ve cho admin frontend
export interface AdminUser {
  id: string;
  email: string;
  name: string | null;
  fullName: string | null;
  role: string;
  phone: string | null;
  avatarUrl: string | null;
  isActive: boolean;
  isLocked: boolean;
  createdAt: string;
}

const PROFILE_COLUMNS =
  'id, email, full_name, phone, avatar_url, role, is_active, is_locked, created_at';

function toAdminUser(row: ProfileRow): AdminUser {
  return {
    id: row.id,
    email: row.email ?? '',
    name: row.full_name,
    fullName: row.full_name,
    role: row.role,
    phone: row.phone,
    avatarUrl: row.avatar_url,
    isActive: row.is_active,
    isLocked: row.is_locked,
    createdAt: row.created_at,
  };
}

// Lop truy cap du lieu cho: Quan tri nguoi dung
export class AdminModel {
  protected db = supabase;

  /** [Admin] Danh sach tat ca nguoi dung */
  async listUsers(): Promise<AdminUser[]> {
    const { data, error } = await this.db
      .from('profiles')
      .select(PROFILE_COLUMNS)
      .order('created_at', { ascending: false });

    if (error) throw new Error(error.message);
    return (data ?? []).map((row) => toAdminUser(row as ProfileRow));
  }

  /** [Admin] Tao nguoi dung moi qua Supabase Auth, roi cap nhat ho so */
  async createUser(input: AdminCreateUserInput): Promise<AdminUser> {
    // Mat khau mac dinh neu admin khong nhap
    const password = input.password ?? 'menly@123';

    const { data: created, error: authError } = await this.db.auth.admin.createUser({
      email: input.email,
      password,
      email_confirm: true,
      user_metadata: { full_name: input.name, role: input.role },
    });

    if (authError || !created?.user) {
      if (authError?.message?.toLowerCase().includes('already')) {
        throw new Error('Email này đã được đăng ký trong hệ thống');
      }
      throw new Error(authError?.message ?? 'Không thể tạo người dùng');
    }

    // Trigger da tao san ho so; cap nhat them ten + role theo yeu cau
    const { data: profile, error: profileError } = await this.db
      .from('profiles')
      .update({ full_name: input.name, role: input.role, email: input.email })
      .eq('id', created.user.id)
      .select(PROFILE_COLUMNS)
      .maybeSingle();

    if (profileError || !profile) {
      // Ho so chua kip tao -> tu insert
      const { data: inserted, error: insertError } = await this.db
        .from('profiles')
        .upsert(
          {
            id: created.user.id,
            email: input.email,
            full_name: input.name,
            role: input.role,
            is_active: true,
            is_locked: false,
          },
          { onConflict: 'id' },
        )
        .select(PROFILE_COLUMNS)
        .single();
      if (insertError || !inserted) {
        throw new Error(insertError?.message ?? 'Tạo tài khoản nhưng không lưu được hồ sơ');
      }
      return toAdminUser(inserted as ProfileRow);
    }

    return toAdminUser(profile as ProfileRow);
  }

  /** [Admin] Cap nhat ho so nguoi dung (ten / role / so dien thoai) */
  async updateUser(id: string, input: AdminUpdateUserInput): Promise<AdminUser | null> {
    const patch: Record<string, unknown> = {};
    const fullName = input.fullName ?? input.name;
    if (fullName !== undefined) patch.full_name = fullName;
    if (input.role !== undefined) patch.role = input.role;
    if (input.phone !== undefined) patch.phone = input.phone;

    // Doi email: cap nhat ca ben Auth lan bang profiles
    if (input.email !== undefined) {
      const { error: authErr } = await this.db.auth.admin.updateUserById(id, {
        email: input.email,
        email_confirm: true,
      });
      if (authErr) {
        if (authErr.message?.toLowerCase().includes('already')) {
          throw new Error('Email này đã được sử dụng bởi tài khoản khác');
        }
        throw new Error(authErr.message);
      }
      patch.email = input.email;
    }

    if (Object.keys(patch).length === 0) return this.getUser(id);

    const { data, error } = await this.db
      .from('profiles')
      .update(patch)
      .eq('id', id)
      .select(PROFILE_COLUMNS)
      .maybeSingle();

    if (error) throw new Error(error.message);
    if (!data) return null;
    return toAdminUser(data as ProfileRow);
  }

  /** [Admin] Lay 1 nguoi dung */
  async getUser(id: string): Promise<AdminUser | null> {
    const { data, error } = await this.db
      .from('profiles')
      .select(PROFILE_COLUMNS)
      .eq('id', id)
      .maybeSingle();

    if (error) throw new Error(error.message);
    if (!data) return null;
    return toAdminUser(data as ProfileRow);
  }

  /** [Admin] Khoa / mo khoa nguoi dung */
  async setLock(id: string, isLocked: boolean): Promise<AdminUser | null> {
    const { data, error } = await this.db
      .from('profiles')
      .update({ is_locked: isLocked })
      .eq('id', id)
      .select(PROFILE_COLUMNS)
      .maybeSingle();

    if (error) throw new Error(error.message);
    if (!data) return null;
    return toAdminUser(data as ProfileRow);
  }

  /** [Admin] Xoa nguoi dung (xoa auth.users -> profiles tu xoa theo cascade) */
  async deleteUser(id: string): Promise<boolean> {
    const { error } = await this.db.auth.admin.deleteUser(id);
    if (error) throw new Error(error.message);
    return true;
  }
}
