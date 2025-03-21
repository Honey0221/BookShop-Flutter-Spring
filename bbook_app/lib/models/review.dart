class Review {
  final int? id;
  final int memberId;
  final int bookId;
  final int rating;
  final String? content;
  final List<String> images;
  final String? tagType;
  final int likeCount;
  final String createdAt;
  final bool blocked;
  final bool flagged;

  Review({
    this.id,
    required this.memberId,
    required this.bookId,
    required this.rating,
    this.content,
    this.images = const [],
    this.tagType,
    this.likeCount = 0,
    required this.createdAt,
    this.blocked = false,
    this.flagged = false,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['images'] != null) {
      images = List<String>.from(json['images']);
    }

    return Review(
      id: json['id'],
      memberId: json['memberId'],
      bookId: json['bookId'],
      rating: json['rating'],
      content: json['content'],
      images: images,
      tagType: json['tagType'],
      likeCount: json['likeCount'] ?? 0,
      createdAt: json['createdAt'],
      blocked: json['blocked'] ?? false,
      flagged: json['flagged'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'bookId': bookId,
      'rating': rating,
      'content': content,
      'images': images,
      'tagType': tagType,
      'likeCount': likeCount,
      'createdAt': createdAt,
      'blocked': blocked,
      'flagged': flagged,
    };
  }

  String getDisplayContent() {
    if (blocked) {
      return "클린봇에 의해 차단되었습니다.";
    }
    return content ?? "";
  }
}