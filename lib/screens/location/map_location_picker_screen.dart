import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/address_model.dart';
import '../../services/location_service.dart';
import '../../services/address_service.dart';
import '../../state/app_state.dart';

class MapLocationPickerScreen extends StatefulWidget {
  final AddressModel? initialAddress;

  const MapLocationPickerScreen({super.key, this.initialAddress});

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final AddressService _addressService = AddressService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();

  late LatLng _currentCenter;
  double _currentZoom = 15.0;
  bool _isGeocoding = false;
  bool _isServiceable = true;
  String _serviceZoneName = '';
  String _formattedAddress = 'Loading location details...';
  String _detectedArea = '';
  String _detectedCity = '';
  String _detectedPincode = '';
  String _selectedLabel = 'Home';

  Timer? _debounceTimer;

  // Key Dabzo service areas & major cities
  final List<Map<String, dynamic>> _quickCities = [
    {'name': 'Malur', 'lat': 13.0038, 'lng': 77.9407, 'taluk': 'Malur'},
    {'name': 'KGF / Robertsonpet', 'lat': 12.9592, 'lng': 78.2720, 'taluk': 'Kolar Gold Fields'},
    {'name': 'Bangarapet', 'lat': 12.9818, 'lng': 78.2045, 'taluk': 'Bangarapet'},
    {'name': 'Kolar', 'lat': 13.1367, 'lng': 78.1292, 'taluk': 'Kolar'},
    {'name': 'Bangalore', 'lat': 12.9716, 'lng': 77.5946, 'taluk': 'Bangalore Urban'},
    {'name': 'Chennai', 'lat': 13.0827, 'lng': 80.2707, 'taluk': 'Chennai'},
  ];

  @override
  void initState() {
    super.initState();
    final initialLat = widget.initialAddress?.latitude ?? 13.0038;
    final initialLng = widget.initialAddress?.longitude ?? 77.9407;
    _currentCenter = LatLng(initialLat, initialLng);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _receiverNameController.text = user.displayName ?? '';
      _receiverPhoneController.text = user.phoneNumber ?? '';
    }

