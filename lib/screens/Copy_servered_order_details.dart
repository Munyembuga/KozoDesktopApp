// Updated file: lib/screens/orders/served_order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kozo/cashierScreens/addItemDialog.dart';
import 'package:kozo/cashierScreens/kitchen_item_selection_dialog.dart';
import 'package:kozo/cashierScreens/reportToptab/payment_dialog.dart';
import 'package:kozo/cashierScreens/returnItemDialog.dart';
import 'package:kozo/models/order_detail_model.dart';
import 'package:kozo/services/auth_service.dart';
import 'package:kozo/services/bill_receipt_services.dart';
import 'package:kozo/services/kitchen_receipt_service.dart';
import 'package:kozo/services/bar_receipt_service.dart';
import 'package:kozo/utils/constants.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../services/order_service.dart';
import '../../services/receipt_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../models/cart_item_model.dart';

// Kitchen item model to handle API response
class KitchenItem {
  final int itemId;
  final String itemName;
  final int categoryId;
  final String categoryName;
  final int quantity;
  final int specificationId;
  final String specificationName;
  final String unitPrice;
  final String totalPrice;
  final int? accompanimentId;
  final String? accompanimentName;
  final String? comment;

  KitchenItem({
    required this.itemId,
    required this.itemName,
    required this.categoryId,
    required this.categoryName,
    required this.quantity,
    required this.specificationId,
    required this.specificationName,
    required this.unitPrice,
    required this.totalPrice,
    this.accompanimentId,
    this.accompanimentName,
    this.comment,
  });

  factory KitchenItem.fromJson(Map<String, dynamic> json) {
    return KitchenItem(
      itemId: json['item_id'],
      itemName: json['item_name'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      quantity: json['quantity'],
      specificationId: json['specification_id'],
      specificationName: json['specification_name'],
      unitPrice: json['unit_price'],
      totalPrice: json['total_price'],
      accompanimentId: json['accompaniments_id'],
      accompanimentName: json['accompaniment_name'],
      comment: json['Comment'],
    );
  }

  bool get hasAccompaniment =>
      accompanimentName != null && accompanimentName!.isNotEmpty;
  bool get hasComment => comment != null && comment!.isNotEmpty;
}

class KitchenItemsResponse {
  final bool success;
  final bool hasKitchenItems;
  final List<KitchenItem> kitchenItems;

  KitchenItemsResponse({
    required this.success,
    required this.hasKitchenItems,
    required this.kitchenItems,
  });

  factory KitchenItemsResponse.fromJson(Map<String, dynamic> json) {
    return KitchenItemsResponse(
      success: json['success'],
      hasKitchenItems: json['hasKitchenItems'],
      kitchenItems: (json['kitchenItems'] as List)
          .map((item) => KitchenItem.fromJson(item))
          .toList(),
    );
  }
}

class BarItemsResponse {
  final bool success;
  final bool hasBarItems;
  final List<KitchenItem> barItems;

  BarItemsResponse({
    required this.success,
    required this.hasBarItems,
    required this.barItems,
  });

  factory BarItemsResponse.fromJson(Map<String, dynamic> json) {
    return BarItemsResponse(
      success: json['success'],
      hasBarItems: json['hasBarItems'],
      barItems: (json['barItems'] as List)
          .map((item) => KitchenItem.fromJson(item))
          .toList(),
    );
  }
}

class ServedOrderDetailScreen extends StatefulWidget {
  final int orderId;
  final VoidCallback onOrderUpdated;

  const ServedOrderDetailScreen({
    super.key,
    required this.orderId,
    required this.onOrderUpdated,
  });

  @override
  State<ServedOrderDetailScreen> createState() =>
      _ServedOrderDetailScreenState();
}

class _ServedOrderDetailScreenState extends State<ServedOrderDetailScreen> {
  OrderDetail? _orderDetail;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLoadingKitchen = false;
  bool _isLoadingBar = false;
  KitchenItemsResponse? _kitchenItemsResponse;
  BarItemsResponse? _barItemsResponse;
  String? _role;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
    _loadUserRole();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll to top method
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // Scroll to bottom method
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void didUpdateWidget(ServedOrderDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      _fetchOrderDetail();
    }
  }

