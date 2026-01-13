import 'package:flutter/material.dart';
import 'package:kozo/cashierScreens/completed_order_detail.dart';
import 'package:kozo/models/paymentMethodModel.dart';
import 'package:kozo/services/waiter_order_services.dart';
import '../../models/order_model.dart';
import '../../models/waiter_model.dart';
import '../../models/table_model.dart';
import '../../constants/app_constants.dart';

// Use PaymentMethod from waiter_order_services.dart

class WaiterOrderTabCompleted extends StatefulWidget {
  const WaiterOrderTabCompleted({super.key});

  @override
  State<WaiterOrderTabCompleted> createState() =>
      _WaiterOrderTabCompletedState();
}

class _WaiterOrderTabCompletedState extends State<WaiterOrderTabCompleted> {
  List<Order> _completedOrders = [];
  List<TableModel> _tables = [];
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;
  String? _errorMessage;
  Order? _selectedOrder;

  Waiter? _selectedWaiter;
  TableModel? _selectedTable;
  String _orderSearch = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedPaymentMethod;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // Add ScrollController

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose(); // Dispose ScrollController
    super.dispose();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchTables(),
      _fetchCompletedOrders(),
      _fetchPaymentMethods(),
    ]);
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      // Only show loading indicator if methods are empty
      if (_paymentMethods.isEmpty) {
        setState(() {
          _isLoading = true;
        });
      }

      final methods = await WaiterOrderServices.fetchPaymentMethods();

      if (mounted) {
        setState(() {
          _paymentMethods = methods;
          _isLoading = false;
        });
        debugPrint('✓ Fetched ${methods.length} payment methods');
      }
    } catch (e) {
      debugPrint('✗ Error fetching payment methods: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTables() async {
    try {
      final tables = await WaiterOrderServices.fetchTables();
      if (mounted) {
        setState(() {
          _tables = tables;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tables: $e');
    }
  }

  Future<void> _fetchCompletedOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final orders = await WaiterOrderServices.fetchCompletedOrders(
        dateFrom: _dateFrom?.toIso8601String().split('T')[0],
        dateTo: _dateTo?.toIso8601String().split('T')[0],
        paymentMethod: _selectedPaymentMethod,
        orderSearch: _orderSearch.isNotEmpty ? _orderSearch : null,
      );

      if (mounted) {
        setState(() {
          _completedOrders = orders;
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

  void _onFilterChanged() {
    _fetchCompletedOrders();
  }

  void _clearFilters() {
    setState(() {
      _selectedWaiter = null;
      _selectedTable = null;
      _dateFrom = null;
      _dateTo = null;
      _orderSearch = '';
      _selectedPaymentMethod = null;
      _searchController.clear();
    });
    _fetchCompletedOrders();
  }

  Future<void> _selectDate(bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
      _onFilterChanged();
    }
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                // First row - Date filters and search
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date From
                      SizedBox(
                        width: 200,
                        child: InkWell(
                          onTap: () => _selectDate(true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'From Date',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            child: Text(
                              _dateFrom != null
                                  ? '${_dateFrom!.day}/${_dateFrom!.month}/${_dateFrom!.year}'
                                  : 'Select date',
                              style: TextStyle(
                                color: _dateFrom != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Date To
                      SizedBox(
                        width: 200,
                        child: InkWell(
                          onTap: () => _selectDate(false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'To Date',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            child: Text(
                              _dateTo != null
                                  ? '${_dateTo!.day}/${_dateTo!.month}/${_dateTo!.year}'
                                  : 'Select date',
                              style: TextStyle(
                                color: _dateTo != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Search
                      SizedBox(
                        width: 300,
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search Orders',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _orderSearch = value;
                            });
                            _onFilterChanged();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Second row - Waiter, Table, Payment Method, Clear button
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 16),
                      // Table dropdown
                      SizedBox(
                        width: 200,
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
                      // Payment Method dropdown
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          value: _selectedPaymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Payment Method',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Methods'),
                            ),
                            ..._paymentMethods
                                .map((method) => DropdownMenuItem<String>(
                                      value: method.methodName,
                                      child: Text(method.displayName),
                                    )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value;
                            });
                            _onFilterChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Clear filters button
                      ElevatedButton.icon(
                        onPressed: (_selectedWaiter != null ||
                                _selectedTable != null ||
                                _dateFrom != null ||
                                _dateTo != null ||
                                _orderSearch.isNotEmpty ||
                                _selectedPaymentMethod != null)
                            ? _clearFilters
                            : null,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
              onPressed: _fetchCompletedOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_completedOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No completed orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No orders match your filters',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchCompletedOrders,
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
          child: RefreshIndicator(
            onRefresh: _fetchCompletedOrders,
            child: Scrollbar(
              controller: _scrollController, // Use the ScrollController
              thumbVisibility: true,
              thickness: 20.0, // Reduced thickness
              radius: const Radius.circular(4),
              trackVisibility: true, // Hide track for cleaner look
              child: ListView.builder(
                controller:
                    _scrollController, // Assign ScrollController to ListView
                padding: const EdgeInsets.all(30.0),
                itemCount: _completedOrders.length,
                itemBuilder: (context, index) {
                  final order = _completedOrders[index];
                  return _buildOrderCard(order, context);
                },
              ),
            ),
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
              ? CompletedOrderDetailScreen(
                  orderId: _selectedOrder!.id,
                  onOrderUpdated: _fetchCompletedOrders,
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
          color: isSelected ? AppColors.primary : Colors.blue.withOpacity(0.3),
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        'COMPLETED',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                    order.tableDisplay,
                    style: const TextStyle(
                      color: Colors.blue,
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
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.locationDisplay,
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Order Details
            Row(
              children: [
                Text(
                  'Order #: ${order.orderNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  order.paymentDate ?? 'Not Paid', // default text if null
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
                    color: Colors.blue,
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
