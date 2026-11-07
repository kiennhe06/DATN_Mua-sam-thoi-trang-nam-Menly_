'use client';

import React from 'react';
import { UserAccount } from '../lib/types';
import { Shield, User as UserIcon, Lock, Unlock, Edit2, Trash2 } from 'lucide-react';

interface UsersTableProps {
  users: UserAccount[];
  loading: boolean;
  onToggleLock: (u: UserAccount) => void;
  onEdit: (u: UserAccount) => void;
  onDelete: (u: UserAccount) => void;
}

export function UsersTable({
  users,
  loading,
  onToggleLock,
  onEdit,
  onDelete,
}: UsersTableProps) {
  return (
    <div className="bg-panel border border-line rounded-2xl overflow-hidden shadow-xl">
      {loading ? (
        <div className="py-20 text-center text-ink-muted text-sm">Đang tải danh sách người dùng...</div>
      ) : users.length === 0 ? (
        <div className="py-20 text-center text-ink-muted text-sm">Không tìm thấy người dùng nào</div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-line text-xs text-ink-muted uppercase tracking-wider font-semibold bg-tint">
                <th className="py-3 px-4">Tài khoản & Email</th>
                <th className="py-3 px-4">Vai trò</th>
                <th className="py-3 px-4">Trạng thái đăng nhập</th>
                <th className="py-3 px-4">Ngày tạo</th>
                <th className="py-3 px-4 text-right">Thao tác quản trị</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-line text-ink-mid text-xs">
              {users.map((u) => (
                <tr key={u.id} className="hover:bg-tint transition-colors">
                  <td className="py-3 px-4">
                    <div className="flex items-center gap-3">
                      <div
                        className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-xs ${
                          u.role === 'admin'
                            ? 'bg-camel-tint text-camel-dark border border-camel/25'
                            : 'bg-tint text-ink-mid'
                        }`}
                      >
                        {u.name ? u.name.charAt(0).toUpperCase() : 'U'}
                      </div>
                      <div>
                        <p className="font-semibold text-ink">{u.name}</p>
                        <p className="text-ink-muted font-mono text-[11px]">{u.email}</p>
                      </div>
                    </div>
                  </td>

                  <td className="py-3 px-4">
                    <span
                      className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full font-bold text-[10px] border ${
                        u.role === 'admin'
                          ? 'bg-camel-tint text-camel-dark border-camel/25'
                          : u.role === 'staff'
                          ? 'bg-role-staff-bg text-role-staff-text border-role-staff-text/20'
                          : u.role === 'seller'
                          ? 'bg-ok-bg text-ok border-ok-line'
                          : 'bg-role-customer-bg text-role-customer-text border-role-customer-text/20'
                      }`}
                    >
                      {u.role === 'admin' ? <Shield className="w-3 h-3" /> : <UserIcon className="w-3 h-3" />}
                      {u.role === 'admin'
                        ? 'Quản trị viên (Admin)'
                        : u.role === 'staff'
                        ? 'Nhân viên (Staff)'
                        : u.role === 'seller'
                        ? 'Người bán (Seller)'
                        : 'Khách hàng (User)'}
                    </span>
                  </td>

                  <td className="py-3 px-4">
                    <span
                      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full font-bold text-[10px] border ${
                        u.isLocked
                          ? 'bg-danger-bg text-danger border-danger-line'
                          : 'bg-ok-bg text-ok border-ok-line'
                      }`}
                    >
                      <span
                        className={`w-1.5 h-1.5 rounded-full ${
                          u.isLocked ? 'bg-danger' : 'bg-ok'
                        }`}
                      />
                      {u.isLocked ? 'Đã bị khóa đăng nhập' : 'Đang hoạt động'}
                    </span>
                  </td>

                  <td className="py-3 px-4 font-mono text-ink-muted">
                    {new Date(u.createdAt).toLocaleDateString('vi-VN')}
                  </td>

                  <td className="py-3 px-4 text-right">
                    <div className="flex items-center justify-end gap-2">
                      <button
                        onClick={() => onToggleLock(u)}
                        disabled={u.email === 'admin@gmail.com'}
                        className={`p-1.5 rounded-lg border text-xs font-semibold flex items-center gap-1 transition-colors cursor-pointer disabled:opacity-30 disabled:cursor-not-allowed ${
                          u.isLocked
                            ? 'bg-ok-bg text-ok border-ok-line hover:bg-ok-bg'
                            : 'bg-danger-bg text-danger border-danger-line hover:bg-danger-bg'
                        }`}
                        title={u.isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản'}
                      >
                        {u.isLocked ? <Unlock className="w-3.5 h-3.5" /> : <Lock className="w-3.5 h-3.5" />}
                        {u.isLocked ? 'Mở khóa' : 'Khóa TK'}
                      </button>

                      <button
                        onClick={() => onEdit(u)}
                        className="p-1.5 rounded-lg bg-tint hover:bg-tint-strong text-ink-mid hover:text-ink border border-line-strong transition-colors cursor-pointer"
                        title="Chỉnh sửa thông tin"
                      >
                        <Edit2 className="w-3.5 h-3.5" />
                      </button>

                      <button
                        onClick={() => onDelete(u)}
                        disabled={u.email === 'admin@gmail.com'}
                        className="p-1.5 rounded-lg bg-tint hover:bg-danger-bg text-ink-muted hover:text-danger border border-line-strong transition-colors cursor-pointer disabled:opacity-30 disabled:cursor-not-allowed"
                        title="Xóa tài khoản"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
