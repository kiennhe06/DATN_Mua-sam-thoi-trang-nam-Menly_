-- Du lieu mau de chay thu he thong Menly (idempotent, co the chay lai nhieu lan)
-- Su dung toan bo anh CDN Unsplash thoi trang nam cao cap, load cuc nhanh va khong bi redirect 302

-- 1. Danh muc san pham
insert into public.categories (name, slug, sort_order) values
  ('Ao so mi','ao-so-mi',1),
  ('Ao thun','ao-thun',2),
  ('Quan jeans','quan-jeans',3),
  ('Quan tay','quan-tay',4),
  ('Ao khoac','ao-khoac',5)
on conflict (slug) do nothing;

-- 2. San pham (~8 mon moi danh muc) + anh Unsplash chuan Menly + search_text
insert into public.products (category_id, name, slug, description, price, thumbnail_url, search_text, is_active)
select c.id, p.name, p.slug, p.descr, p.price, p.img, lower(p.name), true
from (values
  -- Ao so mi (8 san pham)
  ('Ao so mi trang basic','ao-so-mi-trang-basic','Ao so mi nam mau trang basic sang trong, chat vai cotton modal chong nhan', 299000, 'ao-so-mi', 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=600&auto=format&fit=crop'),
  ('Ao so mi caro','ao-so-mi-caro','Ao so mi nam hoa tiet caro tre trung nang dong', 329000, 'ao-so-mi', 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&auto=format&fit=crop'),
  ('Ao so mi oxford xanh','ao-so-mi-oxford-xanh','Ao so mi oxford mau xanh nha nhan phu hop cong so', 349000, 'ao-so-mi', 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=600&auto=format&fit=crop'),
  ('Ao so mi linen be','ao-so-mi-linen-be','Ao so mi vai linen mat me mau be phong cach vintage', 359000, 'ao-so-mi', 'https://images.unsplash.com/photo-1620012253295-c15c429f66bf?w=600&auto=format&fit=crop'),
  ('Ao so mi tay dai den','ao-so-mi-tay-dai-den','Ao so mi tay dai mau den lich su cuon hut', 319000, 'ao-so-mi', 'https://images.unsplash.com/photo-1603252109303-2751441dd157?w=600&auto=format&fit=crop'),
  ('Ao so mi cuban hoa tiet','ao-so-mi-cuban-hoa-tiet','Ao so mi co cuban hoa tiet mua he thoang mat', 379000, 'ao-so-mi', 'https://images.unsplash.com/photo-1607345366928-199ea26cfe3e?w=600&auto=format&fit=crop'),
  ('Ao so mi flannel ke soc','ao-so-mi-flannel-ke-soc','Ao so mi flannel am ap ke soc phong tran', 389000, 'ao-so-mi', 'https://images.unsplash.com/photo-1563630423918-b58f07336ac9?w=600&auto=format&fit=crop'),
  ('Ao so mi tay ngan trang','ao-so-mi-tay-ngan-trang','Ao so mi tay ngan mau trang thoang mat ngay he', 269000, 'ao-so-mi', 'https://images.unsplash.com/photo-1608256246200-53e635b5b65f?w=600&auto=format&fit=crop'),

  -- Ao thun & Polo (8 san pham)
  ('Ao thun co tron','ao-thun-co-tron','Ao thun nam co tron cotton 100% thoang khi co gian', 159000, 'ao-thun', 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=600&auto=format&fit=crop'),
  ('Ao polo','ao-polo','Ao polo nam phoi co thanh lich the thao', 229000, 'ao-thun', 'https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=600&auto=format&fit=crop'),
  ('Ao thun co tim','ao-thun-co-tim','Ao thun nam co tim ca tinh hien dai', 149000, 'ao-thun', 'https://images.unsplash.com/photo-1525171254930-643fc658b64e?w=600&auto=format&fit=crop'),
  ('Ao thun oversize den','ao-thun-oversize-den','Ao thun form rong street style mau den ca tinh', 189000, 'ao-thun', 'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=600&auto=format&fit=crop'),
  ('Ao thun in logo','ao-thun-in-logo','Ao thun in logo thoi trang noi bat', 179000, 'ao-thun', 'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=600&auto=format&fit=crop'),
  ('Ao polo ke soc','ao-polo-ke-soc','Ao polo ke soc ngang nang dong phong cach', 249000, 'ao-thun', 'https://images.unsplash.com/photo-1578587018452-892bacefd3f2?w=600&auto=format&fit=crop'),
  ('Ao thun the thao','ao-thun-the-thao','Ao thun the thao thoang khi quick-dry', 169000, 'ao-thun', 'https://images.unsplash.com/photo-1584370848010-d7fe6bc767ec?w=600&auto=format&fit=crop'),
  ('Ao thun tay dai basic','ao-thun-tay-dai-basic','Ao thun tay dai basic de phoi do thu dong', 199000, 'ao-thun', 'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=600&auto=format&fit=crop'),

  -- Quan jeans (8 san pham)
  ('Quan jeans slimfit','quan-jeans-slimfit','Quan jeans nam om slimfit ton dang co gian tot', 459000, 'quan-jeans', 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600&auto=format&fit=crop'),
  ('Quan jeans xanh nhat','quan-jeans-xanh-nhat','Quan jeans nam mau xanh nhat tre trung', 479000, 'quan-jeans', 'https://images.unsplash.com/photo-1552374196-c4e7ffc6e126?w=600&auto=format&fit=crop'),
  ('Quan jeans den skinny','quan-jeans-den-skinny','Quan jeans den form skinny co gian cao cap', 489000, 'quan-jeans', 'https://images.unsplash.com/photo-1582552938357-32b906df40cb?w=600&auto=format&fit=crop'),
  ('Quan jeans rach goi','quan-jeans-rach-goi','Quan jeans rach goi bui bam ca tinh street style', 519000, 'quan-jeans', 'https://images.unsplash.com/photo-1584370848010-d7fe6bc767ec?w=600&auto=format&fit=crop'),
  ('Quan jeans straight','quan-jeans-straight','Quan jeans ong suong straight co dien', 499000, 'quan-jeans', 'https://images.unsplash.com/photo-1542272604-780c96856592?w=600&auto=format&fit=crop'),
  ('Quan jeans xanh dam','quan-jeans-xanh-dam','Quan jeans mau xanh dam de mac moi dip', 469000, 'quan-jeans', 'https://images.unsplash.com/photo-1534030347209-467a5b0ad3e6?w=600&auto=format&fit=crop'),
  ('Quan jeans regular fit','quan-jeans-regular-fit','Quan jeans regular fit thoai mai van dong', 449000, 'quan-jeans', 'https://images.unsplash.com/photo-1604176354204-9268737828e4?w=600&auto=format&fit=crop'),
  ('Quan jeans co cao','quan-jeans-co-cao','Quan jeans lung cao ton dang thanh lich', 529000, 'quan-jeans', 'https://images.unsplash.com/photo-1517445312882-bc9910d016b7?w=600&auto=format&fit=crop'),

  -- Quan tay & Kaki (8 san pham)
  ('Quan tay cong so','quan-tay-cong-so','Quan tay nam cong so dung form lich lam', 389000, 'quan-tay', 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=600&auto=format&fit=crop'),
  ('Quan kaki','quan-kaki','Quan kaki nam mau be co ban thoai mai', 349000, 'quan-tay', 'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=600&auto=format&fit=crop'),
  ('Quan tay slimfit den','quan-tay-slimfit-den','Quan tay slimfit mau den sang trong quy phai', 399000, 'quan-tay', 'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600&auto=format&fit=crop'),
  ('Quan kaki be','quan-kaki-be','Quan kaki mau be thanh lich phu hop di choi di lam', 359000, 'quan-tay', 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=600&auto=format&fit=crop'),
  ('Quan tay xam cong so','quan-tay-xam-cong-so','Quan tay mau xam cong so ton dang lich thiep', 409000, 'quan-tay', 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?w=600&auto=format&fit=crop'),
  ('Quan tay om navy','quan-tay-om-navy','Quan tay om mau xanh navy tre trung hien dai', 419000, 'quan-tay', 'https://images.unsplash.com/photo-1617137968427-85924c800a22?w=600&auto=format&fit=crop'),
  ('Quan kaki xanh reu','quan-kaki-xanh-reu','Quan kaki mau xanh reu phong cach safari ca tinh', 369000, 'quan-tay', 'https://images.unsplash.com/photo-1517445312882-bc9910d016b7?w=600&auto=format&fit=crop'),
  ('Quan tay vai cao cap','quan-tay-vai-cao-cap','Quan tay vai tuyet mua cao cap phong cach Y', 549000, 'quan-tay', 'https://images.unsplash.com/photo-1521498542256-5aeb47ba2b36?w=600&auto=format&fit=crop'),

  -- Ao khoac (8 san pham)
  ('Ao khoac bomber','ao-khoac-bomber','Ao khoac bomber nam du phong gio am ap', 599000, 'ao-khoac', 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600&auto=format&fit=crop'),
  ('Ao khoac jean','ao-khoac-jean','Ao khoac jean nam denim wash phong cach bui bam', 549000, 'ao-khoac', 'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=600&auto=format&fit=crop'),
  ('Ao khoac gio the thao','ao-khoac-gio-the-thao','Ao khoac gio the thao nhe chong nuoc can gio', 499000, 'ao-khoac', 'https://images.unsplash.com/photo-1544441893-675973e31985?w=600&auto=format&fit=crop'),
  ('Ao khoac da PU','ao-khoac-da-pu','Ao khoac da PU biker manh me phong tran', 899000, 'ao-khoac', 'https://images.unsplash.com/photo-1520975954732-35dd22299614?w=600&auto=format&fit=crop'),
  ('Ao khoac kaki 2 lop','ao-khoac-kaki-2-lop','Ao khoac kaki 2 lop giu am co be thanh lich', 659000, 'ao-khoac', 'https://images.unsplash.com/photo-1548883354-7622d03aca27?w=600&auto=format&fit=crop'),
  ('Ao khoac hoodie ni','ao-khoac-hoodie-ni','Ao khoac hoodie ni bong am ap oversize mua dong', 459000, 'ao-khoac', 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=600&auto=format&fit=crop'),
  ('Ao khoac blazer cong so','ao-khoac-blazer-cong-so','Ao blazer cong so lich lam quy ong hien dai', 799000, 'ao-khoac', 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=600&auto=format&fit=crop'),
  ('Ao khoac phao mua dong','ao-khoac-phao-mua-dong','Ao phao long vu mua dong sieu nhe sieu am', 849000, 'ao-khoac', 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=600&auto=format&fit=crop')
) as p(name, slug, descr, price, cat_slug, img)
join public.categories c on c.slug = p.cat_slug
on conflict (slug) do update set thumbnail_url = excluded.thumbnail_url, description = excluded.description;

-- 3. Bien the: 4 size (S,M,L,XL hoac 29,30,31,32) x 3 mau cho moi san pham
insert into public.product_variants (product_id, size, color, sku, stock)
select pr.id, v.size, v.color, pr.slug || '-' || v.size || '-' || v.color, 40
from public.products pr
cross join (values
  ('S','Den'),('M','Den'),('L','Den'),('XL','Den'),
  ('S','Trang'),('M','Trang'),('L','Trang'),('XL','Trang'),
  ('S','Xanh'),('M','Xanh'),('L','Xanh'),('XL','Xanh')
) as v(size, color)
on conflict (sku) do nothing;

-- 4. Bo suu tap anh chi tiet: 3 anh moi san pham
insert into public.product_images (product_id, url, sort_order)
select pr.id,
       case g.n
         when 0 then pr.thumbnail_url
         when 1 then regexp_replace(pr.thumbnail_url, 'fit=crop', 'fit=crop&rot=1')
         else regexp_replace(pr.thumbnail_url, 'fit=crop', 'fit=crop&rot=2')
       end,
       g.n
from public.products pr
cross join (values (0),(1),(2)) as g(n)
where not exists (
  select 1 from public.product_images i where i.product_id = pr.id
);

-- 5. Banner trang chu thoi trang Menly
insert into public.banners (title, image_url, link_url, sort_order, end_date)
select b.title, b.image_url, b.link_url, b.sort_order, now() + interval '365 days'
from (values
  ('Bo suu tap Thu Dong Menly 2025', 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&h=450&fit=crop', null::text, 1),
  ('Uu dai Ao so mi cao cap - giam den 30%', 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=1200&h=450&fit=crop', null, 2),
  ('Quan jeans & Kaki nam phong cach Y', 'https://images.unsplash.com/photo-1479064555552-3ef4979f8908?w=1200&h=450&fit=crop', null, 3),
  ('Mien phi van chuyen toan quoc cho don tu 499k', 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=1200&h=450&fit=crop', null, 4)
) as b(title, image_url, link_url, sort_order)
where not exists (select 1 from public.banners);

-- 6. Ma giam gia (Vouchers)
insert into public.vouchers (code, title, discount_type, discount_value, min_order_value, max_discount, usage_limit, end_date) values
  ('WELCOME10','Giam 10% cho don dau tien','percentage',10,200000,50000,1000, now() + interval '90 days'),
  ('SALE50K','Giam 50k cho don tu 300k','fixed_amount',50000,300000,null,500, now() + interval '60 days'),
  ('MENLY20','Giam 20% toi da 100k','percentage',20,500000,100000,300, now() + interval '60 days'),
  ('FREESHIP','Mien phi van chuyen','fixed_amount',25000,0,null,1000, now() + interval '90 days'),
  ('NEWBIE15','Giam 15% cho khach moi','percentage',15,200000,60000,500, now() + interval '90 days')
on conflict (code) do nothing;

-- 7. Don hang mau da dang trang thai (cho phep hien thi day du tren app va admin)
do $$
declare
  v_user_id uuid;
  v_order_id uuid;
  v_var_1 uuid;
  v_var_2 uuid;
begin
  select id into v_user_id from auth.users limit 1;
  if v_user_id is null then
    select id into v_user_id from public.profiles limit 1;
  end if;

  if v_user_id is not null and not exists (select 1 from public.orders) then
    select id into v_var_1 from public.product_variants limit 1;
    select id into v_var_2 from public.product_variants offset 1 limit 1;

    -- Đơn 1: Đang xử lý
    insert into public.orders (code, user_id, status, payment_method, subtotal, shipping_fee, total, ship_name, ship_phone, ship_address)
    values ('MNL-10001', v_user_id, 'processing', 'cod', 329000, 25000, 354000, 'Nguyễn Văn Nam', '0912345678', '123 Cầu Giấy, Hà Nội')
    returning id into v_order_id;
    insert into public.order_items (order_id, variant_id, product_name, size, color, unit_price, quantity)
    values (v_order_id, v_var_1, 'Áo sơ mi caro', 'L', 'Trắng', 329000, 1);

    -- Đơn 2: Đang giao hàng
    insert into public.orders (code, user_id, status, payment_method, subtotal, shipping_fee, total, ship_name, ship_phone, ship_address)
    values ('MNL-10002', v_user_id, 'shipping', 'vnpay', 459000, 0, 459000, 'Trần Minh Tuấn', '0987654321', '45 Lê Lợi, Quận 1, TP.HCM')
    returning id into v_order_id;
    insert into public.order_items (order_id, variant_id, product_name, size, color, unit_price, quantity)
    values (v_order_id, v_var_2, 'Quần jeans slimfit', '31', 'Đen', 459000, 1);

    -- Đơn 3: Đã giao hàng
    insert into public.orders (code, user_id, status, payment_method, subtotal, shipping_fee, total, ship_name, ship_phone, ship_address)
    values ('MNL-10003', v_user_id, 'delivered', 'cod', 549000, 0, 549000, 'Lê Quốc Bảo', '0933221100', '88 Nguyễn Văn Linh, Đà Nẵng')
    returning id into v_order_id;
    insert into public.order_items (order_id, variant_id, product_name, size, color, unit_price, quantity)
    values (v_order_id, v_var_1, 'Áo khoác jean', 'XL', 'Xanh', 549000, 1);

    -- Đơn 4: Chờ thanh toán
    insert into public.orders (code, user_id, status, payment_method, subtotal, shipping_fee, total, ship_name, ship_phone, ship_address)
    values ('MNL-10004', v_user_id, 'pending_payment', 'vnpay', 299000, 25000, 324000, 'Hoàng Anh Quân', '0944556677', '12 Quang Trung, Hải Phòng')
    returning id into v_order_id;
    insert into public.order_items (order_id, variant_id, product_name, size, color, unit_price, quantity)
    values (v_order_id, v_var_2, 'Áo sơ mi trắng basic', 'M', 'Trắng', 299000, 1);

    -- Đơn 5: Đã hủy
    insert into public.orders (code, user_id, status, payment_method, subtotal, shipping_fee, total, ship_name, ship_phone, ship_address)
    values ('MNL-10005', v_user_id, 'cancelled', 'cod', 159000, 25000, 184000, 'Đỗ Khắc Tiệp', '0911223344', '56 Phan Bội Châu, Cần Thơ')
    returning id into v_order_id;
    insert into public.order_items (order_id, variant_id, product_name, size, color, unit_price, quantity)
    values (v_order_id, v_var_1, 'Áo thun cổ tròn', 'S', 'Đen', 159000, 1);
  end if;
end $$;
