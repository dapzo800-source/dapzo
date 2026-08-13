import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item_model.dart';

enum OrderStatus {
  placed,
  shopAccepted,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.shopAccepted:
        return 'Shop Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.placed,
    );
  }
}

class OrderModel {
  final String id;
  final String orderCode; // "DZ1025"
  final String userId;
  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryCharge;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod; // "cod" | "online"
  final String paymentStatus; // "pending" | "paid" | "failed"
  final OrderStatus status;
  final String addressId;
  final String? couponCode;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryCharge,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.addressId,
    this.couponCode,
    this.createdAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    return OrderModel(
      id: doc.id,
      orderCode: data['orderCode'] ?? data['orderNumber'] ?? doc.id,
      userId: data['userId'] ?? data['customerId'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => CartItemModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      deliveryCharge: (data['deliveryCharge'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      total: (data['total'] ?? data['totalAmount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'cod',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      status: OrderStatusX.fromString(data['status'] ?? 'placed'),
      addressId: data['addressId'] ?? '',
      couponCode: data['couponCode'],
      createdAt: parseDate(data['createdAt']),
    );
  }
}
