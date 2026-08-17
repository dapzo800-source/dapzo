import 'package:cloud_firestore/cloud_firestore.dart';

class ShopModel {
  final String id;
  final String name;
  final String mode; // "food" | "meat" | "both"
  final double latitude;
  final double longitude;
  final double deliveryRadiusKm;
  final bool isActive;
  final String status; // "approved" | "pending" | "rejected"

  ShopModel({
    required this.id,
    required this.name,
    required this.mode,
    required this.latitude,
    required this.longitude,
    required this.deliveryRadiusKm,
    this.isActive = true,
    this.status = 'approved',
  });

  factory ShopModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ShopModel(
      id: doc.id,
      name: data['name'] ?? '',
      mode: data['mode'] ?? 'food',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      deliveryRadiusKm: (data['deliveryRadiusKm'] ?? 5).toDouble(),
      isActive: data['isActive'] ?? true,
      status: (data['status'] ?? 'approved').toString(),
    );
  }
}
