import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address_model.dart';

class AddressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _addresses(String uid) =>
      _db.collection('users').doc(uid).collection('addresses');

  Stream<List<AddressModel>> streamAddresses(String uid) {
    return _addresses(uid).snapshots().map(
          (snap) => snap.docs.map((d) => AddressModel.fromFirestore(d)).toList(),
        );
  }

  Future<void> addAddress(String uid, AddressModel address) async {
    // Use the address's own id as the Firestore document id, since the
    // caller (CheckRadiusScreen) already generates a UUID for it.
    // Using .add() here would let Firestore assign a different id,
    // leaving the in-memory AppState.selectedAddress pointing at an id
    // that doesn't match the saved document.
    await _addresses(uid).doc(address.id).set(address.toMap());
  }

  Future<void> updateAddress(String uid, AddressModel address) async {
    await _addresses(uid).doc(address.id).update(address.toMap());
  }

  Future<void> deleteAddress(String uid, String addressId) async {
    await _addresses(uid).doc(addressId).delete();
  }
}