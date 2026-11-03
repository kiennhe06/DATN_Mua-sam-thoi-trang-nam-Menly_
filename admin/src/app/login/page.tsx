'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { loginUser, getLockoutStatus } from '@/lib/api';
import { ShieldCheck, AlertCircle, CheckCircle2 } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

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
      if (res.user.role !== 'admin') {
        throw new Error('Chỉ tài khoản Quản trị viên (Admin) mới có quyền truy cập trang quản trị!');
      }

      setSuccessMsg(`Đăng nhập thành công! Chào mừng ${res.user.fullName || res.user.email}`);
      localStorage.setItem('menshop_admin_token', `Bearer ${res.accessToken}`);
      localStorage.setItem('menshop_admin_user', JSON.stringify(res.user));

      setTimeout(() => {
        router.push('/');
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

  const handlePreview = () => {
    localStorage.setItem('menshop_admin_token', 'ui-preview');
    localStorage.setItem(
      'menshop_admin_user',
      JSON.stringify({ fullName: 'Admin Preview', email: 'admin@menly.local', role: 'admin' })
    );
    router.push('/');
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-950 p-4">
      <div className="w-full max-w-md bg-slate-900 border border-slate-800 rounded-3xl p-8 shadow-2xl">
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-amber-500/15 border border-amber-500/30 text-amber-400 font-bold text-2xl mb-3 shadow-lg">
            M
          </div>
          <h1 className="text-2xl font-bold text-white tracking-tight">MenShop Admin Portal</h1>
          <p className="text-xs text-slate-400 mt-1">Cổng quản trị hệ thống thương mại điện tử</p>
        </div>

        {errorMsg && (
          <div className="mb-4 p-3 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-400 text-xs flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}

        {successMsg && (
          <div className="mb-4 p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{successMsg}</span>
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1">Địa chỉ Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white focus:outline-none focus:border-amber-500"
              required
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1">Mật khẩu</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-sm text-white focus:outline-none focus:border-amber-500"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 rounded-xl bg-amber-500 text-slate-950 font-bold hover:bg-amber-400 transition-all cursor-pointer disabled:opacity-50 text-sm shadow-md mt-2 flex items-center justify-center gap-2"
          >
            {loading ? 'Đang xử lý...' : (
              <>
                <ShieldCheck className="w-4 h-4" />
                Đăng nhập Admin
              </>
            )}
          </button>
        </form>

        {process.env.NODE_ENV === 'development' && (
          <div className="mt-4 rounded-xl border border-slate-800 bg-slate-950/60 p-3">
            <p className="mb-2 text-center text-[11px] text-slate-400">
              Chỉ muốn xem giao diện? Có thể xem trước mà không kết nối backend.
            </p>
            <button
              type="button"
              onClick={handlePreview}
              className="w-full rounded-lg border border-amber-400/30 bg-amber-400/5 px-3 py-2 text-xs font-semibold text-amber-200 transition hover:bg-amber-400/10"
            >
              Xem trước giao diện quản trị
            </button>
          </div>
        )}

        <div className="mt-6 p-3 rounded-xl bg-slate-950/60 border border-slate-800/80 text-[11px] text-slate-400">
          Đăng nhập bằng tài khoản Supabase có quyền quản trị viên (role admin).
        </div>
      </div>
    </div>
  );
}
