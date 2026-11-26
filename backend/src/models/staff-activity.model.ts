import { supabase } from '../config/supabase.js';

/** Một dòng trong nhật ký thao tác của nhân viên. */
export interface StaffActivityEntry {
  staffId: string;
  staffName: string;
  loai: 'order' | 'chat' | 'stock';
  moTa: string;
  /** Mã đơn để bấm vào xem; chỉ có với loại 'order'. */
  orderId?: string | null;
  orderCode?: string | null;
  at: string;
}

/** Số việc mỗi loại của một nhân viên. */
export interface StaffCounts {
  orders: number;
  chats: number;
  stock: number;
}

/** Một dòng trong bảng tổng kết: nhân viên + số việc + lương tính ra. */
export interface StaffSummaryRow {
  staffId: string;
  staffName: string;
  email: string | null;
  role: string;
  counts: StaffCounts;
  salary: StaffSalary;
  /** Lương tính ra theo đúng số việc trong khoảng đang xem. */
  tongLuong: number;
}

/** Cấu hình lương của một nhân viên. */
export interface StaffSalary {
  baseSalary: number;
  bonusPerOrder: number;
  bonusPerChat: number;
  bonusPerStock: number;
}

const LUONG_MAC_DINH: StaffSalary = {
  baseSalary: 0,
  bonusPerOrder: 0,
  bonusPerChat: 0,
  bonusPerStock: 0,
};

export interface StaffActivityFilter {
  staffId?: string;
  /** Mốc đầu, ISO. Để trống thì lấy tất cả. */
  from?: string;
  /** Mốc cuối, ISO. */
  to?: string;
  /** Giới hạn số dòng nhật ký trả về. */
  limit?: number;
}

/**
 * Lớp tổng hợp hoạt động của nhân viên.
 *
 * Không có bảng "nhật ký nhân viên" riêng: dấu vết "ai làm gì" nằm rải ở ba
 * bảng (đổi trạng thái đơn, trả lời chat, chỉnh kho). Lớp này gom chúng lại
 * thành một dòng thời gian và đếm số việc, rồi tính lương từ số đó.
 */
export class StaffActivityModel {
  protected db = supabase;

  /** Toàn bộ nhân viên (vai trò staff hoặc admin). */
  async listStaff(): Promise<Array<{ id: string; name: string; email: string | null; role: string }>> {
    const { data, error } = await this.db
      .from('profiles')
      .select('id, full_name, email, role')
      .in('role', ['staff', 'admin'])
      .order('full_name');
    if (error) throw new Error(error.message);
    return (data ?? []).map((row) => ({
      id: row.id,
      name: row.full_name || row.email || 'Không tên',
      email: row.email ?? null,
      role: row.role,
    }));
  }

  /**
   * Nhật ký thao tác, trộn từ ba nguồn và xếp theo thời gian mới nhất.
   */
  async getActivityLog(loc: StaffActivityFilter = {}): Promise<StaffActivityEntry[]> {
    const nhanVien = await this.listStaff();
    const tenTheoId = new Map(nhanVien.map((nv) => [nv.id, nv.name]));
    const idNhanVien = new Set(nhanVien.map((nv) => nv.id));
    const limit = Math.min(Math.max(loc.limit ?? 200, 1), 500);

    const trongKhoang = (mocThoiGian: string) => {
      if (loc.from && mocThoiGian < loc.from) return false;
      if (loc.to && mocThoiGian > loc.to) return false;
      return true;
    };
    const dungNguoi = (id: string | null) =>
      !!id && idNhanVien.has(id) && (!loc.staffId || loc.staffId === id);

    const ketQua: StaffActivityEntry[] = [];

    // 1. Đổi trạng thái đơn.
    const { data: lichSuDon, error: loiDon } = await this.db
      .from('order_status_history')
      .select('changed_by, to_status, created_at, orders(id, code)')
      .order('created_at', { ascending: false })
      .limit(limit);
    if (loiDon) throw new Error(loiDon.message);
    for (const dong of lichSuDon ?? []) {
      if (!dungNguoi(dong.changed_by) || !trongKhoang(dong.created_at)) continue;
      const don = (dong as any).orders;
      ketQua.push({
        staffId: dong.changed_by!,
        staffName: tenTheoId.get(dong.changed_by!) ?? 'Không rõ',
        loai: 'order',
        moTa: `Chuyển đơn sang "${dong.to_status}"`,
        orderId: don?.id ?? null,
        orderCode: don?.code ?? null,
        at: dong.created_at,
      });
    }

    // 2. Trả lời chat CSKH.
    const { data: tinNhan, error: loiChat } = await this.db
      .from('support_messages')
      .select('sender_id, sender_role, created_at')
      .in('sender_role', ['staff', 'admin'])
      .order('created_at', { ascending: false })
      .limit(limit);
    if (loiChat) throw new Error(loiChat.message);
    for (const tin of tinNhan ?? []) {
      if (!dungNguoi(tin.sender_id) || !trongKhoang(tin.created_at)) continue;
      ketQua.push({
        staffId: tin.sender_id!,
        staffName: tenTheoId.get(tin.sender_id!) ?? 'Không rõ',
        loai: 'chat',
        moTa: 'Trả lời tin nhắn khách',
        at: tin.created_at,
      });
    }

    // 3. Chỉnh kho.
    const { data: khoHang, error: loiKho } = await this.db
      .from('inventory_movements')
      .select('created_by, reason, change, created_at')
      .order('created_at', { ascending: false })
      .limit(limit);
    if (loiKho) throw new Error(loiKho.message);
    for (const dong of khoHang ?? []) {
      if (!dungNguoi(dong.created_by) || !trongKhoang(dong.created_at)) continue;
      ketQua.push({
        staffId: dong.created_by!,
        staffName: tenTheoId.get(dong.created_by!) ?? 'Không rõ',
        loai: 'stock',
        moTa: `Chỉnh kho (${dong.reason}, ${dong.change > 0 ? '+' : ''}${dong.change})`,
        at: dong.created_at,
      });
    }

    ketQua.sort((a, b) => (a.at < b.at ? 1 : a.at > b.at ? -1 : 0));
    return ketQua.slice(0, limit);
  }

