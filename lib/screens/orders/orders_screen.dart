import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../state/app_state.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  final bool embedded; // true when shown as a bottom-nav tab (no back button)
  const OrdersScreen({super.key, this.embedded = false});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _orderService = OrderService();

  final _tabs = const ['All', 'Active', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  bool _matchesTab(OrderModel order, int tabIndex) {
    switch (tabIndex) {
      case 1: // Active
        return order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled;
      case 2: // Completed
        return order.status == OrderStatus.delivered;
      case 3: // Cancelled
        return order.status == OrderStatus.cancelled;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AppState>().user?.uid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: uid == null
          ? Center(child: Text('Please sign in to view orders', style: AppTextStyles.supporting))
          : StreamBuilder<List<OrderModel>>(
              stream: _orderService.streamUserOrders(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data!;
                return TabBarView(
                  controller: _tabController,
                  children: List.generate(_tabs.length, (tabIndex) {
                    final filtered = orders.where((o) => _matchesTab(o, tabIndex)).toList();
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text('No orders here yet', style: AppTextStyles.supporting),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final order = filtered[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Order #${order.orderCode}', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                                    Text('₹${order.total.toStringAsFixed(0)}', style: AppTextStyles.price),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.items.isNotEmpty ? order.items.first.name : '',
                                  style: AppTextStyles.supporting,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  order.status.label,
                                  style: AppTextStyles.caption.copyWith(
                                    color: order.status == OrderStatus.delivered
                                        ? AppColors.success
                                        : order.status == OrderStatus.cancelled
                                            ? AppColors.error
                                            : AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => OrderTrackingScreen(orderId: order.id),
                                      ),
                                    ),
                                    child: const Text('Track Order'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                );
              },
            ),
    );
  }
}
