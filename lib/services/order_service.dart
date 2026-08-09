import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Creates the order document. Delivery-radius and price validation
  /// MUST be re-checked server-side (Cloud Function trigger on create,
  /// or an onCall function invoked here) before the order is confirmed —
  /// this client call alone should not be treated as authoritative.
  Future<String> createOrder({
    required String userId,
    required List<CartItemModel> items,
    required double subtotal,
    required double deliveryCharge,
    required double discount,
    required double tax,
    required double total,
    required String paymentMethod, // 'cod' | 'online'
    required String addressId,
    String? couponCode,
    String? gatewayTransactionId,
  }) async {
    final orderCode = 'DZ${DateTime.now().millisecondsSinceEpoch % 100000}';

    final docRef = await _db.collection('orders').add({
      'orderCode': orderCode,
      'userId': userId,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryCharge': deliveryCharge,
      'discount': discount,
      'tax': tax,
      'total': total,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentMethod == 'cod' ? 'pending' : 'paid',
      'gatewayTransactionId': gatewayTransactionId,
      'status': OrderStatus.placed.name,
      'addressId': addressId,
      'couponCode': couponCode,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Stream<List<OrderModel>> streamUserOrders(String userId, {String? statusFilter}) {
    Query<Map<String, dynamic>> query = _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    return query.snapshots().map(
          (snap) => snap.docs.map((d) => OrderModel.fromFirestore(d)).toList(),
        );
  }

  Stream<OrderModel> streamOrder(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => OrderModel.fromFirestore(doc));
  }

  /// Validates a coupon code against Firestore. Discount logic lives
  /// server-side in a real deployment; this reads the coupon doc for
  /// display + a client-side estimate only.
  Future<Map<String, dynamic>?> validateCoupon(String code, double subtotal) async {
    final snap = await _db
        .collection('coupons')
        .where('code', isEqualTo: code.toUpperCase())
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();

    final minOrder = (data['minOrderValue'] ?? 0).toDouble();
    if (subtotal < minOrder) return null;

    return data;
  }
}
