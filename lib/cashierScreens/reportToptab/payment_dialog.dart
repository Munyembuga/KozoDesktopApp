import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:kozo/utils/constants.dart';

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final Function(
      double amountReceived,
      List<Map<String, dynamic>> paymentMethods,
      String notes,
      double discountAmount,
      double discountPercentage) onPayment;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    required this.onPayment,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final List<PaymentMethod> _paymentMethods = [];
  final TextEditingController _coversController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Payment method selection
  PaymentMethodModel? _selectedPaymentMethod;
  List<PaymentMethodModel> _availablePaymentMethods = [];
  bool _isLoading = true;
  bool _isInlinePaymentFormVisible = false;

  // Client deposit functionality
  List<DepositClient> _depositClients = [];
  DepositClient? _selectedDepositClient;
  bool _isLoadingDeposits = false;

  // Discount functionality removed as it's now handled elsewhere
  double get _discountAmount {
    return 0.0;
  }

  double get _discountedTotal {
    return widget.totalAmount;
  }

  double get _totalPaid {
    return _paymentMethods.fold(0.0, (sum, method) => sum + method.amount);
  }

  double get _remainingAmount {
    return _discountedTotal - _totalPaid;
  }

  @override
  void initState() {
    super.initState();
    _fetchPaymentMethods();
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/Orders/payment_method'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _availablePaymentMethods = (data['data'] as List)
                .map((item) => PaymentMethodModel.fromJson(item))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Failed to fetch payment methods: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Define helper getters for required logic
  bool get _requiresCustomerName =>
      _selectedPaymentMethod?.id == 13 || _selectedPaymentMethod?.id == 14;
  bool get _isDepositPayment => _selectedPaymentMethod?.id == 15;

  Future<void> _fetchDepositClients(String searchTerm) async {
    try {
      setState(() {
        _isLoadingDeposits = true;
      });

      print('Fetching deposit clients with search term: "$searchTerm"');

      Map<String, String> queryParams = {};
      if (searchTerm.isNotEmpty) {
        queryParams['search'] = searchTerm;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}/Orders/deposite_client')
          .replace(queryParameters: queryParams);

      print('Fetching from URI: $uri');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data.containsKey('clients')) {
          setState(() {
            _depositClients = (data['clients'] as List)
                .map((item) => DepositClient.fromJson(item))
                .toList();
          });
          print('Found ${_depositClients.length} deposit clients');
        } else {
          print('No clients found in response or success was false');
          setState(() {
            _depositClients = [];
          });
        }
      } else {
        print('Failed to fetch deposit clients: HTTP ${response.statusCode}');
        setState(() {
          _depositClients = [];
        });
      }
    } catch (e) {
      print('Exception when fetching deposit clients: $e');
      setState(() {
        _depositClients = [];
      });
    } finally {
      setState(() {
        _isLoadingDeposits = false;
      });
    }
  }

  @override
  void dispose() {
    _coversController.dispose();
    _discountController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _customerNameController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fixed Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payment, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Record Payment',
                    style: TextStyle(
                      fontSize: 20,
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

            // Scrollable Content
            Flexible(
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 20.0,
                radius: const Radius.circular(10),
                trackVisibility: true,
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Amount Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Amount:',
                                    style: TextStyle(fontSize: 14)),
                                Text(
                                  'RWF ${widget.totalAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            if (_discountAmount > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Discount:',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.red)),
                                  Text(
                                    '- RWF ${_discountAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Discounted Total:',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    'RWF ${_discountedTotal.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_paymentMethods.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Amount Paid:',
                                      style: TextStyle(fontSize: 14)),
                                  Text(
                                    'RWF ${_totalPaid.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _remainingAmount > 0
                                        ? 'Remaining:'
                                        : 'Change:',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'RWF ${_remainingAmount.abs().toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _remainingAmount > 0
                                          ? Colors.red
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Payment Methods Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payment Methods',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_isInlinePaymentFormVisible)
                            ElevatedButton.icon(
                              onPressed: _addPaymentMethod,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Inline Payment Form
                      if (_isInlinePaymentFormVisible) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Add Payment Method',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isInlinePaymentFormVisible = false;
                                      });
                                    },
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Close',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Payment Method Dropdown
                              DropdownButtonFormField<PaymentMethodModel>(
                                value: _selectedPaymentMethod,
                                decoration: const InputDecoration(
                                  labelText: 'Payment Method',
                                  border: OutlineInputBorder(),
                                ),
                                items: _availablePaymentMethods
                                    .map((method) => DropdownMenuItem(
                                          value: method,
                                          child: Text(method.displayName),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPaymentMethod = value;
                                    // Clear selected client when payment method changes
                                    _selectedDepositClient = null;
                                  });

                                  // Fetch deposit clients if deposit payment method is selected
                                  if (value?.id == 15) {
                                    print(
                                        "Deposit payment method selected, fetching clients...");
                                    _fetchDepositClients('');
                                  }
                                },
                                isExpanded: true,
                                hint: const Text('Select payment method'),
                              ),
                              const SizedBox(height: 16),

                              // Client Deposit Section (only shown when deposit payment method is selected)
                              if (_isDepositPayment) ...[
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.blue.withOpacity(0.2)),
                                  ),
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Client Deposits',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          labelText: 'Search Clients',
                                          hintText:
                                              'Enter client name (min. 3 characters)',
                                          prefixIcon: const Icon(Icons.search),
                                          border: const OutlineInputBorder(),
                                          fillColor: Colors.white,
                                          filled: true,
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _searchController.clear();
                                              _fetchDepositClients('');
                                            },
                                          ),
                                        ),
                                        onChanged: (value) {
                                          if (value.length > 2) {
                                            _fetchDepositClients(value);
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        constraints: const BoxConstraints(
                                            maxHeight: 200),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: _isLoadingDeposits
                                            ? const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(20.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      CircularProgressIndicator(),
                                                      SizedBox(height: 16),
                                                      Text(
                                                          'Fetching client deposits...'),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : _depositClients.isEmpty
                                                ? Center(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              20.0),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .account_balance_wallet_outlined,
                                                              size: 48,
                                                              color: Colors
                                                                  .grey[400]),
                                                          const SizedBox(
                                                              height: 16),
                                                          const Text(
                                                            'No deposit clients found',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .grey),
                                                          ),
                                                          const SizedBox(
                                                              height: 8),
                                                          ElevatedButton.icon(
                                                            onPressed: () =>
                                                                _fetchDepositClients(
                                                                    ''),
                                                            icon: const Icon(
                                                                Icons.refresh),
                                                            label: const Text(
                                                                'Refresh'),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : ListView.builder(
                                                    shrinkWrap: true,
                                                    itemCount:
                                                        _depositClients.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final client =
                                                          _depositClients[
                                                              index];
                                                      return Card(
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            vertical: 4,
                                                            horizontal: 2),
                                                        color: _selectedDepositClient
                                                                    ?.depositId ==
                                                                client.depositId
                                                            ? Colors
                                                                .blue.shade50
                                                            : null,
                                                        elevation: 0,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          side: BorderSide(
                                                            color: _selectedDepositClient
                                                                        ?.depositId ==
                                                                    client
                                                                        .depositId
                                                                ? Colors.blue
                                                                : Colors
                                                                    .transparent,
                                                            width: 1.5,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: ListTile(
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 8),
                                                          leading: CircleAvatar(
                                                            backgroundColor:
                                                                Colors.blue
                                                                    .shade100,
                                                            child: const Icon(
                                                                Icons.person,
                                                                color: Colors
                                                                    .blue),
                                                          ),
                                                          title: Text(
                                                            client.clientName,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          subtitle: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              const SizedBox(
                                                                  height: 4),
                                                              Text(
                                                                  'Deposit ID: ${client.depositId}'),
                                                              const SizedBox(
                                                                  height: 2),
                                                              Text(
                                                                'Available: RWF ${client.totalAmount}',
                                                                style:
                                                                    const TextStyle(
                                                                  color: Colors
                                                                      .green,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          selected:
                                                              _selectedDepositClient
                                                                      ?.depositId ==
                                                                  client
                                                                      .depositId,
                                                          onTap: () {
                                                            setState(() {
                                                              _selectedDepositClient =
                                                                  client;

                                                              // Calculate remaining amount to be paid
                                                              double
                                                                  remainingAmount =
                                                                  _remainingAmount;

                                                              // Calculate the deposit amount available
                                                              double
                                                                  depositAmount =
                                                                  double.tryParse(
                                                                          client
                                                                              .totalAmount) ??
                                                                      0.0;

                                                              // Use the smaller of the two values to prevent overpayment
                                                              double
                                                                  amountToUse =
                                                                  remainingAmount >
                                                                          0
                                                                      ? (depositAmount >
                                                                              remainingAmount
                                                                          ? remainingAmount
                                                                          : depositAmount)
                                                                      : 0;

                                                              _amountController
                                                                      .text =
                                                                  amountToUse
                                                                      .toStringAsFixed(
                                                                          0);
                                                              _customerNameController
                                                                      .text =
                                                                  client
                                                                      .clientName;
                                                            });
                                                          },
                                                          trailing: _selectedDepositClient
                                                                      ?.depositId ==
                                                                  client
                                                                      .depositId
                                                              ? const Icon(
                                                                  Icons
                                                                      .check_circle,
                                                                  color: Colors
                                                                      .green)
                                                              : null,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                      ),
                                      if (_selectedDepositClient != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                  color: Colors.green.shade200),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.check_circle,
                                                    color: Colors.green),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Selected: ${_selectedDepositClient!.clientName}',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Text(
                                                          'Available: RWF ${_selectedDepositClient!.totalAmount}'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Amount Field
                              TextField(
                                controller: _amountController,
                                decoration: const InputDecoration(
                                  labelText: 'Amount',
                                  border: OutlineInputBorder(),
                                  prefixText: 'RWF ',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Customer Name Field (only shown for methods that require it)
                              if (_requiresCustomerName) ...[
                                TextField(
                                  controller: _customerNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Customer Name',
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter customer name',
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Reference Field
                              TextField(
                                controller: _referenceController,
                                decoration: const InputDecoration(
                                  labelText: 'Reference (Optional)',
                                  border: OutlineInputBorder(),
                                  hintText:
                                      'Transaction reference, receipt number, etc.',
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Add Payment Button
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _confirmAddPayment,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                      child: const Text('Add Payment Method'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Payment Methods List
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: _paymentMethods.isEmpty
                            ? Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No payment methods added yet',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _paymentMethods.length,
                                itemBuilder: (context, index) {
                                  final method = _paymentMethods[index];
                                  return _buildPaymentMethodCard(method, index);
                                },
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Payment Notes
                      TextField(
                        controller: _coversController,
                        decoration: const InputDecoration(
                          labelText: 'Number of Covers',
                          border: OutlineInputBorder(),
                          hintText: '12 or 15 persons',
                          // contentPadding: EdgeInsets.symmetric(
                          //     horizontal: 12, vertical: 12),
                        ),
                        // maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed Footer with Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_paymentMethods.isNotEmpty ||
                              _discountAmount >= widget.totalAmount)
                          ? _processPayment
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Record Payment',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_getPaymentIcon(method.type), color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'RWF ${method.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _paymentMethods.removeAt(index);
              });
            },
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'mobile money':
        return Icons.phone_android;
      case 'bank_transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  // Method removed as it's no longer used

  void _addPaymentMethod() {
    // Instead of showing a separate dialog, we'll add the payment method directly in this dialog
    _showInlinePaymentMethodForm();
  }

  // Payment method selection and deposit client handling will be added inline
  void _showInlinePaymentMethodForm() {
    _selectedPaymentMethod = null;
    _amountController.text = _remainingAmount.toStringAsFixed(0);
    _referenceController.text = '';
    _customerNameController.text = '';
    _selectedDepositClient = null;
    _depositClients = [];
    _searchController.text = '';
    _isInlinePaymentFormVisible = true;

    setState(() {});
  }

  void _confirmAddPayment() {
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if amount exceeds remaining amount
    // if (amount > _remainingAmount && _remainingAmount > 0) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(
    //           'Amount exceeds remaining balance (RWF ${_remainingAmount.toStringAsFixed(0)})'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    //   return;
    // }

    // Check if customer name is required but empty
    if (_requiresCustomerName && _customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter customer name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if deposit payment method is selected but no client is selected
    if (_isDepositPayment && _selectedDepositClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a deposit client'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Prepare reference - include customer name for methods that require it
    String reference = _referenceController.text.trim();
    if (_requiresCustomerName) {
      String customerName = _customerNameController.text.trim();
      // reference = reference.isEmpty
      //     ? "Customer: $customerName"
      //     : "$reference - Customer: $customerName";
    }

    final paymentMethod = PaymentMethod(
      type: _selectedPaymentMethod!.displayName,
      methodName: _selectedPaymentMethod!.methodName,
      amount: amount,
      reference: "",
      methodId: _selectedPaymentMethod!.id,
      // Include deposit client info if using deposit payment method
      clientId: _isDepositPayment ? _selectedDepositClient?.clientId : null,
      clientName: _isDepositPayment
          ? _selectedDepositClient?.clientName
          : _requiresCustomerName
              ? _customerNameController.text.trim()
              : null,
      depositId: _isDepositPayment ? _selectedDepositClient?.depositId : null,
    );

    setState(() {
      _paymentMethods.add(paymentMethod);
      _isInlinePaymentFormVisible = false;
    });
  }

  void _processPayment() {
    // Allow empty payment methods only when 100% discount is applied
    if (_paymentMethods.isEmpty && _discountAmount < widget.totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if any deposit payment method is missing client selection
    bool hasMissingDepositInfo = _paymentMethods.any((method) =>
        method.methodId == 15 &&
        (method.clientId == null || method.depositId == null));

    if (hasMissingDepositInfo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'One or more deposit payments are missing client information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final paymentMethodsData = _paymentMethods
        .map((method) => {
              'method':
                  method.methodName, // Use the actual method_name from API
              'amount': method.amount.toString(),
              'reference': method.reference,
              if (method.clientId != null)
                'client_id': method.clientId.toString(),
              if (method.clientName != null) 'client_name': method.clientName,
              if (method.depositId != null)
                'depositId': method.depositId.toString(),
            })
        .toList();

    // Discount is now handled separately, so we'll pass 0 values
    final discountPercentage = 0.0;
    final discountAmount = 0.0;

    // Handle 100% discount case - if discount is full amount, ensure we have at least empty payment data
    if (discountAmount >= widget.totalAmount && paymentMethodsData.isEmpty) {
      // Create a placeholder zero-amount payment for API compatibility
      paymentMethodsData.add({
        'method': 'cash', // Default to cash for zero payments
        'amount': '0',
        'reference': 'Full discount applied',
      });
    }

    widget.onPayment(
      _totalPaid,
      paymentMethodsData,
      _coversController.text.trim(),
      discountAmount, // Send calculated discount amount
      discountPercentage, // Send percentage value
    );
    Navigator.of(context).pop();
  }
}

// This class was moved into the main PaymentDialog class
// It's been removed to avoid duplication

class PaymentMethod {
  final String type;
  final double amount;
  final String reference;
  final String methodName;
  final int methodId;
  final int? clientId;
  final String? clientName;
  final int? depositId;

  PaymentMethod({
    required this.type,
    required this.amount,
    this.reference = '',
    required this.methodName,
    required this.methodId,
    this.clientId,
    this.clientName,
    this.depositId,
  });

  @override
  String toString() {
    final ref = reference.isNotEmpty ? ' (Ref: $reference)' : '';
    return '$type: RWF ${amount.toStringAsFixed(0)}$ref';
  }
}

class PaymentMethodModel {
  final int id;
  final int categoryId;
  final String methodName;
  final String methodCode;
  final bool requiresReference;
  final String status;
  final String categoryName;
  final String categoryCode;
  final String displayName;

  PaymentMethodModel({
    required this.id,
    required this.categoryId,
    required this.methodName,
    required this.methodCode,
    required this.requiresReference,
    required this.status,
    required this.categoryName,
    required this.categoryCode,
    required this.displayName,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      methodName: json['method_name'] ?? '',
      methodCode: json['method_code'] ?? '',
      requiresReference: json['requires_reference'] == '1',
      status: json['status'] ?? '',
      categoryName: json['category_name'] ?? '',
      categoryCode: json['category_code'] ?? '',
      displayName: json['display_name'] ?? '',
    );
  }
}

class DepositClient {
  final int clientId;
  final String clientName;
  final int depositId;
  final String totalAmount;

  DepositClient({
    required this.clientId,
    required this.clientName,
    required this.depositId,
    required this.totalAmount,
  });

  factory DepositClient.fromJson(Map<String, dynamic> json) {
    // Safe parsing to handle different data types from API
    int parseIntSafely(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          print('Error parsing int: $e for value: $value');
          return 0;
        }
      }
      return 0;
    }

    return DepositClient(
      clientId: parseIntSafely(json['client_id']),
      clientName: json['client_name']?.toString() ?? '',
      depositId: parseIntSafely(json['deposit_id']),
      totalAmount: json['total_amount']?.toString() ?? '0.00',
    );
  }

  double get availableAmount => double.tryParse(totalAmount) ?? 0.0;

  @override
  String toString() {
    return '$clientName (RWF ${totalAmount})';
  }
}
