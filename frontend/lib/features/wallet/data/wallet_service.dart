import 'package:menly_app/core/network/api_client.dart';

class WalletTransaction {
  final int amount;
  final int balanceAfter;
  final String reason;
  final String? note;
  final DateTime? createdAt;

  const WalletTransaction({
    required this.amount,
    required this.balanceAfter,
    required this.reason,
    this.note,
    this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        balanceAfter: (json['balance_after'] as num?)?.toInt() ?? 0,
        reason: json['reason']?.toString() ?? '',
        note: json['note']?.toString(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}

class WalletOverview {
  final int walletBalance;
  final int coinBalance;
  final List<WalletTransaction> walletTransactions;
  final List<WalletTransaction> coinTransactions;

  const WalletOverview({
    required this.walletBalance,
    required this.coinBalance,
    required this.walletTransactions,
    required this.coinTransactions,
  });

  factory WalletOverview.fromJson(Map<String, dynamic> json) => WalletOverview(
        walletBalance: (json['walletBalance'] as num?)?.toInt() ?? 0,
        coinBalance: (json['coinBalance'] as num?)?.toInt() ?? 0,
        walletTransactions: _transactions(json['walletTransactions']),
        coinTransactions: _transactions(json['coinTransactions']),
      );

  static List<WalletTransaction> _transactions(dynamic value) => value is List
      ? value
          .whereType<Map>()
          .map((row) =>
              WalletTransaction.fromJson(Map<String, dynamic>.from(row)))
          .toList()
      : const [];
}

class WalletService {
  WalletService._();
  static final instance = WalletService._();

  Future<WalletOverview> load() async {
    final response = await ApiClient().dio.get('/wallet');
    final data = response.data?['data'];
    if (data is! Map) throw StateError('Dữ liệu ví không hợp lệ');
    return WalletOverview.fromJson(Map<String, dynamic>.from(data));
  }
}
