import { WalletModel } from '../models/wallet.model.js';

export class WalletViewModel {
  private model = new WalletModel();

  getForUser(userId: string) {
    return this.model.getForUser(userId);
  }
}
