import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/address_model.dart';
import '../../services/address_service.dart';
import 'check_radius_screen.dart';

/// Manage saved addresses from the Profile menu (view/delete/add).
class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final addressService = AddressService();

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
          'Saved Addresses',
          style: AppTextStyles.heading.copyWith(fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CheckRadiusScreen()),
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: uid == null
          ? Center(
              child: Text('Please sign in to view saved addresses', style: AppTextStyles.supporting),
            )
          : StreamBuilder<List<AddressModel>>(
              stream: addressService.streamAddresses(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final addresses = snapshot.data ?? [];
                if (addresses.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off_outlined, size: 54, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text('No saved addresses yet', style: AppTextStyles.heading.copyWith(fontSize: 17)),
                          const SizedBox(height: 6),
                          Text('Tap the button below to add your first delivery address.',
                              textAlign: TextAlign.center, style: AppTextStyles.supporting),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];

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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(iconData, color: AppColors.primary, size: 20),
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
                                  if (address.name.isNotEmpty || address.phone.isNotEmpty)
                                    Text(
                                      '${address.name}${address.name.isNotEmpty && address.phone.isNotEmpty ? ' · ' : ''}${address.phone}',
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${address.address}, ${address.area}, ${address.city} ${address.pincode}',
                                    style: AppTextStyles.supporting.copyWith(fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                              color: AppColors.error,
                              tooltip: 'Delete',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    title: const Text('Delete Address?'),
                                    content: Text('Remove "${address.label}" from your saved addresses?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await addressService.deleteAddress(uid, address.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}