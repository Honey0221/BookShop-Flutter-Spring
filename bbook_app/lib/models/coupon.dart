class Coupon {
  final int? id;
  final int? memberId;
  final int discountAmount;
  final int amount;
  final bool isUsed;
  final int minimumOrderAmount;
  final int? templateId;
  final String expirationDate;
  final String couponType;

  Coupon({
    this.id,
    this.memberId,
    required this.discountAmount,
    required this.amount,
    this.isUsed = false,
    required this.minimumOrderAmount,
    this.templateId,
    required this.expirationDate,
    required this.couponType,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'],
      memberId: json['memberId'],
      discountAmount: json['discountAmount'],
      amount: json['amount'],
      isUsed: json['isUsed'] ?? false,
      minimumOrderAmount: json['minimumOrderAmount'],
      templateId: json['templateId'],
      expirationDate: json['expirationDate'],
      couponType: json['couponType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'discountAmount': discountAmount,
      'amount': amount,
      'isUsed': isUsed,
      'minimumOrderAmount': minimumOrderAmount,
      'templateId': templateId,
      'expirationDate': expirationDate,
      'couponType': couponType,
    };
  }

  bool isDownloaded() {
    return memberId != null;
  }

  bool isExpired() {
    final expiry = DateTime.parse(expirationDate);
    return expiry.isBefore(DateTime.now());
  }
}