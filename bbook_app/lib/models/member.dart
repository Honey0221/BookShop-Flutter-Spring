class Member {
  final int? id;
  final String email;
  final String? password;
  final String? nickname;
  final String? name;
  final String? phone;
  final String? address;
  final String role;
  final bool isSocialMember;
  final int point;
  final String? createdAt;
  final String? subscriptionExpiryDate;

  Member({
    this.id,
    required this.email,
    this.password,
    this.nickname,
    this.name,
    this.phone,
    this.address,
    required this.role,
    this.isSocialMember = false,
    this.point = 0,
    this.createdAt,
    this.subscriptionExpiryDate,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      email: json['email'],
      password: json['password'],
      nickname: json['nickname'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      role: json['role'],
      isSocialMember: json['isSocialMember'] ?? false,
      point: json['point'] ?? 0,
      createdAt: json['createdAt'],
      subscriptionExpiryDate: json['subscriptionExpiryDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'nickname': nickname,
      'name': name,
      'phone': phone,
      'address': address,
      'role': role,
      'isSocialMember': isSocialMember,
      'point': point,
      'createdAt': createdAt,
      'subscriptionExpiryDate': subscriptionExpiryDate,
    };
  }

  bool isSubscriber() {
    if (subscriptionExpiryDate == null) return false;
    final expiryDate = DateTime.parse(subscriptionExpiryDate!);
    return expiryDate.isAfter(DateTime.now());
  }
}