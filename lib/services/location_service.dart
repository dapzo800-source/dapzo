import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_model.dart';

class ServiceabilityInfo {
  final bool isServiceable;
  final String? zoneName;
  final String? taluk;
  final double deliveryFee;

  ServiceabilityInfo({
    required this.isServiceable,
    this.zoneName,
    this.taluk,
    this.deliveryFee = 30.0,
  });
}

/// Handles device location + master locations & delivery-zone matching (KGF, Malur, Bangarapet, Kolar, etc.).
class LocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<String> supportedDeliveryAreas = [
    'KGF',
    'Kolar Gold Fields',
    'Malur',
    'Bangarapet',
    'Robertsonpet',
    'Oorgaum',
    'Marikuppam',
    'Champion Reefs',
    'Kolar',
    'Mulbagal',
    'Srinivaspur',
  ];

  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  double distanceInKm(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  bool isAreaServiceable(String areaName) {
    if (areaName.trim().isEmpty) return false;
    final lower = areaName.toLowerCase();
    return supportedDeliveryAreas.any(
      (area) => area.toLowerCase().contains(lower) || lower.contains(area.toLowerCase().split(' ')[0]),
    );
  }

  /// Real-time listener for delivery partner location from `delivery_locations` collection.
  Stream<Map<String, dynamic>?> streamDeliveryPartnerLocation(String deliveryPartnerId) {
    if (deliveryPartnerId.isEmpty) return Stream.value(null);
    return _db
        .collection('delivery_locations')
        .doc(deliveryPartnerId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  /// Asynchronously verifies whether an area or lat/lng is inside an active Dabzo service zone
  /// by querying `master_locations` and `delivery_zones`.
  Future<ServiceabilityInfo> checkServiceabilityDetailed({
    String area = '',
    String city = '',
    required double latitude,
    required double longitude,
  }) async {
    // 1. Check master_locations
    try {
      final snap = await _db.collection('master_locations').where('isActive', isEqualTo: true).get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final taluk = (data['taluk'] ?? data['city'] ?? '').toString();
        final locArea = (data['area'] ?? '').toString();
        final fee = (data['deliveryFee'] ?? 30.0).toDouble();
        final radius = (data['defaultRadiusKm'] ?? data['radiusKm'] ?? 10.0).toDouble();
        final locLat = (data['latitude'] ?? 0.0).toDouble();
        final locLng = (data['longitude'] ?? 0.0).toDouble();

        // Match by text
        if (area.isNotEmpty && (area.toLowerCase().contains(locArea.toLowerCase()) || locArea.toLowerCase().contains(area.toLowerCase()))) {
          return ServiceabilityInfo(isServiceable: true, zoneName: locArea, taluk: taluk, deliveryFee: fee);
        }
        if (city.isNotEmpty && (city.toLowerCase().contains(taluk.toLowerCase()) || taluk.toLowerCase().contains(city.toLowerCase()))) {
          return ServiceabilityInfo(isServiceable: true, zoneName: locArea, taluk: taluk, deliveryFee: fee);
        }

        // Match by GPS distance
        if (locLat != 0.0 && locLng != 0.0 && latitude != 0.0 && longitude != 0.0) {
          final dist = distanceInKm(latitude, longitude, locLat, locLng);
          if (dist <= radius) {
            return ServiceabilityInfo(isServiceable: true, zoneName: locArea, taluk: taluk, deliveryFee: fee);
          }
        }
      }
    } catch (_) {}

    // 2. Check delivery_zones
    try {
      final snap = await _db.collection('delivery_zones').where('isActive', isEqualTo: true).get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final zoneName = (data['name'] ?? data['area'] ?? '').toString();
        final cityVal = (data['city'] ?? '').toString();
        final fee = (data['deliveryFee'] ?? 30.0).toDouble();
        final radius = (data['radiusKm'] ?? 10.0).toDouble();
        final zoneLat = (data['latitude'] ?? 0.0).toDouble();
        final zoneLng = (data['longitude'] ?? 0.0).toDouble();

        if (area.isNotEmpty && zoneName.toLowerCase().contains(area.toLowerCase())) {
          return ServiceabilityInfo(isServiceable: true, zoneName: zoneName, taluk: cityVal, deliveryFee: fee);
        }
        if (zoneLat != 0.0 && zoneLng != 0.0 && latitude != 0.0 && longitude != 0.0) {
          final dist = distanceInKm(latitude, longitude, zoneLat, zoneLng);
          if (dist <= radius) {
            return ServiceabilityInfo(isServiceable: true, zoneName: zoneName, taluk: cityVal, deliveryFee: fee);
          }
        }
      }
    } catch (_) {}

    final bool fallback = isAreaServiceable(area) || isAreaServiceable(city);
    return ServiceabilityInfo(isServiceable: fallback, zoneName: area.isNotEmpty ? area : city);
  }

  Future<bool> checkServiceability({
    String area = '',
    required double latitude,
    required double longitude,
  }) async {
    final info = await checkServiceabilityDetailed(
      area: area,
      latitude: latitude,
      longitude: longitude,
    );
    return info.isServiceable;
  }

  /// Returns the nearest active shop that covers the given coordinates,
  /// or null if nothing is within range.
  Future<ShopModel?> findServingShop({
    required double latitude,
    required double longitude,
    String? mode,
  }) async {
    Query<Map<String, dynamic>> query =
        _db.collection('shops').where('isActive', isEqualTo: true);
    if (mode != null) {
      query = query.where('mode', whereIn: [mode, 'both']);
    }

    final snap = await query.get();
    ShopModel? nearest;
    double nearestDistance = double.infinity;

    for (final doc in snap.docs) {
      final shop = ShopModel.fromFirestore(doc);
      if (shop.status != 'approved') continue;
      final distance =
          distanceInKm(latitude, longitude, shop.latitude, shop.longitude);
      if (distance <= shop.deliveryRadiusKm && distance < nearestDistance) {
        nearest = shop;
        nearestDistance = distance;
      }
    }
    return nearest;
  }
}
