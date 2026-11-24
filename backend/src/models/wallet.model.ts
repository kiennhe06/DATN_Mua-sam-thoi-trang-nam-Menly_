import { supabase } from '../config/supabase.js';

export class WalletModel {
  private db = supabase;

  async getForUser(userId: string) {
    const [walletCreate, coinCreate] = await Promise.all([
      this.db.from('wallets').upsert({ user_id: userId }, { onConflict: 'user_id', ignoreDuplicates: true }),
      this.db.from('coin_accounts').upsert({ user_id: userId }, { onConflict: 'user_id', ignoreDuplicates: true }),
    ]);
    if (walletCreate.error) throw new Error(`Không thể khởi tạo ví: ${walletCreate.error.message}`);
    if (coinCreate.error) throw new Error(`Không thể khởi tạo tài khoản xu: ${coinCreate.error.message}`);

    const [wallet, coins, walletHistory, coinHistory] = await Promise.all([
      this.db.from('wallets').select('balance').eq('user_id', userId).single(),
      this.db.from('coin_accounts').select('balance').eq('user_id', userId).single(),
      this.db.from('wallet_transactions').select('id, amount, balance_after, reason, note, created_at').eq('user_id', userId).order('created_at', { ascending: false }).limit(100),
      this.db.from('coin_transactions').select('id, amount, balance_after, reason, note, created_at').eq('user_id', userId).order('created_at', { ascending: false }).limit(100),
    ]);
    const error = wallet.error ?? coins.error ?? walletHistory.error ?? coinHistory.error;
    if (error) throw new Error(`Không thể tải dữ liệu ví: ${error.message}`);

    return {
      walletBalance: Number(wallet.data?.balance ?? 0),
      coinBalance: Number(coins.data?.balance ?? 0),
      walletTransactions: walletHistory.data ?? [],
      coinTransactions: coinHistory.data ?? [],
    };
  }
}
