import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/cart_item_model.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../state/app_state.dart';
import '../home/home_screen.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  final bool embedded;

  const OrdersScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final OrderService _orderService = OrderService();

  final List<String> _tabs = const [
    'All',
    'Active',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // TAB FILTER
  // ------------------------------------------------------------

  bool _matchesTab(
    OrderModel order,
    int tabIndex,
  ) {
    switch (tabIndex) {
      case 1:
        // Active orders
        return order.status != OrderStatus.delivered &&
            order.status != OrderStatus.cancelled;

      case 2:
        // Completed orders
        return order.status == OrderStatus.delivered;

      case 3:
        // Cancelled orders
        return order.status == OrderStatus.cancelled;

      case 0:
      default:
        // All orders
        return true;
    }
  }

  // ------------------------------------------------------------
  // MAIN BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final appUser = context.watch<AppState>().user;

    final uid =
        FirebaseAuth.instance.currentUser?.uid ??
        appUser?.uid ??
        '';

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          color: AppColors.textDark,
          tooltip: 'Back',
          onPressed: () {
            if (widget.embedded) {
              context.findAncestorStateOfType<HomeScreenState>()?.goToTab(0);
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            }
          },
        ),

        title: Text(
          'My Orders',
          style: AppTextStyles.heading.copyWith(fontSize: 18),
        ),

        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,

          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,

          indicatorColor: AppColors.primary,
          indicatorWeight: 3,

          labelStyle: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),

          unselectedLabelStyle: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),

          tabs: _tabs.map(
            (tab) => Tab(
              text: tab,
            ),
          ).toList(),
        ),
      ),

      // --------------------------------------------------------
      // USER CHECK
      // --------------------------------------------------------

      body: uid.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 56,
                      color: AppColors.textSecondary,
                    ),

                    const SizedBox(height: 14),

                    Text(
                      'Please sign in to view orders',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.supporting,
                    ),
                  ],
                ),
              ),
            )

          // ------------------------------------------------------
          // ORDERS STREAM
          // ------------------------------------------------------

          : StreamBuilder<List<OrderModel>>(
              stream: _orderService.streamUserOrders(uid),

              builder: (
                BuildContext context,
                AsyncSnapshot<List<OrderModel>> snapshot,
              ) {
                // ------------------------------------------------
                // LOADING
                // ------------------------------------------------

                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // ------------------------------------------------
                // ERROR
                // ------------------------------------------------

                if (snapshot.hasError) {
                  if (kDebugMode) {
                    debugPrint(
                      'Orders stream error: ${snapshot.error}',
                    );
                  }

                  return _buildErrorState(
                    snapshot.error.toString(),
                  );
                }

                // ------------------------------------------------
                // DATA
                // ------------------------------------------------

                final orders = snapshot.data ?? <OrderModel>[];

                // ------------------------------------------------
                // TABS
                // ------------------------------------------------

                return TabBarView(
                  controller: _tabController,

                  children: List.generate(
                    _tabs.length,
                    (tabIndex) {
                      final filteredOrders = orders
                          .where(
                            (order) => _matchesTab(
                              order,
                              tabIndex,
                            ),
                          )
                          .toList();

                      // ------------------------------------------
                      // EMPTY TAB
                      // ------------------------------------------

                      if (filteredOrders.isEmpty) {
                        return _buildEmptyOrdersState(
                          hasAnyOrders: orders.isNotEmpty,
                          tabIndex: tabIndex,
                        );
                      }

                      // ------------------------------------------
                      // ORDER LIST
                      // ------------------------------------------

                      return RefreshIndicator(
                        color: AppColors.primary,

                        onRefresh: () async {
                          // Firestore Stream updates automatically.
                          // This small delay gives RefreshIndicator
                          // time to complete smoothly.
                          await Future.delayed(
                            const Duration(
                              milliseconds: 300,
                            ),
                          );
                        },

                        child: ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(),

                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),

                          itemCount: filteredOrders.length,

                          itemBuilder: (
                            BuildContext context,
                            int index,
                          ) {
                            final order =
                                filteredOrders[index];

                            return _OrderCard(
                              order: order,
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  // ------------------------------------------------------------
  // ERROR STATE
  // ------------------------------------------------------------

  Widget _buildErrorState(
    String error,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 58,
              color: Colors.red,
            ),

            const SizedBox(height: 14),

            const Text(
              'Unable to load orders',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'There was a problem loading your orders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFECACA),
                ),
              ),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF991B1B),
                ),
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _buildEmptyOrdersState({
    required bool hasAnyOrders,
    required int tabIndex,
  }) {
    String message;

    if (!hasAnyOrders) {
      message = 'No orders placed yet';
    } else {
      switch (tabIndex) {
        case 1:
          message = 'No active orders';
          break;

        case 2:
          message = 'No completed orders';
          break;

        case 3:
          message = 'No cancelled orders';
          break;

        default:
          message = 'No orders found';
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:
                    AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 52,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.supporting,
            ),

            if (!hasAnyOrders) ...[
              const SizedBox(height: 6),

              const Text(
                'Your placed orders will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// ORDER CARD
// ==================================================================

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOnline =
        order.paymentMethod == 'online';

    final String dateStr = order.createdAt != null
        ? DateFormat(
            'dd MMM yyyy, hh:mm a',
          ).format(order.createdAt!)
        : 'Recent Order';

    final List<CartItemModel> items = order.items;

    final String shopName =
        order.shopName.isNotEmpty
            ? order.shopName
            : (
                items.isNotEmpty
                    ? items.first.shopName
                    : 'Dapzo Partner Shop'
              );

    // ------------------------------------------------------------
    // STATUS COLOR
    // ------------------------------------------------------------

    Color statusColor;

    switch (order.status) {
      case OrderStatus.delivered:
        statusColor = AppColors.success;
        break;

      case OrderStatus.cancelled:
        statusColor = AppColors.error;
        break;

      case OrderStatus.shopAccepted:
        statusColor = const Color(0xFF2563EB); // Vibrant Royal Blue
        break;

      case OrderStatus.preparing:
        statusColor = const Color(0xFFD97706); // Amber Orange
        break;

      case OrderStatus.ready:
        statusColor = const Color(0xFF059669); // Emerald Green
        break;

      case OrderStatus.outForDelivery:
        statusColor = const Color(0xFF7C3AED); // Deep Purple
        break;

      case OrderStatus.placed:
        statusColor = AppColors.primary;
        break;
    }

    // ------------------------------------------------------------
    // CARD
    // ------------------------------------------------------------

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(
          16,
        ),

        border: Border.all(
          color: AppColors.divider,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ------------------------------------------------------
          // HEADER
          // ------------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              10,
            ),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Container(
                  padding: const EdgeInsets.all(
                    8,
                  ),

                  decoration: BoxDecoration(
                    color:
                        statusColor.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),

                  child: Icon(
                    Icons.storefront_rounded,
                    size: 20,
                    color: statusColor,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        shopName,
                        style:
                            AppTextStyles.sectionHeading
                                .copyWith(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      Text(
                        '#${order.orderCode} · $dateStr',
                        style:
                            AppTextStyles.caption
                                .copyWith(
                          fontSize: 11.5,
                          color:
                              AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),

                  decoration: BoxDecoration(
                    color:
                        statusColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(
                        alpha: 0.25,
                      ),
                      width: 1,
                    ),
                  ),

                  child: Text(
                    order.status.label,
                    style:
                        AppTextStyles.caption
                            .copyWith(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
          ),

          // ------------------------------------------------------
          // ITEMS
          // ------------------------------------------------------

          if (items.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                8,
              ),

              child: Column(
                children: [
                  ...items.map(
                    (item) => _OrderItemRow(
                      item: item,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(
                16,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Order placed successfully',
                    style:
                        AppTextStyles.supporting,
                  ),
                ],
              ),
            ),

          const Divider(
            height: 1,
          ),

          // ------------------------------------------------------
          // FOOTER
          // ------------------------------------------------------

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              14,
            ),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,

              children: [
                // PAYMENT + TOTAL
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isOnline
                                  ? 'Online Payment'
                                  : 'Cash on Delivery',

                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,

                              style:
                                  AppTextStyles.caption
                                      .copyWith(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    AppColors.textMedium,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 6,
                          ),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  order.paymentStatus.toLowerCase() ==
                                          'paid'
                                      ? AppColors
                                          .success
                                          .withValues(
                                          alpha: 0.1,
                                        )
                                      : AppColors
                                          .warning
                                          .withValues(
                                          alpha: 0.1,
                                        ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                4,
                              ),
                            ),

                            child: Text(
                              order.paymentStatus
                                  .toUpperCase(),

                              style:
                                  AppTextStyles.caption
                                      .copyWith(
                                fontSize: 9.5,
                                color:
                                    order.paymentStatus.toLowerCase() ==
                                            'paid'
                                        ? AppColors
                                            .success
                                        : AppColors
                                            .warning,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        'Total: ₹${order.total.toStringAsFixed(0)}',

                        style:
                            AppTextStyles.price
                                .copyWith(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                // TRACK BUTTON
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderTrackingScreen(
                          orderId: order.id,
                        ),
                      ),
                    );
                  },

                  icon: const Icon(
                    Icons.navigation_outlined,
                    size: 16,
                  ),

                  label: const Text(
                    'Track Order',
                  ),

                  style:
                      ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),

                    textStyle:
                        AppTextStyles.caption
                            .copyWith(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// ORDER ITEM ROW
// ==================================================================

class _OrderItemRow extends StatelessWidget {
  final CartItemModel item;

  const _OrderItemRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValidImage = item.imageUrl.isNotEmpty &&
        (item.imageUrl.startsWith('http://') ||
            item.imageUrl.startsWith('https://'));

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --------------------------------------------------------
          // IMAGE
          // --------------------------------------------------------

          ClipRRect(
            borderRadius:
                BorderRadius.circular(8),

            child: SizedBox(
              width: 44,
              height: 44,

              child: hasValidImage
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,

                      placeholder:
                          (
                            context,
                            url,
                          ) =>
                              _placeholder(),

                      errorWidget:
                          (
                            context,
                            url,
                            error,
                          ) =>
                              _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // --------------------------------------------------------
          // ITEM NAME & WEIGHT
          // --------------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  item.name.isNotEmpty ? item.name : 'Product',

                  style:
                      AppTextStyles.body
                          .copyWith(
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 13.5,
                  ),

                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                ),

                if (item.selectedWeight != null &&
                    item.selectedWeight!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1.5),
                    child: Text(
                      item.selectedWeight!.trim(),

                      style:
                          AppTextStyles.caption
                              .copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),

                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // --------------------------------------------------------
          // QUANTITY & UNIT PRICE
          // --------------------------------------------------------

          Text(
            '${item.quantity} × ₹${item.unitPrice.toStringAsFixed(0)}',

            style:
                AppTextStyles.caption.copyWith(
              fontSize: 12,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // --------------------------------------------------------
          // TOTAL
          // --------------------------------------------------------

          Text(
            '₹${item.totalPrice.toStringAsFixed(0)}',

            style:
                AppTextStyles.body.copyWith(
              fontWeight:
                  FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  // IMAGE PLACEHOLDER
  // --------------------------------------------------------------

  Widget _placeholder() {
    IconData icon;
    if (item.mode.toLowerCase() == 'meat') {
      icon = Icons.restaurant_rounded;
    } else {
      icon = Icons.fastfood_outlined;
    }

    return Container(
      color: AppColors.surfaceVariant,

      child: Center(
        child: Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}