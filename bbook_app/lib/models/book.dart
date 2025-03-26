class Book {
  final int? id;
  final String? bookStatus;
  final int? price;
  final int? stock;
  final int? sales;
  final String? createdAt;
  final String? author;
  final String? detailCategory;
  final String? imageUrl;
  final String? mainCategory;
  final String? midCategory;
  final String? publisher;
  final String? subCategory;
  final String? title;
  final String? description;
  final int? viewCount;

  Book({
    this.id,
    this.bookStatus,
    this.price,
    this.stock,
    this.sales,
    this.createdAt,
    this.author,
    this.detailCategory,
    this.imageUrl,
    this.mainCategory,
    this.midCategory,
    this.publisher,
    this.subCategory,
    this.title,
    this.description,
    this.viewCount,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final bookId = json['id'] ?? json['bookId'];
    
    return Book(
      id: bookId,
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
    };
  }
}