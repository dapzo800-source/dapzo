import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String label; // "Home" | "Work" | "Other"
  final String name;
  final String phone;
  final String address;
  final String area;
  final String city;
  final String pincode;
  final double latitude;
  final double longitude;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.address,
    required this.area,
    required this.city,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });

  factory AddressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AddressModel(
      id: doc.id,
      label: data['label'] ?? 'Home',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      area: data['area'] ?? '',
      city: data['city'] ?? '',
      pincode: data['pincode'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'name': name,
        'phone': phone,
        'address': address,
        'area': area,
        'city': city,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      };
}
