import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kozo/models/categories_sold_item.dart';
import 'package:kozo/services/auth_service.dart';
import '../../constants/app_constants.dart';
import '../../services/report_service.dart';
import '../../services/report_print_service.dart';

class SummaryStatsReport extends StatefulWidget {
  const SummaryStatsReport({Key? key}) : super(key: key);

  @override
  State<SummaryStatsReport> createState() => _SummaryStatsReportState();
}

class _SummaryStatsReportState extends State<SummaryStatsReport> {
  final ReportService _reportService = ReportService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isPrintingAllowed =
      false; // Flag to control print/download buttons visibility
  String _error = '';
  Map<String, dynamic>? _summaryStats;
  List<dynamic>? _paymentBreakdown;
  List<dynamic>? _categoryRevenue;
  List<dynamic>? _wholeSummary;
  List<dynamic>? _taxRevenue;
  List<dynamic>? _discountSummary;
  List<dynamic>? _depositSummary;
  List<dynamic>? _depositDetails;
  List<dynamic>? _depositData;
  String? _totalServiceFee;
  List<CategorySoldSummary>? _categorySoldItems; // Add this property

  // Default date range for the last 24 hours
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime _toDate = DateTime.now();
  String _paymentMethodFilter = "";
  int? _cashierId; // This could be obtained from user context or preferences

