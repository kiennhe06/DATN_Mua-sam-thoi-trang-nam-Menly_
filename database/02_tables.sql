-- Toàn bộ bảng của hệ thống Menly

-- Hồ sơ người dùng & phân quyền
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  email text,
  full_name text,
  phone text,
  avatar_url text,
  role text not null default 'customer' check (role in ('customer','admin','user','seller','staff')),
  is_guest boolean not null default false,
  is_active boolean not null default true,
  is_locked boolean not null default false,
  created_at timestamptz not null default now()
);

-- Danh mục sản phẩm
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  sort_order int not null default 0
);

-- Cửa hàng / người bán
create table if not exists public.shops (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users on delete cascade,
  name text not null unique,
  slug text not null unique,
  description text,
  logo_url text,
  banner_url text,
  phone text not null,
  address text not null,
  status text not null default 'pending' check (status in ('pending','active','suspended','rejected')),
  rating_avg numeric(3,2) not null default 0.00 check (rating_avg between 0 and 5),
  rating_count int not null default 0,
  created_at timestamptz not null default now()
);

-- Sản phẩm
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories,
  shop_id uuid references public.shops on delete cascade,
  name text not null,
  slug text not null unique,
  description text,
  price int not null check (price >= 0),
  thumbnail_url text,
  search_text text not null default '',
  approval_status text not null default 'approved' check (approval_status in ('pending','approved','rejected')),
  rating_avg numeric(3,2) not null default 0.00,
  rating_count int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Biến thể sản phẩm (size, màu, tồn kho)
create table if not exists public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products on delete cascade,
  size text not null,
  color text not null,
  sku text not null unique,
  stock int not null default 0 check (stock >= 0),
  unique (product_id, size, color)
);

-- Ảnh sản phẩm
create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products on delete cascade,
  url text not null,
  sort_order int not null default 0
);

-- Giỏ hàng
create table if not exists public.cart_items (
  user_id uuid not null references auth.users on delete cascade,
  variant_id uuid not null references public.product_variants on delete cascade,
  quantity int not null check (quantity between 1 and 20),
  updated_at timestamptz not null default now(),
  primary key (user_id, variant_id)
);

-- Đơn hàng
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  user_id uuid not null references auth.users,
  shop_id uuid references public.shops,
  parent_order_id uuid references public.orders(id) on delete cascade,
  status order_status not null default 'pending_payment',
  payment_method text not null check (payment_method in ('cod','vnpay')),
  subtotal int not null,
  shipping_fee int not null default 0,
  total int not null,
  ship_name text not null,
  ship_phone text not null,
  ship_address text not null,
  idempotency_key text,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, idempotency_key)
);

-- Chi tiết đơn hàng (bản chụp tại thời điểm đặt)
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders on delete cascade,
  variant_id uuid references public.product_variants on delete set null,
  product_name text not null,
  size text not null,
  color text not null,
  unit_price int not null,
  quantity int not null check (quantity > 0),
  thumbnail_url text
);

-- Giao dịch thanh toán (VNPay)
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders,
  provider text not null default 'vnpay',
  txn_ref text not null unique,
  amount int not null,
  status payment_status not null default 'pending',
  provider_txn_no text,
  bank_code text,
  response_code text,
  raw jsonb,
  created_at timestamptz not null default now(),
  paid_at timestamptz
);

-- Nhật ký biến động tồn kho
create table if not exists public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references public.product_variants on delete cascade,
  change int not null,
  reason inventory_movement_reason not null,
  order_id uuid references public.orders,
  created_by uuid references auth.users,
  note text,
  created_at timestamptz not null default now()
);

-- Lịch sử trạng thái đơn hàng
create table if not exists public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders on delete cascade,
  from_status order_status,
  to_status order_status not null,
  changed_by uuid references auth.users,
  note text,
  created_at timestamptz not null default now()
);

-- Nhật ký thao tác quản trị
create table if not exists public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references auth.users,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  before jsonb,
  after jsonb,
  created_at timestamptz not null default now()
);

-- Sổ địa chỉ giao hàng
create table if not exists public.user_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  recipient_name text not null,
  phone text not null,
  province text not null,
  district text not null,
  ward text not null,
  detail_address text not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

-- Mã giảm giá
create table if not exists public.vouchers (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  shop_id uuid references public.shops on delete cascade,
  title text not null,
  discount_type text not null check (discount_type in ('percentage','fixed_amount')),
  discount_value int not null check (discount_value > 0),
  min_order_value int not null default 0,
  max_discount int,
  usage_limit int not null default 100,
  used_count int not null default 0,
  start_date timestamptz not null default now(),
  end_date timestamptz not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Voucher áp dụng cho đơn
create table if not exists public.order_vouchers (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders on delete cascade,
  voucher_id uuid not null references public.vouchers,
  discount_amount int not null check (discount_amount >= 0),
  created_at timestamptz not null default now()
);

-- Đánh giá sản phẩm
create table if not exists public.product_reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products on delete cascade,
  order_item_id uuid not null references public.order_items,
  user_id uuid not null references auth.users,
  rating int not null check (rating between 1 and 5),
  comment text,
  images jsonb default '[]'::jsonb,
  reply_comment text,
  reply_at timestamptz,
  created_at timestamptz not null default now(),
  unique (order_item_id)
);

-- Yêu cầu trả hàng / hoàn tiền
create table if not exists public.order_returns (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders on delete cascade,
  user_id uuid not null references auth.users,
  shop_id uuid references public.shops,
  reason text not null,
  proof_images jsonb default '[]'::jsonb,
  status text not null default 'requested' check (status in
    ('requested','shop_approved','shop_rejected','admin_dispute_review','refunded','rejected')),
  refund_amount int not null,
  rejection_reason text,
  admin_resolution_note text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

-- Yêu thích
create table if not exists public.wishlists (
  user_id uuid not null references auth.users on delete cascade,
  product_id uuid not null references public.products on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

-- Theo dõi cửa hàng
create table if not exists public.shop_followers (
  user_id uuid not null references auth.users on delete cascade,
  shop_id uuid not null references public.shops on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, shop_id)
);

-- Hội thoại chat
create table if not exists public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  shop_id uuid not null references public.shops on delete cascade,
  last_message text,
  last_message_at timestamptz default now(),
  unread_user_count int not null default 0,
  unread_shop_count int not null default 0,
  created_at timestamptz not null default now(),
  unique (user_id, shop_id)
);

-- Tin nhắn chat
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations on delete cascade,
  sender_id uuid not null references auth.users,
  message_type text not null default 'text' check (message_type in ('text','image')),
  content text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- Thông báo
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  title text not null,
  body text not null,
  type text not null check (type in ('order','promo','system')),
  data jsonb default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- Banner trang chủ
create table if not exists public.banners (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  image_url text not null,
  link_url text,
  sort_order int not null default 0,
  is_active boolean not null default true,
  start_date timestamptz not null default now(),
  end_date timestamptz not null
);

-- Flash sale (khuyến mãi giờ vàng)
create table if not exists public.flash_sales (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  is_active boolean not null default false
);

create table if not exists public.flash_sale_items (
  id uuid primary key default gen_random_uuid(),
  flash_sale_id uuid not null references public.flash_sales on delete cascade,
  variant_id uuid not null references public.product_variants on delete cascade,
  sale_price int not null check (sale_price > 0),
  quantity_limit int not null check (quantity_limit > 0),
  sold_count int not null default 0,
  unique (flash_sale_id, variant_id)
);
