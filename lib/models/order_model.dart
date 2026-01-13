class Order {
  final int id;
  final String orderNumber;
  final String total;
  final String? grandTotal;
  final String createdAt;
  final String tableNumber;
  final String tableLocation;
  final String waiterName;
  final String? clientName;
  final int itemCount;
  final String? updatedAt; // Make nullable to handle missing field
  final String? paymentDate; // make nullable

  Order({
    required this.id,
    required this.orderNumber,
    required this.total,
    this.grandTotal,
    required this.createdAt,
    required this.tableNumber,
    required this.tableLocation,
    required this.waiterName,
    this.clientName,
    required this.itemCount,
    this.updatedAt, // No longer required
    this.paymentDate, // nullable
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      total: json['total'],
      grandTotal: json['grand_total']?.toString(),
      createdAt: json['created_at'],
      tableNumber: json['table_number'],
      tableLocation: json['table_location'],
      waiterName: json['waiter_name'],
      clientName: json['client_name'],
      itemCount: json['item_count'],
      updatedAt: json['updated_at'] ??
          json['created_at'], // Use created_at as fallback
      paymentDate: json['payment_date'], // nullable
    );
  }

  String get tableDisplay => 'Table $tableNumber';
  String get locationDisplay => tableLocation;
  String get formattedTotal => 'RWF ${double.parse(total).toStringAsFixed(0)}';

  // Add formatted grand total
  String get formattedGrandTotal => grandTotal != null
      ? 'RWF ${double.parse(grandTotal!).toStringAsFixed(0)}'
      : formattedTotal;

  String get waitTime {
    try {
      final orderTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(orderTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min';
      } else {
        return '${difference.inHours}h ${difference.inMinutes % 60}min';
      }
    } catch (e) {
      return '0 min';
    }
  }

  // Optional: formatted payment date
  String get formattedPaymentDate {
    if (paymentDate == null || paymentDate!.isEmpty) {
      return 'Not Paid'; // or 'Pending'
    }
    try {
      final date = DateTime.parse(paymentDate!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  // Get a safely formatted updated time
  String get formattedUpdateTime {
    final timeStr =
        updatedAt ?? createdAt; // Fall back to created_at if updated_at is null
    try {
      final dateTime = DateTime.parse(timeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
