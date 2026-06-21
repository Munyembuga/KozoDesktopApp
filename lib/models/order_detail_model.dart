class OrderDetail {
  final int id;
  final String orderNumber;
  final int tableId;
  final int? clientId;
  final int waiterId;
  final String orderType;
  final String subtotal;
  final String discount;
  final String total;
  final String? vat;
  final String? serviceFee;
  final String? serviceFeeDiscount;
  final String? grandTotal;
  final String status;
  final String orderNotes;
  final String createdAt;
  final String updatedAt;
  final int ebmRecorded;
  final String tableNumber;
  final String tableLocation;
  final String? clientName;
  final String waiterName;
  final String? paymentStatus;
  final List<OrderItem> items;
  final Payment? payment;
  final List<PaymentMethodDetail> paymentMethods;
  final String? serviceFeeRemoved;
  final int? serviceFeeRemovedBy;
  final String? serviceFeeRemovedAt;
  final int? covers; // Added new field for number of people
  final List<Course> courses; // Add new field for courses

  OrderDetail({
    required this.id,
    required this.orderNumber,
    required this.tableId,
    this.clientId,
    required this.waiterId,
    required this.orderType,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.vat,
    this.serviceFee,
    this.serviceFeeDiscount,
    this.grandTotal,
    required this.status,
    required this.orderNotes,
    required this.createdAt,
    required this.updatedAt,
    required this.ebmRecorded,
    required this.tableNumber,
    required this.tableLocation,
    this.clientName,
    required this.waiterName,
    this.paymentStatus,
    required this.items,
    this.payment,
    this.paymentMethods = const [],
    this.serviceFeeRemoved,
    this.serviceFeeRemovedBy,
    this.serviceFeeRemovedAt,
    this.covers, // Added to constructor
    required this.courses, // Add to constructor
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    // Handle both old and new API response structures
    final data = json['data'] ??
        json; // Use 'data' if it exists, otherwise use json directly
    final orderData = data['order'];
    final itemsData = data['items'] as List;
    final paymentData = data['payment'];
    final paymentMethodsData = data['payment_methods'] as List? ?? [];
    final coursesData = data['courses'] as List? ?? []; // Parse courses

    return OrderDetail(
      id: orderData['id'] is String
          ? int.parse(orderData['id'])
          : orderData['id'],
      orderNumber: orderData['order_number'] ?? '',
      tableId: orderData['table_id'] ?? 0,
      clientId: orderData['client_id'],
      waiterId: orderData['waiter_id'] ?? 0,
      orderType: orderData['order_type'] ?? '',
      subtotal: orderData['subtotal']?.toString() ?? '0',
      discount: orderData['discount']?.toString() ?? '0',
      total: orderData['total']?.toString() ?? '0',
      vat: orderData['vat']?.toString(),
      serviceFee: orderData['service_fee']?.toString(),
      serviceFeeDiscount: orderData['service_fee_discount']?.toString(),
      grandTotal: orderData['grand_total']?.toString(),
      status: orderData['status'] ?? '',
      orderNotes: orderData['order_notes']?.toString() ?? '',
      createdAt: orderData['created_at'] ?? '',
      updatedAt: orderData['updated_at'] ?? '',
      ebmRecorded:
          int.tryParse(orderData['ebm_recorded']?.toString() ?? '0') ?? 0,
      tableNumber: orderData['table_number']?.toString() ?? '',
      tableLocation: orderData['table_location'] ?? '',
      clientName: orderData['client_name'],
      waiterName: orderData['waiter_name'] ?? '',
      paymentStatus: orderData['payment_status'],
      items: itemsData.map((item) => OrderItem.fromJson(item)).toList(),
      payment: paymentData != null ? Payment.fromJson(paymentData) : null,
      paymentMethods: paymentMethodsData
          .map((method) => PaymentMethodDetail.fromJson(method))
          .toList(),
      serviceFeeRemoved: orderData['service_fee_removed']?.toString(),
      serviceFeeRemovedBy: orderData['service_fee_removed_by'],
      serviceFeeRemovedAt: orderData['service_fee_removed_at']?.toString(),
      covers: orderData['covers'] != null
          ? int.tryParse(orderData['covers'].toString())
          : null, // Parse covers field
      courses: coursesData
          .map((course) => Course.fromJson(course))
          .toList(), // Parse courses
    );
  }

  String get formattedTotal => 'RWF ${double.parse(total).toStringAsFixed(0)}';
  String get formattedSubtotal =>
      'RWF ${double.parse(subtotal).toStringAsFixed(0)}';
  String get formattedDiscount =>
      'RWF ${double.parse(discount).toStringAsFixed(0)}';
  String get formattedVat =>
      vat != null ? 'RWF ${double.parse(vat!).toStringAsFixed(0)}' : 'RWF 0';
  String get formattedServiceFee => serviceFee != null
      ? 'RWF ${double.parse(serviceFee!).toStringAsFixed(0)}'
      : 'RWF 0';
  String get formattedGrandTotal => grandTotal != null
      ? 'RWF ${double.parse(grandTotal!).toStringAsFixed(0)}'
      : formattedTotal;
  String get tableDisplay => ' $tableNumber';

  bool get isPaid => payment != null;
  bool get hasChange =>
      payment != null && double.parse(payment!.changeAmount) > 0;
}

// Add new Course model
class Course {
  final String courseNumber;
  final int status;

  Course({
    required this.courseNumber,
    required this.status,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseNumber: json['course_number'] ?? '',
      status: json['status'] ?? 0,
    );
  }

  String get displayName {
    return courseNumber.replaceFirst('cource', 'Course');
  }
}

class Payment {
  final int id;
  final int orderId;
  final String paymentReference;
  final String totalAmount;
  final String amountReceived;
  final String changeAmount;
  final String paymentNotes;
  final String? paymentStatus;
  final String? remainingAmount;
  final int recordedBy;
  final String createdAt;
  final String updatedAt;
  final bool isEditable; // New property
  final String? closedBy; // Add new field for closed by

  Payment({
    required this.id,
    required this.orderId,
    required this.paymentReference,
    required this.totalAmount,
    required this.amountReceived,
    required this.changeAmount,
    required this.paymentNotes,
    this.paymentStatus,
    this.remainingAmount,
    required this.recordedBy,
    required this.createdAt,
    required this.updatedAt,
    this.isEditable = false, // Default value
    this.closedBy, // Add to constructor
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      paymentReference: json['payment_reference']?.toString() ?? '',
      totalAmount: json['total_amount']?.toString() ?? '0',
      amountReceived: json['amount_received']?.toString() ?? '0',
      changeAmount: json['change_amount']?.toString() ?? '0',
      paymentNotes: json['payment_notes']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString(),
      // Handle remaining_amount which may be returned as int or string
      remainingAmount: json['remaining_amount'] != null
          ? json['remaining_amount'].toString()
          : null,
      recordedBy: json['recorded_by'] ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      isEditable: json['is_editable'] == true, // Parse the boolean value
      closedBy: json['closed_by_name']?.toString(), // Parse closed by field
    );
  }

  String get formattedTotalAmount =>
      ' RWF ${double.parse(totalAmount).toStringAsFixed(0)}';
  String get formattedAmountReceived =>
      ' RWF ${double.parse(amountReceived).toStringAsFixed(0)}';
  String get formattedChangeAmount =>
      ' RWF ${double.parse(changeAmount).toStringAsFixed(0)}';
  String get formattedRemainingAmount => remainingAmount != null
      ? ' RWF ${double.parse(remainingAmount!).toStringAsFixed(0)}'
      : ' RWF 0';

  bool get isPartialPayment => paymentStatus?.toLowerCase() == 'partial';
  bool get hasRemainingAmount =>
      remainingAmount != null && double.parse(remainingAmount!) > 0;
}

class PaymentMethodDetail {
  final int id;
  final int paymentId;
  final String methodType;
  final String amount;
  final String referenceNumber;
  final String createdAt;
  final String? clientName; // Added new field for client name

  PaymentMethodDetail({
    required this.id,
    required this.paymentId,
    required this.methodType,
    required this.amount,
    required this.referenceNumber,
    required this.createdAt,
    this.clientName, // Added to constructor
  });

  factory PaymentMethodDetail.fromJson(Map<String, dynamic> json) {
    return PaymentMethodDetail(
      id: json['id'] ?? 0,
      paymentId: json['payment_id'] ?? 0,
      methodType: json['method_type'] ?? '',
      amount: json['amount']?.toString() ?? '0',
      referenceNumber: json['reference_number']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      clientName: json['client_name'], // Parse client name from JSON
    );
  }

  String get formattedAmount =>
      'RWF ${double.parse(amount).toStringAsFixed(0)}';
  String get displayMethodType {
    switch (methodType.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'mobile':
      case 'mobilemoney':
        return 'Mobile Money';
      default:
        return methodType.toUpperCase();
    }
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int menuItemId;
  final int specificationId;
  final int quantity;
  final int? accompanimentId;
  final String? comment;
  final String unitPrice;
  final String totalPrice;
  final String createdAt;
  final String itemName;
  final String specificationName;
  final String? accompanimentName;
  final String? courseNumber; // Add new field

  OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.specificationId,
    required this.quantity,
    this.accompanimentId,
    this.comment,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
    required this.itemName,
    required this.specificationName,
    this.accompanimentName,
    this.courseNumber, // Add to constructor
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      menuItemId: json['menu_item_id'] ?? 0,
      specificationId: json['specification_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      accompanimentId: json['accompaniments_id'],
      comment: json['Comment'],
      unitPrice: json['unit_price']?.toString() ?? '0',
      totalPrice: json['total_price']?.toString() ?? '0',
      createdAt: json['created_at'] ?? '',
      itemName: json['item_name'] ?? '',
      specificationName: json['specification_name'] ?? '',
      accompanimentName: json['accompaniment_name'],
      courseNumber: json['course_number'], // Parse course number
    );
  }

  String get formattedUnitPrice =>
      'RWF ${double.parse(unitPrice).toStringAsFixed(0)}';
  String get formattedTotalPrice =>
      'RWF ${double.parse(totalPrice).toStringAsFixed(0)}';

  String get fullItemDescription {
    String description = '$itemName - $specificationName';
    if (accompanimentName != null && accompanimentName!.isNotEmpty) {
      description += ' with $accompanimentName';
    }
    return description;
  }

  bool get hasComment => comment != null && comment!.isNotEmpty;
}
