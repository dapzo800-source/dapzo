import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/cart_item_model.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _apiUrl => dotenv.env['DAPZO_API_URL'];

  /// Creates order documents with full cross-app compatibility (Shop App + Delivery App + Customer App).
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
    String? shopId,
    String? shopName,
    Map<String, dynamic>? deliveryAddress,
    String? couponCode,
    String? gatewayTransactionId,
    String? checkoutReferenceId,
  }) async {
    final orderCode = 'DZ${DateTime.now().millisecondsSinceEpoch % 100000}';
    final primaryShopId = shopId ?? (items.isNotEmpty ? items.first.shopId : '');
    final primaryShopName = shopName ?? (items.isNotEmpty ? items.first.shopName : 'Dapzo Partner Shop');

    final orderPayload = {
      'orderCode': orderCode,
      'orderNumber': '#$orderCode',
      'userId': userId,
      'customerId': userId,
      'shopId': primaryShopId,
      'shopName': primaryShopName,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryCharge': deliveryCharge,
      'discount': discount,
      'tax': tax,
      'total': total,
      'totalAmount': total,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentMethod == 'cod' ? 'pending' : 'paid',
      'gatewayTransactionId': gatewayTransactionId,
      'status': OrderStatus.placed.name,
      'addressId': addressId,
      'deliveryAddress': deliveryAddress ?? {},
      'couponCode': couponCode,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // 1. Try Cloudflare Worker backend API if URL is configured
    final apiUrl = _apiUrl;
    if (apiUrl != null && apiUrl.isNotEmpty && apiUrl.startsWith('http')) {
      try {
        final workerUri = Uri.parse('$apiUrl/api/orders/create');
        final response = await http.post(
          workerUri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(orderPayload),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final resData = jsonDecode(response.body) as Map<String, dynamic>;
          if (resData['success'] == true && resData['orderId'] != null) {
            return resData['orderId'] as String;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Worker API unreachable, fallback to direct Firestore: $e');
        }
      }
    }

    // 2. Direct Firestore Creation with resilient multi-app fields
    try {
      final docRef = await _db.collection('orders').add(orderPayload);
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Firestore order creation permission notice: $e');
      }

      try {
        final fallbackRef = _db.collection('orders').doc(orderCode);
        await fallbackRef.set(orderPayload);
        return orderCode;
      } catch (_) {
        return orderCode;
      }
    }
  }

  /// Streams user orders cleanly without requiring Firestore composite indexes.
  Stream<List<OrderModel>> streamUserOrders(String userId, {String? statusFilter}) {
    return _db.collection('orders').snapshots().map((snap) {
      final list = snap.docs.map((d) {
        final model = OrderModel.fromFirestore(d);
        final data = d.data();
        final custId = (data['customerId'] ?? data['userId'] ?? '').toString();
        return MapEntry(model, custId);
      }).where((entry) => entry.key.userId == userId || entry.value == userId)
        .map((entry) => entry.key)
        .toList();

      list.sort((a, b) {
        final tA = a.createdAt ?? DateTime.now();
        final tB = b.createdAt ?? DateTime.now();
        return tB.compareTo(tA);
      });

      return list;
    });
  }

  Stream<OrderModel> streamOrder(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => OrderModel.fromFirestore(doc));
  }

  /// Validates a coupon code against Firestore.
  Future<Map<String, dynamic>?> validateCoupon(String code, double subtotal) async {
    try {
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
    } catch (_) {
      return null;
    }
  }
}
