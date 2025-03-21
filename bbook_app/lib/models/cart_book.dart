import 'book.dart';

class CartBook {
  final int? id;
  final int? cartId;
  final Book? book;
  final int count;

  CartBook({
    this.id,
    this.cartId,
    this.book,
    required this.count,
  });

  factory CartBook.fromJson(Map<String, dynamic> json) {
    return CartBook(
      id: json['id'],
      cartId: json['cartId'],
      book: json['book'] != null ? Book.fromJson(json['book']) : null,
      count: json['count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cartId': cartId,
      'book': book?.toJson(),
      'count': count,
    };
  }
}