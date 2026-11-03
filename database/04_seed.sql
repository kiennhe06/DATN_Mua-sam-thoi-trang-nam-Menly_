-- Du lieu mau de chay thu (co the chay lai nhieu lan, idempotent)
-- Anh dung URL picsum on dinh theo slug; co the thay bang anh that sau.

-- Danh muc
insert into public.categories (name, slug, sort_order) values
  ('Ao so mi','ao-so-mi',1),
  ('Ao thun','ao-thun',2),
  ('Quan jeans','quan-jeans',3),
  ('Quan tay','quan-tay',4),
  ('Ao khoac','ao-khoac',5)
on conflict (slug) do nothing;

-- San pham (~8 mon moi danh muc) + anh dai dien + search_text
insert into public.products (category_id, name, slug, description, price, thumbnail_url, search_text, is_active)
select c.id, p.name, p.slug, p.descr, p.price,
       'https://picsum.photos/seed/' || p.slug || '/400/500',
       lower(p.name), true
from (values
  -- Ao so mi
  ('Ao so mi trang basic','ao-so-mi-trang-basic','Ao so mi nam mau trang basic', 299000, 'ao-so-mi'),
  ('Ao so mi caro','ao-so-mi-caro','Ao so mi nam ho a tiet caro', 329000, 'ao-so-mi'),
  ('Ao so mi oxford xanh','ao-so-mi-oxford-xanh','Ao so mi oxford mau xanh nha nhan', 349000, 'ao-so-mi'),
  ('Ao so mi linen be','ao-so-mi-linen-be','Ao so mi vai linen mat me mau be', 359000, 'ao-so-mi'),
  ('Ao so mi tay dai den','ao-so-mi-tay-dai-den','Ao so mi tay dai mau den lich su', 319000, 'ao-so-mi'),
  ('Ao so mi cuban hoa tiet','ao-so-mi-cuban-hoa-tiet','Ao so mi co cuban hoa tiet tre trung', 379000, 'ao-so-mi'),
  ('Ao so mi flannel ke soc','ao-so-mi-flannel-ke-soc','Ao so mi flannel am ap ke soc', 389000, 'ao-so-mi'),
  ('Ao so mi tay ngan trang','ao-so-mi-tay-ngan-trang','Ao so mi tay ngan mau trang thoang mat', 269000, 'ao-so-mi'),
  -- Ao thun
  ('Ao thun co tron','ao-thun-co-tron','Ao thun nam co tron', 159000, 'ao-thun'),
  ('Ao polo','ao-polo','Ao polo nam', 229000, 'ao-thun'),
  ('Ao thun co tim','ao-thun-co-tim','Ao thun nam co tim ca tinh', 149000, 'ao-thun'),
  ('Ao thun oversize den','ao-thun-oversize-den','Ao thun form rong mau den', 189000, 'ao-thun'),
  ('Ao thun in logo','ao-thun-in-logo','Ao thun in logo thoi trang', 179000, 'ao-thun'),
  ('Ao polo ke soc','ao-polo-ke-soc','Ao polo ke soc nang dong', 249000, 'ao-thun'),
  ('Ao thun the thao','ao-thun-the-thao','Ao thun the thao thoang khi', 169000, 'ao-thun'),
  ('Ao thun tay dai basic','ao-thun-tay-dai-basic','Ao thun tay dai basic de phoi', 199000, 'ao-thun'),
  -- Quan jeans
  ('Quan jeans slimfit','quan-jeans-slimfit','Quan jeans nam om slimfit', 459000, 'quan-jeans'),
  ('Quan jeans xanh nhat','quan-jeans-xanh-nhat','Quan jeans nam mau xanh nhat', 479000, 'quan-jeans'),
  ('Quan jeans den skinny','quan-jeans-den-skinny','Quan jeans den form skinny', 489000, 'quan-jeans'),
  ('Quan jeans rach goi','quan-jeans-rach-goi','Quan jeans rach goi ca tinh', 519000, 'quan-jeans'),
  ('Quan jeans straight','quan-jeans-straight','Quan jeans ong suong straight', 499000, 'quan-jeans'),
  ('Quan jeans xanh dam','quan-jeans-xanh-dam','Quan jeans mau xanh dam', 469000, 'quan-jeans'),
  ('Quan jeans regular fit','quan-jeans-regular-fit','Quan jeans regular fit thoai mai', 449000, 'quan-jeans'),
  ('Quan jeans co cao','quan-jeans-co-cao','Quan jeans lung cao ton dang', 529000, 'quan-jeans'),
  -- Quan tay
  ('Quan tay cong so','quan-tay-cong-so','Quan tay nam cong so', 389000, 'quan-tay'),
  ('Quan kaki','quan-kaki','Quan kaki nam', 349000, 'quan-tay'),
  ('Quan tay slimfit den','quan-tay-slimfit-den','Quan tay slimfit mau den', 399000, 'quan-tay'),
  ('Quan kaki be','quan-kaki-be','Quan kaki mau be thanh lich', 359000, 'quan-tay'),
  ('Quan tay xam cong so','quan-tay-xam-cong-so','Quan tay mau xam cong so', 409000, 'quan-tay'),
  ('Quan tay om navy','quan-tay-om-navy','Quan tay om mau navy', 419000, 'quan-tay'),
  ('Quan kaki xanh reu','quan-kaki-xanh-reu','Quan kaki mau xanh reu', 369000, 'quan-tay'),
  ('Quan tay vai cao cap','quan-tay-vai-cao-cap','Quan tay vai cao cap', 549000, 'quan-tay'),
  -- Ao khoac
  ('Ao khoac bomber','ao-khoac-bomber','Ao khoac bomber nam', 599000, 'ao-khoac'),
  ('Ao khoac jean','ao-khoac-jean','Ao khoac jean nam', 549000, 'ao-khoac'),
  ('Ao khoac gio the thao','ao-khoac-gio-the-thao','Ao khoac gio the thao nhe', 499000, 'ao-khoac'),
  ('Ao khoac da PU','ao-khoac-da-pu','Ao khoac da PU manh me', 899000, 'ao-khoac'),
  ('Ao khoac kaki 2 lop','ao-khoac-kaki-2-lop','Ao khoac kaki 2 lop giu am', 659000, 'ao-khoac'),
  ('Ao khoac hoodie ni','ao-khoac-hoodie-ni','Ao khoac hoodie ni am ap', 459000, 'ao-khoac'),
  ('Ao khoac blazer cong so','ao-khoac-blazer-cong-so','Ao blazer cong so lich lam', 799000, 'ao-khoac'),
  ('Ao khoac phao mua dong','ao-khoac-phao-mua-dong','Ao phao mua dong giu nhiet', 849000, 'ao-khoac')
) as p(name, slug, descr, price, cat_slug)
join public.categories c on c.slug = p.cat_slug
on conflict (slug) do nothing;

