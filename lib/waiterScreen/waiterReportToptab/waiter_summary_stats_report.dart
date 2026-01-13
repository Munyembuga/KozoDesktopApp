import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kozo/services/auth_service.dart';
import 'package:kozo/services/waiter_reporting_services.dart';
import '../../constants/app_constants.dart';
import '../../services/report_service.dart';

class WaiterSummaryStatsReport extends StatefulWidget {
  const WaiterSummaryStatsReport({Key? key}) : super(key: key);

  @override
  State<WaiterSummaryStatsReport> createState() =>
      _WaiterSummaryStatsReportState();
}

class _WaiterSummaryStatsReportState extends State<WaiterSummaryStatsReport> {
  final WaiterReportingServices _waiterReportingService =
      WaiterReportingServices();
  bool _isLoading = false;
  String _error = '';
  Map<String, dynamic>? _summaryStats;
  List<dynamic>? _paymentBreakdown;

  // Default date range for the last 24 hours
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime _toDate = DateTime.now();
  String _paymentMethodFilter = "";
  int? _waiterId; // This could be obtained from user context or preferences

  // Format for date display and API request
  final DateFormat _displayDateFormat = DateFormat('MMM dd, yyyy HH:mm');
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd HH:mm');

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
      _waiterId = currentUser.id;
    });
    _fetchData();
  }

  // Fetch both summary stats and payment breakdown
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await Future.wait([
        _fetchSummaryStats(),
        _fetchPaymentBreakdown(),
      ]);
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch summary statistics using the service
  Future<void> _fetchSummaryStats() async {
    try {
      // Check if waiter ID is null and handle it
      if (_waiterId == null) {
        throw Exception('Waiter ID is not available. Please log in again.');
      }

      final data = await _waiterReportingService.getSummaryStats(
        waiterId: _waiterId!, // Add the non-null assertion operator
        dateTimeFrom: _apiDateFormat.format(_fromDate),
        dateTimeTo: _apiDateFormat.format(_toDate),
        paymentMethodFilter: _paymentMethodFilter,
      );
      setState(() {
        _summaryStats = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  // Fetch payment breakdown using the service
  Future<void> _fetchPaymentBreakdown() async {
    try {
      final methods = await _waiterReportingService.getPaymentMethodsBreakdown(
        waiterId: _waiterId!,
        dateTimeFrom: _apiDateFormat.format(_fromDate),
        dateTimeTo: _apiDateFormat.format(_toDate),
        paymentMethodFilter: _paymentMethodFilter,
      );
      setState(() {
        _paymentBreakdown = methods;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
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

  // Show date range picker
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _fetchData();
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

        _fetchData();
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
        _fetchData();
      }
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
            // Header with individual date-time selectors
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Summary Statistics',
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
              ],
            ),

            const SizedBox(height: 16),

            // Loading indicator or error message
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error.isNotEmpty)
              Center(
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (_summaryStats != null) ...[
              // Statistics cards
              Row(
                children: [
                  _buildStatCard(
                    title: 'Total Orders',
                    value: '${_summaryStats!['total_payments']}',
                    icon: Icons.receipt,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    title: 'Total Revenue',
                    value: _formatCurrency(_summaryStats!['total_revenue']),
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    title: 'Unpaid Orders',
                    value: '${_summaryStats!['served_unpaid_count']}',
                    icon: Icons.pending,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    title: 'Pending Revenue',
                    value: _formatCurrency(_summaryStats!['pending_revenue']),
                    icon: Icons.money_off,
                    color: Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Payment methods breakdown
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
                    const Text(
                      'Payment Methods Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_paymentBreakdown == null || _paymentBreakdown!.isEmpty)
                      const Center(
                        child: Text(
                          'No payment data available for the selected period',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (var method in _paymentBreakdown!)
                            _buildPaymentMethodItem(method),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
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
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem(Map<String, dynamic> method) {
    // Define colors and icons for different payment methods
    final IconData icon;
    final Color color;
    final String methodName;

    switch (method['method_type']) {
      case 'mobile_money':
        icon = Icons.phone_android;
        color = Colors.purple;
        methodName = 'Mobile Money';
        break;
      case 'cash':
        icon = Icons.money;
        color = Colors.green;
        methodName = 'Cash';
        break;
      case 'card':
        icon = Icons.credit_card;
        color = Colors.blue;
        methodName = 'Card';
        break;
      default:
        icon = Icons.payment;
        color = Colors.grey;
        methodName = method['method_type'] ?? 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  methodName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${method['transaction_count']} transactions',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(method['total_amount']),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
