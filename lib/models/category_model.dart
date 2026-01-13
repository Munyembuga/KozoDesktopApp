class Category {
  final int id;
  final String categoryName;
  final String description;
  final String status;
  final String createdAt;
  final String updatedAt;
  final int stockCount;
  final int menuCount;

  Category({
    required this.id,
    required this.categoryName,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.stockCount,
    required this.menuCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      categoryName: json['category_name'],
      description: json['description'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      stockCount: json['stock_count'],
      menuCount: json['menu_count'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_name': categoryName,
        'description': description,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'stock_count': stockCount,
        'menu_count': menuCount,
      };

  String get displayName => '$categoryName ($menuCount items)';
}

class Accompaniment {
  final int id;
  final String accompanimentName;
  final String isRequired;
  final String status;

  Accompaniment({
    required this.id,
    required this.accompanimentName,
    required this.isRequired,
    required this.status,
  });

  factory Accompaniment.fromJson(Map<String, dynamic> json) {
    return Accompaniment(
      id: json['id'] ?? 0,
      accompanimentName: json['accompaniment_name'] ?? '',
      isRequired: json['is_required'] ?? 'no',
      status: json['status'] ?? 'inactive',
    );
  }

  bool get isRequiredBool => isRequired.toLowerCase() == 'yes';
}

class StockInfo {
  final int categoryStockId;
  final int sellingStatus;
  final int stockId;
  final double quantity;
  final bool hasSufficientStock;

  StockInfo({
    required this.categoryStockId,
    required this.sellingStatus,
    required this.stockId,
    required this.quantity,
    required this.hasSufficientStock,
  });

  factory StockInfo.fromJson(Map<String, dynamic> json) {
    return StockInfo(
      categoryStockId: json['category_stock_id'] ?? 0,
      sellingStatus: json['selling_status'] ?? 0,
      stockId: json['stock_id'] ?? 0,
      quantity: double.tryParse(json['total_quantity']?.toString() ??
              json['quantity']?.toString() ??
              '0') ??
          0.0,
      hasSufficientStock: json['has_sufficient_stock'] ?? false,
    );
  }
}

class PressureCooking {
  final int pressureId;
  final String requiresPressure;
  final String createdAt;
  final String pressureLevel;

  PressureCooking({
    required this.pressureId,
    required this.requiresPressure,
    required this.createdAt,
    required this.pressureLevel,
  });

  factory PressureCooking.fromJson(Map<String, dynamic> json) {
    return PressureCooking(
      pressureId: json['pressure_id'] ?? 0,
      requiresPressure: json['requires_pressure'] ?? 'no',
      createdAt: json['created_at'] ?? '',
      pressureLevel: json['pressure_level'] ?? '',
    );
  }

  String get displayText => pressureLevel;
}

class Specification {
  final int id;
  final String specificationName;
  final double price;
  final String status;
  final String reduceStock;
  final int categoryId;
  final String categoryName;
  final List<Accompaniment> accompaniments;
  final StockInfo? stockInfo;
  final String requiresPressure;
  final List<PressureCooking> pressureCooking;

  Specification({
    required this.id,
    required this.specificationName,
    required this.price,
    required this.status,
    this.reduceStock = 'no',
    this.categoryId = 0,
    this.categoryName = '',
    this.accompaniments = const [],
    this.stockInfo,
    this.requiresPressure = 'no',
    this.pressureCooking = const [],
  });

  factory Specification.fromJson(Map<String, dynamic> json) {
    var accompanimentsList = <Accompaniment>[];
    if (json['accompaniments'] != null) {
      accompanimentsList = (json['accompaniments'] as List)
          .map((accompaniment) => Accompaniment.fromJson(accompaniment))
          .toList();
    }

    StockInfo? stockInfo;
    if (json['stock_info'] != null) {
      stockInfo = StockInfo.fromJson(json['stock_info']);
    }

    var pressureCookingList = <PressureCooking>[];
    if (json['pressure_cooking'] != null) {
      pressureCookingList = (json['pressure_cooking'] as List)
          .map((pressure) => PressureCooking.fromJson(pressure))
          .toList();
    }

    return Specification(
      id: json['id'] ?? 0,
      specificationName: json['specification_name'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      status: json['status'] ?? 'inactive',
      reduceStock: json['reduce_stock'] ?? 'no',
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      accompaniments: accompanimentsList,
      stockInfo: stockInfo,
      requiresPressure: json['requires_pressure'] ?? 'no',
      pressureCooking: pressureCookingList,
    );
  }

  bool get hasAccompaniments => accompaniments.isNotEmpty;
  bool get requiresStockTracking => reduceStock.toLowerCase() == 'yes';
  bool get needsPressureCooking => requiresPressure.toLowerCase() == 'yes';
  bool get hasPressureOptions => pressureCooking.isNotEmpty;
  bool get isOutOfStock {
    if (requiresStockTracking && stockInfo != null) {
      print(
          'Stock check for ${specificationName}: quantity=${stockInfo!.quantity}, hasSufficientStock=${stockInfo!.hasSufficientStock}');
      return !stockInfo!.hasSufficientStock;
    }
    return false;
  }

  bool get hasLowStock =>
      requiresStockTracking &&
      stockInfo != null &&
      stockInfo!.hasSufficientStock && // Available but low
      stockInfo!.quantity <= 5 &&
      stockInfo!.hasSufficientStock;
  bool get isAvailable => !isOutOfStock;
}