  Future<void> _loadUserRole() async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (mounted) {
        setState(() {
          _role = currentUser?.role;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _role = null; // or handle error accordingly
        });
      }
    }
  }

  Future<void> _fetchOrderDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final orderDetail =
          await OrderService.fetchServedOrderDetail(widget.orderId);

      if (mounted) {
        setState(() {
          _orderDetail = orderDetail;
          _isLoading = false;
        });
      }
      // print('Order Detail Fetched: ${_orderDetail?.toJson()}'); // Debug log
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Print Bill using ReceiptService
  Future<void> _printBill() async {
    if (_orderDetail == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: true, // Allow closing
        builder: (context) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Preparing receipt...'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(
                  child: Text('Please wait while we prepare your receipt')),
            ],
          ),
        ),
      );

      await BillReceiptServices.printReceipt(_orderDetail!);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt printed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Preview Bill using ReceiptService
  Future<void> _previewBill() async {
    if (_orderDetail == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: true, // Allow closing
        builder: (context) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Preparing receipt...'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(
                  child: Text('Please wait while we prepare your receipt')),
            ],
          ),
        ),
      );

      await ReceiptService.previewReceipt(_orderDetail!);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preview failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Updated method to check kitchen items
  Future<void> _checkKitchenItems() async {
    if (_orderDetail == null || _orderDetail!.items.isEmpty) return;

    try {
      setState(() {
        _isLoadingKitchen = true;
      });

      // Extract item IDs from order items
      List<int> itemIds =
          _orderDetail!.items.map((item) => item.menuItemId).toSet().toList();

      // Prepare the request body
      final body = jsonEncode({
        'itemIds': itemIds,
        'orderId': _orderDetail!.id.toString(),
      });

      // Print request body in terminal
      print("Kitchen Request Body: $body");

      // Make the POST request
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/Orders/show_kichen_item'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final kitchenItemsResponse =
            KitchenItemsResponse.fromJson(jsonResponse);

        if (mounted) {
          setState(() {
            _kitchenItemsResponse = kitchenItemsResponse;
            _isLoadingKitchen = false;
          });

          // Show results in a dialog
          _showKitchenItemsDialog(kitchenItemsResponse);
        }
      } else {
        throw Exception(
            'Failed to check kitchen items: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingKitchen = false;
        });

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Kitchen Items Error'),
              ],
            ),
            content: Text('Failed to check kitchen items: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _checkKitchenItems(); // Retry
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  // New method to check bar items
  Future<void> _checkBarItems() async {
    if (_orderDetail == null || _orderDetail!.items.isEmpty) return;

    try {
      setState(() {
        _isLoadingBar = true;
      });

      // Extract item IDs from order items
      List<int> itemIds =
          _orderDetail!.items.map((item) => item.menuItemId).toSet().toList();

      // Prepare the request body
      final body = jsonEncode({
        'itemIds': itemIds,
        'orderId': _orderDetail!.id.toString(),
      });

      // Print request body in terminal
      print("Bar Request Body: $body");

      // Make the POST request - using the bar items endpoint
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/Orders/show_bar_item'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final barItemsResponse = BarItemsResponse.fromJson(jsonResponse);

        if (mounted) {
          setState(() {
            _barItemsResponse = barItemsResponse;
            _isLoadingBar = false;
          });

          // Show results in a dialog
          _showBarItemsDialog(barItemsResponse);
        }
      } else {
        throw Exception('Failed to check bar items: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBar = false;
        });

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Bar Items Error'),
              ],
            ),
            content: Text('Failed to check bar items: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _checkBarItems(); // Retry
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showKitchenItemsDialog(KitchenItemsResponse response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              response.hasKitchenItems ? Icons.kitchen : Icons.no_meals,
              color: response.hasKitchenItems ? Colors.orange : Colors.grey,
            ),
            const SizedBox(width: 8),
            const Text('Kitchen Items'),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: response.hasKitchenItems
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Found ${response.kitchenItems.length} kitchen items:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: response.kitchenItems.length,
                        itemBuilder: (context, index) {
                          final item = response.kitchenItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.itemName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Qty: ${item.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Category: ${item.categoryName}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Specification: ${item.specificationName}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                if (item.hasAccompaniment)
                                  Text(
                                    'with ${item.accompanimentName}',
                                    style: TextStyle(
                                      color: Colors.blue[600],
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                if (item.hasComment)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: Colors.orange[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.comment,
                                            size: 12,
                                            color: Colors.orange[600]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Note: ${item.comment}',
                                            style: TextStyle(
                                              color: Colors.orange[700],
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Unit Price: RWF ${item.unitPrice}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'Total: RWF ${item.totalPrice}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              : const Text('No kitchen items found for this order.'),
        ),
        actions: [
          if (response.hasKitchenItems) ...[
            TextButton.icon(
              onPressed: () =>
                  _showKitchenItemSelectionDialogForPreview(response),
              icon: const Icon(Icons.preview, size: 16),
              label: const Text('Preview'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showKitchenItemSelectionDialog(response),
              icon: const Icon(Icons.print, size: 16),
              label: const Text('Print Receipt'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange,
              ),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // New method to show bar items dialog
  void _showBarItemsDialog(BarItemsResponse response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              response.hasBarItems ? Icons.local_bar : Icons.no_drinks,
              color: response.hasBarItems ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 8),
            const Text('Bar Items'),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: response.hasBarItems
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Found ${response.barItems.length} bar items:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: response.barItems.length,
                        itemBuilder: (context, index) {
                          final item = response.barItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.itemName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Qty: ${item.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Category: ${item.categoryName}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Specification: ${item.specificationName}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                if (item.hasAccompaniment)
                                  Text(
                                    'with ${item.accompanimentName}',
                                    style: TextStyle(
                                      color: Colors.blue[600],
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                if (item.hasComment)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: Colors.orange[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.comment,
                                            size: 12,
                                            color: Colors.orange[600]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Note: ${item.comment}',
                                            style: TextStyle(
                                              color: Colors.orange[700],
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Unit Price: RWF ${item.unitPrice}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'Total: RWF ${item.totalPrice}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              : const Text('No bar items found for this order.'),
        ),
        actions: [
          if (response.hasBarItems) ...[
            TextButton.icon(
              onPressed: () => _showBarItemSelectionDialogForPreview(response),
              icon: const Icon(Icons.preview, size: 16),
              label: const Text('Preview'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showBarItemSelectionDialog(response),
              icon: const Icon(Icons.print, size: 16),
              label: const Text('Print Receipt'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // New method for preview selection
  void _showKitchenItemSelectionDialogForPreview(
      KitchenItemsResponse response) {
    Navigator.of(context).pop(); // Close the kitchen items dialog

    showDialog(
      context: context,
      builder: (context) => KitchenItemSelectionDialog(
        response: response,
        onItemsSelected: (selectedItems) {
          _previewKitchenReceipt(response, selectedItems);
        },
      ),
    );
  }

  // New method to show item selection dialog
  void _showKitchenItemSelectionDialog(KitchenItemsResponse response) {
    Navigator.of(context).pop(); // Close the kitchen items dialog

    showDialog(
      context: context,
      builder: (context) => KitchenItemSelectionDialog(
        response: response,
        onItemsSelected: (selectedItems) {
          _printKitchenReceipt(response, selectedItems);
        },
      ),
    );
  }

  // Bar item selection methods
  void _showBarItemSelectionDialogForPreview(BarItemsResponse response) {
    Navigator.of(context).pop(); // Close the bar items dialog

    // Convert BarItemsResponse to KitchenItemsResponse for compatibility
    final kitchenResponse = KitchenItemsResponse(
      success: response.success,
      hasKitchenItems: response.hasBarItems,
      kitchenItems: response.barItems,
    );

    showDialog(
      context: context,
      builder: (context) => KitchenItemSelectionDialog(
        response: kitchenResponse,
        onItemsSelected: (selectedItems) {
          _previewBarReceipt(kitchenResponse, selectedItems);
        },
      ),
    );
  }

  void _showBarItemSelectionDialog(BarItemsResponse response) {
    Navigator.of(context).pop(); // Close the bar items dialog

    // Convert BarItemsResponse to KitchenItemsResponse for compatibility
    final kitchenResponse = KitchenItemsResponse(
      success: response.success,
      hasKitchenItems: response.hasBarItems,
      kitchenItems: response.barItems,
    );

    showDialog(
      context: context,
      builder: (context) => KitchenItemSelectionDialog(
        response: kitchenResponse,
        onItemsSelected: (selectedItems) {
          _printBarReceipt(kitchenResponse, selectedItems);
        },
      ),
    );
  }

  // Updated method to accept selected items
  Future<void> _printKitchenReceipt(KitchenItemsResponse response,
      [List<KitchenItem>? selectedItems]) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Preparing receipt...'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(
                  child: Text('Please wait while we prepare your receipt')),
            ],
          ),
        ),
      );

      await KitchenReceiptService.printKitchenReceipt(
          response, _orderDetail!, selectedItems);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kitchen receipt printed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Also update the preview method
  Future<void> _previewKitchenReceipt(KitchenItemsResponse response,
      [List<KitchenItem>? selectedItems]) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: true, // Allow closing
        builder: (context) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Preparing receipt...'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(
                  child: Text('Please wait while we prepare your receipt')),
            ],
          ),
        ),
      );

      await KitchenReceiptService.previewKitchenReceipt(
          response, _orderDetail!, selectedItems);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preview failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Bar receipt methods
  Future<void> _printBarReceipt(KitchenItemsResponse response,
      [List<KitchenItem>? selectedItems]) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Preparing bar receipt...'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(
                  child: Text('Please wait while we prepare your bar receipt')),
            ],
          ),
        ),
      );

      await BarReceiptService.printBarReceipt(
          response, _orderDetail!, selectedItems);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bar receipt printed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bar print failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _previewBarReceipt(KitchenItemsResponse response,
      [List<KitchenItem>? selectedItems]) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: true, // Allow closing
        builder: (context) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Preparing bar receipt...'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(
                  child: Text('Please wait while we prepare your bar receipt')),
            ],
          ),
        ),
      );

      await BarReceiptService.previewBarReceipt(
          response, _orderDetail!, selectedItems);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bar preview failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _recordPayment() async {
    if (_orderDetail == null) return;

    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        totalAmount: double.parse(_orderDetail!.grandTotal.toString()),
        onPayment: (amountReceived, paymentMethodsData, notes, discount) async {
          await _processPayment(
              amountReceived, paymentMethodsData, notes, discount);
        },
      ),
    );
  }

  Future<void> _processPayment(
    double amountReceived,
    List<Map<String, dynamic>> paymentMethodsData,
    String notes,
    double discount,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Recording payment...'),
            ],
          ),
        ),
      );

      final success = await OrderService.recordPayment(
        orderId: _orderDetail!.id,
        totalAmount: double.parse(_orderDetail!.total.toString()),
        amountReceived: amountReceived,
        paymentMethods: paymentMethodsData,
        paymentNotes: notes.isNotEmpty ? notes : null,
        discount: discount,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment recorded successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh order details
          widget.onOrderUpdated();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Payment Error'),
              ],
            ),
            content: Text('Failed to record payment: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _recordPayment(); // Retry
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showReturnItemDialog() {
    if (_orderDetail == null) return;

    showDialog(
      context: context,
      builder: (context) => ReturnItemDialog(
        orderDetail: _orderDetail!,
        onReturnItems: _processReturnItems,
      ),
    );
  }

  // Method to handle removing service fees
  Future<void> _removeServiceFees() async {
    try {
      // Show confirmation dialog
      bool shouldProceed = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.money_off, color: Colors.teal),
                  const SizedBox(width: 8),
                  const Text('Remove Service Fees'),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Are you sure you want to remove the service fees from this order?',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This action cannot be undone.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Remove Fees'),
                ),
              ],
            ),
          ) ??
          false;

      if (!shouldProceed) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Removing service fees...'),
            ],
          ),
        ),
      );

      // Call API to remove service fees
      final success = await OrderService.removeServiceFee(_orderDetail!.id);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service fees removed successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh order details
        _fetchOrderDetail();
        widget.onOrderUpdated();
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      print("Failed to remove service fees***********************: $e");
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to remove service fees: No service fee found for this order.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Updated method to process return items using the API
  Future<void> _processReturnItems(List<ReturnItemModel> returnItems) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processing return...'),
            ],
          ),
        ),
      );

      // Prepare return data for API
      final returnData = returnItems
          .map((item) => {
                'orderItemId': item.orderItemId,
                'quantity': item.returnQuantity,
                'returnReason': item.reason,
              })
          .toList();

      // Call API to process return
      final result = await OrderService.processItemReturn(
        orderId: _orderDetail!.id,
        returnItems: returnData,
      );

      // Hide loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true) {
        // Close return dialog
        if (mounted) {
          Navigator.of(context).pop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('${returnItems.length} items returned successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh order details
          _fetchOrderDetail();
          widget.onOrderUpdated();
        }
      }
    } catch (e) {
      // Hide loading if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      print("Failed to process return: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 👈 Updated showAddItemDialog method
  void _showAddItemDialog() {
    if (_orderDetail == null) return;

    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        orderDetail: _orderDetail!,
        onAddItems: _addItemsToOrder,
      ),
    );
  }

  // 👈 Updated method to handle multiple items with correct API format
  Future<void> _addItemsToOrder(List<CartItem> cartItems) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get current user for cashier ID
      final currentUser = await AuthService.getCurrentUser();
      final cashierId = currentUser?.id ?? 0;

      // Prepare items for API - convert CartItem to the expected format
      final newItems = cartItems.map((cartItem) {
        Map<String, dynamic> itemData = {
          'itemId': cartItem.id,
          'specificationId': cartItem.specificationId ?? cartItem.id,
          'quantity': cartItem.quantity,
          'price': cartItem.price,
          'total': cartItem.price * cartItem.quantity,
        };

        // Add accompaniments ID if available
        if (cartItem.accompanimentsIds != null &&
            cartItem.accompanimentsIds!.isNotEmpty) {
          // For single accompaniment, use the first one
          itemData['accompanimentsId'] =
              cartItem.accompanimentsIds!.first.toString();
          print(
              'Adding accompanimentsId: ${cartItem.accompanimentsIds!.first} for item: ${cartItem.itemName}'); // Debug log
        } else {
          print(
              'No accompaniments for item: ${cartItem.itemName}'); // Debug log
        }

        // Add comment if available
        if (cartItem.comment != null && cartItem.comment!.isNotEmpty) {
          itemData['comment'] = cartItem.comment;
        }

        return itemData;
      }).toList();

      // Prepare the complete request body
      final requestBody = {
        'orderId': _orderDetail!.id.toString(),
        'cashierId': cashierId.toString(),
        'newItems': newItems,
      };

      print('New Items Request Body: $requestBody'); // Debug log

      // Call API to add items to existing order
      final result = await OrderService.addItemToOrder(
        orderId: _orderDetail!.id,
        items: newItems,
      );
      print('Add Items Result: $result'); // Debug log      // Hide loading
      Navigator.of(context).pop();

      if (result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${cartItems.length} items added to order'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh order details
        _fetchOrderDetail();
        widget.onOrderUpdated();
      }
    } catch (e) {
      // Hide loading if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add items: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPrintOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.print, color: Colors.green),
            SizedBox(width: 8),
            Text('Print Options'),
          ],
        ),
        content: const Text('Choose how you want to print the receipt:'),
        actions: [
          // TextButton.icon(
          //   onPressed: () {
          //     Navigator.of(context).pop();
          //     _previewBill();
          //   },
          //   icon: const Icon(Icons.preview, size: 16),
          //   label: const Text('Preview'),
          //   style: TextButton.styleFrom(
          //     foregroundColor: Colors.blue,
          //   ),
          // ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _printBill();
            },
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Print'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading details',
                style: TextStyle(fontSize: 18, color: Colors.red[700]),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_errorMessage!, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchOrderDetail,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_orderDetail == null) {
      return const Center(child: Text('No order details found'));
    }

    // Check if user is cashier for conditional rendering
    final bool isCashier = _role?.toLowerCase() == 'cashier';

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true, // Always shows the draggable thumb
      thickness: 20.0, // More reasonable thickness for better usability
      radius: const Radius.circular(10), // Rounded corners for modern look
      trackVisibility: true, // Shows the background track
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Order Servedhhhhiii',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            _orderDetail!.orderNumber,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Add spacing between rows

                  // First row - Payment and Add Item (only show payment for cashiers)
                  if (isCashier) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _recordPayment,
                            icon: const Icon(Icons.payment, size: 20),
                            label: const Text('Record Payment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showAddItemDialog,
                            icon: const Icon(Icons.add_shopping_cart, size: 20),
                            label: const Text('Add New Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // For waiters, only show Add New Item in full width
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showAddItemDialog,
                            icon: const Icon(Icons.add_shopping_cart, size: 20),
                            label: const Text('Add New Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16), // Add spacing between rows

                  // Second row - Kitchen Items, Bar Items, and Print Bill
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLoadingKitchen ? null : _checkKitchenItems,
                          icon: _isLoadingKitchen
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.kitchen, size: 16),
                          label: Text(_isLoadingKitchen
                              ? 'Loading...'
                              : 'Kitchen Items'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingBar ? null : _checkBarItems,
                          icon: _isLoadingBar
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.local_bar, size: 16),
                          label:
                              Text(_isLoadingBar ? 'Loading...' : 'Bar Items'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showPrintOptions,
                          icon: const Icon(Icons.print, size: 20),
                          label: const Text('Print Bill'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Third row - Return Items (only for cashiers)
                  if (isCashier) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showReturnItemDialog,
                            icon: const Icon(Icons.keyboard_return, size: 20),
                            label: const Text('Return Items'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _removeServiceFees,
                            icon: const Icon(Icons.money_off, size: 20),
                            label: const Text('Remove Service Fees'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Info
            _buildInfoCard(),
            const SizedBox(height: 16),

            // Items
            Text(
              'Order Items',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Items list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _orderDetail!.items.length,
              itemBuilder: (context, index) {
                final item = _orderDetail!.items[index];
                return _buildItemCard(item);
              },
            ),
            const SizedBox(height: 16),

            // Scroll control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: "scrollTopBtn",
                  onPressed: _scrollToTop,
                  backgroundColor: Colors.green,
                  tooltip: "Scroll to top",
                  child: const Icon(Icons.arrow_upward, size: 20),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  heroTag: "scrollBottomBtn",
                  onPressed: _scrollToBottom,
                  backgroundColor: Colors.green,
                  tooltip: "Scroll to bottom",
                  child: const Icon(Icons.arrow_downward, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final order = _orderDetail!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16), // 👈 More space below

      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
              'Table', '${order.tableNumber} (${order.tableLocation})'),
          _buildInfoRow('Waiter', order.waiterName),
          if (order.clientName != null)
            _buildInfoRow('Client', order.clientName!),
          const Divider(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show discount only if greater than 0
              if (double.tryParse(order.discount) != null &&
                  double.parse(order.discount) > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      order.formattedSubtotal,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discount:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      '- ${order.formattedDiscount}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const Divider(thickness: 1),
              ],

              // Always show subtotal if no discount
              if (double.tryParse(order.discount) == null ||
                  double.parse(order.discount) == 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      order.formattedSubtotal,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
              ],

              // Show VAT if available
              if (order.vat != null && double.parse(order.vat!) > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'VAT:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      order.formattedVat,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
              ],

              // Show Service Fee if available
              if (order.serviceFee != null &&
                  double.parse(order.serviceFee!) > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Service Fee:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      order.formattedServiceFee,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
              ],

              // Show Grand Total if different from total
              if (order.grandTotal != null &&
                  double.parse(order.grandTotal!) !=
                      double.parse(order.total)) ...[
                const Divider(thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      order.formattedGrandTotal,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Divider(thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      order.formattedTotal,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  item.specificationName,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (item.accompanimentName != null &&
                    item.accompanimentName!.isNotEmpty)
                  Text(
                    'with ${item.accompanimentName}',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (item.hasComment)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.comment,
                            size: 14, color: Colors.orange[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.comment!,
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Text(
            'Qty: ${item.quantity}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Text(
            item.formattedTotalPrice,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
