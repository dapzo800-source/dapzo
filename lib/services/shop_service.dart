import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Loads real shop data from Firestore for Home-page shop listings.
///
/// Returns raw `Map<String, dynamic>` shop data (with the Firestore doc id
/// merged in as `'id'`) rather than a strict model, so existing screens that
/// already expect a shop `Map` (e.g. `ShopScreen`) keep working unchanged.
class ShopService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Streams active shops that serve the given [mode] ('food' | 'meat'),
  /// including shops flagged 'both'.
  Stream<List<Map<String, dynamic>>> streamShops(String mode) {
    return _db
        .collection('shops')
        .where('mode', whereIn: [mode, 'both'])
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
              .toList(),
        );
  }

  /// Straight-line distance in km between two coordinates. Used to show a
  /// live "X.X km away" chip on shop cards when the user has a selected
  /// delivery address.
  double distanceInKm(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}