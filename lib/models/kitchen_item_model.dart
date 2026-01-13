class KitchenItem {
  final int itemId;
  final String itemName;
  final int categoryId;
  final String categoryName;

  KitchenItem({
    required this.itemId,
    required this.itemName,
    required this.categoryId,
    required this.categoryName,
  });

  factory KitchenItem.fromJson(Map<String, dynamic> json) {
    // Add debugging print to see what we're receiving
    print('Parsing KitchenItem JSON: $json');

    try {
      return KitchenItem(
        itemId: _parseToInt(json['item_id']),
        itemName: _parseToString(json['item_name']),
        categoryId: _parseToInt(json['category_id']),
        categoryName: _parseToString(json['category_name']),
      );
    } catch (e) {
      print('Error parsing KitchenItem: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  static String _parseToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'item_name': itemName,
        'category_id': categoryId,
        'category_name': categoryName,
      };
}