  // Format for date display and API request
  final DateFormat _displayDateFormat = DateFormat('MMM dd, yyyy HH:mm');
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _initUserAndFetchData();
    // Add listener to scroll controller for custom scroll behavior if needed
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    // Don't forget to dispose of the scroll controller
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll listener for custom scroll behavior
  void _scrollListener() {
    // You can implement custom scroll behavior here if needed
    // For example, loading more data when reaching the bottom
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Reached the bottom - can implement additional loading here
    }
  }

  Future<void> _initUserAndFetchData() async {
    final currentUser = await AuthService.getCurrentUser();
    if (currentUser == null) {
      throw Exception('User not logged in');
    }
    setState(() {
      _cashierId = currentUser.id;
    });
    _fetchData();
  }

  Future<void> _fetchCategorySoldItems() async {
    try {
      final categorySoldItems = await _reportService.getCategorySoldItems(
        dateTimeFrom: _apiDateFormat.format(_fromDate),
        dateTimeTo: _apiDateFormat.format(_toDate),
      );

      setState(() {
        _categorySoldItems = categorySoldItems;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  // Fetch summary stats, payment breakdown, and category revenue
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Check if printing is allowed for the selected date range
      await _checkPrintingAllowed();

      await Future.wait([
        _fetchSummaryStats(),
        _fetchPaymentBreakdown(),
        _fetchCategoryRevenue(),
        _fetchWholeSummary(),
        _fetchTaxRevenue(),
        _fetchDiscountSummary(),
        _fetchDepositData(),
        _fetchCategorySoldItems(), // Fetch category sold items
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

  // Check if printing is allowed for the selected date range
  Future<void> _checkPrintingAllowed() async {
    try {
      final String fromDateStr = _apiDateFormat.format(_fromDate);
      final String toDateStr = _apiDateFormat.format(_toDate);

      print(
          'Checking if printing is allowed for date range: $fromDateStr to $toDateStr');

      final result = await _reportService.isPrintingAllowed(
        dateTimeFrom: fromDateStr,
        dateTimeTo: toDateStr,
      );

      setState(() {
        _isPrintingAllowed = result;
      });

      print('Printing allowed status: $_isPrintingAllowed');
    } catch (e) {
      print('Error checking if printing is allowed: $e');
      setState(() {
        _isPrintingAllowed = false;
      });
    }
  } // Fetch summary statistics using the service

  Future<void> _fetchSummaryStats() async {
    try {
      // Check if cashier ID is null and handle it
      if (_cashierId == null) {
        throw Exception('Cashier ID is not available. Please log in again.');
      }

      final data = await _reportService.getSummaryStats(
        cashierId: _cashierId!, // Add the non-null assertion operator
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
      final methods = await _reportService.getPaymentMethodsBreakdown(
        cashierId: _cashierId!,
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

  // Fetch category revenue using the service
  Future<void> _fetchCategoryRevenue() async {
    try {
      final categories = await _reportService.getCategoryRevenue(
        dateTimeFrom: _apiDateFormat.format(_fromDate),
        dateTimeTo: _apiDateFormat.format(_toDate),
      );
      setState(() {
        _categoryRevenue = categories;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  // Fetch whole summary using the service
  Future<void> _fetchWholeSummary() async {
    try {
      final summary = await _reportService.getWholeSummary(
        dateTimeFrom: _apiDateFormat.format(_fromDate),
        dateTimeTo: _apiDateFormat.format(_toDate),
      );
      setState(() {
        _wholeSummary = summary;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  // Fetch tax revenue using the service
  Future<void> _fetchTaxRevenue() async {
    try {
      final taxData = await _reportService.getTaxRevenue(
        dateTimeFrom: _apiDateFormat.format(_fromDate),
        dateTimeTo: _apiDateFormat.format(_toDate),
      );
      setState(() {
        _taxRevenue = taxData;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  // Fetch discount summary using the service
  Future<void> _fetchDiscountSummary() async {
    try {
      final discountData = await _reportService.getDiscountSummary(
        dateTimeFrom: _apiDateFormat.format(_fromDate),
        dateTimeTo: _apiDateFormat.format(_toDate),
      );
      setState(() {
        _discountSummary = discountData;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  // Fetch deposit data using the service
  Future<void> _fetchDepositData() async {
    try {
      final depositData = await _reportService.getAllDeposits(
        dateTimeFrom: _apiDateFormat.format(_fromDate),
        dateTimeTo: _apiDateFormat.format(_toDate),
      );

      setState(() {
        _depositSummary = depositData['summary'];
        _depositDetails = depositData['details'];
        _depositData = depositData['data'];
      });
    } catch (e) {
      print('Error fetching deposit data: $e');
      // We'll continue even if deposit data fails
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

  // Print summary report
  Future<void> _printSummaryReport() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Preparing report for printing...'),
              ],
            ),
          );
        },
      );

      // Format dates for the report header
      final String fromDateFormatted = _displayDateFormat.format(_fromDate);
      final String toDateFormatted = _displayDateFormat.format(_toDate);

      // Call the report print service
      await ReportPrintService.printSummaryReport(
        fromDate: fromDateFormatted,
        toDate: toDateFormatted,
        wholeSummary: _wholeSummary?.first,
        paymentBreakdown: _paymentBreakdown,
        categoryRevenue: _categoryRevenue,
        taxRevenue: _taxRevenue,
        discountSummary: _discountSummary,
        depositDetails: _depositDetails,
        categorySoldItems: _categorySoldItems, // Add this parameter
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        print("Failed to print report: $e");
        // Show error dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to print report: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // Download summary report
  Future<void> _downloadSummaryReport() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Preparing report for download...'),
              ],
            ),
          );
        },
      );

      // Format dates for the report header
      final String fromDateFormatted = _displayDateFormat.format(_fromDate);
      final String toDateFormatted = _displayDateFormat.format(_toDate);

      // Call the report download service
      final fileName = await ReportPrintService.downloadSummaryReport(
        fromDate: fromDateFormatted,
        toDate: toDateFormatted,
        wholeSummary: _wholeSummary?.first,
        paymentBreakdown: _paymentBreakdown,
        categoryRevenue: _categoryRevenue,
        taxRevenue: _taxRevenue,
        discountSummary: _discountSummary,
        depositDetails: _depositDetails,
        categorySoldItems: _categorySoldItems, // Add this parameter
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted && fileName != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved as $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        print("Failed to download report: $e");
        // Show error dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to download report: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // Add this helper method to build category sold items
  Widget _buildCategorySoldItemsSection() {
    if (_categorySoldItems == null || _categorySoldItems!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _categorySoldItems!
          .map((category) => _buildCategorySoldItem(category))
          .toList(),
    );
  }

  Widget _buildCategorySoldItem(CategorySoldSummary category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              Text(
                '${category.categoryName} - Sold Items Breakdown',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Items Table Header
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Item',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Specification',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Qty Sold',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Unit Price',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Revenue',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Items List
              ...category.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(item.itemName),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(item.specificationName),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${item.quantitySold}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${item.price}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            _formatCurrency(item.totalRevenue),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  )),

              const Divider(),

              // Category Total
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Revenue:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCurrency(category.totalRevenue),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: RawScrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 20.0,
      thumbColor: AppColors.primary.withOpacity(0.5),
      radius: const Radius.circular(10.0),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header with individual date-time selectors
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Summary Stats',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  children: [
                    // Download button - only shown if printing is allowed
                    if (!_isLoading &&
                        _error.isEmpty &&
                        _summaryStats != null &&
                        _isPrintingAllowed)
                      ElevatedButton.icon(
                        onPressed: _downloadSummaryReport,
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    if (_isPrintingAllowed) const SizedBox(width: 8),

                    // Print button - only shown if printing is allowed
                    if (!_isLoading &&
                        _error.isEmpty &&
                        _summaryStats != null &&
                        _isPrintingAllowed)
                      ElevatedButton.icon(
                        onPressed: _printSummaryReport,
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('Print'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    // If printing is not allowed, show an info icon with tooltip
                    if (!_isPrintingAllowed &&
                        !_isLoading &&
                        _error.isEmpty &&
                        _summaryStats != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          // Show explanation dialog when the button is pressed
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Printing Disabled'),
                              content: const Text(
                                'Printing and downloading reports are disabled for this date range because there are still unpaid orders. All orders must be paid before generating reports.',
                                style: TextStyle(fontSize: 16),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('Why can\'t I print?'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    const SizedBox(width: 16),
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
              // Row(
              //   children: [
              //     _buildStatCard(
              //       title: 'Total Orders',
              //       value: '${_summaryStats!['total_payments']}',
              //       icon: Icons.receipt,
              //       color: Colors.blue,
              //     ),
              //     const SizedBox(width: 16),
              //     _buildStatCard(
              //       title: 'Total Revenue',
              //       value: _formatCurrency(_summaryStats!['total_revenue']),
              //       icon: Icons.attach_money,
              //       color: Colors.green,
              //     ),
              //     const SizedBox(width: 16),
              //     _buildStatCard(
              //       title: 'Unpaid Orders',
              //       value: '${_summaryStats!['served_unpaid_count']}',
              //       icon: Icons.pending,
              //       color: Colors.orange,
              //     ),
              //     const SizedBox(width: 16),
              //     _buildStatCard(
              //       title: 'Pending Revenue',
              //       value: _formatCurrency(_summaryStats!['pending_revenue']),
              //       icon: Icons.money_off,
              //       color: Colors.red,
              //     ),
              //   ],
              // ),
              _buildWholeSummarySection(),

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

              const SizedBox(height: 32),

              // Category revenue breakdown
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
                      'Category Revenue Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_categoryRevenue == null || _categoryRevenue!.isEmpty)
                      const Center(
                        child: Text(
                          'No category revenue data available for the selected period',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (var category in _categoryRevenue!)
                            _buildCategoryRevenueItem(category),

                          // Add separator line
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(thickness: 1),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Whole summary section
              _buildWholeSummarySection(),

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

              const SizedBox(height: 32),

              // Category revenue breakdown
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
                      'Category Revenue Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_categoryRevenue == null || _categoryRevenue!.isEmpty)
                      const Center(
                        child: Text(
                          'No category revenue data available for the selected period',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (var category in _categoryRevenue!)
                            _buildCategoryRevenueItem(category),

                          // Add separator line
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(thickness: 1),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Tax revenue section
              _buildTaxRevenueSection(),

              const SizedBox(height: 32),

              // Discount summary section
              _buildDiscountSummarySection(),

              // Add Deposit Details Section if available
              if (_depositDetails != null && _depositDetails!.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildDepositSection(),
              ],

              const SizedBox(height: 32),

              // Category sold items breakdown
              _buildCategorySoldItemsSection(),

              const SizedBox(height: 32),
            ],
          ]),
        ),
      ),
    ));
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

  Widget _buildCategoryRevenueItem(Map<String, dynamic> category) {
    // Define colors for different categories (you can customize this)
    final Color color;
    final IconData icon;
    _totalServiceFee = category['service_fee'];
    // Assign colors based on category name (customize as needed)
    switch (category['category_name']?.toLowerCase()) {
      case 'food':
        color = Colors.orange;
        icon = Icons.restaurant;
        break;
      case 'drink':
      case 'drinks':
      case 'beverages':
        color = Colors.blue;
        icon = Icons.local_bar;
        break;
      case 'dessert':
        color = Colors.pink;
        icon = Icons.cake;
        break;
      default:
        color = Colors.teal;
        icon = Icons.category;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // First row with category name and icon
          Row(
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
                      category['category_name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${category['order_count']} orders, ${category['item_count']} items',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Revenue information
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                // Gross revenue row
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     const Text(
                //       'Net Revenue:',
                //       style: TextStyle(
                //         fontSize: 14,
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //     Text(
                //       _formatCurrency(category['net_revenue']),
                //       style: TextStyle(
                //         fontWeight: FontWeight.bold,
                //         fontSize: 14,
                //         color: Colors.green[700],
                //       ),
                //     ),
                //   ],
                // ),

                // const SizedBox(height: 4),

                // // Service fee row
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     const Text(
                //       'Service Fee:',
                //       style: TextStyle(
                //         fontSize: 14,
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //     Text(
                //       _formatCurrency(category['service_fee']),
                //       style: TextStyle(
                //         fontWeight: FontWeight.bold,
                //         fontSize: 14,
                //         color: Colors.purple[700],
                //       ),
                //     ),
                //   ],
                // ),

                // const Divider(height: 8),

                // Net revenue row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gross Revenue:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatCurrency(category['gross_revenue']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     const Text(
                //       'Service Fee:',
                //       style: TextStyle(
                //         fontSize: 14,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //     Text(
                //       _totalServiceFee != null
                //           ? _formatCurrency(_totalServiceFee)
                //           : _formatCurrency('0'),
                //       style: const TextStyle(
                //         fontWeight: FontWeight.bold,
                //         fontSize: 16,
                //         color: Colors.blue,
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWholeSummarySection() {
    if (_wholeSummary == null || _wholeSummary!.isEmpty) {
      return const Center(
        child: Text(
          'No whole summary data available for the selected period',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    // Get the first (and likely only) summary record
    final summary = _wholeSummary!.first;

    return Container(
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
              const Text(
                'Revenue Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                summary['date'] ?? 'N/A',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid of summary data
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildSummaryItem(
                title: 'Total Revenue Inclusive',
                value: summary['total_inclusive'] ?? '0',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
              _buildSummaryItem(
                title: 'Total Revenue Exclusive',
                value: summary['total_exclusive'] ?? '0',
                icon: Icons.money,
                color: Colors.blue,
              ),
              _buildSummaryItem(
                title: 'Service Fee',
                value: summary['total_service_fee'] ?? '0',
                icon: Icons.room_service,
                color: Colors.purple,
              ),
              _buildSummaryItem(
                title: 'Total Tax',
                value: summary['total_tax'] ?? '0',
                icon: Icons.receipt_long,
                color: Colors.orange,
              ),
              _buildSummaryItem(
                title: 'Transactions',
                value: summary['total_transactions']?.toString() ?? '0',
                icon: Icons.receipt,
                color: Colors.teal,
                isCount: true,
              ),
              _buildSummaryItem(
                title: 'Total Spend',
                value: summary['total_spend'] ?? '0',
                icon: Icons.shopping_cart,
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isCount = false,
  }) {
    return Container(
      width: 180,
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
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCount ? value : _formatCurrency(value),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxRevenueSection() {
    if (_taxRevenue == null || _taxRevenue!.isEmpty) {
      return const Center(
        child: Text(
          'No tax revenue data available for the selected period',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    // Get the first (and likely only) tax record
    final taxData = _taxRevenue!.first;

    return Container(
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
              const Text(
                'Tax Revenue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                taxData['date'] ?? 'N/A',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tax data item
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long,
                      color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net Tax Revenue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'For date: ${taxData['date'] ?? 'N/A'}',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatCurrency(taxData['net_tax']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Add note about tax
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tax revenue represents the total VAT collected during the selected period.',
                    style: TextStyle(
                      color: AppColors.grey,
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
    );
  }

  Widget _buildDiscountSummarySection() {
    if (_discountSummary == null || _discountSummary!.isEmpty) {
      return const Center(
        child: Text(
          'No discount data available for the selected period',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    // Get the first (and likely only) discount record
    final discountData = _discountSummary!.first;

    // Calculate discount percentage
    int totalOrders = discountData['total_orders'] as int? ?? 0;
    int ordersWithDiscount = discountData['orders_with_discount'] as int? ?? 0;
    double discountPercentage =
        totalOrders > 0 ? (ordersWithDiscount / totalOrders) * 100 : 0;

    return Container(
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
              const Text(
                'Discount Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                discountData['date'] ?? 'N/A',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main discount data item
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.discount, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Discount Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ordersWithDiscount} out of ${totalOrders} orders (${discountPercentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatCurrency(discountData['total_discount_amount']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Add note about discounts
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Discounts can significantly impact revenue. Monitor discount usage for optimal pricing strategy.',
                    style: TextStyle(
                      color: AppColors.grey,
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
    );
  }

  Widget _buildDiscountMetricItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isCount = false,
  }) {
    return Container(
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
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCount ? value : _formatCurrency(value),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add this new method to build the deposit section
  Widget _buildDepositSection() {
    double totalDepositAmount = 0;

    // Calculate total deposit amount
    for (var deposit in _depositDetails!) {
      totalDepositAmount +=
          double.tryParse(deposit['amount']?.toString() ?? '0') ?? 0;
    }

    return Container(
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
              const Text(
                'Deposit Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _displayDateFormat.format(_fromDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary card if available
          if (_depositSummary != null && _depositSummary!.isNotEmpty) ...[
            _buildDepositSummaryCard(_depositSummary!.first),
            const SizedBox(height: 16),
          ],

          // Deposits list
          if (_depositDetails!.isEmpty)
            const Center(
              child: Text(
                'No deposit data available for the selected period',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            )
          else ...[
            const Text(
              'Deposit Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Individual deposit items
            ...(_depositDetails!
                .map((deposit) => _buildDepositItem(deposit))
                .toList()),

            const Divider(height: 20),

            // Total deposits row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL DEPOSITS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatCurrency(totalDepositAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDepositSummaryCard(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  title: 'Total Deposits',
                  value: summary['total_deposits']?.toString() ?? '0',
                  icon: Icons.receipt,
                  color: Colors.blue,
                  isCount: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  title: 'Total Amount',
                  value: summary['total_deposit_amount'] ?? '0',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  title: 'Active Deposits',
                  value: summary['active_deposits']?.toString() ?? '0',
                  icon: Icons.check_circle,
                  color: Colors.teal,
                  isCount: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  title: 'Unique Clients',
                  value: summary['unique_clients']?.toString() ?? '0',
                  icon: Icons.people,
                  color: Colors.purple,
                  isCount: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepositItem(Map<String, dynamic> deposit) {
    // Define colors for different payment methods
    Color color;
    IconData icon;

    // Set color and icon based on payment method
    switch ((deposit['method_name'] as String?)?.toUpperCase()) {
      case 'CASH':
        color = Colors.green;
        icon = Icons.money;
        break;
      case 'MOMO':
      case 'MOBILE MONEY':
        color = Colors.purple;
        icon = Icons.phone_android;
        break;
      case 'EQUITY':
      case 'BK':
      case 'CARD':
        color = Colors.blue;
        icon = Icons.credit_card;
        break;
      default:
        color = Colors.grey;
        icon = Icons.payment;
    }

    final String clientName = deposit['client_name'] ?? 'Unknown Client';
    final String methodName = deposit['method_name'] ?? 'Unknown Method';
    final String amount = deposit['amount']?.toString() ?? '0';
    final String createdAt = deposit['created_at'] ?? 'Unknown Date';

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
                  clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Via $methodName • $createdAt',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
