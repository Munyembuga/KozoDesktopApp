import 'package:flutter/material.dart';
import 'package:kozo/models/order_detail_model.dart';
import 'package:kozo/models/order_model.dart';
import 'package:kozo/models/table_model.dart';
import 'package:kozo/models/waiter_model.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:kozo/services/order_service.dart';
import 'package:kozo/services/auth_service.dart';

class TransferItemDialog extends StatefulWidget {
  final OrderItem item;

  const TransferItemDialog({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<TransferItemDialog> createState() => _TransferItemDialogState();
}

class _TransferItemDialogState extends State<TransferItemDialog> {
  bool _isLoading = false;
  List<Order> _activeOrders = [];
  Order? _selectedOrder;
  String? _errorMessage;

  // Add ScrollController for orders list
  late ScrollController _ordersScrollController;

  // Quantity control
  int _transferQuantity = 1;

  // For creating new order
  bool _createNewOrder = false;
  List<TableModel> _tables = [];
  List<Waiter> _waiters = [];
  TableModel? _selectedTable;
  Waiter? _selectedWaiter;
  bool _isLoadingTables = false;
  bool _isLoadingWaiters = false;

  @override
  void initState() {
    super.initState();
    _transferQuantity =
        widget.item.quantity; // Initialize with current quantity
    // Initialize scroll controller
    _ordersScrollController = ScrollController();
    _fetchActiveOrders();
    _fetchTables();
    _fetchWaiters();
  }

  @override
  void dispose() {
    // Dispose the scroll controller
    _ordersScrollController.dispose();
    super.dispose();
  }

  // Quantity control helper methods
  void _incrementQuantity() {
    if (_transferQuantity < widget.item.quantity) {
      setState(() {
        _transferQuantity++;
      });
    }
  }

  void _decrementQuantity() {
    if (_transferQuantity > 1) {
      setState(() {
        _transferQuantity--;
      });
    }
  }

  void _setQuantity(int quantity) {
    if (quantity >= 1 && quantity <= widget.item.quantity) {
      setState(() {
        _transferQuantity = quantity;
      });
    }
  }

  Future<void> _fetchTables() async {
    try {
      setState(() {
        _isLoadingTables = true;
      });

      final tables = await OrderService.fetchTables();
      if (mounted) {
        setState(() {
          _tables = tables;
          _isLoadingTables = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tables: $e');
      if (mounted) {
        setState(() {
          _isLoadingTables = false;
        });
      }
    }
  }

  Future<void> _fetchWaiters() async {
    try {
      setState(() {
        _isLoadingWaiters = true;
      });

      final waiters = await OrderService.fetchWaiters();
      if (mounted) {
        // Add the self-handled (cashier) option at the beginning
        final defaultWaiter = Waiter(id: -1, name: 'Cashier (Self-handled)');
        setState(() {
          _waiters = [defaultWaiter, ...waiters];
          _selectedWaiter = defaultWaiter; // Default to self-handled
          _isLoadingWaiters = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching waiters: $e');
      if (mounted) {
        setState(() {
          _isLoadingWaiters = false;
        });
      }
    }
  }

  Future<void> _fetchActiveOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Use OrderService to fetch real active orders
      final servedOrders = await OrderService.fetchDifferentOrder(
          orderId: widget.item.orderId.toString());

      if (mounted) {
        setState(() {
          _activeOrders = servedOrders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _transferItem() async {
    // For existing order transfer
    if (!_createNewOrder) {
      if (_selectedOrder == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a destination order')));
        return;
      }

      try {
        setState(() {
          _isLoading = true;
        });

        // Call the OrderService transfer method for existing order
        final result = await OrderService.transferItem(
          sourceOrderId: int.parse(widget.item.orderId.toString()),
          sourceItemId: widget.item.id,
          quantity: _transferQuantity, // Use the selected quantity
          targetOrderId: _selectedOrder!.id,
          // For existing order transfer, we use the current user's ID
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          Navigator.of(context).pop(result['success']); // Return success status

          // Show result message
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result['message'] ?? 'Item transfer completed'),
            backgroundColor: result['success'] ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ));
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
    // For new order creation
    else {
      if (_selectedTable == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a table')));
        return;
      }

      if (_selectedWaiter == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a waiter')));
        return;
      }

      try {
        setState(() {
          _isLoading = true;
        });

        // Get current user for self-handling cases
        final currentUser = await AuthService.getCurrentUser();
        if (currentUser == null) {
          throw Exception('User not logged in');
        }

        // Determine the actual handler ID to use
        int actualHandlerId;
        if (_selectedWaiter!.id == -1) {
          // Self-handled case: use current user ID
          actualHandlerId = currentUser.id;
        } else {
          // Waiter-handled case: use selected waiter ID
          actualHandlerId = _selectedWaiter!.id;
        }

        // Create a new order with the item transfer
        final orderResult = await OrderService.transferItem(
          sourceOrderId: int.parse(widget.item.orderId.toString()),
          sourceItemId: widget.item.id,
          quantity: _transferQuantity, // Use the selected quantity
          tableId: _selectedTable!.id,
          handlerId: actualHandlerId, // Pass the correct handler ID
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (orderResult['success'] == true) {
            Navigator.of(context).pop(true); // Return success

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'New order created with transferred item: ${orderResult['order_number']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ));
          } else {
            // Show error message from API
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(orderResult['message'] ?? 'Failed to create new order'),
              backgroundColor: Colors.red,
            ));
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.swap_horiz, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Transfer Item',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Item details with quantity selector
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Specification: ${widget.item.specificationName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (widget.item.accompanimentName != null &&
                      widget.item.accompanimentName!.isNotEmpty)
                    Text(
                      'with ${widget.item.accompanimentName}',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Quantity selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transfer Quantity:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Available: ${widget.item.quantity}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _transferQuantity > 1
                                  ? _decrementQuantity
                                  : null,
                              icon: const Icon(Icons.remove),
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 40),
                              child: Text(
                                '$_transferQuantity',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  _transferQuantity < widget.item.quantity
                                      ? _incrementQuantity
                                      : null,
                              icon: const Icon(Icons.add),
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Transfer options
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _createNewOrder = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_createNewOrder
                            ? Colors.blue.shade100
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !_createNewOrder
                              ? Colors.blue.shade400
                              : Colors.grey.shade300,
                          width: !_createNewOrder ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            color: !_createNewOrder
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Existing Order',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: !_createNewOrder
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _createNewOrder = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _createNewOrder
                            ? Colors.green.shade100
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _createNewOrder
                              ? Colors.green.shade400
                              : Colors.grey.shade300,
                          width: _createNewOrder ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle,
                            color: _createNewOrder
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'New Order',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _createNewOrder
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Show appropriate content based on selected option
            if (!_createNewOrder) ...[
              // Existing order selection
              const Text(
                'Select Destination Order:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),

              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _activeOrders.isEmpty
                          ? const Center(
                              child: Text('No active orders available'),
                            )
                          : Scrollbar(
                              controller: _ordersScrollController,
                              thickness: 20.0,
                              radius: const Radius.circular(10),
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: ListView.builder(
                                controller: _ordersScrollController,
                                itemCount: _activeOrders.length,
                                itemBuilder: (context, index) {
                                  final order = _activeOrders[index];
                                  final isSelected = _selectedOrder == order;

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedOrder = order;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.blue.shade100
                                            : Colors.white,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected
                                                ? Icons.check_circle
                                                : Icons.circle_outlined,
                                            color: isSelected
                                                ? Colors.blue
                                                : Colors.grey,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Order: ${order.orderNumber}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'Table: ${order.tableDisplay} | Waiter: ${order.waiterName}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
            ] else ...[
              // New order creation UI
              // Table and Waiter selection
              Row(
                children: [
                  // Waiter Section
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Waiter',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _isLoadingWaiters
                              ? const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : DropdownSearch<Waiter>(
                                  selectedItem: _selectedWaiter,
                                  items: (filter, infiniteScrollProps) {
                                    return _waiters;
                                  },
                                  itemAsString: (Waiter waiter) => waiter.name,
                                  compareFn: (Waiter? a, Waiter? b) =>
                                      a?.id == b?.id,
                                  decoratorProps: DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      labelText: 'Select Waiter',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    showSelectedItems: true,
                                    scrollbarProps: ScrollbarProps(
                                      thickness: 8,
                                      radius: Radius.circular(10),
                                      thumbVisibility: true,
                                      trackVisibility: true,
                                    ),
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: 'Search waiters...',
                                        prefixIcon: Icon(Icons.search),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    menuProps: MenuProps(
                                      borderRadius: BorderRadius.circular(8),
                                      elevation: 2,
                                    ),
                                    itemBuilder: (context, item, isDisabled,
                                        isSelected) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Text(
                                          item.name,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  onChanged: (waiter) {
                                    if (waiter != null) {
                                      setState(() {
                                        _selectedWaiter = waiter;
                                      });
                                    }
                                  },
                                  validator: (Waiter? value) {
                                    if (value == null) {
                                      return 'Please select a waiter';
                                    }
                                    return null;
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),

                  // Table Section
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Table',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _isLoadingTables
                              ? const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : DropdownButtonFormField<TableModel>(
                                  value: _selectedTable,
                                  decoration: InputDecoration(
                                    labelText: 'Select Table',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  isExpanded: true,
                                  items: _tables.map((table) {
                                    return DropdownMenuItem<TableModel>(
                                      value: table,
                                      child: Text(
                                          '${table.tableName} (${table.location})'),
                                    );
                                  }).toList(),
                                  onChanged: (table) {
                                    setState(() {
                                      _selectedTable = table;
                                    });
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Action buttons
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _transferItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_createNewOrder
                          ? 'Create New Order'
                          : 'Transfer Item'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
