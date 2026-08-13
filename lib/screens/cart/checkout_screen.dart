import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/cart_item_model.dart';
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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    if (appState.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    setState(() => _placing = true);

    try {
      String? gatewayTxnId;
      final checkoutRefId = 'chk_${DateTime.now().millisecondsSinceEpoch}_${uid.substring(0, uid.length > 5 ? 5 : uid.length)}';

      if (_method == _PaymentMethod.online) {
        final session = await _paymentService.createPaymentSession(
          orderId: 'pending',
          amount: total,
          userId: uid,
        );
        gatewayTxnId = session['sessionId'] as String?;
      }

      final selectedAddr = appState.selectedAddress!;
      final primaryShopId = cart.items.isNotEmpty ? cart.items.first.shopId : '';
      final primaryShopName = cart.items.isNotEmpty ? cart.items.first.shopName : 'Dapzo Partner Shop';

      final orderId = await _orderService.createOrder(
        userId: uid,
        items: cart.items,
        subtotal: cart.subtotal,
        deliveryCharge: AppConstants.deliveryChargeDefault,
        discount: _discount,
        tax: total - cart.subtotal - AppConstants.deliveryChargeDefault + _discount,
        total: total,
        paymentMethod: _method == _PaymentMethod.cod ? 'cod' : 'online',
        addressId: selectedAddr.id,
        shopId: primaryShopId,
        shopName: primaryShopName,
        deliveryAddress: selectedAddr.toMap(),
        couponCode: _appliedCoupon,
        gatewayTransactionId: gatewayTxnId,
        checkoutReferenceId: checkoutRefId,
      );

      // Cart cleared ONLY on backend success
      cart.clear();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)),
        (route) => route.isFirst,
      );
    } catch (e) {
      final String rawMsg = e.toString();
      final String cleanMsg = rawMsg.contains('permission-denied')
          ? 'Unable to place order: Authorization required. Please try again shortly.'
          : rawMsg.replaceFirst(RegExp(r'^Exception:\s*'), '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cleanMsg),
          backgroundColor: AppColors.textDark,
        ),
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
          if (cart.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text('Your cart is empty',
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else ...[
            Text('Order Items (${cart.itemCount})',
                style: AppTextStyles.sectionHeading.copyWith(fontSize: 15)),
            const SizedBox(height: 8),
            for (final item in cart.items) _buildItemTile(item, cart),
            const SizedBox(height: 22),

            // ── Meat Section Recommendation ──
            _buildMeatRecommendation(context),
            const SizedBox(height: 22),
          ],

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
                  Icon(Icons.location_on_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      appState.selectedAddress != null
                          ? '${appState.selectedAddress!.label} — ${appState.selectedAddress!.address}, ${appState.selectedAddress!.area}'
                          : 'Select a delivery address',
                      style: AppTextStyles.body,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
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
              color: AppColors.surface,
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
              onPressed: (_placing || cart.isEmpty) ? null : () => _placeOrder(total),
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

  Widget _buildItemTile(CartItemModel item, CartService cart) {
    try {
      return _CheckoutItemTile(item: item, cart: cart);
    } catch (e, st) {
      debugPrint('CHECKOUT ITEM BUILD ERROR for productId=${item.productId}: $e');
      debugPrint('$st');
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.name.isNotEmpty ? item.name : 'Item',
                style: AppTextStyles.body,
              ),
            ),
            Text('x${item.quantity}', style: AppTextStyles.caption),
          ],
        ),
      );
    }
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

  Widget _buildMeatRecommendation(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<AppState>().setMode('meat');
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('assets/images/meat_banner.png'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Craving Fresh Meat?',
                style: AppTextStyles.heading.copyWith(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Explore our premium\nselection of raw cuts.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Order Now',
                  style: AppTextStyles.badge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutItemTile extends StatelessWidget {
  final CartItemModel item;
  final CartService cart;

  const _CheckoutItemTile({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl.isEmpty
                ? _fallbackThumb()
                : Image.network(
                    item.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackThumb(),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                if (item.selectedWeight != null)
                  Text(item.selectedWeight!, style: AppTextStyles.caption),
                Text('₹${item.unitPrice.toStringAsFixed(0)}', style: AppTextStyles.caption),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => cart.decrementQty(item.lineKey),
                child: Icon(Icons.remove_circle_outline, size: 20, color: AppColors.textSecondary),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('${item.quantity}', style: AppTextStyles.body),
              ),
              InkWell(
                onTap: () => cart.incrementQty(item.lineKey),
                child: Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackThumb() {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.divider,
      child: Icon(Icons.fastfood_outlined, size: 20, color: AppColors.textSecondary),
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
          color: selected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surface,
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