import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:menly_app/core/theme/app_theme.dart';
import '../providers/voucher_provider.dart';

/// Trang khuyen mai gom ma giam gia Menly (TM10)
class VoucherListPage extends StatefulWidget {
  const VoucherListPage({super.key});

  @override
  State<VoucherListPage> createState() => _VoucherListPageState();
}

class _VoucherListPageState extends State<VoucherListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voucherProv = context.watch<VoucherProvider>();
    final vouchers = voucherProv.vouchers;
    final query = _searchController.text.trim().toLowerCase();

    final filteredVouchers = vouchers.where((v) {
      if (query.isEmpty) return true;
      return v.code.toLowerCase().contains(query) || v.title.toLowerCase().contains(query);
    }).toList();

    final activeCount = vouchers.where((v) => v.isActive).length;
    final savedCount = voucherProv.vouchers.where((v) => voucherProv.isCollected(v.id)).length;
    final expiringSoon = vouchers.where((v) => v.endDate.difference(DateTime.now()).inDays <= 7).length;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Kho Voucher'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => voucherProv.loadVouchers(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => voucherProv.loadVouchers(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF1F2937)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'FLASH SALE MENLY',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Mã giảm giá hấp dẫn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Giảm tối đa 100.000đ cho các đơn hàng mới.',
                          style: TextStyle(
                            color: Color(0xFFE5E7EB),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.local_offer_rounded,
                      color: Colors.amber,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Đang có',
                    value: '$activeCount',
                    color: AppTheme.primary,
                    icon: Icons.discount_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Đã lưu',
                    value: '$savedCount',
                    color: AppTheme.accentGreen,
                    icon: Icons.bookmark_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Sắp hết',
                    value: '$expiringSoon',
                    color: AppTheme.primaryAccent,
                    icon: Icons.timer_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Tìm mã hoặc tên voucher',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_searchController.text.trim().isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Mã giảm giá đang diễn ra',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (voucherProv.isLoading && vouchers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (voucherProv.error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  voucherProv.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (filteredVouchers.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Center(
                  child: Text(
                    'Không tìm thấy mã voucher phù hợp.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ...filteredVouchers.map((v) => _VoucherCard(v: v)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final dynamic v;

  const _VoucherCard({required this.v});

  @override
  Widget build(BuildContext context) {
    final isCollected = context.read<VoucherProvider>().isCollected(v.id);
    final isPercentage = v.discountType == 'percentage';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Container(
            width: 118,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isPercentage
                  ? const LinearGradient(
                      colors: [Color(0xFFFFF1E9), Color(0xFFFFE5D3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFEAF4FF), Color(0xFFDDEBFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPercentage ? Icons.percent_rounded : Icons.attach_money_rounded,
                  color: isPercentage ? AppTheme.primaryAccent : AppTheme.primary,
                  size: 26,
                ),
                const SizedBox(height: 8),
                Text(
                  isPercentage ? '${v.discountValue}% OFF' : '${v.discountValue ~/ 1000}K',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isPercentage ? AppTheme.primaryAccent : AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          v.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPercentage ? Colors.orange.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isPercentage ? 'Giảm %' : 'Giảm tiền',
                          style: TextStyle(
                            color: isPercentage ? AppTheme.primaryAccent : Colors.blue.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      v.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppTheme.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Đơn tối thiểu ${_formatCurrency(v.minOrderValue)}đ • HSD ${_formatDate(v.endDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: v.code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã sao chép: ${v.code}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                          icon: const Icon(Icons.copy_all_rounded, size: 16),
                          label: const Text('Sao chép'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isCollected ? null : () {
                          context.read<VoucherProvider>().collectVoucher(v.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã lưu mã ${v.code} vào ví của bạn'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCollected ? Colors.grey.shade300 : AppTheme.primary,
                          foregroundColor: isCollected ? AppTheme.textSecondary : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(isCollected ? 'Đã lưu' : 'Lưu mã'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(int value) => value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (Match m) => ',',
      );

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
