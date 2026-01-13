// Updated file: lib/screens/orders/served_order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kozo/models/order_detail_model.dart';
import 'package:kozo/services/bill_receipt_services.dart';
import 'package:kozo/services/waiter_kitchen_receipt_services.dart';
import 'package:kozo/services/waiter_order_services.dart';
import 'package:kozo/waiterScreen/waiter_kitchen_item_selection_dialog.dart';
import '../../services/receipt_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
    );
  }
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

class WaiterDeliveryDetails extends StatefulWidget {
  final int orderId;
  final VoidCallback onOrderUpdated;

  const WaiterDeliveryDetails({
    super.key,
    required this.orderId,
    required this.onOrderUpdated,
  });

  @override
  State<WaiterDeliveryDetails> createState() => _WaiterDeliveryDetailsState();
}

class _WaiterDeliveryDetailsState extends State<WaiterDeliveryDetails> {
  OrderDetail? _orderDetail;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLoadingKitchen = false;
  KitchenItemsResponse? _kitchenItemsResponse;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  @override
  void didUpdateWidget(WaiterDeliveryDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      _fetchOrderDetail();
    }
  }

  Future<void> _fetchOrderDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final orderDetail =
          await WaiterOrderServices.fetchServedOrderDetail(widget.orderId);

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

      final response = await http.post(
        Uri.parse(
            'https://kigalisportlounge.hdev.rw/API/Orders/show_kichen_item'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'itemIds': itemIds,
          'orderId': _orderDetail!.id.toString(),
        }),
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

  // New method for preview selection
  void _showKitchenItemSelectionDialogForPreview(
      KitchenItemsResponse response) {
    Navigator.of(context).pop(); // Close the kitchen items dialog

    showDialog(
      context: context,
      builder: (context) => WaiterKitchenItemSelectionDialog(
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
      builder: (context) => WaiterKitchenItemSelectionDialog(
        response: response,
        onItemsSelected: (selectedItems) {
          _printKitchenReceipt(response, selectedItems);
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

      await WaiterKitchenReceiptServices.printKitchenReceipt(
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

      await WaiterKitchenReceiptServices.previewKitchenReceipt(
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

  // Remove the _recordPayment method
  // Remove the _processPayment method
  // Remove the _showReturnItemDialog method
  // Remove the _processReturnItems method

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
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

    return SingleChildScrollView(
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
                          'Order Served',
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

                // Only keep Add New Item button
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Show add item dialog
                        },
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
                const SizedBox(height: 16), // Add spacing between rows

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
                        label: Text(
                            _isLoadingKitchen ? 'Loading...' : 'Kitchen Items'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Show print options
                        },
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
          Text("")
        ],
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
                      'RWF ${order.subtotal}',
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
                      '- RWF ${order.discount}',
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'RWF ${order.total}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
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
                Text(
                  item.quantity.toString(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
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
