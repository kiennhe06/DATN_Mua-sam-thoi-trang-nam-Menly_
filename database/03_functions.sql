-- Cac ham nghiep vu cua he thong

-- Kiem tra nguoi dang dang nhap co phai admin / nhan vien khong
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role in ('admin','staff')
  );
$$;

-- Tao don hang nguyen tu: tao don + chi tiet + tru kho + ap ma giam gia, trong 1 giao dich
-- p_items dang: [{"variant_id":"...","quantity":2}, ...]
create or replace function public.create_order(
  p_user_id uuid,
  p_payment_method text,
  p_ship_name text,
  p_ship_phone text,
  p_ship_address text,
  p_items jsonb,
  p_voucher_code text default null,
  p_idempotency_key text default null,
  p_shipping_fee int default 0
) returns public.orders
language plpgsql
as $$
declare
  v_order public.orders;
  v_code text;
  v_subtotal int := 0;
  v_shipping int := greatest(0, coalesce(p_shipping_fee, 0));
  v_discount int := 0;
  v_total int;
  item jsonb;
  v_variant public.product_variants;
  v_product public.products;
  v_qty int;
  v_voucher public.vouchers;
begin
  if auth.uid() is not null and auth.uid() <> p_user_id then
    raise exception 'Không thể tạo đơn hàng cho tài khoản khác';
  end if;
  if p_payment_method not in ('cod','vnpay') then
    raise exception 'Phuong thuc thanh toan khong hop le';
  end if;

  -- Neu da tao don voi cung idempotency_key thi tra lai don cu (tranh tao trung)
  if p_idempotency_key is not null then
    select * into v_order from public.orders
     where user_id = p_user_id and idempotency_key = p_idempotency_key;
    if found then return v_order; end if;
  end if;

  v_code := 'MENLY' || to_char(now(),'YYMMDD') || lpad((floor(random()*100000))::text,5,'0');

  insert into public.orders (
    code, user_id, status, payment_method, subtotal, shipping_fee, total,
    ship_name, ship_phone, ship_address, idempotency_key, expires_at
  ) values (
    v_code, p_user_id,
    case when p_payment_method='vnpay' then 'pending_payment'::order_status
         else 'processing'::order_status end,
    p_payment_method, 0, 0, 0,
    p_ship_name, p_ship_phone, p_ship_address, p_idempotency_key,
    case when p_payment_method='vnpay' then now() + interval '30 minutes' else null end
  ) returning * into v_order;

  -- Duyet tung mon: kiem tra ton kho, luu chi tiet, tru kho, ghi nhat ky kho
  for item in select * from jsonb_array_elements(p_items)
  loop
    v_qty := (item->>'quantity')::int;
    select * into v_variant from public.product_variants
      where id = (item->>'variant_id')::uuid for update;
    if not found then raise exception 'San pham khong ton tai'; end if;
    if v_variant.stock < v_qty then raise exception 'San pham khong du hang'; end if;
    select * into v_product from public.products where id = v_variant.product_id;

    insert into public.order_items (order_id, variant_id, product_name, size, color, unit_price, quantity)
    values (v_order.id, v_variant.id, v_product.name, v_variant.size, v_variant.color, v_product.price, v_qty);

    update public.product_variants set stock = stock - v_qty where id = v_variant.id;
    insert into public.inventory_movements (variant_id, change, reason, order_id)
    values (v_variant.id, -v_qty, 'order', v_order.id);

    v_subtotal := v_subtotal + v_product.price * v_qty;
  end loop;

  -- Ap ma giam gia (neu hop le)
  if p_voucher_code is not null then
    select * into v_voucher from public.vouchers
      where code = p_voucher_code and is_active = true
        and now() between start_date and end_date
        and used_count < usage_limit
        and v_subtotal >= min_order_value;
    if found then
      if v_voucher.discount_type = 'percentage' then
        v_discount := (v_subtotal * v_voucher.discount_value) / 100;
        if v_voucher.max_discount is not null and v_discount > v_voucher.max_discount then
          v_discount := v_voucher.max_discount;
        end if;
      else
        v_discount := v_voucher.discount_value;
      end if;
      insert into public.order_vouchers (order_id, voucher_id, discount_amount)
      values (v_order.id, v_voucher.id, v_discount);
      update public.vouchers set used_count = used_count + 1 where id = v_voucher.id;
    end if;
  end if;

  v_total := v_subtotal + v_shipping - v_discount;
  if v_total < 0 then v_total := 0; end if;

  update public.orders
    set subtotal = v_subtotal, shipping_fee = v_shipping, total = v_total
    where id = v_order.id
    returning * into v_order;

  return v_order;
