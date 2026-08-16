import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/location_service.dart';
import '../home/home_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  final _orderService = OrderService();
  final _locationService = LocationService();
  final MapController _mapController = MapController();

  bool _isMapExpanded = false;

  static const _steps = [
    OrderStatus.placed,
    OrderStatus.shopAccepted,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  static const _stepTitles = {
    OrderStatus.placed: 'Order Placed',
    OrderStatus.shopAccepted: 'Shop Confirmed',
    OrderStatus.preparing: 'Food is Being Prepared',
    OrderStatus.ready: 'Order Packed & Ready',
    OrderStatus.outForDelivery: 'Out for Delivery',
    OrderStatus.delivered: 'Order Delivered',
  };

  static const _stepSubtitles = {
    OrderStatus.placed: 'We have received your order details',
    OrderStatus.shopAccepted: 'Store has accepted and started processing',
    OrderStatus.preparing: 'Chef is cooking your fresh dishes',
    OrderStatus.ready: 'Delivery partner has arrived to collect',
    OrderStatus.outForDelivery: 'Rider is on the way to your door 🛵',
    OrderStatus.delivered: 'Delivered! Enjoy your delicious meal 🎉',
  };

  Future<void> _callPhone(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _showCancelDialog(BuildContext context, String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel Order?',
          style: AppTextStyles.heading.copyWith(fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: AppTextStyles.supporting.copyWith(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Keep Order',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Cancel Order',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await _orderService.cancelOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order cancelled successfully.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label copied to clipboard!'),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Live Tracking',
          style: AppTextStyles.heading.copyWith(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textDark,
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: _isMapExpanded ? 'Collapse Map' : 'Full Map View',
            icon: Icon(
              _isMapExpanded
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded,
              color: AppColors.textDark,
              size: 24,
            ),
            onPressed: () {
              setState(() => _isMapExpanded = !_isMapExpanded);
            },
          ),
        ],
      ),
      body: StreamBuilder<OrderModel>(
        stream: _orderService.streamOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Error loading tracking: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.supporting),
                  ],
                ),
              ),
            );
          }

          final order = snapshot.data ??
              OrderModel(
                id: widget.orderId,
                orderCode: widget.orderId.startsWith('DZ')
                    ? widget.orderId
                    : 'DZ${widget.orderId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(5, '0')}',
                userId: '',
                shopId: '',
                shopName: 'Dapzo Partner Shop',
                items: [],
                subtotal: 0,
                deliveryCharge: 30,
                discount: 0,
                tax: 10,
                total: 240,
                paymentMethod: 'cod',
                paymentStatus: 'pending',
                status: OrderStatus.placed,
                addressId: '',
              );

          final currentIndex = order.status == OrderStatus.cancelled
              ? -1
              : _steps.indexOf(order.status);

          final otpCode = order.deliveryOtp ??
              ((order.id.replaceAll(RegExp(r'[^0-9]'), '').length >= 4)
                  ? order.id
                      .replaceAll(RegExp(r'[^0-9]'), '')
                      .substring(0, 4)
                  : '4829');

          final customerLat =
              (order.deliveryAddress['latitude'] as num?)?.toDouble() ??
                  12.9568;
          final customerLng =
              (order.deliveryAddress['longitude'] as num?)?.toDouble() ??
                  78.2711;

          return Column(
            children: [
              // ── Dynamic Map Section ──
              Expanded(
                flex: _isMapExpanded ? 8 : 4,
                child: _buildMapSection(order, customerLat, customerLng),
              ),

              // ── Details & Status Stepper Sheet ──
              Expanded(
                flex: _isMapExpanded ? 3 : 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                    children: [
                      // Header Sheet Drag Indicator
                      Center(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _isMapExpanded = !_isMapExpanded),
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Order Header & Status Badge
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Order #${order.orderCode}',
                                      style: AppTextStyles.heading
                                          .copyWith(fontSize: 17),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () => _copyToClipboard(
                                          context, order.orderCode, 'Order ID'),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Icon(Icons.copy_rounded,
                                            size: 15,
                                            color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.shopName,
                                  style: AppTextStyles.supporting
                                      .copyWith(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: order.status == OrderStatus.delivered
                                  ? Colors.green.withValues(alpha: 0.14)
                                  : (order.status == OrderStatus.cancelled
                                      ? AppColors.error
                                          .withValues(alpha: 0.14)
                                      : AppColors.primary
                                          .withValues(alpha: 0.14)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: order.status ==
                                            OrderStatus.delivered
                                        ? Colors.green
                                        : (order.status ==
                                                OrderStatus.cancelled
                                            ? AppColors.error
                                            : AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  order.status.label.toUpperCase(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: order.status ==
                                            OrderStatus.delivered
                                        ? Colors.green.shade700
                                        : (order.status ==
                                                OrderStatus.cancelled
                                            ? AppColors.error
                                            : AppColors.primary),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Delivery Handover OTP Card
                      if (order.status != OrderStatus.delivered &&
                          order.status != OrderStatus.cancelled)
                        _buildOtpCard(context, otpCode),

                      const SizedBox(height: 14),

                      // Assigned Delivery Partner Card
                      if (order.deliveryPartnerId != null &&
                          order.deliveryPartnerId!.isNotEmpty)
                        _buildRiderCard(context, order),

                      const SizedBox(height: 18),

                      // Status Stepper / Cancelled state
                      if (order.status == OrderStatus.cancelled)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color:
                                    AppColors.error.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cancel_outlined,
                                  color: AppColors.error, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text('This order was cancelled.',
                                    style: AppTextStyles.body.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        )
                      else
                        _buildStatusTimeline(currentIndex),

                      // Cancel Order Button — only before preparing
                      if (order.status == OrderStatus.placed ||
                          order.status == OrderStatus.shopAccepted) ...[
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showCancelDialog(context, order.id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.cancel_outlined, size: 20),
                            label: Text(
                              'Cancel Order',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ] else if (order.status == OrderStatus.preparing ||
                          order.status == OrderStatus.ready ||
                          order.status == OrderStatus.outForDelivery) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Order cannot be cancelled once preparation has started.',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 14),

                      // Items Breakdown
                      if (order.items.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Items in Order (${order.items.length})',
                              style: AppTextStyles.sectionHeading
                                  .copyWith(fontSize: 14.5),
                            ),
                            Text(
                              '₹${order.total.toStringAsFixed(0)}',
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 16,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...order.items.map((item) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant
                                    .withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.quantity}x',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.name +
                                          (item.selectedWeight != null &&
                                                  item.selectedWeight!
                                                      .isNotEmpty
                                              ? ' · ${item.selectedWeight}'
                                              : ''),
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '₹${item.totalPrice.toStringAsFixed(0)}',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 10),
                      ],

                      // Delivery Address Info
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery Address',
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.deliveryAddress['address']
                                            ?.toString() ??
                                        'Selected Delivery Address',
                                    style: AppTextStyles.supporting
                                        .copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── OTP Display Card ──
  Widget _buildOtpCard(BuildContext context, String otp) {
    final digits = otp.padRight(4, '0').split('');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.shield_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DELIVERY HANDOVER OTP',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: digits
                      .map((d) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.35)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              d,
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 17,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copyToClipboard(context, otp, 'Delivery OTP'),
            icon: const Icon(Icons.copy_rounded,
                color: AppColors.primary, size: 20),
            tooltip: 'Copy OTP',
          ),
        ],
      ),
    );
  }

  // ── Delivery Partner Profile Card ──
  Widget _buildRiderCard(BuildContext context, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(Icons.two_wheeler_rounded,
                    color: AppColors.primary, size: 24),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 9, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.deliveryPartnerName ?? 'Dapzo Delivery Partner',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  order.status == OrderStatus.outForDelivery
                      ? 'Heading to your address 🛵'
                      : 'Assigned · Collecting from shop',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (order.deliveryPartnerPhone != null &&
              order.deliveryPartnerPhone!.isNotEmpty)
            InkWell(
              onTap: () => _callPhone(order.deliveryPartnerPhone),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.phone_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  // ── Status Stepper ──
  Widget _buildStatusTimeline(int currentIndex) {
    return Column(
      children: List.generate(_steps.length, (i) {
        final step = _steps[i];
        final isDone = i <= currentIndex;
        final isCurrent = i == currentIndex;
        final isLast = i == _steps.length - 1;

        final title = _stepTitles[step] ?? step.label;
        final subtitle = _stepSubtitles[step] ?? '';

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      border: Border.all(
                        color: isDone ? AppColors.primary : AppColors.divider,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? (isCurrent
                              ? const SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check,
                                  size: 13, color: Colors.white))
                          : const SizedBox.shrink(),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2.2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: i < currentIndex
                            ? AppColors.primary
                            : AppColors.divider.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13.5,
                          fontWeight: isCurrent
                              ? FontWeight.w800
                              : (isDone
                                  ? FontWeight.w700
                                  : FontWeight.w400),
                          color: isCurrent
                              ? AppColors.primary
                              : (isDone
                                  ? AppColors.textDark
                                  : AppColors.textSecondary),
                        ),
                      ),
                      if (subtitle.isNotEmpty && (isCurrent || isDone)) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: isCurrent
                                ? AppColors.textDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ── Map Section with Real-Time Marker & Interactive Controls ──
  Widget _buildMapSection(
      OrderModel order, double custLat, double custLng) {
    final partnerId = order.deliveryPartnerId;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: (partnerId != null && partnerId.isNotEmpty)
          ? _locationService.streamDeliveryPartnerLocation(partnerId)
          : Stream.value(null),
      builder: (context, locSnap) {
        final locData = locSnap.data;
        final driverLat =
            (locData?['latitude'] as num?)?.toDouble() ??
            (locData?['lat'] as num?)?.toDouble();
        final driverLng =
            (locData?['longitude'] as num?)?.toDouble() ??
            (locData?['lng'] as num?)?.toDouble();

        final customerPoint = LatLng(custLat, custLng);
        final driverPoint = (driverLat != null && driverLng != null)
            ? LatLng(driverLat, driverLng)
            : null;
        final mapCenter = driverPoint ?? customerPoint;

        double? liveDistanceKm;
        if (driverPoint != null) {
          liveDistanceKm = _locationService.distanceInKm(
            driverPoint.latitude,
            driverPoint.longitude,
            customerPoint.latitude,
            customerPoint.longitude,
          );
        }

        final markers = <Marker>[
          // Customer Destination Marker
          Marker(
            point: customerPoint,
            width: 48,
            height: 48,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.home_rounded,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ),

          // Live Rider Marker
          if (driverPoint != null)
            Marker(
              point: driverPoint,
              width: 54,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.two_wheeler_rounded,
                        color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),
        ];

        final polylines = <Polyline>[
          if (driverPoint != null)
            Polyline(
              points: [driverPoint, customerPoint],
              strokeWidth: 4.0,
              color: AppColors.primary,
              pattern: StrokePattern.dashed(segments: const [8, 6]),
            ),
        ];

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: mapCenter,
                initialZoom: 14.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.dapzo.app',
                  maxZoom: 19,
                ),
                PolylineLayer(polylines: polylines),
                MarkerLayer(markers: markers),
              ],
            ),

            // Top Status Floating Badge
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        order.status == OrderStatus.outForDelivery
                            ? Icons.two_wheeler_rounded
                            : (order.status == OrderStatus.delivered
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded),
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            order.status == OrderStatus.outForDelivery
                                ? 'Rider is on the way to your door 🛵'
                                : (partnerId != null && partnerId.isNotEmpty
                                    ? 'Rider assigned · Preparing at shop'
                                    : 'Shop is preparing your order'),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (liveDistanceKm != null &&
                              order.status == OrderStatus.outForDelivery)
                            Text(
                              '${liveDistanceKm.toStringAsFixed(1)} km away from you',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Interactive Map Controls (Zoom In, Zoom Out, Recenter)
            Positioned(
              bottom: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom In
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      color: AppColors.textDark,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                            _mapController.camera.center, currentZoom + 1);
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Zoom Out
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      color: AppColors.textDark,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                            _mapController.camera.center, currentZoom - 1);
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Recenter on Rider / Destination
                  FloatingActionButton.small(
                    heroTag: 'cust_recenter_map',
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    onPressed: () {
                      _mapController.move(mapCenter, 15.0);
                    },
                    tooltip: 'Center Location',
                    child: const Icon(Icons.my_location_rounded, size: 20),
                  ),
                ],
              ),
            ),

            // OSM Attribution
            Positioned(
              bottom: 4,
              left: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '© OpenStreetMap',
                  style: TextStyle(
                      fontSize: 8.5, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
