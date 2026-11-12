'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { loginUser, getLockoutStatus } from '@/lib/api';
import { laVaiTroQuanTri, tenVaiTro, trangMacDinh } from '@/lib/admin-session';
import { ShieldCheck, AlertCircle, CheckCircle2 } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();

  // Dien san tai khoan admin chinh cho tien dang nhap (du an public, chap nhan cong khai)
  const [email, setEmail] = useState('admin@gmail.com');
  const [password, setPassword] = useState('123456');

  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setErrorMsg(null);
    setSuccessMsg(null);

    try {
      const res = await loginUser(email, password);
      // Nhan vien duoc cap quyen cung dang nhap bang chinh tai khoan cua ho,
      // chi khac la vao duoc it trang hon admin.
      if (!laVaiTroQuanTri(res.user.role)) {
        throw new Error(
          'Tài khoản này chưa được cấp quyền quản trị hoặc nhân viên. Liên hệ quản trị viên để được cấp quyền.',
        );
      }

      const vaiTro = res.user.role;
      setSuccessMsg(
        `Đăng nhập thành công! Chào mừng ${res.user.fullName || res.user.email} (${tenVaiTro(vaiTro)})`,
      );
      localStorage.setItem('menshop_admin_token', `Bearer ${res.accessToken}`);
      localStorage.setItem('menshop_admin_user', JSON.stringify(res.user));

      setTimeout(() => {
        router.push(trangMacDinh(vaiTro));
      }, 800);
    } catch (err: unknown) {
      const error = err as { message?: string; status?: number };
      setErrorMsg(error.message || 'Đăng nhập không thành công');
      try {
        await getLockoutStatus(email);
      } catch {
        // ignore
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-canvas p-4">
      <div className="w-full max-w-md bg-panel border border-line rounded-3xl p-8 shadow-panel-lg">
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-camel/15 border border-camel/30 text-camel-dark font-bold text-2xl mb-3">
            M
          </div>
          <h1 className="text-2xl font-bold text-ink tracking-tight">MenShop Admin Portal</h1>
          <p className="text-xs text-ink-muted mt-1">Cổng quản trị hệ thống thương mại điện tử</p>
        </div>

        {errorMsg && (
          <div className="mb-4 p-3 rounded-xl bg-danger-bg border border-danger-line text-danger text-xs flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}

        {successMsg && (
          <div className="mb-4 p-3 rounded-xl bg-ok-bg border border-ok-line text-ok text-xs flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{successMsg}</span>
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-ink-mid mb-1">Địa chỉ Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-panel border border-line rounded-xl text-sm text-ink focus:outline-none focus:border-camel shadow-panel"
              required
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-ink-mid mb-1">Mật khẩu</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-panel border border-line rounded-xl text-sm text-ink focus:outline-none focus:border-camel shadow-panel"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 rounded-xl bg-camel text-ink font-bold hover:bg-camel-hover transition-all cursor-pointer disabled:opacity-50 text-sm shadow-md mt-2 flex items-center justify-center gap-2"
          >
            {loading ? 'Đang xử lý...' : (
              <>
                <ShieldCheck className="w-4 h-4" />
                Đăng nhập
              </>
            )}
          </button>
        </form>

        <div className="mt-6 p-3 rounded-xl bg-tint border border-line text-[11px] text-ink-muted">
          Dành cho tài khoản đã được cấp quyền. Nhân viên vào Đơn hàng và Chat CSKH;
          quản trị viên vào các mục còn lại.
        </div>
      </div>
    </div>
  );
}
