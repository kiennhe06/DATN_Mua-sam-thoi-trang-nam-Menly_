'use client';

import React, { useState } from 'react';
import { Modal } from './Modal';
import { UserAccount } from '../lib/types';

interface EditUserModalProps {
  user: UserAccount | null;
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (id: string, data: { name?: string; email?: string; role?: 'admin' | 'staff' | 'user' | 'seller' }) => Promise<void>;
}

export function EditUserModal({ user, isOpen, onClose, onSubmit }: EditUserModalProps) {
  const [name, setName] = useState(user?.name || user?.fullName || '');
  const [email, setEmail] = useState(user?.email || '');
  const [role, setRole] = useState<'admin' | 'staff' | 'user' | 'seller'>('user');
  const [submitting, setSubmitting] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  React.useEffect(() => {
    if (user) {
      setName(user.name || user.fullName || '');
      setEmail(user.email);
      setRole((user.role as any) || 'user');
    }
  }, [user]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    setSubmitting(true);
    setErr(null);
    try {
      await onSubmit(user.id, { name, email, role });
      onClose();
    } catch (e: unknown) {
      setErr((e as Error).message || 'Lỗi khi cập nhật');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Chỉnh Sửa Thông Tin Người Dùng">
      <form onSubmit={handleSubmit} className="space-y-4 text-xs">
        {err && (
          <div className="p-3 rounded-xl bg-danger-bg border border-danger-line text-danger">
            {err}
          </div>
        )}
        <div>
          <label className="block text-ink-mid font-semibold mb-1">Họ và tên</label>
          <input
            type="text"
            required
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full px-3 py-2 bg-panel border border-line rounded-xl text-ink text-xs shadow-panel"
          />
        </div>
        <div>
          <label className="block text-ink-mid font-semibold mb-1">Địa chỉ Email</label>
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full px-3 py-2 bg-panel border border-line rounded-xl text-ink text-xs shadow-panel"
          />
        </div>
        <div>
          <label className="block text-ink-mid font-semibold mb-1">Vai trò</label>
          <select
            value={role}
            disabled={user?.email === 'admin@gmail.com'}
            onChange={(e) => setRole(e.target.value as 'admin' | 'staff' | 'user' | 'seller')}
            className="w-full px-3 py-2 bg-panel border border-line rounded-xl text-ink text-xs disabled:opacity-50 shadow-panel"
          >
            <option value="user">Khách hàng (User)</option>
            <option value="staff">Nhân viên (Staff)</option>
            <option value="seller">Người bán (Seller)</option>
            <option value="admin">Quản trị viên (Admin)</option>
          </select>
        </div>
        <div className="flex justify-end gap-2 pt-2">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-xl text-ink-muted hover:text-ink"
          >
            Hủy
          </button>
          <button
            type="submit"
            disabled={submitting}
            className="px-4 py-2 bg-camel text-ink rounded-xl font-bold hover:bg-camel-hover transition-colors disabled:opacity-50"
          >
            {submitting ? 'Đang lưu...' : 'Lưu thay đổi'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
