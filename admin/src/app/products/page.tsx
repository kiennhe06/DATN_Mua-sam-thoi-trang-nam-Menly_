'use client';

import { useState, useEffect, useMemo, useCallback } from 'react';
import { Header } from '../../components/Header';
import { ProductDetailModal } from '../../components/ProductDetailModal';
import { CreateProductModal } from '../../components/CreateProductModal';
import { EditProductModal } from '../../components/EditProductModal';
import { DeleteProductModal } from '../../components/DeleteProductModal';
import { CompactVariantDisplay } from '../../components/CompactVariantDisplay';
import { approveProduct, fetchAdminProducts, fetchCategories, fetchProductDetail, updateProduct } from '../../lib/api';
import { Product, Category } from '../../lib/types';
import {
  Search,
  Eye,
  ArrowUpDown,
  Layers,
  LayoutGrid,
  List,
  CheckCircle2,
  FolderOpen,
  Plus,
  Pencil,
  BadgeCheck,
  RotateCcw,
  Trash2,
  AlertCircle,
} from 'lucide-react';

type SortOption =
  | 'category'
  | 'price_asc'
  | 'price_desc'
  | 'name_asc'
  | 'stock_desc'
  | 'stock_asc';

export default function ProductsPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState<SortOption>('category');
  const [viewMode, setViewMode] = useState<'grouped' | 'table'>('grouped');
  // Mac dinh hien TAT CA. Truoc day mac dinh la 'active', ma san pham vua tao
  // luon o trang thai tat + cho duyet, nen vua them xong la bi chinh bo loc giau
  // di, khong ai tim thay de bam duyet.
  const [statusFilter, setStatusFilter] =
    useState<'active' | 'pending' | 'inactive' | 'all'>('all');
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [productToDelete, setProductToDelete] = useState<Product | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [notification, setNotification] = useState<{
    message: string;
    type: 'success' | 'error';
  } | null>(null);

  async function loadData() {
    setLoading(true);
    setLoadError(null);
    try {
      const [cats, prods] = await Promise.all([
        fetchCategories(),
        fetchAdminProducts({ limit: 400 }),
      ]);
      setCategories(cats);
      setProducts(prods.items);
    } catch (error) {
      setCategories([]);
      setProducts([]);
      setLoadError(error instanceof Error ? error.message : 'Không tải được dữ liệu từ backend.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadData();
  }, []);

  const getProductCategory = useCallback((p: Product): Category => {
    if (p.categoryId) {
      const found = categories.find((c) => c.id === p.categoryId || c.slug === p.categoryId);
      if (found) return found;
    }
    const s = p.slug.toLowerCase();
    if (s.startsWith('ao-so-mi')) {
      const cat = categories.find((c) => c.slug === 'ao-so-mi-nam');
      if (cat) return cat;
    }
    if (s.startsWith('ao-polo') || s.startsWith('ao-thun')) {
      const cat = categories.find((c) => c.slug === 'ao-polo-t-shirt');
      if (cat) return cat;
    }
    if (
      s.startsWith('quan-jeans') ||
      s.startsWith('quan-bo') ||
      s.includes('jeans') ||
      s.includes('quan-short-jeans') ||
      s.includes('quan-short-bo')
    ) {
      const cat = categories.find((c) => c.slug === 'quan-jeans-nam');
      if (cat) return cat;
    }
    if (
      s.startsWith('quan-tay') ||
      s.startsWith('quan-kaki') ||
      s.startsWith('quan-au') ||
      s.startsWith('quan-short')
    ) {
      const cat = categories.find((c) => c.slug === 'quan-tay-kaki');
      if (cat) return cat;
    }
    if (
      s.startsWith('ao-khoac') ||
      s.startsWith('ao-blazer') ||
      s.startsWith('ao-mang-to') ||
      s.startsWith('ao-phao') ||
      s.startsWith('ao-gile') ||
      s.startsWith('ao-hoodie')
    ) {
      const cat = categories.find((c) => c.slug === 'ao-khoac-blazer');
      if (cat) return cat;
    }
    return categories[0] || {
      id: p.categoryId || 'uncategorized',
      name: 'Chưa phân loại',
      slug: 'chua-phan-loai',
      sortOrder: Number.MAX_SAFE_INTEGER,
    };
  }, [categories]);

  // Change product category directly and persist to backend
  const handleUpdateProductCategory = async (productId: string, newCategoryId: string) => {
    const targetCat = categories.find((c) => c.id === newCategoryId);
    try {
      await updateProduct(productId, { categoryId: newCategoryId });
      setProducts((prev) =>
        prev.map((p) => p.id === productId ? { ...p, categoryId: newCategoryId } : p)
      );
      setNotification({
        message: `Đã chuyển sản phẩm sang danh mục "${targetCat?.name || 'Mới'}"`,
        type: 'success',
      });
    } catch (error) {
      setNotification({
        message: error instanceof Error ? error.message : 'Không cập nhật được sản phẩm.',
        type: 'error',
      });
    }
    setTimeout(() => setNotification(null), 3000);
  };

  const handleToggleProductVisibility = async (product: Product) => {
    const willShow = product.isActive === false;
    if (!willShow) {
      setProductToDelete(product);
      return;
    }

    try {
      await updateProduct(product.id, { isActive: true });
      setProducts((current) => current.map((item) =>
        item.id === product.id ? { ...item, isActive: true } : item
      ));
      setNotification({ message: `Đã hiển thị lại sản phẩm “${product.name}”.`, type: 'success' });
    } catch (error) {
      setNotification({
        message: error instanceof Error ? error.message : 'Không cập nhật được trạng thái sản phẩm.',
        type: 'error',
      });
    }
    setTimeout(() => setNotification(null), 3500);
  };

  /**
   * Duyet san pham de ung dung nhin thay no.
   *
   * San pham moi tao luon o trang thai cho duyet. Truoc day trang quan tri
   * khong co cho nao duyet, nen san pham them tu day khong bao gio hien trong
   * ung dung va khong ai biet tai sao.
   */
  const handleApproveProduct = async (product: Product) => {
    try {
      await approveProduct(product.id);
      setProducts((current) =>
        current.map((item) =>
          item.id === product.id
            ? { ...item, approvalStatus: 'approved', isActive: true }
            : item,
        ),
      );
      setNotification({
        message: `Đã duyệt “${product.name}”. Sản phẩm sẽ hiện trong ứng dụng.`,
        type: 'success',
      });
    } catch (error) {
      setNotification({
        message: error instanceof Error ? error.message : 'Không duyệt được sản phẩm.',
        type: 'error',
      });
    }
    setTimeout(() => setNotification(null), 3500);
  };

  const renderProductActions = (product: Product) => (
    <div className="flex items-center justify-center gap-1.5">
      {product.approvalStatus === 'pending' && (
        <button
          type="button"
          onClick={() => handleApproveProduct(product)}
          title="Duyệt sản phẩm để hiển thị trong ứng dụng"
          className="rounded-lg bg-ok-bg p-1.5 text-ok transition-colors hover:opacity-80"
        >
          <BadgeCheck className="h-3.5 w-3.5" />
        </button>
      )}
      <button
        type="button"
        onClick={async () => {
          try {
            const detail = await fetchProductDetail(product.id);
            setSelectedProduct(detail || product);
          } catch (error) {
            setNotification({
              message: error instanceof Error ? error.message : 'Không tải được chi tiết sản phẩm.',
              type: 'error',
            });
            setTimeout(() => setNotification(null), 3500);
          }
        }}
        title="Xem chi tiết và tồn kho"
        className="rounded-lg bg-tint px-2.5 py-1.5 text-xs font-semibold text-ink-mid transition-all hover:bg-camel-hover hover:text-ink"
      >
        <Eye className="h-3.5 w-3.5" />
      </button>
      <button
        type="button"
        onClick={async () => {
          try {
            const detail = await fetchProductDetail(product.id);
            setEditingProduct(detail || product);
          } catch (error) {
            setNotification({
              message: error instanceof Error ? error.message : 'Không tải được sản phẩm để sửa.',
              type: 'error',
            });
            setTimeout(() => setNotification(null), 3500);
          }
        }}
        title="Sửa sản phẩm"
        className="rounded-lg bg-tint p-1.5 text-camel-dark transition-colors hover:bg-camel-hover hover:text-ink"
      >
        <Pencil className="h-3.5 w-3.5" />
      </button>
      <button
        type="button"
        onClick={() => handleToggleProductVisibility(product)}
        title={product.isActive === false ? 'Hiển thị lại sản phẩm' : 'Ẩn sản phẩm khỏi ứng dụng'}
        className={`rounded-lg bg-tint p-1.5 transition-colors ${product.isActive === false ? 'text-ok hover:bg-ok-bg' : 'text-danger hover:bg-danger-bg'}`}
      >
        {product.isActive === false ? <RotateCcw className="h-3.5 w-3.5" /> : <Trash2 className="h-3.5 w-3.5" />}
      </button>
    </div>
  );

  const getProductStock = (p: Product) => {
    return p.variants?.reduce((sum, v) => sum + v.stock, 0) || 0;
  };

  // Filter products by selected category and search query
  /// Bon nhom tach bach, khong chong len nhau.
  ///
  /// 'active' la dang ban that su tren ung dung: vua bat vua da duyet. San pham
  /// cho duyet du co bat cung chua len app nen khong tinh vao nhom nay.
  const matchesStatus = useCallback(
    (p: Product) => {
      const isPending = p.approvalStatus === 'pending';
      switch (statusFilter) {
        case 'all':
          return true;
        case 'pending':
          return isPending;
        case 'inactive':
          return !isPending && p.isActive === false;
        case 'active':
        default:
          return !isPending && p.isActive !== false;
      }
    },
    [statusFilter],
  );

  // Dung cho cac chip danh muc, de con so tren chip khop voi so san pham that
  // su hien ra ben duoi.
  const productsInStatus = useMemo(
    () => products.filter(matchesStatus),
    [products, matchesStatus],
  );

  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const pCat = getProductCategory(p);
      const matchCat =
        selectedCategory === 'all' ||
        p.categoryId === selectedCategory ||
        pCat.id === selectedCategory;
      const matchSearch =
        !searchQuery.trim() ||
        p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.slug.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.id.toLowerCase().includes(searchQuery.toLowerCase());
      return matchCat && matchSearch && matchesStatus(p);
    });
  }, [products, selectedCategory, searchQuery, getProductCategory, matchesStatus]);

  // Sort products based on selected sort option
  const sortedProducts = useMemo(() => {
    const list = [...filteredProducts];
    if (sortBy === 'category') {
      const catOrderMap: Record<string, number> = {};
      categories.forEach((c, idx) => {
        catOrderMap[c.id] = c.sortOrder ?? idx + 1;
      });
      list.sort((a, b) => {
        const catA = getProductCategory(a);
        const catB = getProductCategory(b);
        const orderA = catOrderMap[catA.id] ?? 999;
        const orderB = catOrderMap[catB.id] ?? 999;
        if (orderA !== orderB) return orderA - orderB;
        return a.name.localeCompare(b.name);
      });
    } else if (sortBy === 'price_asc') {
      list.sort((a, b) => a.price - b.price);
    } else if (sortBy === 'price_desc') {
      list.sort((a, b) => b.price - a.price);
    } else if (sortBy === 'name_asc') {
      list.sort((a, b) => a.name.localeCompare(b.name));
    } else if (sortBy === 'stock_desc') {
      list.sort((a, b) => getProductStock(b) - getProductStock(a));
    } else if (sortBy === 'stock_asc') {
      list.sort((a, b) => getProductStock(a) - getProductStock(b));
    }
    return list;
  }, [filteredProducts, sortBy, categories, getProductCategory]);

  // Group products by category for Grouped View
  const groupedProducts = useMemo(() => {
    const map = new Map<string, { category: Category; items: Product[] }>();
    categories.forEach((cat) => {
      map.set(cat.id, { category: cat, items: [] });
    });

    sortedProducts.forEach((p) => {
      const cat = getProductCategory(p);
      if (!map.has(cat.id)) {
        map.set(cat.id, { category: cat, items: [] });
      }
      map.get(cat.id)!.items.push(p);
    });

    return Array.from(map.values()).filter((g) =>
      selectedCategory === 'all' ? g.items.length > 0 : g.category.id === selectedCategory
    );
  }, [sortedProducts, categories, selectedCategory, getProductCategory]);

  return (
    <div className="flex-1 flex flex-col">
      <Header
        title="Quản lý Sản phẩm & Danh mục Phân loại"
        subtitle={`Hiển thị và sắp xếp ${sortedProducts.length} sản phẩm vào ${categories.length} danh mục`}
        onRefresh={loadData}
      />

      <div className="flex-1 space-y-6 p-4 sm:p-6 xl:p-8">
        <div className="flex justify-end">
          <button
            type="button"
            disabled={categories.length === 0}
            title={categories.length === 0 ? 'Backend chưa có danh mục để gán cho sản phẩm' : undefined}
            onClick={() => setShowCreateModal(true)}
            className="inline-flex items-center gap-2 rounded-xl bg-camel px-4 py-2.5 text-sm font-bold text-ink shadow-lg shadow-camel/15 transition-colors hover:bg-camel-hover disabled:cursor-not-allowed disabled:opacity-50"
          >
            <Plus className="h-4 w-4" /> Thêm sản phẩm
          </button>
        </div>

        {/* Toast Notification */}
        {notification && (
          <div
            role={notification.type === 'error' ? 'alert' : 'status'}
            className={`flex items-center gap-2 rounded-xl border px-4 py-2.5 text-xs shadow-lg animate-fade-in ${
              notification.type === 'error'
                ? 'border-danger-line bg-danger-bg text-danger'
                : 'border-ok-line bg-ok-bg text-ok'
            }`}
          >
            {notification.type === 'error' ? (
              <AlertCircle className="h-4 w-4 shrink-0" />
            ) : (
              <CheckCircle2 className="h-4 w-4 shrink-0" />
            )}
            <span className="font-semibold">{notification.message}</span>
          </div>
        )}

        {loadError && (
          <div className="flex items-center justify-between gap-4 rounded-xl border border-danger-line bg-danger-bg px-4 py-3 text-sm text-danger">
            <span>{loadError}</span>
            <button type="button" onClick={loadData} className="shrink-0 font-semibold underline">
              Thử tải lại
            </button>
          </div>
        )}

        {/* 1. Category Filter Tabs */}
        <div className="bg-panel border border-line p-4 rounded-2xl space-y-3 shadow-panel">
          <div className="flex items-center justify-between text-xs text-ink-muted font-semibold">
            <span className="flex items-center gap-1.5">
              <FolderOpen className="w-4 h-4 text-camel-dark" />
              DANH MỤC THỜI TRANG NAM ({categories.length} danh mục)
            </span>
            <span className="text-[11px] text-ink-muted font-normal">
              Bấm vào danh mục để lọc hoặc chọn &quot;Tất cả&quot; để xem phân nhóm
            </span>
          </div>

          <div className="flex items-center gap-2 overflow-x-auto pb-1">
            <button
              onClick={() => setSelectedCategory('all')}
              className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all shrink-0 cursor-pointer flex items-center gap-2 ${
                selectedCategory === 'all'
                  ? 'bg-camel text-ink shadow-md shadow-camel/20'
                  : 'bg-tint text-ink-mid hover:bg-tint-strong'
              }`}
            >
              <Layers className="w-3.5 h-3.5" />
              <span>Tất cả</span>
              <span
                className={`px-1.5 py-0.2 rounded-full text-[10px] ${
                  selectedCategory === 'all'
                    ? 'bg-panel text-camel-dark font-mono'
                    : 'bg-panel text-ink-muted'
                }`}
              >
                {productsInStatus.length}
              </span>
            </button>

            {categories.map((c) => {
              const count = productsInStatus.filter((p) => {
                const cat = getProductCategory(p);
                return p.categoryId === c.id || cat.id === c.id;
              }).length;

              return (
                <button
                  key={c.id}
                  onClick={() => setSelectedCategory(c.id)}
                  className={`px-3.5 py-2 rounded-xl text-xs font-bold transition-all shrink-0 cursor-pointer flex items-center gap-2 ${
                    selectedCategory === c.id
                      ? 'bg-camel text-ink shadow-md shadow-camel/20'
                      : 'bg-tint text-ink-mid hover:bg-tint-strong'
                  }`}
                >
                  <span>{c.name}</span>
                  <span
                    className={`px-1.5 py-0.2 rounded-full text-[10px] ${
                      selectedCategory === c.id
                        ? 'bg-panel text-camel-dark font-mono'
                        : 'bg-panel text-ink-muted'
                    }`}
                  >
                    {count}
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        {/* 2. Control Toolbar: Search, Sort & View Mode */}
        <div className="flex flex-col md:flex-row gap-3 items-stretch md:items-center justify-between bg-panel p-4 rounded-2xl border border-line shadow-panel">
          {/* Search Box */}
          <div className="flex items-center gap-3 flex-1 max-w-md bg-panel px-3.5 py-2.5 rounded-xl border border-line shadow-panel">
            <Search className="w-4 h-4 text-ink-muted shrink-0" />
            <input
              type="text"
              placeholder="Tìm kiếm sản phẩm theo tên, slug hoặc ID..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="bg-transparent text-xs text-ink placeholder-ink-muted focus:outline-none w-full"
            />
          </div>

          <div className="flex items-center gap-3">
            <select
              aria-label="Lọc trạng thái sản phẩm"
              value={statusFilter}
              onChange={(event) => setStatusFilter(
                  event.target.value as 'active' | 'pending' | 'inactive' | 'all',
                )}
              className="rounded-xl border border-line bg-panel px-3 py-2 text-xs font-medium text-ink-mid focus:border-camel focus:outline-none shadow-panel"
            >
              <option value="all">Tất cả trạng thái</option>
              <option value="pending">Chờ duyệt</option>
              <option value="active">Đang hiển thị</option>
              <option value="inactive">Đã ẩn</option>
            </select>
            {/* Sort Dropdown */}
            <div className="flex items-center gap-2 bg-panel px-3 py-1.5 rounded-xl border border-line shadow-panel">
              <ArrowUpDown className="w-3.5 h-3.5 text-camel-dark shrink-0" />
              <span className="text-[11px] text-ink-muted font-medium">Sắp xếp:</span>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as SortOption)}
                className="bg-transparent text-xs text-ink font-medium focus:outline-none cursor-pointer pr-1"
              >
                <option value="category" className="bg-panel text-ink">
                  Theo Danh mục (Áo sơ mi → Áo Polo → Quần → Áo khoác)
                </option>
                <option value="price_asc" className="bg-panel text-ink">
                  Giá: Thấp đến Cao
                </option>
                <option value="price_desc" className="bg-panel text-ink">
                  Giá: Cao đến Thấp
                </option>
                <option value="name_asc" className="bg-panel text-ink">
                  Tên: A → Z
                </option>
                <option value="stock_desc" className="bg-panel text-ink">
                  Tồn kho: Nhiều nhất
                </option>
                <option value="stock_asc" className="bg-panel text-ink">
                  Tồn kho: Ít nhất
                </option>
              </select>
            </div>

            {/* View Mode Toggle: Grouped Sections vs Single Table */}
            <div className="flex items-center bg-panel p-1 rounded-xl border border-line shadow-panel">
              <button
                onClick={() => setViewMode('grouped')}
                title="Gom nhóm theo Danh mục"
                className={`p-1.5 rounded-lg text-xs font-semibold flex items-center gap-1 transition-all ${
                  viewMode === 'grouped'
                    ? 'bg-camel text-ink'
                    : 'text-ink-muted hover:text-ink'
                }`}
              >
                <LayoutGrid className="w-3.5 h-3.5" />
                <span className="hidden sm:inline text-[11px]">Theo Danh mục</span>
              </button>
              <button
                onClick={() => setViewMode('table')}
                title="Danh sách Bảng tổng hợp"
                className={`p-1.5 rounded-lg text-xs font-semibold flex items-center gap-1 transition-all ${
                  viewMode === 'table'
                    ? 'bg-camel text-ink'
                    : 'text-ink-muted hover:text-ink'
                }`}
              >
                <List className="w-3.5 h-3.5" />
                <span className="hidden sm:inline text-[11px]">Bảng đơn</span>
              </button>
            </div>
          </div>
        </div>

        {/* 3. Product Presentation Area */}
        {loading ? (
          <div className="py-20 text-center text-ink-muted text-sm bg-panel border border-line rounded-2xl shadow-panel">
            Đang tải danh mục sản phẩm...
          </div>
        ) : sortedProducts.length === 0 ? (
          <div className="py-20 text-center text-ink-muted text-sm bg-panel border border-line rounded-2xl shadow-panel">
            Không tìm thấy sản phẩm phù hợp với bộ lọc
          </div>
        ) : viewMode === 'grouped' ? (
          /* GROUPED BY CATEGORY VIEW (Người dùng thấy rõ ràng từng Danh mục và các sản phẩm bên trong) */
          <div className="space-y-6">
            {groupedProducts.map((group) => (
              <div
                key={group.category.id}
                className="bg-panel border border-line rounded-2xl overflow-hidden shadow-lg"
              >
                {/* Category Group Header */}
                <div className="p-4 bg-tint border-b border-line flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <span className="w-3 h-3 rounded-full bg-camel shadow-sm shadow-camel/30"></span>
                    <h3 className="font-bold text-ink text-sm tracking-wide">
                      {group.category.name}
                    </h3>
                    <span className="bg-camel-tint text-camel-dark border border-camel/25 px-2 py-0.5 rounded-full text-[11px] font-mono font-bold">
                      {group.items.length} sản phẩm
                    </span>
                  </div>
                  <button
                    onClick={() => setSelectedCategory(group.category.id)}
                    className="text-xs text-ink-muted hover:text-camel-dark transition-colors font-medium flex items-center gap-1"
                  >
                    Xem riêng danh mục này →
                  </button>
                </div>

                {/* Table for this Category */}
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead>
                      <tr className="bg-tint text-ink-muted font-semibold border-b border-line">
                        <th className="py-2.5 px-4">Hình ảnh</th>
                        <th className="py-2.5 px-4">Tên sản phẩm</th>
                        <th className="py-2.5 px-4">Chuyển Danh mục</th>
                        <th className="py-2.5 px-4">Đơn giá</th>
                        <th className="py-2.5 px-4">Biến thể & Tồn kho</th>
                        <th className="py-2.5 px-4 text-center">Hành động</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-line text-ink-mid">
                      {group.items.map((p) => {
                        const totalStock = getProductStock(p);
                        return (
                          <tr key={p.id} className="hover:bg-tint transition-colors">
                            <td className="py-2.5 px-4">
                              <img
                                src={p.thumbnailUrl || undefined}
                                alt={p.name}
                                className="w-12 h-14 object-cover rounded-lg border border-line bg-panel"
                              />
                            </td>
                            <td className="py-2.5 px-4 max-w-xs">
                              <div className="flex items-center gap-2">
                                <p className="font-semibold text-ink line-clamp-1">{p.name}</p>
                                {p.isActive === false && <span className="shrink-0 rounded-md bg-tint-strong px-1.5 py-0.5 text-[9px] font-semibold text-ink-mid">Đã ẩn</span>}
                                {p.approvalStatus === 'pending' && <span className="shrink-0 rounded-md bg-warn-bg px-1.5 py-0.5 text-[9px] font-semibold text-warn">Chờ duyệt</span>}
                              </div>
                              <p className="text-[11px] font-mono text-ink-muted line-clamp-1">
                                {p.slug}
                              </p>
                            </td>
                            <td className="py-2.5 px-4">
                              <select
                                value={group.category.id}
                                onChange={(e) =>
                                  handleUpdateProductCategory(p.id, e.target.value)
                                }
                                className="bg-panel border border-line rounded-lg px-2 py-1 text-[11px] text-camel-dark font-medium focus:outline-none focus:border-camel cursor-pointer"
                              >
                                {categories.map((c) => (
                                  <option key={c.id} value={c.id}>
                                    {c.name}
                                  </option>
                                ))}
                              </select>
                            </td>
                            <td className="py-2.5 px-4 font-bold text-camel-dark font-mono text-xs">
                              {p.price.toLocaleString('vi-VN')} đ
                            </td>
                            <td className="py-2.5 px-4 min-w-[200px]">
                              <div className="flex items-start justify-between gap-2">
                                <CompactVariantDisplay variants={p.variants} />
                                <span className="text-[10px] bg-ok-bg text-ok px-1.5 py-0.5 rounded-md font-mono font-bold border border-ok-line shrink-0 mt-0.5">
                                  {totalStock} pcs
                                </span>
                              </div>
                            </td>
                            <td className="py-2.5 px-4 text-center">
                              {renderProductActions(p)}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            ))}
          </div>
        ) : (
          /* SINGLE TABLE VIEW */
          <div className="bg-panel border border-line rounded-2xl overflow-hidden shadow-lg">
            <div className="p-4 border-b border-line flex items-center justify-between text-xs text-ink-muted font-medium">
              <span>Hiển thị {sortedProducts.length} sản phẩm</span>
              <span>Sắp xếp theo: {sortBy}</span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="bg-tint text-ink-muted font-semibold border-b border-line">
                    <th className="py-3 px-4">Hình ảnh</th>
                    <th className="py-3 px-4">Tên sản phẩm</th>
                    <th className="py-3 px-4">Danh mục phân loại</th>
                    <th className="py-3 px-4">Đơn giá</th>
                    <th className="py-3 px-4">Biến thể & Tồn kho</th>
                    <th className="py-3 px-4 text-center">Hành động</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-line text-ink-mid">
                  {sortedProducts.map((p) => {
                    const cat = getProductCategory(p);
                    const totalStock = getProductStock(p);
                    return (
                      <tr key={p.id} className="hover:bg-tint transition-colors">
                        <td className="py-3 px-4">
                          <img
                            src={p.thumbnailUrl || undefined}
                            alt={p.name}
                            className="w-12 h-14 object-cover rounded-lg border border-line bg-panel"
                          />
                        </td>
                        <td className="py-3 px-4 max-w-xs">
                          <div className="flex items-center gap-2">
                            <p className="font-semibold text-ink line-clamp-1">{p.name}</p>
                            {p.isActive === false && <span className="shrink-0 rounded-md bg-tint-strong px-1.5 py-0.5 text-[9px] font-semibold text-ink-mid">Đã ẩn</span>}
                            {p.approvalStatus === 'pending' && <span className="shrink-0 rounded-md bg-warn-bg px-1.5 py-0.5 text-[9px] font-semibold text-warn">Chờ duyệt</span>}
                          </div>
                          <p className="text-xs font-mono text-ink-muted line-clamp-1">{p.slug}</p>
                        </td>
                        <td className="py-3 px-4">
                          <select
                            value={cat.id}
                            onChange={(e) =>
                              handleUpdateProductCategory(p.id, e.target.value)
                            }
                            className="bg-panel border border-line rounded-lg px-2 py-1 text-xs text-camel-dark font-semibold focus:outline-none focus:border-camel cursor-pointer"
                          >
                            {categories.map((c) => (
                              <option key={c.id} value={c.id}>
                                {c.name}
                              </option>
                            ))}
                          </select>
                        </td>
                        <td className="py-3 px-4 font-bold text-camel-dark font-mono text-xs">
                          {p.price.toLocaleString('vi-VN')} đ
                        </td>
                        <td className="py-3 px-4 min-w-[200px]">
                          <div className="flex items-start justify-between gap-2">
                            <CompactVariantDisplay variants={p.variants} />
                            <span className="text-[10px] bg-ok-bg text-ok px-1.5 py-0.5 rounded-md font-mono font-bold border border-ok-line shrink-0 mt-0.5">
                              {totalStock} pcs
                            </span>
                          </div>
                        </td>
                        <td className="py-3 px-4 text-center">
                          {renderProductActions(p)}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* Product Detail Modal */}
      <ProductDetailModal
        product={selectedProduct}
        onClose={() => setSelectedProduct(null)}
        onStockAdjusted={loadData}
      />
      {showCreateModal && (
        <CreateProductModal
          categories={categories}
          onClose={() => setShowCreateModal(false)}
          onCreated={(product) => {
            setProducts((current) => [product, ...current.filter((item) => item.id !== product.id)]);
            setNotification({ message: `Đã tạo sản phẩm “${product.name}” thành công.`, type: 'success' });
            setTimeout(() => setNotification(null), 3500);
          }}
        />
      )}
      {editingProduct && (
        <EditProductModal
          product={editingProduct}
          categories={categories}
          onClose={() => setEditingProduct(null)}
          onSaved={(updatedProduct) => {
            setProducts((current) => current.map((item) => item.id === updatedProduct.id ? updatedProduct : item));
            setNotification({ message: `Đã cập nhật sản phẩm “${updatedProduct.name}”.`, type: 'success' });
            setTimeout(() => setNotification(null), 3500);
          }}
        />
      )}
      {productToDelete && (
        <DeleteProductModal
          product={productToDelete}
          onClose={() => setProductToDelete(null)}
          onDeleted={() => {
            setProducts((current) => current.map((item) => item.id === productToDelete.id ? { ...item, isActive: false } : item));
            setProductToDelete(null);
            setNotification({ message: `Đã ẩn sản phẩm “${productToDelete.name}” khỏi ứng dụng.`, type: 'success' });
            setTimeout(() => setNotification(null), 3500);
          }}
        />
      )}
    </div>
  );
}