  /**
   * Bảng tổng: mỗi nhân viên một dòng, kèm số việc và lương tính ra.
   *
   * Đếm từ toàn bộ nhật ký trong khoảng (không cắt theo limit như nhật ký
   * hiển thị), để con số lương không bị thiếu việc.
   */
  async getSummary(loc: StaffActivityFilter = {}): Promise<StaffSummaryRow[]> {
    const nhanVien = await this.listStaff();
    const luongTheoId = await this.getAllSalaries();

    const dem = new Map<string, StaffCounts>();
    for (const nv of nhanVien) dem.set(nv.id, { orders: 0, chats: 0, stock: 0 });

    // Dùng lại nhật ký nhưng lấy nhiều để đếm đủ.
    const nhatKy = await this.getActivityLog({ ...loc, limit: 500 });
    for (const dong of nhatKy) {
      const d = dem.get(dong.staffId);
      if (!d) continue;
      if (dong.loai === 'order') d.orders += 1;
      else if (dong.loai === 'chat') d.chats += 1;
      else d.stock += 1;
    }

    return nhanVien
      .filter((nv) => !loc.staffId || nv.id === loc.staffId)
      .map((nv) => {
        const counts = dem.get(nv.id) ?? { orders: 0, chats: 0, stock: 0 };
        const salary = luongTheoId.get(nv.id) ?? LUONG_MAC_DINH;
        return {
          staffId: nv.id,
          staffName: nv.name,
          email: nv.email,
          role: nv.role,
          counts,
          salary,
          tongLuong: tinhLuong(counts, salary),
        };
      });
  }

  /** Cấu hình lương của một người (mặc định toàn 0 nếu chưa đặt). */
  async getSalary(userId: string): Promise<StaffSalary> {
    const { data, error } = await this.db
      .from('staff_salaries')
      .select('base_salary, bonus_per_order, bonus_per_chat, bonus_per_stock')
      .eq('user_id', userId)
      .maybeSingle();
    if (error) throw new Error(error.message);
    if (!data) return { ...LUONG_MAC_DINH };
    return {
      baseSalary: data.base_salary,
      bonusPerOrder: data.bonus_per_order,
      bonusPerChat: data.bonus_per_chat,
      bonusPerStock: data.bonus_per_stock,
    };
  }

  private async getAllSalaries(): Promise<Map<string, StaffSalary>> {
    const { data, error } = await this.db
      .from('staff_salaries')
      .select('user_id, base_salary, bonus_per_order, bonus_per_chat, bonus_per_stock');
    if (error) throw new Error(error.message);
    const map = new Map<string, StaffSalary>();
    for (const row of data ?? []) {
      map.set(row.user_id, {
        baseSalary: row.base_salary,
        bonusPerOrder: row.bonus_per_order,
        bonusPerChat: row.bonus_per_chat,
        bonusPerStock: row.bonus_per_stock,
      });
    }
    return map;
  }

  /** Đặt lại cấu hình lương cho một người. */
  async setSalary(userId: string, luong: StaffSalary): Promise<StaffSalary> {
    const sach = chuanHoaLuong(luong);
    const { error } = await this.db.from('staff_salaries').upsert({
      user_id: userId,
      base_salary: sach.baseSalary,
      bonus_per_order: sach.bonusPerOrder,
      bonus_per_chat: sach.bonusPerChat,
      bonus_per_stock: sach.bonusPerStock,
      updated_at: new Date().toISOString(),
    });
    if (error) throw new Error(error.message);
    return sach;
  }
}

/**
 * Lương = lương cứng + thưởng từng loại việc nhân với số việc.
 *
 * Tách ra ngoài lớp để kiểm thử thẳng, không cần giả lập cơ sở dữ liệu.
 */
export function tinhLuong(counts: StaffCounts, salary: StaffSalary): number {
  return (
    salary.baseSalary +
    counts.orders * salary.bonusPerOrder +
    counts.chats * salary.bonusPerChat +
    counts.stock * salary.bonusPerStock
  );
}

/** Nắn số âm, số lẻ do form gửi sai về số nguyên không âm. */
export function chuanHoaLuong(luong: Partial<StaffSalary>): StaffSalary {
  const nguyenDuong = (v: unknown) => Math.max(0, Math.floor(Number(v) || 0));
  return {
    baseSalary: nguyenDuong(luong.baseSalary),
    bonusPerOrder: nguyenDuong(luong.bonusPerOrder),
    bonusPerChat: nguyenDuong(luong.bonusPerChat),
    bonusPerStock: nguyenDuong(luong.bonusPerStock),
  };
}
