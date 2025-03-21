import 'cart_book.dart';

class Cart {
  final int? id;
  final int? memberId;
  final List<CartBook> cartBooks;

  Cart({
    this.id,
    this.memberId,
    this.cartBooks = const [],
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    List<CartBook> cartBooks = [];
    if (json['cartBooks'] != null) {
      cartBooks = (json['cartBooks'] as List)
          .map((item) => CartBook.fromJson(item))
          .toList();
    }

    return Cart(
      id: json['id'],
      memberId: json['memberId'],
      cartBooks: cartBooks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'cartBooks': cartBooks.map((book) => book.toJson()).toList(),
    };
  }
}