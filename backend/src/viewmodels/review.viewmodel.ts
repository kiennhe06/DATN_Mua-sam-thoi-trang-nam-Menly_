import { ReviewModel } from '../models/review.model.js';

const MAX_REVIEW_IMAGES = 5;
// Chi danh gia duoc khi khach da thuc su nhan hang. Truoc day danh sach nay co
// ca 'paid' va 'processing', nghia la tra tien xong la danh gia duoc ngay khi
// hang chua roi kho — danh gia nhu vay khong phan anh san pham that.
export const REVIEWABLE_STATUSES = ['delivered', 'completed'];

export class ReviewViewModel {
  private model = new ReviewModel();

  listByProduct(productId: string) {
    return this.model.findByProduct(productId);
  }

  listMine(userId: string) {
    return this.model.findByUser(userId);
  }

  /// Nguoi dung co duoc danh gia san pham nay khong.
  ///
  /// Giao dien hoi truoc de khong hien nut "Viet danh gia" cho nguoi chua tung
  /// nhan hang; may chu van kiem tra lai khi luu nen day chi la de do kho chiu.
  async canReview(userId: string, productId: string): Promise<boolean> {
    const reviewable = await this.model.findReviewableOrderItemForProduct(
      userId,
      productId,
      REVIEWABLE_STATUSES,
    );
    return reviewable != null;
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
      const reviewable = await this.model.findReviewableOrderItemForProduct(
        input.userId,
        input.productId,
        REVIEWABLE_STATUSES,
      );
      if (reviewable) {
        orderItemId = reviewable.id;
      } else {
        throw new Error('Bạn cần nhận được sản phẩm này trước khi viết đánh giá');
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
      throw new Error('Chỉ có thể đánh giá sau khi đơn hàng đã giao đến bạn');
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
      // Dung orderItemId da tra ra o tren chu khong phai input.orderItemId:
      // khi nguoi dung danh gia tu man san pham thi input khong co truong nay,
      // gui len null se vi pham rang buoc not null cua product_reviews.
      orderItemId,
      rating: input.rating,
      comment: input.comment,
      images,
    });
  }

  remove(reviewId: string, userId: string) {
    return this.model.removeOwn(reviewId, userId);
  }
}
