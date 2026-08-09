import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin generic wrapper around Firestore so feature services stay small.
class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      db.collection(path);

  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(
    String path,
    String id,
  ) =>
      db.collection(path).doc(id).get();

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
    String path, {
    List<
            List<Object?> // [field, operator, value] triples — kept simple
        >?
        wheres,
  }) {
    Query<Map<String, dynamic>> query = db.collection(path);
    if (wheres != null) {
      for (final w in wheres) {
        query = query.where(w[0] as String, isEqualTo: w[2]);
      }
    }
    return query.snapshots();
  }
}
