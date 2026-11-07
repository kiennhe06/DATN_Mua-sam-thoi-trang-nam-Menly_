/* Trang cong khai hien thi chi tiet san pham tu du lieu that (Supabase).
   Dung cho lien ket chia se tu app Menly. */

type ProductRecord = {
  id?: string;
  name?: string;
  description?: string | null;
  price?: number | string | null;
  thumbnail_url?: string | null;
  rating_avg?: number | string | null;
  rating_count?: number | string | null;
  category_name?: string | null;
  categories?: { name?: string | null } | null;
  product_variants?: Array<{
    size?: string | null;
    color?: string | null;
    stock?: number | string | null;
  }> | null;
  product_images?: Array<{ url?: string | null; sort_order?: number | null }> | null;
};

function escapeHtml(value: unknown): string {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function formatNumber(value: number): string {
  return Math.abs(Math.round(value))
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, '.');
}

function formatPrice(value: unknown): string {
  const amount = Number(value);
  if (!Number.isFinite(amount)) return '0 đ';
  return `${formatNumber(amount)} đ`;
}

function toNumber(value: unknown, fallback = 0): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function buildGallery(product: ProductRecord): string[] {
  const urls = new Set<string>();

  const thumbnail = (product.thumbnail_url ?? '').trim();
  if (thumbnail) urls.add(thumbnail);

  const images = [...(product.product_images ?? [])]
    .sort((a, b) => toNumber(a.sort_order) - toNumber(b.sort_order))
    .map((image) => (image.url ?? '').trim())
    .filter((url) => url.length > 0);

  for (const url of images) {
    urls.add(url);
  }

  return [...urls];
}

function buildVariantChips(product: ProductRecord): string {
  const variants = product.product_variants ?? [];
  if (variants.length === 0) {
    return '<p class="muted">Thông tin phân loại đang được cập nhật.</p>';
  }

  const seen = new Set<string>();
  const chips: string[] = [];

  for (const variant of variants) {
    const size = (variant.size ?? '').trim();
    const color = (variant.color ?? '').trim();
    const stock = toNumber(variant.stock);
    const label = [size, color].filter(Boolean).join(' · ') || 'Mặc định';
    const key = `${label}-${stock > 0 ? 'in' : 'out'}`;
    if (seen.has(key)) continue;
    seen.add(key);

    const className = stock > 0 ? 'chip' : 'chip chip-out';
    const stockLabel = stock > 0 ? `Còn ${stock}` : 'Hết hàng';
    chips.push(
      `<span class="${className}"><strong>${escapeHtml(label)}</strong>` +
        `<small>${stockLabel}</small></span>`,
    );
  }

  return `<div class="variants">${chips.join('')}</div>`;
}

