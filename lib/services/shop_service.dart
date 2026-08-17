import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Loads real shop data from Firestore for Home-page shop listings with delivery radius filtering.
class ShopService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Streams active approved shops that serve the given [mode] ('food' | 'meat')
  /// and cover the customer's delivery coordinates within the shop's delivery radius.
  Stream<List<Map<String, dynamic>>> streamShops(
    String mode, {
    double? customerLat,
    double? customerLng,
  }) {
    return _db
        .collection('shops')
        .where('mode', whereIn: [mode, 'both'])
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final eligibleShops = <Map<String, dynamic>>[];

      for (final d in snap.docs) {
        final data = <String, dynamic>{'id': d.id, ...d.data()};

        // Filter for approved shops
        final status = (data['status'] ?? 'approved').toString().toLowerCase();
        if (status != 'approved') continue;

        if (customerLat != null &&
            customerLng != null &&
            customerLat != 0.0 &&
            customerLng != 0.0) {
          final shopLat = (data['latitude'] ?? data['lat'] ?? 0.0).toDouble();
          final shopLng = (data['longitude'] ?? data['lng'] ?? 0.0).toDouble();
          final radiusKm =
              (data['deliveryRadiusKm'] ?? data['radiusKm'] ?? 10.0).toDouble();

          if (shopLat != 0.0 && shopLng != 0.0) {
            final dist = distanceInKm(customerLat, customerLng, shopLat, shopLng);
            data['distanceToCustomer'] = dist;

            // Only add shop if customer is within the permitted delivery radius
            if (dist <= radiusKm) {
              eligibleShops.add(data);
            }
          } else {
            eligibleShops.add(data);
          }
        } else {
          eligibleShops.add(data);
        }
      }

      // Sort by closest distance if distance available
      eligibleShops.sort((a, b) {
        final distA = (a['distanceToCustomer'] as num?)?.toDouble() ?? 999.0;
        final distB = (b['distanceToCustomer'] as num?)?.toDouble() ?? 999.0;
        return distA.compareTo(distB);
      });

      return eligibleShops;
    });
  }

  /// Straight-line distance in km between two coordinates.
  double distanceInKm(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}