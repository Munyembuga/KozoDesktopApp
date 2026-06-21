class PaymentCode {
  final int id;
  final String name;
  final String code;

  PaymentCode({
    required this.id,
    required this.name,
    required this.code,
  });

  factory PaymentCode.fromJson(Map<String, dynamic> json) {
    return PaymentCode(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
      };
}

class User {
  final int id;
  final String firstName;
  final String lastName;
  final String? email; // Make email nullable
  final String role;
  final int dashboardAccess; // 1 = Cashier, 2 = Waiter
  final int ebmAllowed;
  final String? companyName;
  final String? location;
  final String? telephone;
  final String? tinNumber;
  final List<PaymentCode> paymentCodes;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.role,
    this.dashboardAccess = 1,
    this.ebmAllowed = 0,
    this.companyName,
    this.location,
    this.telephone,
    this.tinNumber,
    this.paymentCodes = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final paymentCodesJson = json['payment_code'] as List<dynamic>?;

    return User(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'] == null ? null : json['email'].toString(),
      role: json['role'],
      dashboardAccess:
          int.tryParse(json['dashboard_access']?.toString() ?? '1') ?? 1,
      ebmAllowed: int.tryParse(json['ebm_allowed']?.toString() ?? '0') ?? 0,
      companyName: json['company name']?.toString(),
      location: json['location']?.toString(),
      telephone: json['telephone']?.toString(),
      tinNumber: json['tin_number']?.toString(),
      paymentCodes: paymentCodesJson == null
          ? []
          : paymentCodesJson
              .map((e) => PaymentCode.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email ?? '',
      'role': role,
      'dashboard_access': dashboardAccess,
      'ebm_allowed': ebmAllowed,
      'company name': companyName ?? '',
      'location': location ?? '',
      'telephone': telephone ?? '',
      'tin_number': tinNumber ?? '',
      'payment_code': paymentCodes.map((e) => e.toJson()).toList(),
    };
  }

  String get fullName => '$firstName $lastName';
}
