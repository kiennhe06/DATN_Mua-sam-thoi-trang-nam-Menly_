import {
  INITIAL_CATEGORIES,
  INITIAL_PRODUCTS,
  INITIAL_USERS,
} from './mock-admin-data';
import type {
  AuditLog,
  InventoryMovement,
  Order,
  Product,
  UserAccount,
  Voucher,
} from './types';

const STORAGE_PREFIX = 'menshop_preview_';

const INITIAL_ORDERS: Order[] = [
  {
    id: 'preview-order-001',
    code: 'ML20261102001',
    userId: 'preview-user-001',
    status: 'processing',
    paymentMethod: 'cod',
    subtotal: 760000,
    shippingFee: 30000,
    total: 790000,
    shipName: 'Nguyễn Minh Khang',
    shipPhone: '0901234567',
    shipAddress: '12 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
    shippingAddress: {
      name: 'Nguyễn Minh Khang',
      phone: '0901234567',
      address: '12 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
      note: 'Giao giờ hành chính',
    },
    createdAt: new Date().toISOString(),
    items: [
      {
        id: 'preview-item-001',
        orderId: 'preview-order-001',
        variantId: 'preview-variant-001',
        productName: INITIAL_PRODUCTS[0].name,
        size: 'L',
        color: 'Trắng',
        unitPrice: 380000,
        quantity: 2,
      },
    ],
  },
  {
    id: 'preview-order-002',
    code: 'ML20261102002',
    userId: 'preview-user-002',
    status: 'shipping',
    paymentMethod: 'vnpay',
    subtotal: 520000,
    shippingFee: 0,
    total: 520000,
    shipName: 'Trần Quốc Bảo',
    shipPhone: '0912345678',
    shipAddress: '28 Lê Lợi, Hải Châu, Đà Nẵng',
    shippingAddress: {
      name: 'Trần Quốc Bảo',
      phone: '0912345678',
      address: '28 Lê Lợi, Hải Châu, Đà Nẵng',
    },
    createdAt: new Date(Date.now() - 3_600_000).toISOString(),
    items: [
      {
        id: 'preview-item-002',
        orderId: 'preview-order-002',
        variantId: 'preview-variant-002',
        productName: INITIAL_PRODUCTS[1].name,
        size: 'M',
        color: 'Xanh',
        unitPrice: 520000,
        quantity: 1,
      },
    ],
  },
  {
    id: 'preview-order-003',
    code: 'ML20261102003',
    userId: 'preview-user-003',
    status: 'pending_payment',
    paymentMethod: 'cod',
    subtotal: 290000,
    shippingFee: 30000,
    total: 320000,
    shipName: 'Lê Hoàng Nam',
    shipPhone: '0987654321',
    shipAddress: '15 Trần Phú, Nha Trang, Khánh Hòa',
    shippingAddress: {
      name: 'Lê Hoàng Nam',
      phone: '0987654321',
      address: '15 Trần Phú, Nha Trang, Khánh Hòa',
    },
    createdAt: new Date(Date.now() - 86_400_000).toISOString(),
    items: [
      {
        id: 'preview-item-003',
        orderId: 'preview-order-003',
        variantId: 'preview-variant-003',
        productName: INITIAL_PRODUCTS[25].name,
        size: 'XL',
        color: 'Đen',
        unitPrice: 290000,
        quantity: 1,
      },
    ],
  },
];

const INITIAL_VOUCHERS: Voucher[] = [
  {
    id: 'preview-voucher-001',
    code: 'MENLY20',
    title: 'Ưu đãi 20% cho đơn hàng thời trang',
    discountType: 'percentage',
    discountValue: 20,
    minOrderValue: 300000,
    maxDiscount: 100000,
    usageLimit: 100,
    usedCount: 34,
    startDate: new Date(Date.now() - 7 * 86_400_000).toISOString(),
    endDate: new Date(Date.now() + 30 * 86_400_000).toISOString(),
    isActive: true,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'preview-voucher-002',
    code: 'FREESHIP',
    title: 'Miễn phí giao hàng',
    discountType: 'fixed_amount',
    discountValue: 30000,
    minOrderValue: 200000,
    maxDiscount: null,
    usageLimit: 200,
    usedCount: 86,
    startDate: new Date(Date.now() - 2 * 86_400_000).toISOString(),
    endDate: new Date(Date.now() + 14 * 86_400_000).toISOString(),
    isActive: true,
    createdAt: new Date().toISOString(),
  },
];