end;
$$;

create or replace function public.cancel_order(
  p_order_id uuid,
  p_user_id uuid,
  p_reason text default null,
  p_is_admin boolean default false
) returns public.orders
language plpgsql
as $$
declare
  v_order public.orders;
  v_item public.order_items;
  v_from_status public.order_status;
begin
  if p_is_admin and not exists (
    select 1 from public.profiles
    where id = p_user_id and role in ('admin', 'staff')
  ) then
    raise exception 'Tài khoản không có quyền quản trị đơn hàng';
  end if;
  if not p_is_admin and auth.uid() is not null and auth.uid() <> p_user_id then
    raise exception 'Không thể hủy đơn hàng của tài khoản khác';
  end if;
  select * into v_order from public.orders
   where id = p_order_id and (p_is_admin or user_id = p_user_id)
   for update;
  if not found then raise exception 'Không tìm thấy đơn hàng'; end if;
  if v_order.status not in ('processing', 'pending_payment') then
    raise exception 'Đơn hàng không thể hủy ở trạng thái hiện tại';
  end if;
  v_from_status := v_order.status;

  for v_item in select * from public.order_items where order_id = p_order_id loop
    update public.product_variants
       set stock = stock + v_item.quantity
     where id = v_item.variant_id;
    insert into public.inventory_movements (variant_id, change, reason, order_id, created_by, note)
    values (v_item.variant_id, v_item.quantity, 'cancel', p_order_id, p_user_id, p_reason);
  end loop;

  update public.orders set status = 'cancelled' where id = p_order_id returning * into v_order;
  insert into public.order_status_history (order_id, from_status, to_status, changed_by, note)
  values (p_order_id, v_from_status, 'cancelled', p_user_id, p_reason);
  return v_order;
end;
$$;

-- Xac nhan thanh toan (goi khi VNPay bao ket qua)
create or replace function public.settle_payment(
  p_txn_ref text,
  p_success boolean,
  p_provider_txn_no text default null,
  p_bank_code text default null,
  p_response_code text default null,
  p_raw jsonb default null
) returns void
language plpgsql
as $$
declare
  v_payment public.payments;
begin
  select * into v_payment from public.payments where txn_ref = p_txn_ref for update;
  if not found then raise exception 'Khong tim thay giao dich'; end if;

  update public.payments
    set status = case when p_success then 'paid'::payment_status else 'failed'::payment_status end,
        provider_txn_no = p_provider_txn_no,
        bank_code = p_bank_code,
        response_code = p_response_code,
        raw = p_raw,
        paid_at = case when p_success then now() else null end
    where id = v_payment.id;

  if p_success then
    update public.orders set status = 'processing'::order_status
      where id = v_payment.order_id and status = 'pending_payment';
  end if;
end;
$$;

-- Huy cac don cho thanh toan qua han + hoan lai kho (chay dinh ky)
create or replace function public.expire_pending_orders()
returns void
language plpgsql
as $$
declare r record; it record;
begin
  for r in select * from public.orders
           where status = 'pending_payment' and expires_at is not null and expires_at < now()
  loop
    for it in select * from public.order_items where order_id = r.id loop
      update public.product_variants set stock = stock + it.quantity where id = it.variant_id;
      insert into public.inventory_movements (variant_id, change, reason, order_id)
      values (it.variant_id, it.quantity, 'cancel', r.id);
    end loop;
    update public.orders set status = 'expired'::order_status where id = r.id;
  end loop;
end;
$$;
