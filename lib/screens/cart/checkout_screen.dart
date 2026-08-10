import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../state/app_state.dart';
import '../../utils/constants.dart';
import '../location/select_location_screen.dart';
import '../orders/order_tracking_screen.dart';

enum _PaymentMethod { cod, online }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  _PaymentMethod _method = _PaymentMethod.cod;
  final _couponController = TextEditingController();
  double _discount = 0;
  String? _appliedCoupon;
  bool _placing = false;

  final _orderService = OrderService();
  final _paymentService = PaymentService();

  Future<void> _applyCoupon(double subtotal) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    final coupon = await _orderService.validateCoupon(code, subtotal);
    if (!mounted) return;

    if (coupon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or inapplicable coupon')),
      );
      return;
    }

    setState(() {
      _appliedCoupon = code.toUpperCase();
      final percent = (coupon['discountPercent'] ?? 0).toDouble();
      final flat = (coupon['discountFlat'] ?? 0).toDouble();
      _discount = percent > 0 ? subtotal * percent / 100 : flat;
    });
  }

  Future<void> _placeOrder(double total) async {
    final appState = context.read<AppState>();
    final cart = context.read<CartService>();

    if (appState.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    setState(() => _placing = true);

    try {
      String? gatewayTxnId;

      if (_method == _PaymentMethod.online) {
        // Online Payment -> Cloudflare Worker -> Payment Gateway -> Verification
        final session = await _paymentService.createPaymentSession(
          orderId: 'pending',
          amount: total,
          userId: appState.user?.uid ?? '',
        );
        // In a full implementation, launch the gateway's checkout UI here
        // with `session`, then call verifyPayment() with its response.
        gatewayTxnId = session['sessionId'] as String?;
      }

      final orderId = await _orderService.createOrder(
        userId: appState.user?.uid ?? '',
        items: cart.items,
        subtotal: cart.subtotal,
        deliveryCharge: AppConstants.deliveryChargeDefault,
        discount: _discount,
        tax: total - cart.subtotal - AppConstants.deliveryChargeDefault + _discount,
        total: total,
        paymentMethod: _method == _PaymentMethod.cod ? 'cod' : 'online',
        addressId: appState.selectedAddress!.id,
        couponCode: _appliedCoupon,
        gatewayTransactionId: gatewayTxnId,
      );

      cart.clear();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)),
        (route) => route.isFirst,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not place order: $e')),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final appState = context.watch<AppState>();

    final subtotal = cart.subtotal;
    const delivery = AppConstants.deliveryChargeDefault;
    final tax = subtotal * AppConstants.taxRatePercent / 100;
    final total = subtotal + delivery - _discount + tax;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Delivery Address', style: AppTextStyles.sectionHeading.copyWith(fontSize: 15)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SelectLocationScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      appState.selectedAddress != null
                          ? '${appState.selectedAddress!.label} — ${appState.selectedAddress!.address}, ${appState.selectedAddress!.area}'
                          : 'Select a delivery address',
                      style: AppTextStyles.body,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text('Coupon', style: AppTextStyles.sectionHeading.copyWith(fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'Enter coupon code'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => _applyCoupon(subtotal),
                child: const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text('Payment Method', style: AppTextStyles.sectionHeading.copyWith(fontSize: 15)),
          const SizedBox(height: 8),
          _PaymentTile(
            title: 'Cash on Delivery',
            subtitle: 'Pay in cash when your order arrives',
            selected: _method == _PaymentMethod.cod,
            onTap: () => setState(() => _method = _PaymentMethod.cod),
          ),
          const SizedBox(height: 10),
          _PaymentTile(
            title: 'Online Payment',
            subtitle: 'Pay securely now',
            selected: _method == _PaymentMethod.online,
            onTap: () => setState(() => _method = _PaymentMethod.online),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _row('Subtotal', subtotal),
                _row('Delivery', delivery),
                _row('Discount', -_discount),
                _row('Tax', tax),
                const Divider(height: 20),
                _row('Total', total, bold: true),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placing ? null : () => _placeOrder(total),
              child: _placing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Place Order'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    final style = bold
        ? AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 16)
        : AppTextStyles.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('${value < 0 ? '-' : ''}₹${value.abs().toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.06) : AppColors.white,
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
