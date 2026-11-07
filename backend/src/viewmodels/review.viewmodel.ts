import { ReviewModel } from '../models/review.model.js';

const MAX_REVIEW_IMAGES = 5;
export const REVIEWABLE_STATUSES = ['delivered', 'completed', 'paid', 'processing'];

export class ReviewViewModel {
  private model = new ReviewModel();

  listByProduct(productId: string) {
    return this.model.findByProduct(productId);
  }

  listMine(userId: string) {
    return this.model.findByUser(userId);
  }

  async create(input: {
    userId: string;
    productId?: string;
    orderItemId?: string;
    rating: number;
    comment?: string;
    files?: Express.Multer.File[];
    images?: string[];
  }) {
    let orderItemId = input.orderItemId;
    if (!orderItemId && input.productId) {
      const reviewable = await this.model.findReviewableOrderItemForProduct(input.userId, input.productId);
      if (reviewable) {
        orderItemId = reviewable.id;
      } else {
        throw new Error('Bạn cần mua và thanh toán sản phẩm này trước khi có thể viết đánh giá');
      }
    }

    if (!orderItemId) throw new Error('Thiếu thông tin sản phẩm trong đơn hàng');
    if (!Number.isInteger(input.rating) || input.rating < 1 || input.rating > 5) {
      throw new Error('Số sao phải từ 1 đến 5');
    }

    const purchased = await this.model.findPurchasedOrderItem(orderItemId, input.userId);
    if (!purchased) {
      throw new Error('Không tìm thấy sản phẩm trong đơn hàng của bạn');
    }
    if (!REVIEWABLE_STATUSES.includes(purchased.orderStatus)) {
      throw new Error('Chỉ có thể đánh giá sản phẩm sau khi đơn hàng được xác nhận hoặc đã giao');
    }
    if (!purchased.productId) {
      throw new Error('Không xác định được sản phẩm cần đánh giá');
    }
    if (input.productId && input.productId !== purchased.productId) {
      throw new Error('Sản phẩm không khớp với đơn hàng');
    }

    const providedImages = input.images ?? [];
    const files = input.files ?? [];
    if (providedImages.length + files.length > MAX_REVIEW_IMAGES) {
      throw new Error(`Chỉ được đính kèm tối đa ${MAX_REVIEW_IMAGES} ảnh`);
    }

    const uploadedImages = await this.model.uploadImages(input.userId, files);
    const images = [...providedImages, ...uploadedImages];

    return this.model.create({
      userId: input.userId,
      productId: purchased.productId,
      orderItemId: input.orderItemId,
      rating: input.rating,
      comment: input.comment,
      images,
    });
  }

  remove(reviewId: string, userId: string) {
    return this.model.removeOwn(reviewId, userId);
  }
}
