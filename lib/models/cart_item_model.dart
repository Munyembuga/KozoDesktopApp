class Specification {
  final int id;
  final String specificationName;
  final String status;
  final double price;

  Specification({
    required this.id,
    required this.specificationName,
    required this.status,
    required this.price,
  });

  factory Specification.fromJson(Map<String, dynamic> json) {
    return Specification(
      id: json['id'],
      specificationName: json['specification_name'],
      status: json['status'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }
}

class CartItem {
  final int id;
  final String itemName;
  final int categoryId;
  final String categoryName;
  final String description;
  final String imagePath;
  int quantity;
  final double price;
  final int? specificationId;
  final List<int>? accompanimentsIds;
  final String? comment;
  final int? prepOrder; // New property for preparation order
  final int? selectedPressureId; // Property for pressure cooking selection
  final bool
      requiresPressure; // Flag to indicate if item requires pressure cooking

  CartItem({
    required this.id,
    required this.itemName,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.imagePath,
    required this.quantity,
    required this.price,
    this.specificationId,
    this.accompanimentsIds,
    this.comment,
    this.prepOrder, // Add the preparation order parameter
    this.selectedPressureId, // Add the pressure cooking parameter
    this.requiresPressure = false, // Default to false
  });

  // Calculate total price for this cart item
  double get totalPrice => price * quantity;

  // Create a copy of the cart item with updated values
  CartItem copyWith({
    int? id,
    String? itemName,
    int? categoryId,
    String? categoryName,
    String? description,
    String? imagePath,
    int? quantity,
    double? price,
    int? specificationId,
    List<int>? accompanimentsIds,
    String? comment,
    int? prepOrder, // Add preparation order to copyWith
    int? selectedPressureId, // Add pressure cooking to copyWith
    bool? requiresPressure,
  }) {
    return CartItem(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      specificationId: specificationId ?? this.specificationId,
      accompanimentsIds: accompanimentsIds ?? this.accompanimentsIds,
      comment: comment ?? this.comment,
      prepOrder: prepOrder ?? this.prepOrder, // Update preparation order
      selectedPressureId: selectedPressureId ??
          this.selectedPressureId, // Update pressure cooking
      requiresPressure: requiresPressure ?? this.requiresPressure,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
      'imagePath': imagePath,
      'quantity': quantity,
      'price': price,
      'specificationId': specificationId,
      'accompanimentsIds': accompanimentsIds,
      'comment': comment,
      'prepOrder': prepOrder, // Include preparation order in JSON
      'selectedPressureId':
          selectedPressureId, // Include pressure cooking in JSON
      'requiresPressure': requiresPressure,
    };
  }

  // Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      itemName: json['itemName'] ?? '',
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'] ?? '',
      description: json['description'] ?? '',
      imagePath: json['imagePath'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0.0).toDouble(),
      specificationId: json['specificationId'],
      accompanimentsIds: json['accompanimentsIds'] != null
          ? List<int>.from(json['accompanimentsIds'])
          : null,
      comment: json['comment']?.toString(),
      prepOrder: json['prepOrder'], // Get preparation order from JSON
      selectedPressureId:
          json['selectedPressureId'], // Get pressure cooking from JSON
      requiresPressure: json['requiresPressure'] ?? false,
    );
  }

  @override
  String toString() {
    return 'CartItem(id: $id, itemName: $itemName, quantity: $quantity, price: $price, specificationId: $specificationId, accompanimentsIds: $accompanimentsIds, comment: $comment, prepOrder: $prepOrder, selectedPressureId: $selectedPressureId, requiresPressure: $requiresPressure)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.id == id &&
        other.specificationId == specificationId;
  }

  @override
  int get hashCode => id.hashCode ^ (specificationId?.hashCode ?? 0);
}

class MenuItem {
  final int id;
  final int categoryId;
  final String itemName;
  final String description;
  final String imagePath;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String categoryName;

  MenuItem({
    required this.id,
    required this.categoryId,
    required this.itemName,
    required this.description,
    required this.imagePath,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.categoryName,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      categoryId: json['category_id'],
      itemName: json['item_name'],
      description: json['description'] ?? '',
      imagePath: json['image_path'] ?? '',
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      categoryName: json['category_name'],
    );
  }
}
