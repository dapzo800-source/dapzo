import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/location_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _orderService = OrderService();
  final _locationService = LocationService();
  GoogleMapController? _mapController;

  static const _steps = [
    OrderStatus.placed,
    OrderStatus.shopAccepted,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Track Order'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
      ),
      body: StreamBuilder<OrderModel>(
        stream: _orderService.streamOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
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
                  ? order.id.replaceAll(RegExp(r'[^0-9]'), '').substring(0, 4)
                  : '4829');

          final customerLat = (order.deliveryAddress['latitude'] as num?)?.toDouble() ?? 12.9568;
          final customerLng = (order.deliveryAddress['longitude'] as num?)?.toDouble() ?? 78.2711;

          return Column(
            children: [
              // ── Top Section: Google Map or Delivery Partner Notice ──
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order #${order.orderCode}', style: AppTextStyles.heading.copyWith(fontSize: 18)),
                              Text(order.shopName, style: AppTextStyles.supporting.copyWith(fontSize: 12)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

                      // Delivery Handover OTP Card
                      if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 24),
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

                      // Cancelled or Timeline
                      if (order.status == OrderStatus.cancelled)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cancel_outlined, color: AppColors.error),
                              const SizedBox(width: 10),
                              Text('This order was cancelled', style: AppTextStyles.body.copyWith(color: AppColors.error)),
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
                                            ? (isCurrent ? Icons.radio_button_checked : Icons.check_circle)
                                            : Icons.radio_button_unchecked,
                                        color: done ? AppColors.primary : AppColors.divider,
                                        size: 20,
                                      ),
                                      if (!isLast)
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            color: i < currentIndex ? AppColors.primary : AppColors.divider,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 18),
                                      child: Text(
                                        step.label,
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                                          color: done ? AppColors.textDark : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Payment Method', style: AppTextStyles.caption),
                              Text(
                                order.paymentMethod == 'cod' ? 'Cash on Delivery' : 'Online Payment',
                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Order Total', style: AppTextStyles.caption),
                              Text(
                                '₹${order.total.toStringAsFixed(0)}',
                                style: AppTextStyles.heading.copyWith(fontSize: 18, color: AppColors.primary),
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

  Widget _buildMapSection(OrderModel order, double custLat, double custLng) {
    final isOutForDelivery = order.status == OrderStatus.outForDelivery;
    final partnerId = order.deliveryPartnerId;

    if (partnerId == null || partnerId.isEmpty) {
      return Container(
        color: AppColors.surfaceVariant,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delivery_dining_outlined, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(
                'Delivery partner not assigned yet',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                order.status.label,
                style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
    }

    if (!isOutForDelivery) {
      return Container(
        color: AppColors.surfaceVariant,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront_outlined, size: 48, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                'Order is being prepared at ${order.shopName}',
                style: AppTextStyles.body.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Live GPS tracking will activate when driver picks up your order.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Stream real-time driver coordinates from Firestore collection `delivery_locations/{deliveryPartnerId}`
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _locationService.streamDeliveryPartnerLocation(partnerId),
      builder: (context, locSnap) {
        final locData = locSnap.data;
        final driverLat = (locData?['latitude'] as num?)?.toDouble() ?? (locData?['lat'] as num?)?.toDouble();
        final driverLng = (locData?['longitude'] as num?)?.toDouble() ?? (locData?['lng'] as num?)?.toDouble();

        final Set<Marker> markers = {
          Marker(
            markerId: const MarkerId('customer'),
            position: LatLng(custLat, custLng),
            infoWindow: const InfoWindow(title: 'Delivery Address'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };

        if (driverLat != null && driverLng != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('driver'),
              position: LatLng(driverLat, driverLng),
              infoWindow: InfoWindow(
                title: order.deliveryPartnerName ?? 'Delivery Partner',
                snippet: 'Out for delivery',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            ),
          );
        }

        final initialTarget = (driverLat != null && driverLng != null)
            ? LatLng(driverLat, driverLng)
            : LatLng(custLat, custLng);

        return GoogleMap(
          initialCameraPosition: CameraPosition(target: initialTarget, zoom: 14),
          markers: markers,
          onMapCreated: (controller) => _mapController = controller,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        );
      },
    );
  }
}
