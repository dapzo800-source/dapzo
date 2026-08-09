import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/address_model.dart';
import '../../services/address_service.dart';
import '../../services/cart_service.dart';
import '../../state/app_state.dart';
import '../../utils/constants.dart';
import '../location/select_location_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final AddressService _addressService = AddressService();

  bool _loadingAddress = true;
  String? _addressError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSelectedAddress();
    });
  }

  Future<void> _loadSelectedAddress() async {
    if (!mounted) return;

    final appState = context.read<AppState>();
    final uid = appState.user?.uid;

    if (uid == null || uid.isEmpty) {
      if (!mounted) return;

      setState(() {
        _loadingAddress = false;
        _addressError = 'Please sign in again.';
      });

      return;
    }

    // ------------------------------------------------------------
    // If AppState already has an address, use it.
    // ------------------------------------------------------------

    if (appState.selectedAddress != null) {
      if (!mounted) return;

      setState(() {
        _loadingAddress = false;
      });

      return;
    }

    // ------------------------------------------------------------
    // Otherwise load saved addresses from Firestore.
    // ------------------------------------------------------------

    try {
      final addresses =
          await _addressService.streamAddresses(uid).first;

      if (!mounted) return;

      if (addresses.isEmpty) {
        setState(() {
          _loadingAddress = false;
          _addressError = 'No delivery address found.';
        });

        return;
      }

      // Prefer default address.
      AddressModel selected = addresses.first;

      for (final address in addresses) {
        if (address.isDefault) {
          selected = address;
          break;
        }
      }

      context.read<AppState>().setSelectedAddress(selected);

      if (!mounted) return;

      setState(() {
        _loadingAddress = false;
        _addressError = null;
      });
    } catch (e) {
      debugPrint('CHECKOUT ADDRESS ERROR: $e');

      if (!mounted) return;

      setState(() {
        _loadingAddress = false;
        _addressError = 'Unable to load delivery address.';
      });
    }
  }

  Future<void> _selectAddress() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SelectLocationScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {
      _addressError = null;
    });

    await _loadSelectedAddress();
  }

  void _placeOrder() {
    final appState = context.read<AppState>();
    final cart = context.read<CartService>();

    final address = appState.selectedAddress;

    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
        ),
      );

      return;
    }

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
        ),
      );

      return;
    }

    // ------------------------------------------------------------
    // Temporary test
    // ------------------------------------------------------------

    debugPrint('================================');
    debugPrint('CHECKOUT');
    debugPrint('Address ID: ${address.id}');
    debugPrint('Address: ${address.address}');
    debugPrint('Area: ${address.area}');
    debugPrint('City: ${address.city}');
    debugPrint('Cart items: ${cart.items.length}');
    debugPrint('Subtotal: ${cart.subtotal}');
    debugPrint('================================');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Address selected: ${address.label}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final appState = context.watch<AppState>();

    final subtotal = cart.subtotal;

    const delivery =
        AppConstants.deliveryChargeDefault;

    final tax =
        subtotal *
        AppConstants.taxRatePercent /
        100;

    final total =
        subtotal +
        delivery +
        tax;

    final address =
        appState.selectedAddress;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ======================================================
            // DELIVERY ADDRESS
            // ======================================================

            Text(
              'Delivery Address',
              style: AppTextStyles.sectionHeading.copyWith(
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 10),

            InkWell(
              onTap: _selectAddress,
              borderRadius: BorderRadius.circular(14),

              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: address != null
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),

                child: _loadingAddress
                    ? const Row(
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Loading address...',
                          ),
                        ],
                      )
                    : address == null
                        ? Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Select a delivery address',
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      _addressError ??
                                          'Tap here to add or select an address',
                                      style:
                                          AppTextStyles.supporting,
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(
                                Icons.chevron_right,
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,

                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),

                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.primary,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            address.label,
                                            style:
                                                AppTextStyles.body.copyWith(
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                        ),

                                        TextButton(
                                          onPressed:
                                              _selectAddress,
                                          child:
                                              const Text('Change'),
                                        ),
                                      ],
                                    ),

                                    Text(
                                      address.address,
                                      style:
                                          AppTextStyles.body,
                                    ),

                                    const SizedBox(height: 3),

                                    Text(
                                      '${address.area}, ${address.city}',
                                      style:
                                          AppTextStyles.supporting,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
              ),
            ),

            const SizedBox(height: 24),

            // ======================================================
            // CART ITEMS
            // ======================================================

            Text(
              'Your Items',
              style: AppTextStyles.sectionHeading.copyWith(
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 10),

            if (cart.items.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Text(
                  'Your cart is empty.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.divider,
                  ),
                ),
                child: Column(
                  children: cart.items.map((item) {
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              style:
                                  AppTextStyles.body.copyWith(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),

                          Text(
                            '× ${item.quantity}',
                            style:
                                AppTextStyles.supporting,
                          ),

                          const SizedBox(width: 15),

                          Text(
                            '₹${item.total.toStringAsFixed(0)}',
                            style:
                                AppTextStyles.body.copyWith(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 24),

            // ======================================================
            // PAYMENT METHOD
            // ======================================================

            Text(
              'Payment Method',
              style: AppTextStyles.sectionHeading.copyWith(
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash on Delivery',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Pay in cash when your order arrives',
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.radio_button_checked,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ======================================================
            // ORDER SUMMARY
            // ======================================================

            Text(
              'Order Summary',
              style: AppTextStyles.sectionHeading.copyWith(
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.divider,
                ),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    'Subtotal',
                    subtotal,
                  ),

                  _summaryRow(
                    'Delivery',
                    delivery,
                  ),

                  _summaryRow(
                    'Tax',
                    tax,
                  ),

                  const Divider(
                    height: 24,
                  ),

                  _summaryRow(
                    'Total',
                    total,
                    bold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 110),
          ],
        ),
      ),

      // ==========================================================
      // PLACE ORDER
      // ==========================================================

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placeOrder,
              child: Text(
                'Place Order · ₹${total.toStringAsFixed(0)}',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontWeight:
                  bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),

          Text(
            '₹${value.toStringAsFixed(0)}',
            style: AppTextStyles.body.copyWith(
              fontWeight:
                  bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}