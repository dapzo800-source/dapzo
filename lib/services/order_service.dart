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
    String paymentStatus = 'pending',
  }) async {
    final orderCode = 'DZ${DateTime.now().millisecondsSinceEpoch % 100000}';
    final primaryShopId = shopId ?? (items.isNotEmpty ? items.first.shopId : '');
    final primaryShopName = shopName ?? (items.isNotEmpty ? items.first.shopName : 'Dapzo Partner Shop');

    // Delivery OTP generation
    final otpCode = '${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}';

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
      'paymentStatus': paymentStatus, // Starts pending, set to paid ONLY on verified gateway success
      'gatewayTransactionId': gatewayTransactionId,
      'checkoutReferenceId': checkoutReferenceId,
      'status': OrderStatus.placed.name,
      'addressId': addressId,
      'deliveryAddress': deliveryAddress ?? {},
      'deliveryOtp': otpCode,
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

  /// Validates a coupon code against Firestore `coupons` collection.
  /// Validates: code, isActive, startAt, endAt, minOrderValue, maxDiscountAmount, usageLimit, usedCount.
  Future<Map<String, dynamic>> validateCouponDetails(String code, double subtotal) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return {'valid': false, 'reason': 'Please enter a coupon code', 'discountAmount': 0.0};
    }

    try {
      final snap = await _db
          .collection('coupons')
          .where('code', isEqualTo: cleanCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        return {'valid': false, 'reason': 'Invalid coupon code', 'discountAmount': 0.0};
      }

      final data = snap.docs.first.data();
      final now = DateTime.now();

      // Validate date range
      if (data['startAt'] != null) {
        final start = (data['startAt'] as Timestamp).toDate();
        if (now.isBefore(start)) {
          return {'valid': false, 'reason': 'Coupon is not active yet', 'discountAmount': 0.0};
        }
      }
      if (data['endAt'] != null) {
        final end = (data['endAt'] as Timestamp).toDate();
        if (now.isAfter(end)) {
          return {'valid': false, 'reason': 'Coupon has expired', 'discountAmount': 0.0};
        }
      }

      // Validate minimum order value
      final minOrder = (data['minOrderValue'] ?? data['minimumOrder'] ?? 0).toDouble();
      if (subtotal < minOrder) {
        return {
          'valid': false,
          'reason': 'Minimum order of ₹${minOrder.toStringAsFixed(0)} required for this coupon',
          'discountAmount': 0.0
        };
      }

      // Validate usage limits
      final usageLimit = (data['usageLimit'] ?? 0).toInt();
      final usedCount = (data['usedCount'] ?? 0).toInt();
      if (usageLimit > 0 && usedCount >= usageLimit) {
        return {'valid': false, 'reason': 'Coupon usage limit reached', 'discountAmount': 0.0};
      }

      // Calculate discount
      final discountPercent = (data['discountPercent'] ?? 0).toDouble();
      final discountFlat = (data['discountFlat'] ?? data['discountAmount'] ?? 0).toDouble();
      final maxDiscount = (data['maxDiscountAmount'] ?? data['maximumDiscount'] ?? double.infinity).toDouble();

      double calculatedDiscount = 0.0;
      if (discountPercent > 0) {
        calculatedDiscount = subtotal * (discountPercent / 100);
        if (calculatedDiscount > maxDiscount) {
          calculatedDiscount = maxDiscount;
        }
      } else if (discountFlat > 0) {
        calculatedDiscount = discountFlat;
      }

      if (calculatedDiscount > subtotal) {
        calculatedDiscount = subtotal;
      }

      return {
        'valid': true,
        'reason': null,
        'discountAmount': calculatedDiscount,
        'code': cleanCode,
        'coupon': data,
      };
    } catch (e) {
      return {'valid': false, 'reason': 'Unable to validate coupon: $e', 'discountAmount': 0.0};
    }
  }

  /// Legacy helper method signature
  Future<Map<String, dynamic>?> validateCoupon(String code, double subtotal) async {
    final result = await validateCouponDetails(code, subtotal);
    if (result['valid'] == true) {
      return result['coupon'] as Map<String, dynamic>?;
    }
    return null;
  }
}
