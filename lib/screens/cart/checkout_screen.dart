import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../services/location_service.dart';
import '../../state/app_state.dart';
import '../../utils/constants.dart';
import '../location/select_location_screen.dart';
import '../orders/order_tracking_screen.dart';

enum _PaymentMethod { online, cod }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  _PaymentMethod _method = _PaymentMethod.online;
  final _couponController = TextEditingController();
  double _discount = 0.0;
  String? _appliedCoupon;
  bool _placing = false;
  bool _isItemsExpanded = false;

  final _orderService = OrderService();
  final _paymentService = PaymentService();

  final List<String> _quickCoupons = ['DAPZO50', 'FIRSTORDER', 'FESTIVE100'];

  @override
  void initState() {
    super.initState();
    _paymentService.initialize(
      onVerifiedSuccess: _handleServerVerifiedPaymentSuccess,
      onPaymentError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _handleServerVerifiedPaymentSuccess(
      String orderId, String orderCode, String paymentId) {
    if (!mounted) return;
    setState(() => _placing = false);

    final cart = context.read<CartService>();
    cart.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment Successful! Order placed.'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)),
      (route) => route.isFirst,
    );
  }

  void _handlePaymentError(String errorMessage) {
    if (!mounted) return;
    setState(() => _placing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: AppColors.surfaceVariant,
        action: SnackBarAction(
          label: 'OK',
          textColor: AppColors.primary,
          onPressed: () {},
        ),
      ),
    );
  }

  void _handleExternalWallet(String walletName) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected wallet: $walletName')),
    );
  }

  Future<void> _applyCoupon(double subtotal, [String? directCode]) async {
    final code = directCode ?? _couponController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a coupon code')),
      );
      return;
    }

    _couponController.text = code;
    final result = await _orderService.validateCouponDetails(code, subtotal);
    if (!mounted) return;

    if (result['valid'] == true) {
      final double calculatedDiscount =
          (result['discountAmount'] as num).toDouble();
      setState(() {
        _appliedCoupon = result['code'] as String;
        _discount = calculatedDiscount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🎉 Coupon applied! You saved ₹${calculatedDiscount.toStringAsFixed(0)}'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final String reason = result['reason'] ?? 'Invalid coupon code';
      setState(() {
        _appliedCoupon = null;
        _discount = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reason),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _discount = 0.0;
      _couponController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coupon removed')),
    );
  }

  Future<void> _handleCheckout(double total) async {
    final appState = context.read<AppState>();
    final cart = context.read<CartService>();
    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? appState.user?.uid ?? '';

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    if (appState.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final addr = appState.selectedAddress!;
    final locationService = LocationService();
    final isServiceable = await locationService.checkServiceability(
      area: addr.area,
      latitude: addr.latitude,
      longitude: addr.longitude,
    );

    if (!isServiceable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery is not available in this location.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String primaryShopId = '';
    String primaryShopName = 'Dapzo Partner Shop';

    for (final item in cart.items) {
      if (item.shopId.isNotEmpty) {
        primaryShopId = item.shopId;
        primaryShopName = item.shopName;
        break;
      }
    }
    if (primaryShopId.isEmpty && appState.servingShopId != null) {
      primaryShopId = appState.servingShopId!;
    }

    setState(() => _placing = true);

    if (_method == _PaymentMethod.online) {
      final orderCode = 'DZ${DateTime.now().millisecondsSinceEpoch % 100000}';
      final orderPayload = <String, dynamic>{
        'orderCode': orderCode,
        'userId': uid,
        'customerId': uid,
        'shopId': primaryShopId,
        'shopName': primaryShopName,
        'items': cart.items.map((e) => e.toMap()).toList(),
        'subtotal': cart.subtotal,
        'deliveryCharge': AppConstants.deliveryChargeDefault,
        'discount': _discount,
        'tax':
            total - cart.subtotal - AppConstants.deliveryChargeDefault + _discount,
        'total': total,
        'paymentMethod': 'online',
        'addressId': addr.id,
        'deliveryAddress': addr.toMap(),
        'couponCode': _appliedCoupon,
      };

      try {
        await _paymentService.startCheckout(
          amountInRupees: total,
          orderCode: orderCode,
          userId: uid,
          customerPhone: addr.phone.isNotEmpty
              ? addr.phone
              : (FirebaseAuth.instance.currentUser?.phoneNumber ?? ''),
          customerEmail: appState.user?.email ?? '',
          orderPayload: orderPayload,
        );
      } catch (e) {
        setState(() => _placing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to start payment: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } else {
      try {
        final orderId = await _orderService.createOrder(
          userId: uid,
          items: cart.items,
          subtotal: cart.subtotal,
          deliveryCharge: AppConstants.deliveryChargeDefault,
          discount: _discount,
          tax:
              total - cart.subtotal - AppConstants.deliveryChargeDefault + _discount,
          total: total,
          paymentMethod: 'cod',
          paymentStatus: 'pending',
          addressId: addr.id,
          shopId: primaryShopId,
          shopName: primaryShopName,
          deliveryAddress: addr.toMap(),
          couponCode: _appliedCoupon,
        );

        cart.clear();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order Placed Successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(orderId: orderId)),
          (route) => route.isFirst,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        if (mounted) setState(() => _placing = false);
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                size: 54, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Your Cart is Empty',
            style: AppTextStyles.heading.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to proceed with checkout',
            style: AppTextStyles.supporting.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Browse Items'),
          ),
        ],
      ),
    );
  }

  // ── Address Card ──
  Widget _buildAddressCard(AppState appState) {
    final addr = appState.selectedAddress;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Colors.green, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delivery Address',
                    style: AppTextStyles.sectionHeading.copyWith(fontSize: 15),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SelectLocationScreen()),
                ),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    addr != null ? 'Change' : 'Select',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          if (addr != null) ...[
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    addr.label.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    addr.area,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${addr.address}, ${addr.area}',
              style: AppTextStyles.supporting.copyWith(fontSize: 12.5),
            ),
            if (addr.phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Contact: ${addr.phone}',
                style: AppTextStyles.caption.copyWith(fontSize: 12),
              ),
            ],
          ] else ...[
            Text(
              'No delivery address selected',
              style: AppTextStyles.supporting.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SelectLocationScreen()),
                ),
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                label: const Text('Select / Add Delivery Address'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Condensed Cart Items Summary ──
  Widget _buildCartItemsSummary(CartService cart) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Items in Order (${cart.itemCount})',
                      style:
                          AppTextStyles.sectionHeading.copyWith(fontSize: 15),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () =>
                      setState(() => _isItemsExpanded = !_isItemsExpanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          _isItemsExpanded ? 'Hide' : 'View',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          _isItemsExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isItemsExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (int i = 0; i < cart.items.length; i++) ...[
                    _buildItemRow(cart.items[i], cart),
                    if (i < cart.items.length - 1)
                      const Divider(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(CartItemModel item, CartService cart) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.selectedWeight != null &&
                  item.selectedWeight!.isNotEmpty)
                Text(
                  item.selectedWeight!,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
            ],
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
    );
  }

  // ── Coupon Card ──
  Widget _buildCouponCard(double subtotal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_offer_outlined,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Coupons & Offers',
                style: AppTextStyles.sectionHeading.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_appliedCoupon != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_appliedCoupon Applied',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            'Saved ₹${_discount.toStringAsFixed(0)} on this order',
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _removeCoupon,
                    child: Text(
                      'Remove',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      hintStyle: AppTextStyles.caption,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 90,
                  child: ElevatedButton(
                    onPressed: () => _applyCoupon(subtotal),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: _quickCoupons.map((code) {
                return ActionChip(
                  label: Text(
                    code,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  backgroundColor: AppColors.surfaceVariant,
                  onPressed: () => _applyCoupon(subtotal, code),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Payment Method Section ──
  Widget _buildPaymentMethodSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payment_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Method',
                style: AppTextStyles.sectionHeading.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Online Payment (UPI, Cards, Wallets via Razorpay)
          InkWell(
            onTap: () => setState(() => _method = _PaymentMethod.online),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _method == _PaymentMethod.online
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _method == _PaymentMethod.online
                      ? AppColors.primary
                      : AppColors.divider,
                  width: _method == _PaymentMethod.online ? 1.8 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _method == _PaymentMethod.online
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _method == _PaymentMethod.online
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Online Payment',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'INSTANT',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'UPI (GPay, PhonePe, Paytm), Cards & NetBanking',
                          style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Cash on Delivery
          InkWell(
            onTap: () => setState(() => _method = _PaymentMethod.cod),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _method == _PaymentMethod.cod
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _method == _PaymentMethod.cod
                      ? AppColors.primary
                      : AppColors.divider,
                  width: _method == _PaymentMethod.cod ? 1.8 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _method == _PaymentMethod.cod
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _method == _PaymentMethod.cod
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash on Delivery (COD)',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pay in cash or scan QR at doorstep',
                          style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Final Bill Summary Card ──
  Widget _buildBillSummaryCard(
      double subtotal, double delivery, double tax, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Summary',
                style: AppTextStyles.sectionHeading.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _billRow('Item Subtotal', subtotal),
          _billRow('Delivery Partner Fee', delivery),
          if (_discount > 0)
            _billRow('Coupon Discount', -_discount, isDiscount: true),
          _billRow('Taxes & Packaging (5%)', tax),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payable',
                style: AppTextStyles.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: AppTextStyles.heading.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.supporting.copyWith(fontSize: 13)),
          Text(
            '${amount < 0 ? '-' : ''}₹${amount.abs().toStringAsFixed(0)}',
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight: isDiscount ? FontWeight.w700 : FontWeight.w600,
              color: isDiscount ? AppColors.success : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined,
              size: 20, color: AppColors.foodOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '100% Safe & Hygienic Delivery. Contactless delivery available.',
              style: AppTextStyles.caption.copyWith(fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCheckoutBar(double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL PAYABLE',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _placing ? null : () => _handleCheckout(total),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _placing
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          _method == _PaymentMethod.online
                              ? 'Pay ₹${total.toStringAsFixed(0)}'
                              : 'Place COD Order',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final cart = context.watch<CartService>();
      final appState = context.watch<AppState>();

      final subtotal = cart.subtotal;
      const delivery = AppConstants.deliveryChargeDefault;
      final tax = subtotal * AppConstants.taxRatePercent / 100;
      final total =
          (subtotal + delivery - _discount + tax).clamp(0.0, double.infinity);

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Checkout',
              style: AppTextStyles.heading.copyWith(fontSize: 18)),
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: false,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: AppColors.textDark,
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                )
              : null,
        ),
        body: cart.isEmpty
            ? _buildEmptyState()
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  _buildAddressCard(appState),
                  const SizedBox(height: 16),
                  _buildCartItemsSummary(cart),
                  const SizedBox(height: 16),
                  _buildCouponCard(subtotal),
                  const SizedBox(height: 16),
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 16),
                  _buildBillSummaryCard(subtotal, delivery, tax, total),
                  const SizedBox(height: 16),
                  _buildSafetyBanner(),
                ],
              ),
        bottomNavigationBar:
            cart.isEmpty ? null : _buildStickyCheckoutBar(total),
      );
    } catch (e, stack) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout Error')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text('Error rendering checkout: $e\n\n$stack',
              style: const TextStyle(color: Colors.red, fontSize: 14)),
        ),
      );
    }
  }
}