const INITIAL_REVIEWS = [
  {
    id: 'preview-review-001',
    userId: 'preview-user-001',
    productId: INITIAL_PRODUCTS[0].id,
    rating: 5,
    comment: 'Chất vải đẹp, mặc vừa vặn và giao hàng nhanh.',
    createdAt: new Date(Date.now() - 2 * 3_600_000).toISOString(),
    user: { id: 'preview-user-001', email: 'khang@example.com', name: 'Nguyễn Minh Khang' },
  },
  {
    id: 'preview-review-002',
    userId: 'preview-user-002',
    productId: INITIAL_PRODUCTS[1].id,
    rating: 4,
    comment: 'Màu sắc đúng hình, đóng gói cẩn thận.',
    createdAt: new Date(Date.now() - 8 * 3_600_000).toISOString(),
    user: { id: 'preview-user-002', email: 'bao@example.com', name: 'Trần Quốc Bảo' },
  },
];

function readList<T>(key: string, initial: T[]): T[] {
  const saved = localStorage.getItem(`${STORAGE_PREFIX}${key}`);
  return saved ? (JSON.parse(saved) as T[]) : initial.map((item) => ({ ...item }));
}

function writeList<T>(key: string, items: T[]): void {
  localStorage.setItem(`${STORAGE_PREFIX}${key}`, JSON.stringify(items));
}

function response<T>(value: T): T {
  return value;
}

