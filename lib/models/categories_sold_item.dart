class SoldItem {
  final int menuItemId;
  final String itemName;
  final int specificationId;
  final String specificationName;
  final double price;
  final int quantitySold;
  final double totalRevenue;

  SoldItem({
    required this.menuItemId,
    required this.itemName,
    required this.specificationId,
    required this.specificationName,
    required this.price,
    required this.quantitySold,
    required this.totalRevenue,
  });

  factory SoldItem.fromJson(Map<String, dynamic> json) {
    return SoldItem(
      menuItemId: json['menu_item_id'] ?? 0,
      itemName: json['item_name'] ?? '',
      specificationId: json['specification_id'] ?? 0,
      specificationName: json['specification_name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantitySold: json['quantity_sold'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
    );
  }
}

class CategorySoldSummary {
  final int categoryId;
  final String categoryName;
  final List<SoldItem> items;
  final int totalQuantity;
  final double totalRevenue;

  CategorySoldSummary({
    required this.categoryId,
    required this.categoryName,
    required this.items,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  factory CategorySoldSummary.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = json['items'] ?? [];
    return CategorySoldSummary(
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      items: itemsJson.map((item) => SoldItem.fromJson(item)).toList(),
      totalQuantity: json['total_quantity'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
    );
  }
}
