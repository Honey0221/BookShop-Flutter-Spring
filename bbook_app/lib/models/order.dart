import 'order_book.dart';

class Order {
  final int? id;
  final int? memberId;
  final String orderDate;
  final String orderStatus;
  final List<OrderBook> orderBooks;
  final String? merchantUid;
  final String? impUid;
  final String? cancelledAt;
  final int? originalPrice;
  final int? shippingFee;
  final int? totalPrice;
  final int? usedPoints;
  final int? earnedPoints;
  final int? discountAmount;
  final bool? isCouponUsed;

  Order({
    this.id,
    this.memberId,
    required this.orderDate,
    required this.orderStatus,
    this.orderBooks = const [],
    this.merchantUid,
    this.impUid,
    this.cancelledAt,
    this.originalPrice,
    this.shippingFee,
    this.totalPrice,
    this.usedPoints,
    this.earnedPoints,
    this.discountAmount,
    this.isCouponUsed,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderBook> orderBooks = [];
    if (json['orderBooks'] != null) {
      orderBooks = (json['orderBooks'] as List)
          .map((item) => OrderBook.fromJson(item))
          .toList();
    }

    return Order(
      id: json['id'],
      memberId: json['memberId'],
      orderDate: json['orderDate'],
      orderStatus: json['orderStatus'],
      orderBooks: orderBooks,
      merchantUid: json['merchantUid'],
      impUid: json['impUid'],
      cancelledAt: json['cancelledAt'],
      originalPrice: json['originalPrice'],
      shippingFee: json['shippingFee'],
      totalPrice: json['totalPrice'],
      usedPoints: json['usedPoints'],
      earnedPoints: json['earnedPoints'],
      discountAmount: json['discountAmount'],
      isCouponUsed: json['isCouponUsed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'orderDate': orderDate,
      'orderStatus': orderStatus,
      'orderBooks': orderBooks.map((book) => book.toJson()).toList(),
      'merchantUid': merchantUid,
      'impUid': impUid,
      'cancelledAt': cancelledAt,
      'originalPrice': originalPrice,
      'shippingFee': shippingFee,
      'totalPrice': totalPrice,
      'usedPoints': usedPoints,
      'earnedPoints': earnedPoints,
      'discountAmount': discountAmount,
      'isCouponUsed': isCouponUsed,
    };
  }
}