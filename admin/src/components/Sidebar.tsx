'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  Boxes,
  ClipboardList,
  LayoutDashboard,
  Menu,
  Settings,
  Shirt,
  ShoppingBag,
  Star,
  Ticket,
  Users,
  X,
} from 'lucide-react';

const NAV_ITEMS = [
  { href: '/', label: 'Tổng quan', icon: LayoutDashboard },
  { href: '/products', label: 'Sản phẩm', icon: Shirt },
  { href: '/orders', label: 'Đơn hàng', icon: ShoppingBag },
  { href: '/inventory', label: 'Kho hàng & tồn kho', icon: Boxes },
  { href: '/vouchers', label: 'Mã giảm giá', icon: Ticket },
  { href: '/reviews', label: 'Đánh giá', icon: Star },
  { href: '/users', label: 'Người dùng', icon: Users },
  { href: '/audit', label: 'Nhật ký hoạt động', icon: ClipboardList },
  { href: '/settings', label: 'Cài đặt hệ thống', icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    setIsOpen(false);
  }, [pathname]);

  return (
    <>
      <button
        type="button"
        onClick={() => setIsOpen(true)}
        aria-label="Mở menu điều hướng"
        aria-expanded={isOpen}
        className="fixed left-4 top-4 z-30 inline-flex h-10 w-10 items-center justify-center rounded-xl border border-slate-700 bg-slate-900 text-slate-200 shadow-lg transition hover:border-amber-400/50 hover:text-amber-300 md:hidden"
      >
        <Menu className="h-5 w-5" />
      </button>

      {isOpen && (
        <button
          type="button"
          onClick={() => setIsOpen(false)}
          aria-label="Đóng menu điều hướng"
          className="fixed inset-0 z-40 bg-slate-950/75 backdrop-blur-sm md:hidden"
        />
      )}

      <aside
        className={`fixed inset-y-0 left-0 z-50 flex h-dvh w-72 max-w-[85vw] shrink-0 flex-col border-r border-slate-800 bg-slate-950 text-slate-200 shadow-2xl transition-transform duration-200 md:sticky md:top-0 md:z-20 md:h-screen md:w-64 md:max-w-none md:translate-x-0 md:shadow-none ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="flex items-center justify-between border-b border-slate-800 px-5 py-5 sm:px-6">
          <Link href="/" className="group min-w-0">
            <div className="flex items-center gap-2.5">
              <span className="flex h-9 w-9 items-center justify-center rounded-xl border border-amber-400/30 bg-amber-400/10 text-lg font-black text-amber-300">
                M
              </span>
              <span className="truncate text-base font-extrabold tracking-[0.16em] text-white">
                MENLY
              </span>
            </div>
            <p className="ml-11 mt-1 text-[10px] font-semibold uppercase tracking-[0.18em] text-slate-500">
              Admin workspace
            </p>
          </Link>
          <button
            type="button"
            onClick={() => setIsOpen(false)}
            aria-label="Đóng menu"
            className="rounded-lg p-2 text-slate-400 transition hover:bg-slate-800 hover:text-white md:hidden"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="px-5 pb-2 pt-6">
          <p className="text-[10px] font-bold uppercase tracking-[0.18em] text-slate-500">
            Không gian quản trị
          </p>
        </div>
        <nav aria-label="Điều hướng quản trị" className="flex-1 space-y-1 overflow-y-auto px-3 pb-5">
          {NAV_ITEMS.map((item) => {
            const Icon = item.icon;
            const isActive =
              pathname === item.href ||
              (item.href !== '/' && pathname.startsWith(`${item.href}/`));

            return (
              <Link
                key={item.href}
                href={item.href}
                aria-current={isActive ? 'page' : undefined}
                className={`group flex items-center gap-3 rounded-xl border px-3.5 py-3 text-[13px] font-semibold transition-colors ${
                  isActive
                    ? 'border-amber-400/20 bg-amber-400/10 text-amber-200'
                    : 'border-transparent text-slate-400 hover:border-slate-800 hover:bg-slate-900 hover:text-slate-100'
                }`}
              >
                <Icon
                  className={`h-[18px] w-[18px] shrink-0 ${
                    isActive ? 'text-amber-300' : 'text-slate-500 group-hover:text-slate-300'
                  }`}
                />
                <span>{item.label}</span>
                {isActive && <span className="ml-auto h-1.5 w-1.5 rounded-full bg-amber-300" />}
              </Link>
            );
          })}
        </nav>

        <div className="border-t border-slate-800 p-4">
          <div className="rounded-xl border border-slate-800 bg-slate-900/70 p-3">
            <div className="flex items-center gap-2.5">
              <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-300">
                <span className="h-2 w-2 rounded-full bg-emerald-400" />
              </span>
              <div>
                <p className="text-xs font-semibold text-slate-200">Hệ thống quản trị</p>
                <p className="mt-0.5 text-[10px] text-slate-500">Không gian làm việc Menly</p>
              </div>
            </div>
          </div>
        </div>
      </aside>
    </>
  );
}
