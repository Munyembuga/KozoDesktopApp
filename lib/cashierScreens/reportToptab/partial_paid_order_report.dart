import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kozo/services/auth_service.dart';
import '../../constants/app_constants.dart';
import '../../services/report_service.dart';

class PartialPaidOrderReport extends StatefulWidget {
  const PartialPaidOrderReport({Key? key}) : super(key: key);

  @override
  State<PartialPaidOrderReport> createState() => _PartialPaidOrderReportState();
}

class _PartialPaidOrderReportState extends State<PartialPaidOrderReport> {
  final ReportService _reportService = ReportService();
  bool _isLoading = false;
  String _error = '';
  List<dynamic>? _partialPaidOrders;

  // Pagination variables
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalPages = 1;

  // Default date range for the last 24 hours
  DateTime _fromDate = DateTime.now()
      .subtract(const Duration(days: 7)); // Show last week by default
  DateTime _toDate = DateTime.now();
  String _paymentMethodFilter = "";
  int? _cashierId; // This could be obtained from user context or preferences

  // Format for date display and API request
  final DateFormat _displayDateFormat = DateFormat('MMM dd, yyyy HH:mm');
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd HH:mm');
  final DateFormat _displayOrderDateFormat = DateFormat('dd/MM/yyyy HH:mm');

  // Sort options
  String _sortBy = 'Date (Newest)';

  // Total amount due
  double _totalAmountDue = 0;

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
    _fetchUnpaidOrders();
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

  Future<void> _fetchUnpaidOrders() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Check if cashier ID is null and handle it
      if (_cashierId == null) {
        throw Exception('Cashier ID is not available. Please log in again.');
      }

      final orders = await _reportService.getUnpaidOrders(
        cashierId: _cashierId!, // Add the non-null assertion operator
        dateTimeFrom: _apiDateFormat.format(_fromDate),
        dateTimeTo: _apiDateFormat.format(_toDate),
        paymentMethodFilter: _paymentMethodFilter,
      );

      // Calculate total amount due
      double total = 0;
      for (var order in orders) {
        total += double.parse(order['total'].toString());
      }

      // Sort orders based on selected option
      _sortOrders(orders);

      // Calculate total pages
      _totalPages = (orders.length / _pageSize).ceil();
      if (_totalPages < 1) _totalPages = 1;

      // Ensure current page is within valid range
      if (_currentPage > _totalPages) {
        _currentPage = _totalPages;
      }

