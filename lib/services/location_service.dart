import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_model.dart';

/// Handles device location + delivery-zone matching.
/// The client-side check here is for UX only — the backend (Cloud Function
/// or the order-creation transaction) MUST re-validate before accepting
/// an order, per spec section 29.
class LocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
