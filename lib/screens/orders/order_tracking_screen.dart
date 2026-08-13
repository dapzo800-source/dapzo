import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  static const _steps = [
    OrderStatus.placed,
    OrderStatus.shopAccepted,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();

    return Scaffold(
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
        stream: orderService.streamOrder(orderId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = snapshot.data!;
          final currentIndex = order.status == OrderStatus.cancelled
              ? -1
              : _steps.indexOf(order.status);

          // Generate 4-digit Delivery OTP from order ID
          final digitsOnly = order.id.replaceAll(RegExp(r'[^0-9]'), '');
          final otpCode = (digitsOnly.length >= 4)
              ? digitsOnly.substring(0, 4)
              : '4829';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #${order.orderCode}', style: AppTextStyles.heading.copyWith(fontSize: 20)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
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
                            const SizedBox(height: 2),
                            Text(
                              otpCode,
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 24,
                                letterSpacing: 4,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Share with rider upon delivery',
                              style: AppTextStyles.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

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
                                size: 22,
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
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Text(
                                step.label,
                                style: AppTextStyles.body.copyWith(
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
              const Divider(height: 32),
              Text('Payment Details', style: AppTextStyles.sectionHeading.copyWith(fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                order.paymentMethod == 'cod' ? 'Cash on Delivery' : 'Online Payment',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 4),
              Text(
                'Payment Status: ${order.paymentStatus[0].toUpperCase()}${order.paymentStatus.substring(1)}',
                style: AppTextStyles.supporting,
              ),
              const SizedBox(height: 24),
              Text('Order Total', style: AppTextStyles.sectionHeading.copyWith(fontSize: 15)),
              const SizedBox(height: 8),
              Text('₹${order.total.toStringAsFixed(0)}', style: AppTextStyles.heading.copyWith(fontSize: 20, color: AppColors.primary)),
            ],
          );
        },
      ),
    );
  }
}
