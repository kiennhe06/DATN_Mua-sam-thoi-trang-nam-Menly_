-- Ghi nhan hang tra ve co ban lai duoc hay khong.
--
-- null  = chua xu ly xong (don chua hoan tien)
-- true  = hang con nguyen, da nhap lai kho
-- false = hang loi, khong nhap lai kho
alter table public.order_returns
  add column if not exists restocked boolean;

comment on column public.order_returns.restocked is
  'true: hang tra con ban duoc va da cong lai kho; false: hang loi, khong cong lai';
