import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kozo/services/auth_service.dart';
import '../../constants/app_constants.dart';
import '../../services/report_service.dart';

class CompletedOrderReport extends StatefulWidget {
  const CompletedOrderReport({Key? key}) : super(key: key);

  @override
  State<CompletedOrderReport> createState() => _CompletedOrderReportState();
}

class _CompletedOrderReportState extends State<CompletedOrderReport> {
  final ReportService _reportService = ReportService();
  bool _isLoading = false;
  String _error = '';
  List<dynamic>? _orders;

  // Pagination variables
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalPages = 1;

  // Default date range for the last 24 hours
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime _toDate = DateTime.now();
  String _paymentMethodFilter = "";
  int? _cashierId; // This could be obtained from user context or preferences

  // Format for date display and API request
  final DateFormat _displayDateFormat = DateFormat('MMM dd, yyyy HH:mm');
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd HH:mm');
  final DateFormat _displayOrderDateFormat = DateFormat('dd/MM/yyyy HH:mm');

  // Total amount of all orders
  double _totalAmount = 0;

  // Payment method filter options
  final List<Map<String, String>> _paymentMethodOptions = [
    {'display': 'All', 'value': ''},
    {'display': 'Mobile Money', 'value': 'mobile_money'},
    {'display': 'Cash', 'value': 'cash'},
    {'display': 'Card', 'value': 'card'},
  ];
  String _selectedPaymentMethodDisplay = 'All';

  @override
  void initState() {
    super.initState();
    _initUserAndFetchData();
  }

  Future<void> _initUserAndFetchData() async {
    final currentUser = await AuthService.getCurrentUser();
    if (currentUser == null) {
      throw Exception('User not logged in');
    }
    setState(() {
      _cashierId = currentUser.id;
    });
    _fetchCompletedOrders();
  }

  // Format currency amounts
  String _formatCurrency(dynamic amount) {
    final formatter = NumberFormat.currency(symbol: 'RWF ', decimalDigits: 0);
    if (amount is String) {
      return formatter.format(double.tryParse(amount) ?? 0);
    } else {
      return formatter.format(amount ?? 0);
    }
  }

  Future<void> _fetchCompletedOrders() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Check if cashier ID is null and handle it
      if (_cashierId == null) {
        throw Exception('Cashier ID is not available. Please log in again.');
      }

      final orders = await _reportService.getCompletedOrders(
        cashierId: _cashierId!, // Add the non-null assertion operator
        dateTimeFrom: _apiDateFormat.format(_fromDate),
        dateTimeTo: _apiDateFormat.format(_toDate),
        paymentMethodFilter: _paymentMethodFilter,
      );
      print("Response Data: $orders");

      // Calculate total amount
      double total = 0;
      for (var order in orders) {
        total += double.parse(order['total'].toString());
      }

      // Calculate total pages
      _totalPages = (orders.length / _pageSize).ceil();
      if (_totalPages < 1) _totalPages = 1;

      // Ensure current page is within valid range
      if (_currentPage > _totalPages) {
        _currentPage = _totalPages;
      }

