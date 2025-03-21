class Book {
  final int? id;
  final String? bookStatus;
  final int price;
  final int stock;
  final int? sales;
  final String? createdAt;
  final String author;
  final String? detailCategory;
  final String imageUrl;
  final String mainCategory;
  final String midCategory;
  final String publisher;
  final String? subCategory;
  final String title;
  final String? description;
  final int? viewCount;
  final String? trailerUrl;

  Book({
    this.id,
    this.bookStatus,
    required this.price,
    required this.stock,
    this.sales,
    this.createdAt,
    required this.author,
    this.detailCategory,
    required this.imageUrl,
    required this.mainCategory,
    required this.midCategory,
    required this.publisher,
    this.subCategory,
    required this.title,
    this.description,
    this.viewCount,
    this.trailerUrl,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      bookStatus: json['bookStatus'],
      price: json['price'],
      stock: json['stock'],
      sales: json['sales'],
      createdAt: json['createdAt'],
      author: json['author'],
      detailCategory: json['detailCategory'],
      imageUrl: json['imageUrl'],
      mainCategory: json['mainCategory'],
      midCategory: json['midCategory'],
      publisher: json['publisher'],
      subCategory: json['subCategory'],
      title: json['title'],
      description: json['description'],
      viewCount: json['viewCount'],
      trailerUrl: json['trailerUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookStatus': bookStatus,
      'price': price,
      'stock': stock,
      'sales': sales,
      'createdAt': createdAt,
      'author': author,
      'detailCategory': detailCategory,
      'imageUrl': imageUrl,
      'mainCategory': mainCategory,
      'midCategory': midCategory,
      'publisher': publisher,
      'subCategory': subCategory,
      'title': title,
      'description': description,
      'viewCount': viewCount,
      'trailerUrl': trailerUrl,
    };
  }
}