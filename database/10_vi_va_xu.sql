-- =============================================================================
-- VÍ THANH TOÁN VÀ XU TÍCH LUỸ
--
-- CÁCH CHẠY (làm đúng 2 bước, theo thứ tự):
--   1. Dán cả file này vào SQL Editor của Supabase rồi chạy.
--   2. Dán lại cả file 03_functions.sql rồi chạy, để cập nhật hàm create_order.
--      File đó toàn lệnh "create or replace" nên chạy lại nhiều lần không sao.
--
-- Chạy lại file này lần nữa cũng không sao: mọi lệnh đều có "if not exists"
-- hoặc "create or replace".
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. VÍ
-- -----------------------------------------------------------------------------

-- Ví của khách, mỗi người đúng một dòng.
-- Cột balance chỉ là con số tổng cho dễ đọc; sổ wallet_transactions mới là
-- nguồn sự thật. Cộng hết sổ lại phải ra đúng balance.
create table if not exists public.wallets (
  user_id uuid primary key references auth.users on delete cascade,
  balance int not null default 0 check (balance >= 0),
  updated_at timestamptz not null default now()
);

-- Sổ ghi từng lần tiền ra vào ví.
create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  amount int not null check (amount <> 0),       -- dương là vào, âm là ra
  balance_after int not null check (balance_after >= 0),
  reason text not null check (reason in
    ('refund', 'order_payment', 'order_refund_cancel', 'adjust')),
  order_id uuid references public.orders on delete set null,
  return_id uuid references public.order_returns on delete set null,
  note text,
  created_by uuid references auth.users,
  created_at timestamptz not null default now()
);


-- -----------------------------------------------------------------------------
-- 2. XU
-- -----------------------------------------------------------------------------

