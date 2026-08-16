import 'dart:async';
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

  /// Creates an order through the Cloudflare Worker API.
  /// If the Worker is unavailable, it falls back to direct Firestore.
  Future<String> createOrder({
    required String userId,
    required List<CartItemModel> items,
    required double subtotal,
    required double deliveryCharge,
    required double discount,
    required double tax,
    required double total,
    required String paymentMethod,
    required String addressId,
    String? shopId,
    String? shopName,
    Map<String, dynamic>? deliveryAddress,
    String? couponCode,
    String? deliveryInstructions,
    String? gatewayTransactionId,
    String? checkoutReferenceId,
    String paymentStatus = 'pending',
  }) async {
    final orderCode =
        'DZ${DateTime.now().millisecondsSinceEpoch % 100000}';

    final primaryShopId =
        (shopId != null && shopId.isNotEmpty)
            ? shopId
            : (items.isNotEmpty ? items.first.shopId : '');

    final primaryShopName =
        (shopName != null && shopName.isNotEmpty)
            ? shopName
            : (items.isNotEmpty
                ? items.first.shopName
                : 'Dapzo Partner Shop');

    final otpCode =
        '${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}';

    final orderData = <String, dynamic>{
      'orderCode': orderCode,
      'orderNumber': '#$orderCode',

      // IMPORTANT:
      // Save BOTH fields so the customer order query
      // works regardless of which field the backend uses.
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
      'paymentStatus': paymentStatus,
      'deliveryInstructions': deliveryInstructions,
      'notes': deliveryInstructions,

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

    // ------------------------------------------------------------
    // 1. Try Cloudflare Worker
    // ------------------------------------------------------------

    final apiUrl = _apiUrl;

    if (apiUrl != null &&
        apiUrl.isNotEmpty &&
        apiUrl.startsWith('http')) {
      try {
        final cleanBase = apiUrl.endsWith('/')
            ? apiUrl.substring(0, apiUrl.length - 1)
            : apiUrl;

        final workerUri =
            Uri.parse('$cleanBase/api/orders/create');

        final response = await http
            .post(
              workerUri,
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
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

                'paymentMethod': paymentMethod,
                'paymentStatus': paymentStatus,

                'gatewayTransactionId': gatewayTransactionId,
                'checkoutReferenceId': checkoutReferenceId,

                'status': OrderStatus.placed.name,

                'addressId': addressId,
                'deliveryAddress': deliveryAddress ?? {},

                'deliveryOtp': otpCode,
                'couponCode': couponCode,
              }),
            )
            .timeout(
              const Duration(seconds: 10),
            );

        if (response.statusCode == 200) {
          final responseData =
              jsonDecode(response.body) as Map<String, dynamic>;

          if (responseData['success'] == true &&
              responseData['orderId'] != null) {
            if (kDebugMode) {
              debugPrint(
                'Order created through Worker: ${responseData['orderId']}',
              );
            }

            return responseData['orderId'] as String;
          }

          if (kDebugMode) {
            debugPrint(
              'Worker order creation failed: ${response.body}',
            );
          }
        } else {
          if (kDebugMode) {
            debugPrint(
              'Worker returned ${response.statusCode}: ${response.body}',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'Worker API failed. Using Firestore fallback: $e',
          );
        }
      }
    }

    // ------------------------------------------------------------
    // 2. Direct Firestore fallback
    // ------------------------------------------------------------

    try {
      final docRef =
          await _db.collection('orders').add(orderData);

      if (kDebugMode) {
        debugPrint(
          'Order created directly in Firestore: ${docRef.id}',
        );
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Firestore add failed. Retrying with orderCode: $e',
        );
      }

      final fallbackRef =
          _db.collection('orders').doc(orderCode);

      await fallbackRef.set(orderData);

      return fallbackRef.id;
    }
  }

  // ----------------------------------------------------------------
  // USER ORDERS
  // ----------------------------------------------------------------

  /// Streams all orders belonging to the current customer.
  ///
  /// Searches BOTH:
  ///   userId
  ///   customerId
  ///
  /// This prevents orders from disappearing when the backend
  /// uses customerId instead of userId.
  Stream<List<OrderModel>> streamUserOrders(
    String userId, {
    String? statusFilter,
  }) {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      return Stream.value(<OrderModel>[]);
    }

    // Use a StreamController to merge two Firestore streams:
    // one by 'userId' and one by 'customerId'.
    // Both are kept in sync; each update from either triggers a merged emit.
    final controller = StreamController<List<OrderModel>>();

    List<OrderModel> byUserIdList = [];
    List<OrderModel> byCustomerIdList = [];

    void emit() {
      if (controller.isClosed) return;
      final seen = <String>{};
      final merged = <OrderModel>[];
      for (final o in [...byUserIdList, ...byCustomerIdList]) {
        if (seen.add(o.id)) merged.add(o);
      }
      merged.sort((a, b) {
        final dateA =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      controller.add(merged);
    }

    final sub1 = _db
        .collection('orders')
        .where('userId', isEqualTo: cleanUserId)
        .snapshots()
        .listen(
      (snap) {
        byUserIdList = _parseDocs(snap.docs, statusFilter);
        emit();
      },
      onError: (e) {
        if (kDebugMode) debugPrint('streamUserOrders userId stream error: $e');
      },
    );

    final sub2 = _db
        .collection('orders')
        .where('customerId', isEqualTo: cleanUserId)
        .snapshots()
        .listen(
      (snap) {
        byCustomerIdList = _parseDocs(snap.docs, statusFilter);
        emit();
      },
      onError: (e) {
        if (kDebugMode) debugPrint('streamUserOrders customerId stream error: $e');
      },
    );

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    return controller.stream;
  }

  List<OrderModel> _parseDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String? statusFilter,
  ) {
    final orders = <OrderModel>[];
    for (final doc in docs) {
      try {
        final order = OrderModel.fromFirestore(doc);
        if (statusFilter == null || order.status.name == statusFilter) {
          orders.add(order);
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('Failed to parse order ${doc.id}: $e');
          debugPrint('$stackTrace');
        }
      }
    }
    return orders;
  }

  // ----------------------------------------------------------------
  // SINGLE ORDER
  // ----------------------------------------------------------------

  Stream<OrderModel> streamOrder(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map(
          (doc) => OrderModel.fromFirestore(doc),
        );
  }

  // ----------------------------------------------------------------
  // CANCEL ORDER
  // ----------------------------------------------------------------

  /// Cancels an order by updating its status to 'cancelled' in Firestore.
  /// Only call this when the order status is still `placed` or `shopAccepted`.
  Future<void> cancelOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'status': OrderStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ----------------------------------------------------------------
  // COUPONS
  // ----------------------------------------------------------------

  Future<Map<String, dynamic>> validateCouponDetails(
    String code,
    double subtotal,
  ) async {
    final cleanCode = code.trim().toUpperCase();

    if (cleanCode.isEmpty) {
      return {
        'valid': false,
        'reason': 'Please enter a coupon code',
        'discountAmount': 0.0,
      };
    }

    try {
      final snap = await _db
          .collection('coupons')
          .where(
            'code',
            isEqualTo: cleanCode,
          )
          .where(
            'isActive',
            isEqualTo: true,
          )
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        return {
          'valid': false,
          'reason': 'Invalid coupon code',
          'discountAmount': 0.0,
        };
      }

      final data = snap.docs.first.data();

      final now = DateTime.now();

      if (data['startAt'] != null) {
        final start =
            (data['startAt'] as Timestamp).toDate();

        if (now.isBefore(start)) {
          return {
            'valid': false,
            'reason': 'Coupon is not active yet',
            'discountAmount': 0.0,
          };
        }
      }

      if (data['endAt'] != null) {
        final end =
            (data['endAt'] as Timestamp).toDate();

        if (now.isAfter(end)) {
          return {
            'valid': false,
            'reason': 'Coupon has expired',
            'discountAmount': 0.0,
          };
        }
      }

      final minOrder =
          (data['minOrderValue'] ??
                  data['minimumOrder'] ??
                  0)
              .toDouble();

      if (subtotal < minOrder) {
        return {
          'valid': false,
          'reason':
              'Minimum order of ₹${minOrder.toStringAsFixed(0)} required for this coupon',
          'discountAmount': 0.0,
        };
      }

      final usageLimit =
          (data['usageLimit'] ?? 0).toInt();

      final usedCount =
          (data['usedCount'] ?? 0).toInt();

      if (usageLimit > 0 &&
          usedCount >= usageLimit) {
        return {
          'valid': false,
          'reason': 'Coupon usage limit reached',
          'discountAmount': 0.0,
        };
      }

      final discountPercent =
          (data['discountPercent'] ?? 0).toDouble();

      final discountFlat =
          (data['discountFlat'] ??
                  data['discountAmount'] ??
                  0)
              .toDouble();

      final maxDiscount =
          (data['maxDiscountAmount'] ??
                  data['maximumDiscount'] ??
                  double.infinity)
              .toDouble();

      double calculatedDiscount = 0.0;

      if (discountPercent > 0) {
        calculatedDiscount =
            subtotal * (discountPercent / 100);

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
      return {
        'valid': false,
        'reason':
            'Unable to validate coupon: $e',
        'discountAmount': 0.0,
      };
    }
  }

  Future<Map<String, dynamic>?> validateCoupon(
    String code,
    double subtotal,
  ) async {
    final result =
        await validateCouponDetails(code, subtotal);

    if (result['valid'] == true) {
      return result['coupon']
          as Map<String, dynamic>?;
    }

    return null;
  }
}