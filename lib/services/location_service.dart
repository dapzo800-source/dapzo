import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_model.dart';

/// Handles device location + delivery-zone matching (including KGF, Bangarapet, etc.).
class LocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<String> supportedDeliveryAreas = [
    'KGF (Kolar Gold Fields)',
    'Bangarapet',
    'Robertsonpet',
    'Oorgaum',
    'Marikuppam',
    'Champion Reefs',
    'Kolar',
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

  /// Asynchronously verifies whether an area or lat/lng is serviceable
  /// using Firestore `delivery_zones` collection with local fallback for KGF, Bangarapet, etc.
  Future<bool> checkServiceability({
    required String area,
    required double latitude,
    required double longitude,
  }) async {
    if (isAreaServiceable(area)) return true;

    try {
      final snap = await _db.collection('delivery_zones').where('isActive', isEqualTo: true).get();
      if (snap.docs.isEmpty) return true; // Default fallback if no explicit zones set

      for (final doc in snap.docs) {
        final data = doc.data();
        final zoneName = (data['name'] ?? data['area'] ?? '').toString().toLowerCase();
        if (area.toLowerCase().contains(zoneName) || zoneName.contains(area.toLowerCase())) {
          return true;
        }
        final zoneLat = (data['latitude'] ?? 0).toDouble();
        final zoneLng = (data['longitude'] ?? 0).toDouble();
        final radiusKm = (data['radiusKm'] ?? 10).toDouble();
        if (zoneLat != 0 && zoneLng != 0) {
          final dist = distanceInKm(latitude, longitude, zoneLat, zoneLng);
          if (dist <= radiusKm) return true;
        }
      }
    } catch (_) {}

    return isAreaServiceable(area);
  }

  /// Returns the nearest active shop that covers the given coordinates,
  /// or null if nothing is within range (i.e. "Not Available").
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
