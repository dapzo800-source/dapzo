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

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _nameController.text = user.displayName!;
      }
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        _phoneController.text = user.phoneNumber!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _checking = true);
    try {
      final position = await _locationService.getCurrentPosition();
      _lat = position.latitude;
      _lng = position.longitude;

      final isServiceable = await _locationService.checkServiceability(
        latitude: _lat!,
        longitude: _lng!,
      );
      setState(() => _available = isServiceable);

      if (isServiceable) {
        if (_areaController.text.isEmpty) {
          _areaController.text = 'Nearby Area';
        }
        if (_cityController.text.isEmpty) {
          _cityController.text = 'Current City';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap "Check Delivery Availability" or "Use Current GPS Location" first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_available != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery is not currently available at this location'),
          backgroundColor: AppColors.error,
        ),
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
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
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
          'Add Delivery Address',
          style: AppTextStyles.heading.copyWith(fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── GPS Detection Card ──
              Container(
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
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _checking ? null : _useCurrentLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _checking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded, size: 20),
                        label: Text(
                          _checking ? 'Verifying Delivery Zone...' : 'Use Current GPS Location',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                    if (_available != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: (_available! ? AppColors.success : AppColors.error)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (_available! ? AppColors.success : AppColors.error)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _available! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: _available! ? AppColors.success : AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _available!
                                    ? 'Great news! Delivery is available at this location 🎉'
                                    : 'Delivery is currently not available here.',
                                style: AppTextStyles.body.copyWith(
                                  color: _available! ? AppColors.success : AppColors.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Address Label Chips ──
              Text(
                'Save address as',
                style: AppTextStyles.sectionHeading.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: AppConstants.addressLabels.map((label) {
                  final selected = _label == label;
                  return ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceVariant,
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.divider,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (_) => setState(() => _label = label),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Form Inputs ──
              Container(
                padding: const EdgeInsets.all(18),
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
                  children: [
                    TextFormField(
                      controller: _nameController,
                      validator: Validators.name,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        labelText: 'Receiver Name',
                        hintText: 'e.g. John Doe',
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        labelStyle: AppTextStyles.caption,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '10-digit mobile number',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        labelStyle: AppTextStyles.caption,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _addressController,
                      validator: (v) => Validators.notEmpty(v, field: 'Address'),
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        labelText: 'House / Flat / Street Name',
                        hintText: 'e.g. Flat 302, Green Valley Apartments',
                        prefixIcon: const Icon(Icons.home_outlined, size: 20),
                        labelStyle: AppTextStyles.caption,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _areaController,
                      validator: (v) => Validators.notEmpty(v, field: 'Area'),
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        labelText: 'Area / Locality',
                        hintText: 'e.g. Indiranagar 100ft Road',
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                        labelStyle: AppTextStyles.caption,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            validator: (v) => Validators.notEmpty(v, field: 'City'),
                            style: AppTextStyles.body,
                            decoration: InputDecoration(
                              labelText: 'City',
                              hintText: 'e.g. Bangalore',
                              labelStyle: AppTextStyles.caption,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _pincodeController,
                            keyboardType: TextInputType.number,
                            validator: (v) => Validators.notEmpty(v, field: 'Pincode'),
                            style: AppTextStyles.body,
                            decoration: InputDecoration(
                              labelText: 'Pincode',
                              hintText: 'e.g. 560038',
                              labelStyle: AppTextStyles.caption,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Save Address & Proceed',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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