-- Bien the: 4 size (S,M,L,XL) x 3 mau (Den, Trang, Xanh) cho moi san pham
insert into public.product_variants (product_id, size, color, sku, stock)
select pr.id, v.size, v.color, pr.slug || '-' || v.size || '-' || v.color, 40
from public.products pr
cross join (values
  ('S','Den'),('M','Den'),('L','Den'),('XL','Den'),
  ('S','Trang'),('M','Trang'),('L','Trang'),('XL','Trang'),
  ('S','Xanh'),('M','Xanh'),('L','Xanh'),('XL','Xanh')
) as v(size, color)
on conflict (sku) do nothing;

-- Anh san pham: 3 anh moi san pham (chi them cho san pham chua co anh)
insert into public.product_images (product_id, url, sort_order)
select pr.id,
       'https://picsum.photos/seed/' || pr.slug || '-' || g.n || '/600/800',
       g.n
from public.products pr
cross join (values (0),(1),(2)) as g(n)
where not exists (
  select 1 from public.product_images i where i.product_id = pr.id
);

-- Banner trang chu (chi seed khi bang banners dang trong)
insert into public.banners (title, image_url, link_url, sort_order, end_date)
select b.title, b.image_url, b.link_url, b.sort_order, now() + interval '365 days'
from (values
  ('Bo suu tap Thu Dong 2025', 'https://picsum.photos/seed/menly-banner-1/1200/450', null::text, 1),
  ('Uu dai Ao so mi - giam den 30%', 'https://picsum.photos/seed/menly-banner-2/1200/450', null, 2),
  ('Quan jeans chinh hang gia tot', 'https://picsum.photos/seed/menly-banner-3/1200/450', null, 3),
  ('Free ship cho don tu 499k', 'https://picsum.photos/seed/menly-banner-4/1200/450', null, 4)
) as b(title, image_url, link_url, sort_order)
where not exists (select 1 from public.banners);

-- Ma giam gia mau
insert into public.vouchers (code, title, discount_type, discount_value, min_order_value, max_discount, usage_limit, end_date) values
  ('WELCOME10','Giam 10% cho don dau tien','percentage',10,200000,50000,1000, now() + interval '90 days'),
  ('SALE50K','Giam 50k cho don tu 300k','fixed_amount',50000,300000,null,500, now() + interval '60 days'),
  ('MENLY20','Giam 20% toi da 100k','percentage',20,500000,100000,300, now() + interval '60 days'),
  ('FREESHIP','Mien phi van chuyen','fixed_amount',30000,0,null,1000, now() + interval '90 days'),
  ('NEWBIE15','Giam 15% cho khach moi','percentage',15,200000,60000,500, now() + interval '90 days')
on conflict (code) do nothing;

-- Ghi chu: tai khoan admin/nhan vien/khach tao qua Supabase Auth (khong hardcode mat khau o day).
