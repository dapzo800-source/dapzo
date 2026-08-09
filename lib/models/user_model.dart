import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phone;
  final String name;
  final String email;
  final DateTime? dateOfBirth;
  final String profileImage;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.phone,
    this.name = '',
    this.email = '',
    this.dateOfBirth,
    this.profileImage = '',
    this.role = 'customer',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      phone: data['phone'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      profileImage: data['profileImage'] ?? '',
      role: data['role'] ?? 'customer',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'phone': phone,
        'name': name,
        'email': email,
        'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
        'profileImage': profileImage,
        'role': role,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
