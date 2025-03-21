import 'book.dart';

class OrderBook {
  final int? id;
  final Book? book;
  final int? orderId;
  final int orderPrice;
  final int count;

  OrderBook({
    this.id,
    this.book,
    this.orderId,
    required this.orderPrice,
    required this.count,
  });

  factory OrderBook.fromJson(Map<String, dynamic> json) {
    return OrderBook(
      id: json['id'],
      book: json['book'] != null ? Book.fromJson(json['book']) : null,
      orderId: json['orderId'],
      orderPrice: json['orderPrice'],
      count: json['count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book': book?.toJson(),
      'orderId': orderId,
      'orderPrice': orderPrice,
      'count': count,
    };
  }

  int getTotalPrice() {
    return orderPrice * count;
  }
}