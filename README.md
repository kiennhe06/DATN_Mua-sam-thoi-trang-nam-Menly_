# Menly (MenShop) — Ứng dụng thương mại điện tử thời trang nam

- `database/`: lược đồ và dữ liệu mẫu Supabase.
- `backend/`: API Node.js + Express.
- `admin/`: trang quản trị Next.js.
- `frontend/`: ứng dụng Flutter.

## Chạy với Supabase dùng chung

### 1. Chuẩn bị cơ sở dữ liệu

Tạo project Supabase dùng cho phát triển nhóm, sau đó chạy các file SQL theo thứ tự trong [database/README.md](database/README.md).

Tạo tài khoản quản trị một lần trong Supabase:

1. Mở **Authentication → Users → Add user** trong Supabase Dashboard và tạo user bằng email/mật khẩu riêng.
2. Sau khi user xuất hiện trong bảng `profiles`, mở **SQL Editor** và cấp quyền admin cho đúng email:

   ```sql
   update public.profiles
   set role = 'admin', is_active = true, is_locked = false
   where lower(email) = lower('admin@example.com');
   ```

3. Xác nhận chỉ đúng một tài khoản được cập nhật, rồi đăng nhập admin bằng email và mật khẩu vừa tạo. Không dùng chung mật khẩu yếu hoặc đưa mật khẩu vào Git.

### 2. Cấu hình và chạy backend

Mỗi thành viên tạo `backend/.env` từ file `.env` được nhóm chia sẻ an toàn hoặc từ `backend/.env.example`, rồi điền URL và key của cùng một Supabase project:

```env
PORT=5000
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

Chỉ backend được giữ service role key. Không commit file `.env`, không đặt key này trong `NEXT_PUBLIC_*` hoặc app Flutter. Khóa trong ví dụ chỉ là chỗ điền; `.env` thật đã bị Git ignore.

```powershell
cd backend
npm ci
npm run dev
```

Kiểm tra `http://localhost:5000/api/v1/health`, sau đó kiểm tra `/api/v1/categories` và `/api/v1/products`. Health check đơn lẻ chỉ xác nhận server hoạt động; dữ liệu thật phải trả về từ API.

### 3. Chạy admin

Trong terminal khác:

```powershell
cd admin
Copy-Item .env.example .env.local
npm ci
npm run dev
```

Mở `http://localhost:3000` và đăng nhập bằng tài khoản Supabase có role `admin`. Nút xem trước giao diện trong môi trường development dùng dữ liệu mẫu, không dùng khi kiểm tra dữ liệu thật.

### 4. Chạy ứng dụng Flutter

```powershell
cd frontend
flutter pub get
flutter run
```

Android Emulator mặc định gọi backend qua `10.0.2.2:5000`. Máy thật cần dùng IP LAN của máy chạy backend, cùng mạng Wi-Fi và được phép truy cập cổng 5000.

## Lưu ý về phạm vi chức năng

Backend hiện đọc dữ liệu thật cho các API đã triển khai, bao gồm danh mục và sản phẩm. Một số API quản trị/đơn hàng vẫn chưa được cài đặt và có thể trả HTTP 501; kết nối Supabase không tự hoàn thiện các nghiệp vụ này. Kiểm tra từng màn/API trước khi dùng như hệ thống vận hành thật.
