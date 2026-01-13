// File: lib/screens/dialogs/return_item_dialog.dart

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:kozo/models/order_detail_model.dart';
import 'package:kozo/services/order_service.dart';

class ReturnItemModel {
  final int orderItemId; // Add this field for the API
  final int itemId;
  final String itemName;
  final String specificationName;
  final int maxQuantity;
  int returnQuantity;
  final double unitPrice;
  String reason;

  ReturnItemModel({
    required this.orderItemId, // Add this parameter
    required this.itemId,
    required this.itemName,
    required this.specificationName,
    required this.maxQuantity,
    this.returnQuantity = 0,
    required this.unitPrice,
    this.reason = '',
  });

  double get totalReturnAmount => unitPrice * returnQuantity;
}

class ReturnItemDialog extends StatefulWidget {
  final OrderDetail orderDetail;
  final Function(List<ReturnItemModel>) onReturnItems;

  const ReturnItemDialog({
    super.key,
    required this.orderDetail,
    required this.onReturnItems,
  });

  @override
  State<ReturnItemDialog> createState() => _ReturnItemDialogState();
}

class _ReturnItemDialogState extends State<ReturnItemDialog> {
  late List<ReturnItemModel> returnItems;
  List<String> _returnReasons = [];
  bool _isLoadingReasons = true;

  @override
  void initState() {
    super.initState();
    _initializeReturnItems();
    _fetchReturnReasons();
  }

  Future<void> _fetchReturnReasons() async {
    try {
      final reasons = await OrderService.fetchReturnReasons();
      setState(() {
        _returnReasons = reasons;
        _isLoadingReasons = false;
      });
    } catch (e) {
      print('Failed to fetch return reasons: $e');
      setState(() {
        _isLoadingReasons = false;
      });
    }
  }

  void _initializeReturnItems() {
    returnItems = widget.orderDetail.items.map((item) {
      return ReturnItemModel(
        orderItemId: item.id, // Use the order item ID from the order detail
        itemId: item.menuItemId,
        itemName: item.itemName,
        specificationName: item.specificationName,
        maxQuantity: item.quantity,
        unitPrice: double.parse(item.unitPrice.toString()),
      );
    }).toList();
  }

  List<ReturnItemModel> get selectedReturnItems {
    return returnItems.where((item) => item.returnQuantity > 0).toList();
  }

  double get totalReturnAmount {
    return selectedReturnItems.fold(
        0.0, (sum, item) => sum + item.totalReturnAmount);
  }

  void _updateReturnQuantity(int index, int quantity) {
    setState(() {
      returnItems[index].returnQuantity = quantity;
    });
  }

  void _updateReason(int index, String reason) {
    setState(() {
      returnItems[index].reason = reason;
    });
  }

  bool _validateReturnItems() {
    final selectedItems = selectedReturnItems;

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item to return'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    for (var item in selectedItems) {
      if (item.reason.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide a reason for all returned items'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
    }

    return true;
  }

  void _handleReturn() {
    if (_validateReturnItems()) {
      widget.onReturnItems(selectedReturnItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.keyboard_return, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Return Items - Order ${widget.orderDetail.orderNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Items list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: returnItems.length,
                itemBuilder: (context, index) {
                  return _buildReturnItemCard(returnItems[index], index);
                },
              ),
            ),

            // Summary and actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                border: Border(
                  top: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
              ),
              child: Column(
                children: [
                  if (selectedReturnItems.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Items to return: ${selectedReturnItems.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total refund: RWF ${totalReturnAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: selectedReturnItems.isNotEmpty
                              ? _handleReturn
                              : null,
                          icon: const Icon(Icons.keyboard_return),
                          label: const Text('Process Return'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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
          ],
        ),
      ),
    );
  }

  Widget _buildReturnItemCard(ReturnItemModel item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.returnQuantity > 0
              ? Colors.red
              : Colors.grey.withOpacity(0.3),
          width: item.returnQuantity > 0 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item info
          Row(
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
                      'Unit Price: RWF ${item.unitPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Available: ${item.maxQuantity}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quantity selector
          Row(
            children: [
              const Text('Return Quantity: '),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: item.returnQuantity > 0
                          ? () => _updateReturnQuantity(
                              index, item.returnQuantity - 1)
                          : null,
                      icon: const Icon(Icons.remove, size: 16),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Text(
                        item.returnQuantity.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: item.returnQuantity < item.maxQuantity
                          ? () => _updateReturnQuantity(
                              index, item.returnQuantity + 1)
                          : null,
                      icon: const Icon(Icons.add, size: 16),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (item.returnQuantity > 0)
                Text(
                  'Refund: RWF ${item.totalReturnAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
            ],
          ),

          // Reason field (only show if item is selected for return)
          if (item.returnQuantity > 0) ...[
            const SizedBox(height: 12),
            const Text(
              'Reason for return:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            _isLoadingReasons
                ? const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : DropdownSearch<String>(
                    items: (filter, infiniteScrollProps) => _returnReasons,
                    selectedItem: item.reason.isNotEmpty ? item.reason : null,
                    onChanged: (value) {
                      if (value != null) {
                        _updateReason(index, value);
                      }
                    },
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        hintText: 'Select reason for return',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        suffixIcon: item.reason.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => _updateReason(index, ''),
                              )
                            : null,
                      ),
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search reasons...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                      fit: FlexFit.loose,
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}
