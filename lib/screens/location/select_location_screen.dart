import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/address_model.dart';
import '../../services/address_service.dart';
import '../../services/location_service.dart';
import '../../state/app_state.dart';
import 'check_radius_screen.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final _addressService = AddressService();
  final _locationService = LocationService();
  bool _detectingLocation = false;

  Future<void> _detectAndUseCurrentGpsLocation() async {
    setState(() => _detectingLocation = true);
    try {
      final position = await _locationService.getCurrentPosition();
      final lat = position.latitude;
      final lng = position.longitude;

      final isServiceable = await _locationService.checkServiceability(
        latitude: lat,
        longitude: lng,
      );

      if (!isServiceable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery is not available at your current GPS location yet.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      final autoAddress = AddressModel(
        id: const Uuid().v4(),
        label: 'Current Location',
        name: 'My Location',
        phone: FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
        address: 'Current Detected GPS Location',
        area: 'Nearby Area',
        city: 'Current City',
        pincode: '',
        latitude: lat,
        longitude: lng,
      );

      if (uid != null) {
        await _addressService.addAddress(uid, autoAddress);
      }

      if (mounted) {
        context.read<AppState>().setSelectedAddress(autoAddress);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery location updated to current GPS!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to detect location: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textDark,
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Select Delivery Location',
          style: AppTextStyles.heading.copyWith(fontSize: 18),
        ),
      ),
      body: uid == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 54, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text('Please Sign In', style: AppTextStyles.heading.copyWith(fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('Sign in to view and manage your saved addresses.',
                        textAlign: TextAlign.center, style: AppTextStyles.supporting),
                  ],
                ),
              ),
            )
          : StreamBuilder<List<AddressModel>>(
              stream: _addressService.streamAddresses(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text('Unable to load addresses: ${snapshot.error}',
                              textAlign: TextAlign.center, style: AppTextStyles.supporting),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final addresses = snapshot.data ?? [];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    // ── GPS Auto-Detect Button Card ──
                    Container(
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
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _detectingLocation ? null : _detectAndUseCurrentGpsLocation,
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: _detectingLocation
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : const Icon(Icons.my_location_rounded,
                                          color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Use Current Location',
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _detectingLocation
                                            ? 'Fetching GPS & verifying delivery zone...'
                                            : 'Enable GPS for fastest delivery setup',
                                        style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.primary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Add New Address Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final saved = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => const CheckRadiusScreen()),
                          );
                          if (!context.mounted) return;
                          if (saved == true) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: AppColors.surface,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
                        label: Text(
                          'Add New Delivery Address',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Saved Addresses Section ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Saved Addresses (${addresses.length})',
                          style: AppTextStyles.sectionHeading.copyWith(fontSize: 15),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (addresses.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.location_off_outlined,
                                size: 44, color: AppColors.textSecondary),
                            const SizedBox(height: 10),
                            Text('No saved addresses yet',
                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              'Add your home, office or other delivery locations for quick checkout.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                    ...addresses.map((address) {
                      final isSelected = appState.selectedAddress?.id == address.id;

                      IconData iconData = Icons.location_on_outlined;
                      final labelLower = address.label.toLowerCase();
                      if (labelLower.contains('home')) {
                        iconData = Icons.home_rounded;
                      } else if (labelLower.contains('work') || labelLower.contains('office')) {
                        iconData = Icons.business_rounded;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.07)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.divider,
                            width: isSelected ? 1.8 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              context.read<AppState>().setSelectedAddress(address);
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.15)
                                          : AppColors.surfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      iconData,
                                      color: isSelected ? AppColors.primary : AppColors.textDark,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              address.label.toUpperCase(),
                                              style: AppTextStyles.body.copyWith(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13.5,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.textDark,
                                              ),
                                            ),
                                            if (address.isDefault) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'DEFAULT',
                                                  style: AppTextStyles.caption.copyWith(
                                                    color: AppColors.primary,
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          address.name.isNotEmpty
                                              ? '${address.name} · ${address.phone}'
                                              : (address.phone.isNotEmpty ? address.phone : ''),
                                          style: AppTextStyles.caption.copyWith(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${address.address}, ${address.area}, ${address.city} ${address.pincode}',
                                          style: AppTextStyles.supporting.copyWith(
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}