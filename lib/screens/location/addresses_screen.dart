import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/address_model.dart';
import '../../services/address_service.dart';
import '../../state/app_state.dart';
import 'check_radius_screen.dart';

/// Manage saved addresses from the Profile menu (view/delete).
/// Selecting a delivery address for an order happens in SelectLocationScreen.
class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AppState>().user?.uid;
    final addressService = AddressService();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CheckRadiusScreen()),
        ),
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: uid == null
          ? const SizedBox.shrink()
          : StreamBuilder<List<AddressModel>>(
              stream: addressService.streamAddresses(uid),
              builder: (context, snapshot) {
                final addresses = snapshot.data ?? [];
                if (addresses.isEmpty) {
                  return Center(
                    child: Text('No saved addresses yet', style: AppTextStyles.supporting),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                        title: Text(address.label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text('${address.address}, ${address.area}, ${address.city}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
                          onPressed: () => addressService.deleteAddress(uid, address.id),
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