create table if not exists public.coin_accounts (
  user_id uuid primary key references auth.users on delete cascade,
  balance int not null default 0 check (balance >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.coin_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  amount int not null check (amount <> 0),
  balance_after int not null check (balance_after >= 0),
  reason text not null check (reason in
    ('earn', 'spend', 'refund_return', 'revoke', 'apology', 'adjust')),
  order_id uuid references public.orders on delete set null,
  return_id uuid references public.order_returns on delete set null,
  note text,
  created_by uuid references auth.users,
  created_at timestamptz not null default now()
);


-- -----------------------------------------------------------------------------
-- 3. HAI CỘT MỚI CHO BẢNG ĐƠN HÀNG
-- -----------------------------------------------------------------------------

alter table public.orders
  add column if not exists wallet_amount int not null default 0
    check (wallet_amount >= 0),
  add column if not exists coin_amount int not null default 0
    check (coin_amount >= 0);

comment on column public.orders.wallet_amount is 'Đơn này trừ từ ví bao nhiêu';
comment on column public.orders.coin_amount is 'Đơn này dùng bao nhiêu xu (1 xu = 1 đồng)';


-- -----------------------------------------------------------------------------
-- 4. CHỈ MỤC — cho màn xem lịch sử
-- -----------------------------------------------------------------------------

create index if not exists wallet_tx_user_time
  on public.wallet_transactions (user_id, created_at desc);
create index if not exists coin_tx_user_time
  on public.coin_transactions (user_id, created_at desc);

-- Dùng để kiểm tra một lần hoàn tiền đã cộng vào ví chưa (chống cộng 2 lần).
create index if not exists wallet_tx_return
  on public.wallet_transactions (return_id) where return_id is not null;
create index if not exists coin_tx_return
  on public.coin_transactions (return_id) where return_id is not null;


-- -----------------------------------------------------------------------------
-- 5. HAI HÀM CỘNG TRỪ
--
-- ĐỪNG cộng trừ thẳng vào bảng wallets / coin_accounts từ code. Mọi thay đổi
-- phải gọi hai hàm này, vì:
--   - Hàm khoá dòng lại ("for update") trước khi sửa, nên hai việc chạy cùng
--     lúc không ghi đè lên nhau. Dự án này đã từng dính đúng lỗi đó ở kho hàng.
--   - Hàm tự ghi một dòng vào sổ, không bao giờ quên.
--   - Hàm tự chặn số dư âm.
-- -----------------------------------------------------------------------------

create or replace function public.wallet_change(
  p_user_id uuid,
  p_amount int,
  p_reason text,
  p_order_id uuid default null,
  p_return_id uuid default null,
  p_note text default null,
  p_created_by uuid default null
) returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_balance int;
begin
  if p_amount = 0 then
    raise exception 'Số tiền thay đổi ví phải khác 0';
  end if;

  -- Chưa có ví thì tạo. Làm trước khi khoá để lần đầu không bị trượt.
  insert into public.wallets (user_id) values (p_user_id)
    on conflict (user_id) do nothing;

  -- Khoá dòng ví lại. Ai chạy sau phải xếp hàng chờ, không đọc được số cũ.
  select balance into v_balance
    from public.wallets
   where user_id = p_user_id
     for update;

  v_balance := v_balance + p_amount;
  if v_balance < 0 then
    raise exception 'Số dư ví không đủ';
  end if;

  update public.wallets
     set balance = v_balance, updated_at = now()
   where user_id = p_user_id;

  insert into public.wallet_transactions
    (user_id, amount, balance_after, reason, order_id, return_id, note, created_by)
  values
    (p_user_id, p_amount, v_balance, p_reason, p_order_id, p_return_id, p_note, p_created_by);

  return v_balance;
end;
$$;


create or replace function public.coin_change(
  p_user_id uuid,
  p_amount int,
  p_reason text,
  p_order_id uuid default null,
  p_return_id uuid default null,
  p_note text default null,
  p_created_by uuid default null
) returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_balance int;
  v_thuc_te int;
begin
  if p_amount = 0 then
    raise exception 'Số xu thay đổi phải khác 0';
  end if;

  insert into public.coin_accounts (user_id) values (p_user_id)
    on conflict (user_id) do nothing;

  select balance into v_balance
    from public.coin_accounts
   where user_id = p_user_id
     for update;

  v_thuc_te := p_amount;

  -- Lấy lại xu mà khách tiêu hết rồi: cho về 0 chứ không để âm, và ghi vào sổ
  -- đúng số thật sự lấy được.
  if p_reason = 'revoke' and v_balance + p_amount < 0 then
    v_thuc_te := -v_balance;
    if v_thuc_te = 0 then
      return 0;   -- không còn xu nào để lấy lại
    end if;
  end if;

  v_balance := v_balance + v_thuc_te;
  if v_balance < 0 then
    raise exception 'Số xu không đủ';
  end if;

  update public.coin_accounts
     set balance = v_balance, updated_at = now()
   where user_id = p_user_id;

  insert into public.coin_transactions
    (user_id, amount, balance_after, reason, order_id, return_id, note, created_by)
  values
    (p_user_id, v_thuc_te, v_balance, p_reason, p_order_id, p_return_id,
     case when v_thuc_te <> p_amount
          then coalesce(p_note, '') || ' (chỉ lấy lại được một phần)'
          else p_note end,
     p_created_by);

  return v_balance;
end;
$$;


-- -----------------------------------------------------------------------------
-- 6. QUYỀN TRUY CẬP
--
-- Khách chỉ đọc được ví và sổ của chính mình. Không ai sửa trực tiếp được,
-- mọi thay đổi phải đi qua hai hàm ở trên (hàm chạy quyền chủ sở hữu).
-- -----------------------------------------------------------------------------

alter table public.wallets enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.coin_accounts enable row level security;
alter table public.coin_transactions enable row level security;

drop policy if exists wallets_doc_cua_minh on public.wallets;
create policy wallets_doc_cua_minh on public.wallets
  for select using (auth.uid() = user_id);

drop policy if exists wallet_tx_doc_cua_minh on public.wallet_transactions;
create policy wallet_tx_doc_cua_minh on public.wallet_transactions
  for select using (auth.uid() = user_id);

drop policy if exists coin_doc_cua_minh on public.coin_accounts;
create policy coin_doc_cua_minh on public.coin_accounts
  for select using (auth.uid() = user_id);

drop policy if exists coin_tx_doc_cua_minh on public.coin_transactions;
create policy coin_tx_doc_cua_minh on public.coin_transactions
  for select using (auth.uid() = user_id);


-- -----------------------------------------------------------------------------
-- 7. KIỂM TRA SAU KHI CHẠY
--
-- Chạy mấy câu dưới đây, phải ra kết quả như ghi trong ngoặc:
--
--   select count(*) from public.wallets;                      -- (0 dòng, không lỗi)
--   select wallet_amount, coin_amount from public.orders limit 1;  -- (2 cột mới, đều 0)
--
-- Thử hai hàm bằng tài khoản thật của mình (thay <user_id> bằng id của bạn):
--
--   select public.wallet_change('<user_id>', 10000, 'adjust', null, null, 'thử');
--     -- trả về 10000
--   select public.wallet_change('<user_id>', -10000, 'adjust', null, null, 'trả lại');
--     -- trả về 0
--   select public.wallet_change('<user_id>', -1, 'adjust');
--     -- BÁO LỖI "Số dư ví không đủ" — đúng như mong đợi
--
-- Xong thì xoá hai dòng thử trong sổ:
--   delete from public.wallet_transactions where note in ('thử', 'trả lại');
-- -----------------------------------------------------------------------------
