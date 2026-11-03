import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/order_status_tabs.dart';

/// Man hinh Don hang cua toi & Loc trang thai (AP-DH2, TM07)
class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final orderProv = context.watch<OrderProvider>();
    final orders = orderProv.myFilteredOrders;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(
          'Đơn hàng của tôi',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => orderProv.loadOrders(),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Thanh Tab loc trang thai don hang co badge dem
            OrderStatusTabs(
              selectedFilter: orderProv.selectedStatusFilter,
              allOrders: orderProv.allOrders,
              onFilterChanged: (filter) => orderProv.setStatusFilter(filter),
            ),
            const SizedBox(height: 12),

            // Danh sach don hang
            Expanded(
              child: orderProv.isLoading && orders.isEmpty
                  ? const LoadingView(message: 'Đang tải danh sách đơn hàng...')
                  : orders.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            StatusView(
                              title: 'Không có đơn hàng nào',
                              message: 'Bạn chưa có đơn hàng nào ở trạng thái này.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: orders.length,
                          itemBuilder: (context, i) {
                            return OrderCard(
                              order: orders[i],
                              orderProv: orderProv,
                              onCancelled: () => setState(() {}),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
