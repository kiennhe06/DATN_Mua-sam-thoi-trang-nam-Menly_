'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { LogOut, RefreshCw, ShieldCheck } from 'lucide-react';

interface HeaderProps {
  title: string;
  subtitle?: string;
  onRefresh?: () => void;
}

interface AdminIdentity {
  fullName?: string;
  name?: string;
  email?: string;
}

function getIdentityName(value: string | null): string {
  if (!value) return 'Quản trị viên';

  try {
    const user: unknown = JSON.parse(value);
    if (typeof user !== 'object' || user === null) return 'Quản trị viên';
    const identity = user as AdminIdentity;
    return identity.fullName || identity.name || identity.email || 'Quản trị viên';
  } catch {
    return 'Quản trị viên';
  }
}

export function Header({ title, subtitle, onRefresh }: HeaderProps) {
  const router = useRouter();
  const [identity, setIdentity] = useState('Quản trị viên');

  useEffect(() => {
    setIdentity(getIdentityName(localStorage.getItem('menshop_admin_user')));
  }, []);

  function handleLogout() {
    localStorage.removeItem('menshop_admin_token');
    localStorage.removeItem('menshop_admin_user');
    router.push('/login');
  }

  return (
    <header className="sticky top-0 z-20 flex items-center justify-between gap-3 border-b border-slate-800/80 bg-slate-950/85 px-4 py-3.5 pl-16 backdrop-blur-xl sm:px-6 sm:pl-16 md:px-8 md:pl-8">
      <div className="min-w-0">
        <p className="mb-1 hidden text-[10px] font-bold uppercase tracking-[0.18em] text-amber-300/80 sm:block">
          Menly / Quản trị
        </p>
        <h1 className="truncate text-base font-bold tracking-tight text-white sm:text-xl">{title}</h1>
        {subtitle && (
          <p className="mt-1 hidden max-w-3xl truncate text-xs text-slate-400 sm:block">{subtitle}</p>
        )}
      </div>

      <div className="flex shrink-0 items-center gap-2 sm:gap-3">
        <div className="hidden items-center gap-2.5 border-r border-slate-800 pr-4 lg:flex">
          <span className="flex h-9 w-9 items-center justify-center rounded-full border border-amber-400/20 bg-amber-400/10 text-amber-300">
            <ShieldCheck className="h-4 w-4" />
          </span>
          <div className="max-w-40">
            <p className="truncate text-xs font-semibold text-slate-200">{identity}</p>
            <p className="mt-0.5 text-[10px] text-slate-500">Quản trị viên</p>
          </div>
        </div>

        {onRefresh && (
          <button
            type="button"
            onClick={onRefresh}
            className="inline-flex h-9 w-9 items-center justify-center rounded-xl border border-slate-800 bg-slate-900 text-slate-300 transition hover:border-slate-700 hover:bg-slate-800 hover:text-white"
            title="Làm mới dữ liệu"
            aria-label="Làm mới dữ liệu"
          >
            <RefreshCw className="h-4 w-4" />
          </button>
        )}

        <button
          type="button"
          onClick={handleLogout}
          className="inline-flex h-9 items-center justify-center gap-2 rounded-xl border border-slate-800 bg-slate-900 px-2.5 text-xs font-semibold text-slate-300 transition hover:border-rose-500/30 hover:bg-rose-500/10 hover:text-rose-300 sm:px-3"
          title="Đăng xuất khỏi hệ thống"
        >
          <LogOut className="h-4 w-4" />
          <span className="hidden sm:inline">Đăng xuất</span>
        </button>
      </div>
    </header>
  );
}
