-- =============================================================================
-- LƯƠNG NHÂN VIÊN: lương cứng + thưởng theo số việc
--
-- CÁCH CHẠY: dán cả file này vào SQL Editor của Supabase rồi chạy. Chạy lại
-- lần nữa cũng không sao.
--
-- Hệ thống không chấm công, không có giờ làm, nên lương không tính theo giờ.
-- Chỉ có: một mức lương cứng mỗi tháng, cộng thưởng theo số việc mỗi người
-- làm (đổi trạng thái đơn, trả lời chat, chỉnh kho). Dấu vết "ai làm gì" đã
-- có sẵn trong order_status_history, support_messages, inventory_movements.
-- =============================================================================

create table if not exists public.staff_salaries (
  user_id uuid primary key references auth.users on delete cascade,

  -- Lương cứng một tháng, đồng.
  base_salary int not null default 0 check (base_salary >= 0),

  -- Thưởng cho mỗi việc, đồng. Để 0 nếu không thưởng loại đó.
  bonus_per_order int not null default 0 check (bonus_per_order >= 0),
  bonus_per_chat int not null default 0 check (bonus_per_chat >= 0),
  bonus_per_stock int not null default 0 check (bonus_per_stock >= 0),

  updated_at timestamptz not null default now()
);

comment on column public.staff_salaries.base_salary is 'Lương cứng mỗi tháng (đồng)';
comment on column public.staff_salaries.bonus_per_order is 'Thưởng mỗi lần đổi trạng thái đơn';
comment on column public.staff_salaries.bonus_per_chat is 'Thưởng mỗi tin nhắn trả lời khách';
comment on column public.staff_salaries.bonus_per_stock is 'Thưởng mỗi lần chỉnh kho';


-- Chỉ mục cho các cột "ai thao tác", để tổng hợp theo nhân viên nhanh hơn.
-- Màn nhân viên lọc theo đúng các cột này.
create index if not exists order_status_history_changed_by
  on public.order_status_history (changed_by, created_at desc);
create index if not exists support_messages_sender
  on public.support_messages (sender_id, created_at desc);
create index if not exists inventory_movements_created_by
  on public.inventory_movements (created_by, created_at desc);


-- -----------------------------------------------------------------------------
-- QUYỀN: chỉ backend (service role) đọc ghi. Bảng lương không cho khách thấy.
-- -----------------------------------------------------------------------------

alter table public.staff_salaries enable row level security;
-- Không tạo policy nào: nghĩa là không ai qua anon/authenticated đọc được,
-- chỉ service role (backend) đi qua. Lương là dữ liệu nhạy cảm.


-- -----------------------------------------------------------------------------
-- KIỂM TRA SAU KHI CHẠY:
--   select count(*) from public.staff_salaries;   -- (0 dòng, không lỗi)
-- -----------------------------------------------------------------------------