    _reverseGeocodeAndCheck(_currentCenter.latitude, _currentCenter.longitude);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _houseNoController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    super.dispose();
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      _currentCenter = camera.center;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 600), () {
        _reverseGeocodeAndCheck(_currentCenter.latitude, _currentCenter.longitude);
      });
    }
  }

  Future<void> _reverseGeocodeAndCheck(double lat, double lng) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);

    try {
      String area = '';
      String city = '';
      String pincode = '';
      String fullAddress = '';

      try {
        final placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          area = place.subLocality?.isNotEmpty == true
              ? place.subLocality!
              : (place.locality ?? place.subAdministrativeArea ?? '');
          city = place.locality?.isNotEmpty == true
              ? place.locality!
              : (place.administrativeArea ?? 'Karnataka');
          pincode = place.postalCode ?? '';

          final street = place.street ?? place.name ?? '';
          fullAddress = [
            if (street.isNotEmpty) street,
            if (area.isNotEmpty) area,
            if (city.isNotEmpty) city,
            if (pincode.isNotEmpty) pincode,
          ].join(', ');
        }
      } catch (e) {
        debugPrint('Geocoding notice: $e');
      }

      if (fullAddress.isEmpty) {
        fullAddress = 'Pinned Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
        area = 'Selected Area';
        city = 'Service Hub';
      }

      // Check serviceability
      final serviceInfo = await _locationService.checkServiceabilityDetailed(
        area: area,
        city: city,
        latitude: lat,
        longitude: lng,
      );

      if (!mounted) return;
      setState(() {
        _formattedAddress = fullAddress;
        _detectedArea = area;
        _detectedCity = city;
        _detectedPincode = pincode;
        _isServiceable = serviceInfo.isServiceable;
        _serviceZoneName = serviceInfo.zoneName ?? area;
        _isGeocoding = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGeocoding = false);
    }
  }

  Future<void> _searchLocation(String query) async {
    final text = query.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();

    // Check quick presets first
    for (final city in _quickCities) {
      if (city['name'].toString().toLowerCase().contains(text.toLowerCase()) ||
          city['taluk'].toString().toLowerCase().contains(text.toLowerCase())) {
        _moveToLocation(city['lat'] as double, city['lng'] as double);
        return;
      }
    }

    try {
      final locations = await locationFromAddress(text);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        _moveToLocation(loc.latitude, loc.longitude);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location not found. Try searching for city or area name.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _moveToLocation(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 15.5);
    _currentCenter = LatLng(lat, lng);
    _reverseGeocodeAndCheck(lat, lng);
  }

  Future<void> _useGps() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      _moveToLocation(pos.latitude, pos.longitude);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _confirmAndSaveAddress() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final addressText = _houseNoController.text.trim().isNotEmpty
        ? '${_houseNoController.text.trim()}, $_formattedAddress'
        : _formattedAddress;

    final addressModel = AddressModel(
      id: widget.initialAddress?.id ?? const Uuid().v4(),
      label: _selectedLabel,
      name: _receiverNameController.text.trim().isNotEmpty
          ? _receiverNameController.text.trim()
          : (FirebaseAuth.instance.currentUser?.displayName ?? 'Customer'),
      phone: _receiverPhoneController.text.trim().isNotEmpty
          ? _receiverPhoneController.text.trim()
          : (FirebaseAuth.instance.currentUser?.phoneNumber ?? ''),
      address: addressText,
      area: _detectedArea.isNotEmpty ? _detectedArea : 'Service Area',
      city: _detectedCity.isNotEmpty ? _detectedCity : 'Dabzo Hub',
      pincode: _detectedPincode,
      latitude: _currentCenter.latitude,
      longitude: _currentCenter.longitude,
      isDefault: true,
    );

    if (uid != null) {
      try {
        await _addressService.addAddress(uid, addressModel);
      } catch (e) {
        debugPrint('Address save warning: $e');
      }
    }

    if (!mounted) return;
    context.read<AppState>().setSelectedAddress(addressModel);

    Navigator.of(context).pop(addressModel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Map View ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: _currentZoom,
              onPositionChanged: _onMapPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dapzo.customer',
              ),
            ],
          ),

          // ── Center Pin Marker (Fixed on screen center) ──
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40), // Offset for pin point
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isServiceable ? AppColors.success : AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _isServiceable ? 'Deliver here' : 'Service unavailable',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.location_pin,
                    size: 46,
                    color: AppColors.primary,
                  ),
                  Container(
                    width: 10,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Top Bar with Search & Presets ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: _searchLocation,
                            decoration: InputDecoration(
                              hintText: 'Search city, area, or address...',
                              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => _searchController.clear(),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                          tooltip: 'Current GPS',
                          onPressed: _useGps,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Quick Taluk / Hub Selector Chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickCities.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final hub = _quickCities[index];
                        return GestureDetector(
                          onTap: () => _moveToLocation(hub['lat'] as double, hub['lng'] as double),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.near_me_rounded, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  hub['name'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Address Confirmation Card ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Serviceability Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (_isServiceable ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isServiceable ? Icons.verified_rounded : Icons.info_outline_rounded,
                          size: 16,
                          color: _isServiceable ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isServiceable
                                ? 'Dapzo Delivery is Active in $_serviceZoneName'
                                : 'Delivery is currently not available in this location',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _isServiceable ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Selected Address Preview
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _detectedArea.isNotEmpty ? _detectedArea : 'Pinned Location',
                              style: AppTextStyles.heading.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isGeocoding ? 'Resolving street address...' : _formattedAddress,
                              style: AppTextStyles.supporting.copyWith(fontSize: 12.5),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // House / Flat optional input
                  TextField(
                    controller: _houseNoController,
                    decoration: InputDecoration(
                      hintText: 'House / Flat / Floor / Building (Optional)',
                      hintStyle: const TextStyle(fontSize: 12.5),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Address label chips (Home, Work, Other)
                  Row(
                    children: ['Home', 'Work', 'Other'].map((lbl) {
                      final isSelected = _selectedLabel == lbl;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(lbl),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _selectedLabel = lbl),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Confirm & Proceed Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _confirmAndSaveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _isServiceable ? 'Confirm Location & Deliver Here' : 'Save Address for Later',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
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
}
