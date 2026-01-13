class PaymentMethod {
  final int id;
  final int categoryId;
  final String methodName;
  final String methodCode;
  final String? description;
  final String requiresReference;
  final String status;
  final String createdAt;
  final String categoryName;
  final String categoryCode;
  final String displayName;

  PaymentMethod({
    required this.id,
    required this.categoryId,
    required this.methodName,
    required this.methodCode,
    this.description,
    required this.requiresReference,
    required this.status,
    required this.createdAt,
    required this.categoryName,
    required this.categoryCode,
    required this.displayName,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: int.tryParse(json['id'].toString()) ?? 0,
      categoryId: int.tryParse(json['category_id'].toString()) ?? 0,
      methodName: json['method_name'].toString(),
      methodCode: json['method_code'].toString(),
      description: json['description']?.toString(),
      requiresReference: json['requires_reference'].toString(),
      status: json['status'].toString(),
      createdAt: json['created_at'].toString(),
      categoryName: json['category_name'].toString(),
      categoryCode: json['category_code'].toString(),
      displayName: json['display_name'].toString(),
    );
  }
}
