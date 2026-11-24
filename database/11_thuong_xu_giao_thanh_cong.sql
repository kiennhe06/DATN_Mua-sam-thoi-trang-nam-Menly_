-- Thưởng 1 xu cho mỗi 100 đồng giá trị hàng sau giảm giá khi đơn giao thành công.
-- Chạy sau database/10_vi_va_xu.sql trên Supabase.
create or replace function public.reward_order_coins(
  p_order_id uuid,
  p_staff_id uuid default null
) returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order record;
  v_reward int;
  v_balance int;
begin
  select id, user_id, status, subtotal, discount_amount
    into v_order
    from public.orders
   where id = p_order_id
   for update;

  if not found then
    raise exception 'Không tìm thấy đơn hàng';
  end if;
  if v_order.status not in ('delivered', 'completed') then
    raise exception 'Chỉ thưởng xu cho đơn đã giao thành công';
  end if;

  select balance into v_balance
    from public.coin_accounts
   where user_id = v_order.user_id;
  v_balance := coalesce(v_balance, 0);

  if exists (
    select 1 from public.coin_transactions
     where order_id = p_order_id and reason = 'earn'
  ) then
    return v_balance;
  end if;

  v_reward := greatest(0, floor(greatest(0, v_order.subtotal - coalesce(v_order.discount_amount, 0)) / 100.0)::int);
  if v_reward = 0 then
    return v_balance;
  end if;

  return public.coin_change(
    v_order.user_id,
    v_reward,
    'earn',
    p_order_id,
    null,
    'Thưởng 1% giá trị hàng sau giảm giá khi giao thành công',
    p_staff_id
  );
end;
$$;

revoke all on function public.reward_order_coins(uuid, uuid) from public, anon, authenticated;
grant execute on function public.reward_order_coins(uuid, uuid) to service_role;

create or replace function public.reward_coins_after_delivery()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'delivered' and old.status is distinct from new.status then
    perform public.reward_order_coins(new.id, null);
  end if;
  return new;
end;
$$;

revoke all on function public.reward_coins_after_delivery() from public, anon, authenticated;
drop trigger if exists orders_reward_coins_after_delivery on public.orders;
create trigger orders_reward_coins_after_delivery
  after update of status on public.orders
  for each row execute function public.reward_coins_after_delivery();
