import 'package:flutter/material.dart';
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

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _orderService = OrderService();
  final _locationService = LocationService();
  final MapController _mapController = MapController();

  static const _steps = [
    OrderStatus.placed,
    OrderStatus.shopAccepted,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  Future<void> _callRider(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Track Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
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
      ),
      body: StreamBuilder<OrderModel>(
        stream: _orderService.streamOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading order: ${snapshot.error}'),
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
              // ── Top Section: Live Map ──
              Expanded(
                flex: 5,
                child: _buildMapSection(order, customerLat, customerLng),
              ),

              // ── Bottom Section: Order Details & Status Timeline ──
              Expanded(
                flex: 6,
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
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order #${order.orderCode}',
                                  style: AppTextStyles.heading
                                      .copyWith(fontSize: 18),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.status.label.toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Assigned Delivery Partner Card
                      if (order.deliveryPartnerId != null &&
                          order.deliveryPartnerId!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.15),
                                child: const Icon(Icons.two_wheeler_rounded,
                                    color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.deliveryPartnerName ??
                                          'Dapzo Delivery Partner',
                                      style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      order.status ==
                                              OrderStatus.outForDelivery
                                          ? 'On the way to your location 🛵'
                                          : 'Assigned & heading to shop',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (order.deliveryPartnerPhone != null &&
                                  order.deliveryPartnerPhone!.isNotEmpty)
                                InkWell(
                                  onTap: () =>
                                      _callRider(order.deliveryPartnerPhone),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.green.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.phone_rounded,
                                        color: Colors.green, size: 20),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Delivery OTP Card
                      if (order.status != OrderStatus.delivered &&
                          order.status != OrderStatus.cancelled)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.shield_rounded,
                                    color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Delivery Handover OTP',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      otpCode,
                                      style: AppTextStyles.heading.copyWith(
                                        fontSize: 22,
                                        letterSpacing: 4,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Timeline or Cancelled
                      if (order.status == OrderStatus.cancelled)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cancel_outlined,
                                  color: AppColors.error),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('This order was cancelled',
                                    style: AppTextStyles.body
                                        .copyWith(color: AppColors.error)),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: List.generate(_steps.length, (i) {
                            final step = _steps[i];
                            final done = i <= currentIndex;
                            final isCurrent = i == currentIndex;
                            final isLast = i == _steps.length - 1;

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Icon(
                                        done
                                            ? (isCurrent
                                                ? Icons.radio_button_checked
                                                : Icons.check_circle)
                                            : Icons.radio_button_unchecked,
                                        color: done
                                            ? AppColors.primary
                                            : AppColors.divider,
                                        size: 20,
                                      ),
                                      if (!isLast)
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            color: i < currentIndex
                                                ? AppColors.primary
                                                : AppColors.divider,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 18),
                                      child: Text(
                                        step.label,
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: done
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: done
                                              ? AppColors.textDark
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),

                      // Items
                      if (order.items.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text('Items Ordered (${order.items.length})',
                            style:
                                AppTextStyles.heading.copyWith(fontSize: 14)),
                        const SizedBox(height: 10),
                        ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('${item.quantity}x',
                                        style: AppTextStyles.caption.copyWith(
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.name +
                                          (item.selectedWeight != null &&
                                                  item.selectedWeight!
                                                      .isNotEmpty
                                              ? ' (${item.selectedWeight})'
                                              : ''),
                                      style: AppTextStyles.body.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                      '₹${item.totalPrice.toStringAsFixed(0)}',
                                      style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ],
                              ),
                            )),
                      ],

                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Payment Method',
                                  style: AppTextStyles.caption),
                              Text(
                                order.paymentMethod == 'cod'
                                    ? 'Cash on Delivery'
                                    : 'Online Payment',
                                style: AppTextStyles.body
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Order Total',
                                  style: AppTextStyles.caption),
                              Text(
                                '₹${order.total.toStringAsFixed(0)}',
                                style: AppTextStyles.heading.copyWith(
                                    fontSize: 18, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
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

        final markers = <Marker>[
          Marker(
            point: customerPoint,
            width: 44,
            height: 44,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home_rounded,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
          if (driverPoint != null)
            Marker(
              point: driverPoint,
              width: 44,
              height: 44,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.two_wheeler_rounded,
                    color: Colors.white, size: 18),
              ),
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
                MarkerLayer(markers: markers),
              ],
            ),

            // Status banner overlay
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      order.status == OrderStatus.outForDelivery
                          ? Icons.two_wheeler_rounded
                          : Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.status == OrderStatus.outForDelivery
                            ? 'Rider is on the way to your delivery address'
                            : (partnerId != null && partnerId.isNotEmpty
                                ? 'Rider assigned · Preparing at ${order.shopName}'
                                : 'Shop is preparing your order'),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // OSM attribution (required by OSM license)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 9, color: Colors.black54),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
