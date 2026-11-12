'use client';

import React, { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import {
  docNguoiDangNhap,
  docToken,
  duocVaoTrang,
  trangMacDinh,
} from '../lib/admin-session';

export function AdminAuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [authorized, setAuthorized] = useState(false);

  useEffect(() => {
    if (pathname === '/login') {
      setAuthorized(true);
      return;
    }

    if (typeof window === 'undefined') return;

    if (!docToken()) {
      router.replace('/login');
      return;
    }

    const nguoiDung = docNguoiDangNhap();
    if (!nguoiDung) {
      router.replace('/login');
      return;
    }

    // Go dia chi mot trang khong thuoc quyen thi dua ve trang dau cua vai tro,
    // khong da ve man dang nhap vi ho van dang dang nhap hop le.
    if (!duocVaoTrang(nguoiDung.role, pathname)) {
      router.replace(trangMacDinh(nguoiDung.role));
      return;
    }

    setAuthorized(true);
  }, [pathname, router]);

  if (!authorized && pathname !== '/login') {
    return (
      <div className="min-h-screen bg-canvas flex items-center justify-center text-ink-muted text-sm">
        Đang kiểm tra quyền đăng nhập quản trị...
      </div>
    );
  }

  return <>{children}</>;
}
