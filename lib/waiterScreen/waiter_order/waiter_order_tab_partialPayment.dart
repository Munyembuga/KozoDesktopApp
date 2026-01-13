import 'package:flutter/material.dart';
import 'package:kozo/cashierScreens/orders/order_partialPayment_detail_screen.dart';
import 'package:kozo/services/waiter_order_services.dart';
import '../../constants/app_constants.dart';
import '../../models/order_model.dart';
import '../../models/waiter_model.dart';
import '../../models/table_model.dart';
import '../../services/order_service.dart';

class waiterOrderTabPartialPayment extends StatefulWidget {
  const waiterOrderTabPartialPayment({super.key});

  @override
  State<waiterOrderTabPartialPayment> createState() =>
      _waiterOrderTabPartialPaymentState();
}

class _waiterOrderTabPartialPaymentState
    extends State<waiterOrderTabPartialPayment> {
  List<Order> _pendingOrders = [];
  List<Waiter> _waiters = [];
  List<TableModel> _tables = [];
  bool _isLoading = true;
  String? _errorMessage;
  Order? _selectedOrder;

  Waiter? _selectedWaiter;
  TableModel? _selectedTable;

  // Scroll controllers
  final ScrollController _filtersScrollController = ScrollController();
  final ScrollController _ordersListScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _filtersScrollController.dispose();
    _ordersListScrollController.dispose();
    super.dispose();
  }

  // Scroll to top of orders list
  void _scrollOrdersToTop() {
    if (_ordersListScrollController.hasClients) {
      _ordersListScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // Scroll to bottom of orders list
  void _scrollOrdersToBottom() {
    if (_ordersListScrollController.hasClients) {
      _ordersListScrollController.animateTo(
        _ordersListScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchTables(),
      _fetchPartialPaymentOrders(),
    ]);
  }

  Future<void> _fetchTables() async {
    try {
      final tables = await WaiterOrderServices.fetchTablesOccupied();
      if (mounted) {
        setState(() {
          _tables = tables;
        });
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      debugPrint('Error fetching tables: $e');
    }
  }

  Future<void> _fetchPartialPaymentOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final orders = await WaiterOrderServices.fetchPartialPaymentOrders(
        tableId: _selectedTable?.id,
      );

      if (mounted) {
        setState(() {
          _pendingOrders = orders;

          // Check if currently selected order still exists in the updated list
          if (_selectedOrder != null) {
            final orderStillExists =
                orders.any((order) => order.id == _selectedOrder!.id);
            if (!orderStillExists) {
              // Clear selection if the order no longer exists (e.g., was marked as delivered)
              _selectedOrder = null;
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Add a method to handle order updates from the details screen
  void _onOrderUpdated() {
    // Refresh the orders list
    _fetchPartialPaymentOrders();
  }

  void _onFilterChanged() {
    _fetchPartialPaymentOrders();
  }

  void _clearFilters() {
    setState(() {
      _selectedWaiter = null;
      _selectedTable = null;
    });
    _fetchPartialPaymentOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Scrollbar(
                controller: _filtersScrollController,
                thumbVisibility: true,
                thickness: 20.0,
                radius: const Radius.circular(10),
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: _filtersScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 16),
                      // Table dropdown
                      SizedBox(
                        width: 250,
                        child: DropdownButtonFormField<TableModel>(
                          value: _selectedTable,
                          decoration: const InputDecoration(
                            labelText: 'Filter by Table',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<TableModel>(
                              value: null,
                              child: Text('All Tables'),
                            ),
                            ..._tables
                                .map((table) => DropdownMenuItem<TableModel>(
                                      value: table,
                                      child: Text(
                                          '${table.tableName} (${table.location})'),
                                    )),
                          ],
                          onChanged: (table) {
                            setState(() {
                              _selectedTable = table;
                            });
                            _onFilterChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Clear filters button
                      ElevatedButton.icon(
                        onPressed:
                            (_selectedWaiter != null || _selectedTable != null)
                                ? _clearFilters
                                : null,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Orders content
        Expanded(
          child: _buildOrdersContent(),
        ),
      ],
    );
  }

  Widget _buildOrdersContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchPartialPaymentOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pendingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Partial Payment orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All orders have been processed',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchPartialPaymentOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // Split screen layout for desktop
    return Row(
      children: [
        // Orders list (left side)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchPartialPaymentOrders,
                  child: Scrollbar(
                    controller: _ordersListScrollController,
                    thumbVisibility: true,
                    thickness: 20.0,
                    radius: const Radius.circular(10),
                    trackVisibility: true,
                    child: ListView.builder(
                      controller: _ordersListScrollController,
                      padding: const EdgeInsets.all(30.0),
                      itemCount: _pendingOrders.length,
                      itemBuilder: (context, index) {
                        final order = _pendingOrders[index];
                        return _buildOrderCard(order, context);
                      },
                    ),
                  ),
                ),
              ),
              // Scroll control buttons
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton.small(
                      heroTag: "scrollTopBtnOrders",
                      onPressed: _scrollOrdersToTop,
                      backgroundColor: Colors.green,
                      tooltip: "Scroll to top",
                      child: const Icon(
                        Icons.arrow_upward,
                        size: 20,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      heroTag: "scrollBottomBtnOrders",
                      onPressed: _scrollOrdersToBottom,
                      backgroundColor: Colors.green,
                      tooltip: "Scroll to bottom",
                      child: const Icon(
                        Icons.arrow_downward,
                        size: 20,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Divider
        Container(
          width: 1,
          color: Colors.grey[300],
        ),
        // Order details (right side)
        Expanded(
          flex: 1,
          child: _selectedOrder != null
              ? OrderDetailScreen(
                  orderId: _selectedOrder!.id,
                  onOrderUpdated: _onOrderUpdated, // Use the new callback
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select an order to view details',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Order order, BuildContext context) {
    final isSelected = _selectedOrder?.id == order.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color:
              isSelected ? AppColors.primary : Colors.orange.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedOrder = order;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.tableDisplay,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.locationDisplay,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        order.waitTime,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Order Details
            Row(
              children: [
                Text(
                  '${order.orderNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  order.createdAt, // make sure this is a formatted date string
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Waiter: ${order.waiterName}',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            if (order.clientName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Client: ${order.clientName}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.restaurant_menu, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${order.itemCount} items',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  order.grandTotal != null && order.grandTotal!.isNotEmpty
                      ? order.formattedGrandTotal
                      : order.formattedTotal,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
