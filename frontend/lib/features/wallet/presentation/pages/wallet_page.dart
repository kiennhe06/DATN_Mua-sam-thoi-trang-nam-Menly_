import 'package:flutter/material.dart';
import 'package:menly_app/core/theme/app_colors.dart';
import 'package:menly_app/core/theme/app_spacing.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import 'package:menly_app/core/utils/format.dart';
import '../../data/wallet_service.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late Future<WalletOverview> _overview;

  @override
  void initState() {
    super.initState();
    _overview = WalletService.instance.load();
  }

  Future<void> _reload() async {
    final next = WalletService.instance.load();
    setState(() => _overview = next);
    try {
      await next;
    } catch (_) {
      // FutureBuilder displays the error and keeps the retry button available.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('Ví của tôi'), centerTitle: true),
      body: FutureBuilder<WalletOverview>(
        future: _overview,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Chưa tải được thông tin ví.'),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(onPressed: _reload, child: const Text('Thử lại')),
                ]),
              ),
            );
          }
          final overview = snapshot.data!;
          return DefaultTabController(
            length: 2,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(children: [
                  Expanded(
                      child: _BalanceCard(
                    title: 'Số dư ví',
                    value: formatPrice(overview.walletBalance),
                    icon: Icons.account_balance_wallet_outlined,
                    color: c.primary,
                  )),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                      child: _BalanceCard(
                    title: 'Xu tích lũy',
                    value: '${formatNumber(overview.coinBalance)} xu',
                    icon: Icons.stars_rounded,
                    color: c.success,
                  )),
                ]),
              ),
              TabBar(
                labelColor: c.primary,
                unselectedLabelColor: c.textMuted,
                indicatorColor: c.primary,
                tabs: const [Tab(text: 'Lịch sử ví'), Tab(text: 'Lịch sử xu')],
              ),
              Expanded(
                child: TabBarView(children: [
                  _HistoryList(
                      rows: overview.walletTransactions, isCoin: false),
                  _HistoryList(rows: overview.coinTransactions, isCoin: true),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _BalanceCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: c.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: TextStyle(color: c.textSecondary, fontSize: 12)),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<WalletTransaction> rows;
  final bool isCoin;
  const _HistoryList({required this.rows, required this.isCoin});

  String _reason(String reason) => switch (reason) {
        'earn' => 'Thưởng xu',
        'spend' => 'Dùng xu thanh toán',
        'refund_return' => 'Hoàn xu',
        'revoke' => 'Thu hồi xu',
        'apology' => 'Xu hỗ trợ',
        'order_payment' => 'Thanh toán đơn hàng',
        'order_refund_cancel' => 'Hoàn tiền đơn hủy',
        'refund' => 'Hoàn tiền',
        'adjust' => 'Điều chỉnh số dư',
        _ => 'Giao dịch',
      };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (rows.isEmpty) {
      return Center(
          child:
              Text('Chưa có giao dịch.', style: TextStyle(color: c.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: rows.length,
      separatorBuilder: (_, __) => Divider(color: c.border),
      itemBuilder: (context, index) {
        final row = rows[index];
        final positive = row.amount > 0;
        final time = row.createdAt;
        final date = time == null
            ? ''
            : '${time.toLocal().day.toString().padLeft(2, '0')}/${time.toLocal().month.toString().padLeft(2, '0')}/${time.toLocal().year}';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor:
                (positive ? c.success : c.danger).withValues(alpha: .12),
            child: Icon(positive ? Icons.add : Icons.remove,
                color: positive ? c.success : c.danger),
          ),
          title: Text(_reason(row.reason),
              style:
                  TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600)),
          subtitle: Text([if (row.note?.isNotEmpty == true) row.note!, date]
              .where((s) => s.isNotEmpty)
              .join(' · ')),
          trailing: Text(
            '${positive ? '+' : ''}${formatNumber(row.amount)}${isCoin ? ' xu' : ' đ'}',
            style: TextStyle(
                color: positive ? c.success : c.danger,
                fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