export function renderProductSharePage(
  product: ProductRecord,
  canonicalUrl: string,
): string {
  const name = escapeHtml(product.name || 'Sản phẩm Menly');
  const description = escapeHtml(
    product.description || 'Sản phẩm thời trang nam chính hãng tại Menly.',
  );
  const category = escapeHtml(
    product.category_name || product.categories?.name || 'Thời trang nam',
  );
  const price = formatPrice(product.price);
  const ratingAvg = toNumber(product.rating_avg);
  const ratingCount = toNumber(product.rating_count);
  const gallery = buildGallery(product);
  const mainImage = gallery[0] ?? '';
  const thumbnails = gallery.slice(1, 5);
  const variantChips = buildVariantChips(product);
  const safeCanonical = escapeHtml(canonicalUrl);
  const safeImage = escapeHtml(mainImage);

  const ratingBlock =
    ratingCount > 0
      ? `<span class="rating">★ ${ratingAvg.toFixed(1)}</span>` +
        `<span class="muted">${formatNumber(ratingCount)} đánh giá</span>`
      : '<span class="muted">Chưa có đánh giá</span>';

  const descriptionBlock = product.description
    ? `<section class="section">
         <h2>Mô tả sản phẩm</h2>
         <p class="description">${description}</p>
       </section>`
    : '';

  const imageBlock = mainImage
    ? `<img class="hero-image" src="${safeImage}" alt="${name}" />`
    : '';

  const thumbnailBlock =
    thumbnails.length > 0
      ? `<div class="thumbs">${thumbnails
          .map(
            (url) =>
              `<img src="${escapeHtml(url)}" alt="${name}" loading="lazy" />`,
          )
          .join('')}</div>`
      : '';

  return `<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${name} | Menly</title>
  <meta name="description" content="${description}" />
  <link rel="canonical" href="${safeCanonical}" />
  <meta property="og:type" content="product" />
  <meta property="og:site_name" content="Menly" />
  <meta property="og:title" content="${name}" />
  <meta property="og:description" content="${description}" />
  <meta property="og:image" content="${safeImage}" />
  <meta property="og:url" content="${safeCanonical}" />
  <meta name="twitter:card" content="summary_large_image" />
  <style>
    :root {
      --ink: #1c1b17;
      --camel: #b8824a;
      --cream: #f7f5f1;
      --border: #e8e2d7;
      --text: #15140f;
      --muted: #6e6a5f;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: var(--cream);
      color: var(--text);
      font-family: "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      line-height: 1.55;
    }
    a { color: inherit; }
    .topbar {
      background: var(--ink);
      color: #fff;
      padding: 16px 20px;
      letter-spacing: 4px;
      font-weight: 700;
      text-transform: uppercase;
      text-align: center;
    }
    .topbar span { color: var(--camel); }
    main {
      max-width: 980px;
      margin: 0 auto;
      padding: 24px 16px 48px;
    }
    .card {
      background: #fff;
      border: 1px solid var(--border);
      border-radius: 18px;
      overflow: hidden;
      box-shadow: 0 18px 40px rgba(28, 27, 23, 0.08);
      display: grid;
      grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
    }
    .media { background: #f2efe9; padding: 18px; }
    .hero-image {
      width: 100%;
      aspect-ratio: 4 / 5;
      object-fit: cover;
      border-radius: 12px;
      display: block;
    }
    .thumbs {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 8px;
      margin-top: 10px;
    }
    .thumbs img {
      width: 100%;
      aspect-ratio: 1;
      object-fit: cover;
      border-radius: 8px;
      border: 1px solid var(--border);
      background: #fff;
    }
    .info { padding: 28px 28px 32px; }
    .category {
      margin: 0 0 10px;
      color: var(--camel);
      font-size: 12px;
      font-weight: 700;
      letter-spacing: 2px;
      text-transform: uppercase;
    }
    h1 {
      margin: 0 0 12px;
      font-size: clamp(24px, 4vw, 34px);
      line-height: 1.25;
    }
    .meta {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 8px 12px;
      margin-bottom: 18px;
      font-size: 14px;
    }
    .rating { color: #d97706; font-weight: 700; }
    .muted { color: var(--muted); }
    .price {
      font-size: clamp(26px, 4vw, 34px);
      font-weight: 800;
      color: #c0564b;
      margin: 0 0 20px;
    }
    .section { margin-top: 24px; }
    h2 {
      margin: 0 0 10px;
      font-size: 16px;
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    .description {
      margin: 0;
      color: var(--muted);
      white-space: pre-line;
    }
    .variants {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }
    .chip {
      display: inline-flex;
      flex-direction: column;
      padding: 8px 14px;
      border: 1px solid var(--border);
      border-radius: 10px;
      background: #faf8f4;
      font-size: 13px;
    }
    .chip small { color: var(--muted); font-size: 11px; }
    .chip-out { opacity: 0.45; }
    .note {
      margin-top: 26px;
      padding: 14px 16px;
      border-radius: 12px;
      background: var(--cream);
      border: 1px dashed var(--border);
      color: var(--muted);
      font-size: 13px;
    }
    footer {
      text-align: center;
      color: var(--muted);
      font-size: 12px;
      padding: 0 16px 32px;
    }
    @media (max-width: 760px) {
      .card { grid-template-columns: 1fr; }
      .info { padding: 22px 18px 26px; }
      .thumbs { grid-template-columns: repeat(3, 1fr); }
    }
  </style>
</head>
<body>
  <header class="topbar">Men<span>ly</span></header>
  <main>
    <article class="card">
      <div class="media">
        ${imageBlock}
        ${thumbnailBlock}
      </div>
      <div class="info">
        <p class="category">${category}</p>
        <h1>${name}</h1>
        <div class="meta">
          ${ratingBlock}
        </div>
        <p class="price">${price}</p>
        <section class="section">
          <h2>Phân loại sản phẩm</h2>
          ${variantChips}
        </section>
        ${descriptionBlock}
        <p class="note">
          Sản phẩm được chia sẻ từ ứng dụng Menly. Mở ứng dụng để chọn size,
          màu và đặt hàng.
        </p>
      </div>
    </article>
  </main>
  <footer>© Menly — Thời trang nam</footer>
</body>
</html>`;
}

export function renderProductNotFoundPage(): string {
  return `<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Không tìm thấy sản phẩm | Menly</title>
  <style>
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      background: #f7f5f1;
      color: #15140f;
      font-family: "Segoe UI", Roboto, Arial, sans-serif;
      text-align: center;
      padding: 24px;
    }
    h1 { margin: 0 0 10px; font-size: 26px; }
    p { margin: 0; color: #6e6a5f; }
    .brand {
      display: inline-block;
      margin-bottom: 18px;
      padding: 8px 18px;
      border-radius: 999px;
      background: #1c1b17;
      color: #fff;
      letter-spacing: 4px;
      font-weight: 700;
      font-size: 13px;
      text-transform: uppercase;
    }
    .brand span { color: #b8824a; }
  </style>
</head>
<body>
  <div>
    <div class="brand">Men<span>ly</span></div>
    <h1>Không tìm thấy sản phẩm</h1>
    <p>Sản phẩm có thể đã ngừng bán hoặc liên kết không còn hợp lệ.</p>
  </div>
</body>
</html>`;
}