      setState(() {
        _partialPaidOrders = orders;
        _totalAmountDue = total;
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

  // Sort orders based on selected option
  void _sortOrders(List<dynamic> orders) {
    switch (_sortBy) {
      case 'Date (Newest)':
        orders.sort((a, b) => DateTime.parse(b['created_at'])
            .compareTo(DateTime.parse(a['created_at'])));
        break;
      case 'Date (Oldest)':
        orders.sort((a, b) => DateTime.parse(a['created_at'])
            .compareTo(DateTime.parse(b['created_at'])));
        break;
      case 'Amount (Highest)':
        orders.sort((a, b) => double.parse(b['total'].toString())
            .compareTo(double.parse(a['total'].toString())));
        break;
      case 'Amount (Lowest)':
        orders.sort((a, b) => double.parse(a['total'].toString())
            .compareTo(double.parse(b['total'].toString())));
        break;
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

        _fetchUnpaidOrders();
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
        _fetchUnpaidOrders();
      }
    }
  }

  // Get paginated orders
  List<dynamic> get _paginatedOrders {
    if (_partialPaidOrders == null || _partialPaidOrders!.isEmpty) {
      return [];
    }

    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize > _partialPaidOrders!.length
        ? _partialPaidOrders!.length
        : startIndex + _pageSize;

    if (startIndex >= _partialPaidOrders!.length) {
      return [];
    }

    return _partialPaidOrders!.sublist(startIndex, endIndex);
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
                  'Partial Paid Orders Report',
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
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Total Due: ${_formatCurrency(_totalAmountDue)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter section
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildFilterDropdown(
                        'Sort By',
                        const [
                          'Date (Newest)',
                          'Date (Oldest)',
                          'Amount (Highest)',
                          'Amount (Lowest)'
                        ],
                        (value) {
                          setState(() {
                            _sortBy = value;
                            if (_partialPaidOrders != null) {
                              _sortOrders(_partialPaidOrders!);
                              _currentPage =
                                  1; // Reset to first page on sort change
                            }
                          });
                        },
                        currentValue: _sortBy,
                      ),
                      const SizedBox(width: 16),
                      _buildFilterDropdown(
                        'Payment Method',
                        _paymentMethodOptions,
                        (display, value) {
                          setState(() {
                            _paymentMethodFilter = value;
                            _currentPage =
                                1; // Reset to first page on filter change
                          });
                          _fetchUnpaidOrders();
                        },
                      ),
                    ],
                  ),
                  if (_partialPaidOrders != null)
                    Text(
                      'Total Unpaid Orders: ${_partialPaidOrders!.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
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
                        onPressed: _fetchUnpaidOrders,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_partialPaidOrders == null || _partialPaidOrders!.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.grey, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'No unpaid orders found for the selected period',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildUnpaidOrdersTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
      String label, List<dynamic> options, Function onChanged,
      {String? currentValue}) {
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
            child: DropdownButton<dynamic>(
              value: currentValue ??
                  (options is List<Map<String, String>>
                      ? _selectedPaymentMethodDisplay
                      : options.first),
              isDense: true,
              items: options.map<DropdownMenuItem<dynamic>>((option) {
                if (option is Map<String, String>) {
                  return DropdownMenuItem<String>(
                    value: option['display'],
                    child: Text(option['display']!),
                  );
                } else {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option.toString()),
                  );
                }
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  if (options is List<Map<String, String>>) {
                    final selectedOption = options.firstWhere(
                      (option) => option['display'] == value,
                      orElse: () => options.first,
                    );
                    setState(() {
                      _selectedPaymentMethodDisplay = value as String;
                    });
                    onChanged(value, selectedOption['value']!);
                  } else {
                    onChanged(value);
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnpaidOrdersTable() {
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
                DataColumn(label: Text('Last Updated')),
                DataColumn(label: Text('Waiter')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Status')),
                // DataColumn(label: Text('Actions')),
              ],
              rows: _paginatedOrders.map<DataRow>((order) {
                return DataRow(cells: [
                  DataCell(Text(order['order_number'])),
                  DataCell(Text(order['table_number'])),
                  DataCell(Text(_displayOrderDateFormat
                      .format(DateTime.parse(order['created_at'])))),
                  DataCell(Text(_displayOrderDateFormat
                      .format(DateTime.parse(order['updated_at'])))),
                  DataCell(Text(order['waiter_name'])),
                  DataCell(Text(_formatCurrency(order['total']),
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Unpaid',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  )),
                  // DataCell(Row(
                  //   children: [
                  //     IconButton(
                  //       icon: const Icon(Icons.visibility,
                  //           size: 20, color: AppColors.primary),
                  //       onPressed: () {
                  //         // View order details
                  //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  //             content: Text(
                  //                 'Viewing order ${order['order_number']}')));
                  //       },
                  //       tooltip: 'View Order',
                  //       constraints: const BoxConstraints(),
                  //       padding: const EdgeInsets.all(4),
                  //     ),
                  //     const SizedBox(width: 8),
                  //     IconButton(
                  //       icon: const Icon(Icons.payment,
                  //           size: 20, color: Colors.green),
                  //       onPressed: () {
                  //         // Process payment
                  //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  //             content: Text(
                  //                 'Processing payment for ${order['order_number']}')));
                  //       },
                  //       tooltip: 'Process Payment',
                  //       constraints: const BoxConstraints(),
                  //       padding: const EdgeInsets.all(4),
                  //     ),
                  //   ],
                  // )),
                ]);
              }).toList(),
            ),
          ),

          // Pagination controls and actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Send reminders button
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.start,
                //   children: [
                //     ElevatedButton.icon(
                //       onPressed: () {
                //         // Send reminders functionality
                //         ScaffoldMessenger.of(context).showSnackBar(
                //             const SnackBar(
                //                 content: Text('Sending reminders...')));
                //       },
                //       icon: const Icon(Icons.email),
                //       label: const Text('Send Reminders'),
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: AppColors.primary,
                //         foregroundColor: Colors.white,
                //       ),
                //     ),
                //   ],
                // ),

                const SizedBox(height: 16),

                // Pagination
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page information
                    Text(
                      'Showing ${_paginatedOrders.length} of ${_partialPaidOrders!.length} orders | Page $_currentPage of $_totalPages',
                      style: TextStyle(
                        color: AppColors.grey,
                      ),
                    ),

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

                          // Page numbers
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              '$_currentPage',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),

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
}
