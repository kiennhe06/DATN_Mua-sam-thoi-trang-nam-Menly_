import { supabase } from '../config/supabase.js';
import type { UpdateProfileInput } from '../validators/profile.validator.js';

export class ProfileError extends Error {
  statusCode: number;
  constructor(message: string, statusCode = 400) {
    super(message);
    this.name = 'ProfileError';
    this.statusCode = statusCode;
  }
}

export interface UserProfile {
  id: string;
  email: string | null;
  fullName: string | null;
  phone: string | null;
  avatarUrl: string | null;
  role: string;
  isGuest: boolean;
  isActive: boolean;
  isLocked: boolean;
  createdAt: string;
}

export interface ProfileUpdateDTO {
  fullName?: string;
  full_name?: string;
  phone?: string;
  avatarUrl?: string;
  avatar_url?: string;
}

export class ProfileModel {
  protected db = supabase;
  private bucketName = 'avatars';
  private bucketEnsured = false;

  private async ensureBucketExists() {
    if (this.bucketEnsured) return;
    try {
      const { data: buckets } = await this.db.storage.listBuckets();
      const exists = buckets?.some((b) => b.name === this.bucketName);
      if (!exists) {
        await this.db.storage.createBucket(this.bucketName, {
          public: true,
          fileSizeLimit: 5 * 1024 * 1024,
          allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
        });
      }
      this.bucketEnsured = true;
    } catch {
      this.bucketEnsured = true;
    }
  }

  async getProfile(userId: string): Promise<UserProfile> {
    const { data, error } = await this.db
      .from('profiles')
      .select('id, email, full_name, phone, avatar_url, role, is_guest, is_active, is_locked, created_at')
      .eq('id', userId)
      .maybeSingle();

    if (error) {
      throw new Error(`Lỗi truy vấn hồ sơ: ${error.message}`);
    }

    if (!data) {
      throw new ProfileError('Không tìm thấy thông tin hồ sơ người dùng', 404);
    }

    return {
      id: data.id,
      email: data.email,
      fullName: data.full_name,
      phone: data.phone,
      avatarUrl: data.avatar_url,
      role: data.role,
      isGuest: data.is_guest,
      isActive: data.is_active,
      isLocked: data.is_locked,
      createdAt: data.created_at,
    };
  }

  /**
   * Alias getById tương thích
   */
  async getById(userId: string) {
    const profile = await this.getProfile(userId);
    return {
      id: profile.id,
      email: profile.email,
      full_name: profile.fullName,
      phone: profile.phone,
      avatar_url: profile.avatarUrl,
      role: profile.role,
      created_at: profile.createdAt,
    };
  }

  async updateProfile(userId: string, input: ProfileUpdateDTO): Promise<UserProfile> {
    const updateData: Record<string, unknown> = {};

    const fullName = input.fullName ?? input.full_name;
    const avatarUrl = input.avatarUrl ?? input.avatar_url;
    const phone = input.phone;

    if (fullName !== undefined) {
      updateData.full_name = fullName;
    }
    if (phone !== undefined) {
      updateData.phone = phone === '' ? null : phone;
    }
    if (avatarUrl !== undefined) {
      updateData.avatar_url = avatarUrl === '' ? null : avatarUrl;
    }

    if (Object.keys(updateData).length === 0) {
      throw new ProfileError('Không có trường dữ liệu nào để cập nhật', 400);
    }

    const { data, error } = await this.db
      .from('profiles')
      .update(updateData)
      .eq('id', userId)
      .select('id, email, full_name, phone, avatar_url, role, is_guest, is_active, is_locked, created_at')
      .maybeSingle();

    if (error) {
      throw new Error(`Không thể cập nhật hồ sơ: ${error.message}`);
    }

    if (!data) {
      throw new ProfileError('Không tìm thấy hồ sơ người dùng để cập nhật', 404);
    }

    // Nếu cập nhật fullName, đồng bộ metadata trong Supabase Auth
    if (fullName !== undefined) {
      try {
        await this.db.auth.admin.updateUserById(userId, {
          user_metadata: { full_name: fullName },
        });
      } catch {
        // Không block nếu metadata sync bị lỗi
      }
    }

    return {
      id: data.id,
      email: data.email,
      fullName: data.full_name,
      phone: data.phone,
      avatarUrl: data.avatar_url,
      role: data.role,
      isGuest: data.is_guest,
      isActive: data.is_active,
      isLocked: data.is_locked,
      createdAt: data.created_at,
    };
  }

  /**
   * Alias update tương thích
   */
  async update(userId: string, fields: { full_name?: string; phone?: string; avatar_url?: string }) {
    const updated = await this.updateProfile(userId, {
      full_name: fields.full_name,
      phone: fields.phone,
      avatar_url: fields.avatar_url,
    });
    return {
      id: updated.id,
      email: updated.email,
      full_name: updated.fullName,
      phone: updated.phone,
      avatar_url: updated.avatarUrl,
      role: updated.role,
    };
  }

  async uploadAvatar(userId: string, file: Express.Multer.File): Promise<{ avatarUrl: string; filePath: string }> {
    await this.ensureBucketExists();

    const extMatch = file.originalname.match(/\.([a-zA-Z0-9]+)$/);
    const ext = extMatch ? extMatch[1].toLowerCase() : (file.mimetype?.split('/')[1] || 'jpg');
    const fileName = `${Date.now()}-${Math.random().toString(36).substring(2, 8)}.${ext}`;
    const filePath = `${userId}/${fileName}`;
    const contentType = file.mimetype && file.mimetype !== 'application/octet-stream'
      ? file.mimetype
      : `image/${ext === 'jpg' ? 'jpeg' : ext}`;

    const { error: uploadError } = await this.db.storage
      .from(this.bucketName)
      .upload(filePath, file.buffer, {
        contentType,
        upsert: true,
      });

    if (uploadError) {
      throw new ProfileError(`Lỗi tải ảnh lên lưu trữ Supabase: ${uploadError.message}`, 500);
    }

    const { data: publicUrlData } = this.db.storage
      .from(this.bucketName)
      .getPublicUrl(filePath);

    const avatarUrl = publicUrlData.publicUrl;

    // Cập nhật avatar_url vào hồ sơ người dùng
    await this.updateProfile(userId, { avatarUrl });

    return {
      avatarUrl,
      filePath,
    };
  }
}
