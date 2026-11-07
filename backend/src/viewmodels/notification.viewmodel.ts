import {
  NotificationModel,
  type CreateNotificationInput,
  type NotificationRow,
} from '../models/notification.model.js';

// Lop xu ly nghiep vu cho: Thong bao
export class NotificationViewModel {
  private model = new NotificationModel();

  async create(input: CreateNotificationInput): Promise<NotificationRow[]> {
    return this.model.createNotification(input);
  }

  async list(userId: string): Promise<NotificationRow[]> {
    return this.model.findByUser(userId);
  }

  async unreadCount(userId: string): Promise<number> {
    return this.model.countUnread(userId);
  }

  async markRead(id: string, userId: string): Promise<void> {
    return this.model.markRead(id, userId);
  }

  async markAllRead(userId: string): Promise<void> {
    return this.model.markAllRead(userId);
  }

  async delete(id: string, userId: string): Promise<void> {
    return this.model.delete(id, userId);
  }
}
