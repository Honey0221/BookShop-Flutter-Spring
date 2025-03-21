class WishBook {
  final int? id;
  final int memberId;
  final int bookId;

  WishBook({
    this.id,
    required this.memberId,
    required this.bookId,
  });

  factory WishBook.fromJson(Map<String, dynamic> json) {
    return WishBook(
      id: json['id'],
      memberId: json['memberId'],
      bookId: json['bookId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'bookId': bookId,
    };
  }
}