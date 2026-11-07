# Cơ sở dữ liệu Menly

Chạy lần lượt trên Supabase (SQL Editor) theo đúng thứ tự:

1. `01_types.sql` — tạo kiểu dữ liệu (enum) và tiện ích.
2. `02_tables.sql` — tạo toàn bộ 26 bảng.
3. `03_functions.sql` — các hàm nghiệp vụ (kiểm tra admin, tạo/hủy đơn nguyên tử, xác nhận thanh toán, hủy đơn quá hạn). Với database đã có, chạy lại file này để cập nhật các hàm.
4. `04_seed.sql` — nhập dữ liệu mẫu (5 danh mục, 40 sản phẩm, biến thể size/màu, ảnh, banner trang chủ, mã giảm giá). Chạy lại được nhiều lần, không tạo trùng.
5. `05_indexes.sql` — tạo index giúp truy vấn nhanh hơn.
6. `06_triggers.sql` — trigger tự tạo hồ sơ khi đăng ký, tự tính điểm đánh giá.
7. `07_policies.sql` — phân quyền truy cập (RLS) cho các bảng.
8. `08_support_chat.sql` — tạo hội thoại CSKH và tin nhắn giữa khách hàng với nhân viên.

Lưu ý: tài khoản người dùng (admin/nhân viên/khách) được tạo qua Supabase Auth,
không ghi sẵn mật khẩu trong file SQL.
