-- =============================================================================
-- HÀNG HỎNG VÀ ĐỔI SIZE
--
-- CÁCH CHẠY: dán cả file này vào SQL Editor của Supabase rồi chạy. Chạy lại
-- lần nữa cũng không sao, mọi lệnh đều bỏ qua khi đã có.
--
-- Nếu báo lỗi "ALTER TYPE ... cannot run inside a transaction block": chạy
-- riêng hai dòng `alter type` ở mục 1 trước (bôi đen đúng hai dòng đó rồi
-- Run), xong mới chạy cả file.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. HAI LÝ DO XUẤT NHẬP KHO MỚI
--
-- Trước đây hàng hỏng phải ghi lẫn vào "Hiệu chỉnh kiểm kê" rồi gõ tay vào ghi
-- chú, nên không lọc được, không đếm được, và cuối tháng không biết hỏng bao
-- nhiêu. Đổi size cũng vậy: hai lần chỉnh kho rời nhau, không biết chúng thuộc
-- cùng một việc.
-- -----------------------------------------------------------------------------

-- Hàng hỏng, vỡ, mất: trừ khỏi kho và không bán được nữa.
alter type inventory_movement_reason add value if not exists 'damaged';

-- Đổi size: một dòng trừ size cũ, một dòng cộng size mới.
alter type inventory_movement_reason add value if not exists 'exchange';


-- -----------------------------------------------------------------------------
-- 2. YÊU CẦU TRẢ HÀNG: PHÂN BIỆT HOÀN TIỀN VÀ ĐỔI SIZE
-- -----------------------------------------------------------------------------

alter table public.order_returns
  -- 'refund': khách muốn lấy lại tiền. 'exchange': khách chỉ muốn đổi size,
  -- tiền giữ nguyên.
  add column if not exists request_type text not null default 'refund',

  -- Biến thể khách muốn đổi sang. Chỉ có nghĩa khi request_type = 'exchange'.
  add column if not exists exchange_variant_id uuid
    references public.product_variants on delete set null,

  -- Biến thể khách đang giữ và muốn trả lại.
  add column if not exists returned_variant_id uuid
    references public.product_variants on delete set null;

comment on column public.order_returns.request_type is
  'refund = đòi lại tiền, exchange = chỉ đổi size';
comment on column public.order_returns.exchange_variant_id is
  'Size khách muốn đổi sang';
comment on column public.order_returns.returned_variant_id is
  'Size khách trả lại';

do $$ begin
  alter table public.order_returns
    add constraint order_returns_request_type_hop_le
    check (request_type in ('refund', 'exchange'));
exception when duplicate_object then null; end $$;

-- Đổi size thì bắt buộc phải nói đổi sang cái nào, nếu không nhân viên duyệt
-- xong cũng không biết lấy hàng nào ra gửi.
do $$ begin
  alter table public.order_returns
    add constraint order_returns_doi_size_phai_co_bien_the
    check (request_type <> 'exchange' or exchange_variant_id is not null);
exception when duplicate_object then null; end $$;


-- -----------------------------------------------------------------------------
-- 3. THÊM TRẠNG THÁI "ĐÃ ĐỔI SIZE"
--
-- Dùng chung cột status với luồng hoàn tiền, nhưng là một kết cục khác: đơn
-- không mất tiền, chỉ đổi hàng.
-- -----------------------------------------------------------------------------

alter table public.order_returns
  drop constraint if exists order_returns_status_check;

alter table public.order_returns
  add constraint order_returns_status_check
  check (status in (
    'requested', 'shop_approved', 'shop_rejected',
    'admin_dispute_review', 'refunded', 'rejected', 'exchanged'
  ));


-- -----------------------------------------------------------------------------
-- 4. CHỈ MỤC
-- -----------------------------------------------------------------------------

-- Màn kho lọc theo lý do để xem riêng hàng hỏng.
create index if not exists inventory_movements_reason_time
  on public.inventory_movements (reason, created_at desc);


-- -----------------------------------------------------------------------------
-- 5. KIỂM TRA SAU KHI CHẠY
--
--   select unnest(enum_range(null::inventory_movement_reason));
--     -- phải thấy đủ: order, cancel, restock, adjust, return, damaged, exchange
--
--   select request_type, exchange_variant_id from public.order_returns limit 1;
--     -- 2 cột mới, request_type mặc định 'refund'
-- -----------------------------------------------------------------------------