      setState(() {
        _orders = orders;
        _totalAmount = total;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Custom date-time picker for selecting start date and time
  Future<void> _selectFromDateTime(BuildContext context) async {
    // First select the date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Start Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Then select the time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_fromDate),
        helpText: 'Select Start Time',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      // Create a new DateTime with the selected date and time
      if (pickedTime != null) {
        setState(() {
          _fromDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });

        // Make sure _toDate is not before _fromDate
        if (_toDate.isBefore(_fromDate)) {
          setState(() {
            _toDate = _fromDate.add(const Duration(hours: 1));
          });
        }

        _fetchCompletedOrders();
      }
    }
  }

  // Custom date-time picker for selecting end date and time
  Future<void> _selectToDateTime(BuildContext context) async {
    // First select the date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate, // Can't select a date before the start date
      lastDate: DateTime.now(),
      helpText: 'Select End Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Then select the time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_toDate),
        helpText: 'Select End Time',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      // Create a new DateTime with the selected date and time
      if (pickedTime != null) {
        setState(() {
          _toDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
        _fetchCompletedOrders();
      }
    }
  }

  // Get payment method icon and color
  Map<String, dynamic> _getPaymentMethodInfo(String methodType) {
    if (methodType.contains(',')) {
      return {
        'icon': Icons.payments,
        'color': Colors.purple,
        'name': 'Multiple'
      };
    }

    switch (methodType.trim()) {
      case 'mobile_money':
        return {
          'icon': Icons.phone_android,
          'color': Colors.purple,
          'name': 'Mobile Money'
        };
      case 'cash':
        return {'icon': Icons.money, 'color': Colors.green, 'name': 'Cash'};
      case 'card':
        return {
          'icon': Icons.credit_card,
          'color': Colors.blue,
          'name': 'Card'
        };
      default:
        return {
          'icon': Icons.help_outline,
          'color': Colors.grey,
          'name': methodType
        };
    }
  }

  // Get paginated orders
  List<dynamic> get _paginatedOrders {
    if (_orders == null || _orders!.isEmpty) {
      return [];
    }

    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize > _orders!.length
        ? _orders!.length
        : startIndex + _pageSize;

    if (startIndex >= _orders!.length) {
      return [];
    }

    return _orders!.sublist(startIndex, endIndex);
  }

  // Navigate to previous page
  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  // Navigate to next page
  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }

  // Navigate to specific page
  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Completed Orders Report',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  children: [
                    // From date-time selector
                    InkWell(
                      onTap: () => _selectFromDateTime(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.lightGrey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'From: ${_displayDateFormat.format(_fromDate)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // To date-time selector
                    InkWell(
                      onTap: () => _selectToDateTime(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.lightGrey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'To: ${_displayDateFormat.format(_toDate)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // IconButton(
                    //   icon: const Icon(Icons.print, color: AppColors.primary),
                    //   onPressed: () {
                    //     // Implement print functionality here
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //         const SnackBar(
                    //             content: Text('Printing report...')));
                    //   },
                    //   tooltip: 'Print Report',
                    // ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter section with total amount display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFilterDropdown(
                        'Payment Method',
                        _paymentMethodOptions,
                        (display, value) {
                          setState(() {
                            _paymentMethodFilter = value;
                            _currentPage =
                                1; // Reset to first page on filter change
                          });
                          _fetchCompletedOrders();
                        },
                      ),

                      // Order count and total amount summary
                      if (_orders != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total Orders: ${_orders!.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Amount: ${_formatCurrency(_totalAmount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Loading indicator or error message
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchCompletedOrders,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_orders == null || _orders!.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.grey, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'No completed orders found for the selected period',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildOrdersTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, List<Map<String, String>> options,
      Function(String, String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightGrey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPaymentMethodDisplay,
              isDense: true,
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option['display'],
                  child: Text(option['display']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final selectedOption = options.firstWhere(
                    (option) => option['display'] == value,
                    orElse: () => options.first,
                  );
                  setState(() {
                    _selectedPaymentMethodDisplay = value;
                  });
                  onChanged(value, selectedOption['value']!);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Order Number')),
                DataColumn(label: Text('Table')),
                DataColumn(label: Text('Created Date')),
                DataColumn(label: Text('Payment Date')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Payment Method')),
                // DataColumn(label: Text('Actions')),
              ],
              rows: _paginatedOrders.map<DataRow>((order) {
                final paymentInfo =
                    _getPaymentMethodInfo(order['payment_methods']);

                return DataRow(cells: [
                  DataCell(Text(order['order_number'])),
                  DataCell(Text(order['table_number'])),
                  DataCell(Text(_displayOrderDateFormat
                      .format(DateTime.parse(order['created_at'])))),
                  DataCell(Text(_displayOrderDateFormat
                      .format(DateTime.parse(order['payment_date'])))),
                  DataCell(Text(_formatCurrency(order['total']),
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Row(
                    children: [
                      Icon(paymentInfo['icon'],
                          color: paymentInfo['color'], size: 16),
                      const SizedBox(width: 4),
                      Text(paymentInfo['name']),
                    ],
                  )),
                  // DataCell(
                  //   Row(
                  //     children: [
                  //       IconButton(
                  //         icon: const Icon(Icons.visibility,
                  //             size: 20, color: AppColors.primary),
                  //         onPressed: () {
                  //           // View order details
                  //           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  //               content: Text(
                  //                   'Viewing order ${order['order_number']}')));
                  //         },
                  //         tooltip: 'View Order',
                  //         constraints: const BoxConstraints(),
                  //         padding: const EdgeInsets.all(4),
                  //       ),
                  //       const SizedBox(width: 8),
                  //       IconButton(
                  //         icon: const Icon(Icons.receipt,
                  //             size: 20, color: AppColors.primary),
                  //         onPressed: () {
                  //           // Print receipt
                  //           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  //               content: Text(
                  //                   'Printing receipt for ${order['order_number']}')));
                  //         },
                  //         tooltip: 'Print Receipt',
                  //         constraints: const BoxConstraints(),
                  //         padding: const EdgeInsets.all(4),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ]);
              }).toList(),
            ),
          ),

          // Pagination controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Page information
                Text(
                  'Showing ${_paginatedOrders.length} of ${_orders!.length} orders | Page $_currentPage of $_totalPages',
                  style: TextStyle(
                    color: AppColors.grey,
                  ),
                ),

                // Pagination controls
                Row(
                  children: [
                    // Export button
                    // ElevatedButton.icon(
                    //   onPressed: () {
                    //     // Export to Excel functionality
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //         const SnackBar(
                    //             content: Text('Exporting to Excel...')));
                    //   },
                    //   icon: const Icon(Icons.file_download),
                    //   label: const Text('Export'),
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: AppColors.primary,
                    //     foregroundColor: Colors.white,
                    //   ),
                    // ),

                    const SizedBox(width: 16),

                    // Page navigation
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.lightGrey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          // Previous page button
                          IconButton(
                            icon: Icon(
                              Icons.chevron_left,
                              color: _currentPage > 1
                                  ? AppColors.primary
                                  : AppColors.lightGrey,
                            ),
                            onPressed: _currentPage > 1 ? _previousPage : null,
                            iconSize: 20,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            tooltip: 'Previous Page',
                          ),

                          // Page buttons (show up to 5 pages)
                          ..._buildPageButtons(),

                          // Next page button
                          IconButton(
                            icon: Icon(
                              Icons.chevron_right,
                              color: _currentPage < _totalPages
                                  ? AppColors.primary
                                  : AppColors.lightGrey,
                            ),
                            onPressed:
                                _currentPage < _totalPages ? _nextPage : null,
                            iconSize: 20,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            tooltip: 'Next Page',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build pagination page buttons
  List<Widget> _buildPageButtons() {
    List<Widget> pageButtons = [];

    // Determine start and end pages to show
    int startPage = _currentPage - 2;
    int endPage = _currentPage + 2;

    // Adjust if out of range
    if (startPage < 1) {
      endPage = endPage + (1 - startPage);
      startPage = 1;
    }
    if (endPage > _totalPages) {
      startPage = startPage - (endPage - _totalPages);
      endPage = _totalPages;
    }

    // Ensure startPage is at least 1
    startPage = startPage < 1 ? 1 : startPage;

    // Add first page button if not already in range
    if (startPage > 1) {
      pageButtons.add(
        _buildPageButton(1),
      );
      // Add ellipsis if there's a gap
      if (startPage > 2) {
        pageButtons.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const Text('...'),
          ),
        );
      }
    }

    // Add page buttons within range
    for (int i = startPage; i <= endPage; i++) {
      pageButtons.add(_buildPageButton(i));
    }

    // Add last page button if not already in range
    if (endPage < _totalPages) {
      // Add ellipsis if there's a gap
      if (endPage < _totalPages - 1) {
        pageButtons.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const Text('...'),
          ),
        );
      }
      pageButtons.add(_buildPageButton(_totalPages));
    }

    return pageButtons;
  }

  // Build an individual page button
  Widget _buildPageButton(int page) {
    return InkWell(
      onTap: () => _goToPage(page),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: page == _currentPage ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          page.toString(),
          style: TextStyle(
            color: page == _currentPage ? Colors.white : AppColors.grey,
          ),
        ),
      ),
    );
  }
}