export function handlePreviewRequest<T>(path: string, options: RequestInit = {}): T {
  if (typeof window === 'undefined') {
    throw new Error('Chế độ xem trước chỉ hoạt động trong trình duyệt.');
  }

  const url = new URL(path, window.location.origin);
  const pathname = url.pathname;
  const method = (options.method || 'GET').toUpperCase();
  const body = options.body ? (JSON.parse(String(options.body)) as Record<string, unknown>) : {};

  if (pathname === '/api/v1/categories' && method === 'GET') {
    return response({ data: readList('categories', INITIAL_CATEGORIES) }) as T;
  }

  if (pathname === '/api/v1/admin/products') {
    const products = readList('products', INITIAL_PRODUCTS);
    if (method === 'GET') {
      const search = (url.searchParams.get('q') || url.searchParams.get('search') || '').toLowerCase();
      const categoryId = url.searchParams.get('categoryId');
      const items = products
        .filter((product) => !categoryId || product.categoryId === categoryId)
        .filter((product) => !search || `${product.name} ${product.slug}`.toLowerCase().includes(search))
        .slice(0, Number(url.searchParams.get('limit') || 400));
      return response({ items, total: items.length }) as T;
    }

    if (method === 'POST') {
      const product: Product = {
        ...(body as unknown as Product),
        id: `preview-product-${Date.now()}`,
        createdAt: new Date().toISOString(),
        variants: [],
        images: [],
      };
      writeList('products', [product, ...products]);
      return response(product) as T;
    }
  }

  const productMatch = pathname.match(/^\/api\/v1\/admin\/products\/([^/]+)$/);
  if (productMatch) {
    const products = readList('products', INITIAL_PRODUCTS);
    const product = products.find((item) => item.id === productMatch[1]);
    if (!product) throw new Error('Không tìm thấy sản phẩm trong dữ liệu xem trước.');
    if (method === 'GET') return response({ data: product }) as T;
    if (method === 'PUT') {
      const updated = { ...product, ...body } as Product;
      writeList('products', products.map((item) => (item.id === product.id ? updated : item)));
      return response(updated) as T;
    }
    if (method === 'DELETE') {
      writeList('products', products.filter((item) => item.id !== product.id));
      return response({ message: 'Đã xóa sản phẩm xem trước.' }) as T;
    }
  }

  if (pathname === '/api/v1/admin/orders') {
    const orders = readList('orders', INITIAL_ORDERS);
    if (method === 'GET') {
      const status = url.searchParams.get('status');
      return response(status ? orders.filter((order) => order.status === status) : orders) as T;
    }
  }

  const orderStatusMatch = pathname.match(/^\/api\/v1\/admin\/orders\/([^/]+)\/status$/);
  if (orderStatusMatch && method === 'PUT') {
    const orders = readList('orders', INITIAL_ORDERS);
    const updated = orders.map((order) =>
      order.id === orderStatusMatch[1] ? { ...order, status: body.status as Order['status'] } : order
    );
    writeList('orders', updated);
    return response({ message: 'Đã cập nhật đơn hàng xem trước.' }) as T;
  }

  if (pathname === '/api/v1/admin/inventory/movements' && method === 'GET') {
    return response(readList<InventoryMovement>('movements', [])) as T;
  }
  if (pathname === '/api/v1/admin/inventory/adjust' && method === 'POST') {
    const movements = readList<InventoryMovement>('movements', []);
    const movement: InventoryMovement = {
      id: `preview-movement-${Date.now()}`,
      variantId: String(body.variantId || ''),
      delta: Number(body.delta || 0),
      change: Number(body.delta || 0),
      reason: (body.reason as InventoryMovement['reason']) || 'admin_restock',
      note: String(body.note || 'Điều chỉnh trong chế độ xem trước'),
      createdAt: new Date().toISOString(),
    };
    writeList('movements', [movement, ...movements]);
    return response({ message: 'Đã điều chỉnh kho xem trước.' }) as T;
  }

  if (pathname === '/api/v1/admin/audit-log' && method === 'GET') {
    return response(readList<AuditLog>('audit', [])) as T;
  }

  if (pathname === '/api/v1/admin/users' && method === 'GET') {
    return response({ data: readList('users', INITIAL_USERS) }) as T;
  }

  if (pathname === '/api/v1/admin/users' && method === 'POST') {
    const users = readList('users', INITIAL_USERS);
    const user: UserAccount = {
      id: `preview-user-${Date.now()}`,
      email: String(body.email || 'demo@example.com'),
      name: String(body.name || ''),
      fullName: String(body.name || ''),
      role: (body.role as UserAccount['role']) || 'customer',
      createdAt: new Date().toISOString(),
      isActive: true,
      isLocked: false,
    };
    writeList('users', [user, ...users]);
    return response(user) as T;
  }

  const userMatch = pathname.match(/^\/api\/v1\/admin\/users\/([^/]+)(?:\/(lock|role))?$/);
  if (userMatch) {
    const users = readList('users', INITIAL_USERS);
    const user = users.find((item) => item.id === userMatch[1]);
    if (!user) throw new Error('Không tìm thấy người dùng trong dữ liệu xem trước.');
    if (method === 'DELETE') {
      writeList('users', users.filter((item) => item.id !== user.id));
      return response({ message: 'Đã xóa người dùng xem trước.' }) as T;
    }
    if (method === 'PUT' || method === 'PATCH') {
      const changes = userMatch[2] === 'lock'
        ? { isLocked: Boolean(body.isLocked) }
        : userMatch[2] === 'role'
          ? { role: body.role as UserAccount['role'] }
          : body;
      const updated = { ...user, ...changes } as UserAccount;
      writeList('users', users.map((item) => (item.id === user.id ? updated : item)));
      return response(userMatch[2] === 'lock' ? { user: updated } : updated) as T;
    }
  }

  if (pathname === '/api/v1/admin/reviews' && method === 'GET') {
    return response({ items: readList('reviews', INITIAL_REVIEWS), pageInfo: { limit: 50, hasNext: false, nextCursor: null } }) as T;
  }
  const reviewMatch = pathname.match(/^\/api\/v1\/admin\/reviews\/([^/]+)$/);
  if (reviewMatch && method === 'DELETE') {
    writeList('reviews', readList('reviews', INITIAL_REVIEWS).filter((review) => review.id !== reviewMatch[1]));
    return response({ message: 'Đã xóa đánh giá xem trước.' }) as T;
  }

  if (pathname === '/api/v1/admin/vouchers') {
    const vouchers = readList('vouchers', INITIAL_VOUCHERS);
    if (method === 'GET') return response({ data: vouchers }) as T;
    if (method === 'POST') {
      const voucher = { ...body, id: `preview-voucher-${Date.now()}`, usedCount: 0, createdAt: new Date().toISOString() };
      writeList('vouchers', [voucher, ...vouchers]);
      return response(voucher) as T;
    }
  }
  const voucherMatch = pathname.match(/^\/api\/v1\/admin\/vouchers\/([^/]+)$/);
  if (voucherMatch) {
    const vouchers = readList('vouchers', INITIAL_VOUCHERS);
    const voucher = vouchers.find((item) => item.id === voucherMatch[1]);
    if (!voucher) throw new Error('Không tìm thấy mã giảm giá trong dữ liệu xem trước.');
    if (method === 'PUT') {
      const updated = { ...voucher, ...body };
      writeList('vouchers', vouchers.map((item) => (item.id === voucher.id ? updated : item)));
      return response(updated) as T;
    }
    if (method === 'DELETE') {
      writeList('vouchers', vouchers.filter((item) => item.id !== voucher.id));
      return response({ success: true }) as T;
    }
  }

  throw new Error(`Chức năng xem trước chưa hỗ trợ ${method} ${pathname}.`);
}
