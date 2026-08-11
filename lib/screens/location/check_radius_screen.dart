import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/address_model.dart';
import '../../services/location_service.dart';
import '../../services/address_service.dart';
import '../../state/app_state.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

/// Confirms a new address is inside a serving shop's delivery radius
/// before allowing it to be saved, per spec section 29.
class CheckRadiusScreen extends StatefulWidget {
  const CheckRadiusScreen({super.key});

  @override
  State<CheckRadiusScreen> createState() => _CheckRadiusScreenState();
}

class _CheckRadiusScreenState extends State<CheckRadiusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService();
  final _addressService = AddressService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _label = 'Home';
  double? _lat;
  double? _lng;
  bool _checking = false;
  bool? _available;

  Future<void> _useCurrentLocation() async {
    setState(() => _checking = true);
    try {
      final position = await _locationService.getCurrentPosition();
      _lat = position.latitude;
      _lng = position.longitude;

      final shop = await _locationService.findServingShop(
        latitude: _lat!,
        longitude: _lng!,
      );
      setState(() => _available = shop != null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check delivery availability first')),
      );
      return;
    }
    if (_available != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery is not available at this location')),
      );
      return;
    }

    final appState = context.read<AppState>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final address = AddressModel(
      id: const Uuid().v4(),
      label: _label,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      area: _areaController.text.trim(),
      city: _cityController.text.trim(),
      pincode: _pincodeController.text.trim(),
      latitude: _lat!,
      longitude: _lng!,
    );

    await _addressService.addAddress(uid, address);
    appState.setSelectedAddress(address);

    if (!mounted) return;
    // Pop once with a success flag. The caller (SelectLocationScreen)
    // decides whether to also pop itself — AddressesScreen (Profile flow)
    // does not, so it correctly lands back on the address list instead
    // of being kicked all the way to Home.
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Address')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: _checking ? null : _useCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: Text(_checking ? 'Checking...' : 'Use Current Location'),
              ),
              if (_available != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_available! ? AppColors.success : AppColors.error).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _available! ? Icons.check_circle : Icons.cancel,
                        color: _available! ? AppColors.success : AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _available! ? 'Delivery available here' : 'Delivery not available here',
                        style: AppTextStyles.body.copyWith(
                          color: _available! ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                children: AppConstants.addressLabels.map((label) {
                  final selected = _label == label;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _label = label),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                validator: Validators.name,
                decoration: const InputDecoration(hintText: 'Receiver name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
                decoration: const InputDecoration(hintText: 'Phone number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                validator: (v) => Validators.notEmpty(v, field: 'Address'),
                decoration: const InputDecoration(hintText: 'House / flat / street'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _areaController,
                validator: (v) => Validators.notEmpty(v, field: 'Area'),
                decoration: const InputDecoration(hintText: 'Area / locality'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      validator: (v) => Validators.notEmpty(v, field: 'City'),
                      decoration: const InputDecoration(hintText: 'City'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.notEmpty(v, field: 'Pincode'),
                      decoration: const InputDecoration(hintText: 'Pincode'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAddress,
                  child: const Text('Save Address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}