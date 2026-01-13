// filepath: d:\Projrct in Flutter\smart_server\smart_server\lib\screens\orders\order_tab_delivery.dart
import 'package:flutter/material.dart';
import 'package:kozo/cashierScreens/served_order_detail.dart';
import '../../constants/app_constants.dart';
import '../../models/order_model.dart';
import '../../models/waiter_model.dart';
import '../../models/table_model.dart';
import '../../services/order_service.dart';
import 'order_partialPayment_detail_screen.dart';

class OrderTabDelivery extends StatefulWidget {
  const OrderTabDelivery({super.key});

  @override
  State<OrderTabDelivery> createState() => _OrderTabDeliveryState();
}

class _OrderTabDeliveryState extends State<OrderTabDelivery> {
  List<Order> _servedOrders = [];
  List<Waiter> _waiters = [];
  List<TableModel> _tables = [];
  bool _isLoading = true;
  String? _errorMessage;
  Order? _selectedOrder;

  Waiter? _selectedWaiter;
  TableModel? _selectedTable;
  String _orderSearch = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
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
      _fetchWaiters(),
      _fetchTables(),
      _fetchServedOrders(),
    ]);
  }

  Future<void> _fetchWaiters() async {
    try {
      final waiters = await OrderService.fetchWaiters();
      if (mounted) {
        setState(() {
          _waiters = waiters;
        });
      }
    } catch (e) {
      debugPrint('Error fetching waiters: $e');
    }
  }

  Future<void> _fetchTables() async {
    try {
      final tables = await OrderService.fetchTablesOccupied();
      if (mounted) {
        setState(() {
          _tables = tables;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tables: $e');
    }
  }

  Future<void> _fetchServedOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final orders = await OrderService.fetchServedOrders(
        dateFrom: _dateFrom?.toIso8601String().split('T')[0],
        dateTo: _dateTo?.toIso8601String().split('T')[0],
        waiterId: _selectedWaiter?.id,
        tableId: _selectedTable?.id,
        orderSearch: _orderSearch.isNotEmpty ? _orderSearch : null,
      );

      if (mounted) {
        setState(() {
          _servedOrders = orders;
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
    _fetchServedOrders();
  }

  void _clearFilters() {
    setState(() {
      _selectedWaiter = null;
      _selectedTable = null;
      _dateFrom = null;
      _dateTo = null;
      _orderSearch = '';
      _searchController.clear();
    });
    _fetchServedOrders();
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
          child: Scrollbar(
            controller: _filtersScrollController,
            thumbVisibility: true,
            thickness: 20.0,
            radius: const Radius.circular(10),
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _filtersScrollController,
              child: Column(
                children: [
                  // First row - Date filters and search
                  Scrollbar(
                    controller: _filtersScrollController,
                    thumbVisibility: true,
                    thickness: 20.0,
                    radius: const Radius.circular(4),
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: _filtersScrollController,
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
                  ),
                  const SizedBox(height: 16),
                  // Second row - Waiter, Table, Clear button
                  Scrollbar(
                    controller: _filtersScrollController,
                    thumbVisibility: true,
                    thickness: 20.0,
                    radius: const Radius.circular(4),
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: _filtersScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Waiter dropdown
                          SizedBox(
                            width: 250,
                            child: DropdownButtonFormField<Waiter>(
                              value: _selectedWaiter,
                              decoration: const InputDecoration(
                                labelText: 'Filter by Waiter',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem<Waiter>(
                                  value: null,
                                  child: Text('All Waiters'),
                                ),
                                ..._waiters
                                    .map((waiter) => DropdownMenuItem<Waiter>(
                                          value: waiter,
                                          child: Text(waiter.name),
                                        )),
                              ],
                              onChanged: (waiter) {
                                setState(() {
                                  _selectedWaiter = waiter;
                                });
                                _onFilterChanged();
                              },
                            ),
                          ),
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
                                ..._tables.map(
                                    (table) => DropdownMenuItem<TableModel>(
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
                            onPressed: (_selectedWaiter != null ||
                                    _selectedTable != null ||
                                    _dateFrom != null ||
                                    _dateTo != null ||
                                    _orderSearch.isNotEmpty)
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
        child: Scrollbar(
          controller: _filtersScrollController,
          thumbVisibility: true,
          thickness: 20.0,
          radius: const Radius.circular(4),
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _filtersScrollController,
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
                  onPressed: _fetchServedOrders,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_servedOrders.isEmpty) {
      return Center(
        child: Scrollbar(
          controller: _filtersScrollController,
          thumbVisibility: true,
          thickness: 20.0,
          radius: const Radius.circular(4),
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _filtersScrollController,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No served orders',
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
                  onPressed: _fetchServedOrders,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
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
                  onRefresh: _fetchServedOrders,
                  child: Scrollbar(
                    controller: _ordersListScrollController,
                    thumbVisibility: true,
                    thickness: 20.0,
                    radius: const Radius.circular(4),
                    trackVisibility: true,
                    child: ListView.builder(
                      controller: _ordersListScrollController,
                      padding: const EdgeInsets.all(30.0),
                      itemCount: _servedOrders.length,
                      itemBuilder: (context, index) {
                        final order = _servedOrders[index];
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
              ? ServedOrderDetailScreen(
                  orderId: _selectedOrder!.id,
                  onOrderUpdated: _fetchServedOrders,
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
          color: isSelected ? AppColors.primary : Colors.green.withOpacity(0.3),
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'SERVED',
                        style: const TextStyle(
                          color: Colors.green,
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
                  '${order.orderNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  order.updatedAt!, // make sure this is a formatted date string
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
