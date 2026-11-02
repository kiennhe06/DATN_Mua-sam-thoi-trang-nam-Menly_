interface ProductDetailsInput {
  name: string;
  price: string;
  thumbnailUrl: string;
}

interface ProductVariantInput {
  size: string;
  color: string;
  sku: string;
  stock: string;
}

export function validateProductDetails({
  name,
  price,
  thumbnailUrl,
}: ProductDetailsInput): string | null {
  const normalizedName = name.trim();
  if (normalizedName.length < 2 || normalizedName.length > 150) {
    return 'Tên sản phẩm phải có từ 2 đến 150 ký tự.';
  }

  const numericPrice = Number(price);
  if (!price.trim() || !Number.isSafeInteger(numericPrice) || numericPrice < 0) {
    return 'Giá bán phải là số nguyên không âm.';
  }

  const normalizedThumbnailUrl = thumbnailUrl.trim();
  if (normalizedThumbnailUrl) {
    try {
      new URL(normalizedThumbnailUrl);
    } catch {
      return 'Đường dẫn ảnh đại diện không hợp lệ.';
    }
  }

  return null;
}

export function validateProductVariants(variants: ProductVariantInput[]): string | null {
  if (variants.length < 1 || variants.length > 100) {
    return 'Sản phẩm cần có từ 1 đến 100 biến thể.';
  }

  const variantKeys = new Set<string>();
  for (const [index, variant] of variants.entries()) {
    const size = variant.size.trim();
    const color = variant.color.trim();
    const sku = variant.sku.trim();
    const stock = Number(variant.stock);

    if (!size || size.length > 30) {
      return `Size của biến thể ${index + 1} phải có từ 1 đến 30 ký tự.`;
    }
    if (!color || color.length > 60) {
      return `Màu của biến thể ${index + 1} phải có từ 1 đến 60 ký tự.`;
    }
    if (sku.length > 100) {
      return `SKU của biến thể ${index + 1} không được vượt quá 100 ký tự.`;
    }
    if (!variant.stock.trim() || !Number.isSafeInteger(stock) || stock < 0) {
      return `Tồn kho của biến thể ${index + 1} phải là số nguyên không âm.`;
    }

    const key = `${size.toLocaleLowerCase()}|${color.toLocaleLowerCase()}`;
    if (variantKeys.has(key)) {
      return 'Các biến thể không được trùng cặp size và màu.';
    }
    variantKeys.add(key);
  }

  return null;
}
