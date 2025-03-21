class Subscription {
  final int? id;
  final int? memberId;
  final String type;
  final String startDate;
  final String endDate;
  final int price;
  final bool isActive;
  final String? merchantUid;
  final String? impUid;
  final String? customerUid;
  final String? nextPaymentDate;

  Subscription({
    this.id,
    this.memberId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.price,
    this.isActive = true,
    this.merchantUid,
    this.impUid,
    this.customerUid,
    this.nextPaymentDate,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      memberId: json['memberId'],
      type: json['type'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      price: json['price'],
      isActive: json['isActive'] ?? true,
      merchantUid: json['merchantUid'],
      impUid: json['impUid'],
      customerUid: json['customerUid'],
      nextPaymentDate: json['nextPaymentDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'type': type,
      'startDate': startDate,
      'endDate': endDate,
      'price': price,
      'isActive': isActive,
      'merchantUid': merchantUid,
      'impUid': impUid,
      'customerUid': customerUid,
      'nextPaymentDate': nextPaymentDate,
    };
  }

  bool isValid() {
    if (!isActive) return false;
    final expiry = DateTime.parse(endDate);
    return expiry.isAfter(DateTime.now());
  }
}