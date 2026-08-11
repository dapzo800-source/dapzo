import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/address_model.dart';
import '../../services/address_service.dart';
import '../../state/app_state.dart';
import 'check_radius_screen.dart';

class SelectLocationScreen extends StatelessWidget {
  const SelectLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final addressService = AddressService();

    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Delivery Location'),
      ),

      body: uid == null
          ? Center(
              child: Text(
                'Please sign in first',
                style: AppTextStyles.supporting,
              ),
            )
          : StreamBuilder<List<AddressModel>>(
              stream: addressService.streamAddresses(uid),

              builder: (context, snapshot) {
                // --------------------------------------------------------
                // ERROR
                // --------------------------------------------------------

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Unable to load addresses\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.supporting,
                      ),
                    ),
                  );
                }

                // --------------------------------------------------------
                // LOADING
                // --------------------------------------------------------

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final addresses = snapshot.data ?? [];

                // --------------------------------------------------------
                // UI
                // --------------------------------------------------------

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ====================================================
                    // ADD NEW ADDRESS
                    // ====================================================

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // CheckRadiusScreen pops with a bool (true on
                          // success) via Navigator.pop(true), not an
                          // AddressModel — so this push must be typed
                          // <bool>. Typing it <AddressModel> caused a
                          // runtime TypeError the moment someone added a
                          // new address from this screen (checkout flow).
                          final saved = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const CheckRadiusScreen(),
                            ),
                          );

                          // ------------------------------------------------
                          // NEW ADDRESS WAS SAVED
                          // ------------------------------------------------

                          if (!context.mounted) return;

                          if (saved == true) {
                            // CheckRadiusScreen already calls
                            // AppState.setSelectedAddress() itself before
                            // popping, so there's nothing left to do here
                            // except return to the previous screen.
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(
                          Icons.add_location_alt_outlined,
                        ),
                        label: const Text('Add New Address'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ====================================================
                    // TITLE
                    // ====================================================

                    Text(
                      'Saved Addresses',
                      style: AppTextStyles.sectionHeading,
                    ),

                    const SizedBox(height: 12),

                    // ====================================================
                    // EMPTY
                    // ====================================================

                    if (addresses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                        ),
                        child: Center(
                          child: Text(
                            'No saved addresses yet',
                            style: AppTextStyles.supporting,
                          ),
                        ),
                      ),

                    // ====================================================
                    // ADDRESS LIST
                    // ====================================================

                    ...addresses.map(
                      (address) {
                        final isSelected =
                            appState.selectedAddress?.id == address.id;

                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),

                            // ------------------------------------------------
                            // ICON
                            // ------------------------------------------------

                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                address.label.toLowerCase() == 'home'
                                    ? Icons.home_outlined
                                    : address.label.toLowerCase() == 'work'
                                        ? Icons.work_outline
                                        : Icons.location_on_outlined,
                                color: AppColors.primary,
                              ),
                            ),

                            // ------------------------------------------------
                            // TITLE
                            // ------------------------------------------------

                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    address.label,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),

                                if (address.isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Default',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            // ------------------------------------------------
                            // ADDRESS
                            // ------------------------------------------------

                            subtitle: Padding(
                              padding: const EdgeInsets.only(
                                top: 5,
                              ),
                              child: Text(
                                '${address.address}, '
                                '${address.area}, '
                                '${address.city}',
                                style: AppTextStyles.supporting,
                              ),
                            ),

                            // ------------------------------------------------
                            // SELECT
                            // ------------------------------------------------

                            trailing: Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey,
                            ),

                            onTap: () {
                              context
                                  .read<AppState>()
                                  .setSelectedAddress(address);

                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}