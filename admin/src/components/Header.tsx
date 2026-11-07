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
    <header className="sticky top-0 z-20 flex items-center justify-between gap-3 border-b border-line bg-canvas/85 px-4 py-3.5 pl-16 backdrop-blur-xl sm:px-6 sm:pl-16 md:px-8 md:pl-8">
      <div className="min-w-0">
        <p className="mb-1 hidden text-[10px] font-bold uppercase tracking-[0.18em] text-camel-dark sm:block">
          Menly / Quản trị
        </p>
        <h1 className="truncate text-base font-bold tracking-tight text-ink sm:text-xl">{title}</h1>
        {subtitle && (
          <p className="mt-1 hidden max-w-3xl truncate text-xs text-ink-muted sm:block">{subtitle}</p>
        )}
      </div>

      <div className="flex shrink-0 items-center gap-2 sm:gap-3">
        <div className="hidden items-center gap-2.5 border-r border-line pr-4 lg:flex">
          <span className="flex h-9 w-9 items-center justify-center rounded-full border border-camel/25 bg-camel-tint text-camel-dark">
            <ShieldCheck className="h-4 w-4" />
          </span>
          <div className="max-w-40">
            <p className="truncate text-xs font-semibold text-ink">{identity}</p>
            <p className="mt-0.5 text-[10px] text-ink-muted">Quản trị viên</p>
          </div>
        </div>

        {onRefresh && (
          <button
            type="button"
            onClick={onRefresh}
            className="inline-flex h-9 w-9 items-center justify-center rounded-lg border border-line bg-panel text-ink-mid shadow-panel transition hover:border-line-strong hover:bg-tint hover:text-ink"
            title="Làm mới dữ liệu"
            aria-label="Làm mới dữ liệu"
          >
            <RefreshCw className="h-4 w-4" />
          </button>
        )}

        <button
          type="button"
          onClick={handleLogout}
          className="inline-flex h-9 items-center justify-center gap-2 rounded-lg border border-line bg-panel px-2.5 text-xs font-semibold text-ink-mid shadow-panel transition hover:border-danger-line hover:bg-danger-bg hover:text-danger sm:px-3"
          title="Đăng xuất khỏi hệ thống"
        >
          <LogOut className="h-4 w-4" />
          <span className="hidden sm:inline">Đăng xuất</span>
        </button>
      </div>
    </header>
  );
}
