import 'package:flutter/material.dart';
import 'package:kozo/navRailscreen/navRailMainCashier.dart';
import 'package:kozo/services/receipt_service.dart';
import '../models/order_detail_model.dart';
import '../services/order_service.dart';
import 'reportToptab/payment_dialog.dart';

class CompletedOrderDetailScreen extends StatefulWidget {
  final int orderId;
  final VoidCallback onOrderUpdated;

  const CompletedOrderDetailScreen({
    super.key,
    required this.orderId,
    required this.onOrderUpdated,
  });

  @override
  State<CompletedOrderDetailScreen> createState() =>
      _CompletedOrderDetailScreenState();
}

class _CompletedOrderDetailScreenState
    extends State<CompletedOrderDetailScreen> {
  OrderDetail? _orderDetail;
  bool _isLoading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll to top method
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // Scroll to bottom method
  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(CompletedOrderDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      _fetchOrderDetail();
    }
  }

  Future<void> _fetchOrderDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final orderDetail =
            await OrderService.fetchCompletedOrderDetail(widget.orderId);

        if (mounted) {
          setState(() {
            _orderDetail = orderDetail;
            _isLoading = false;
          });
        }
      } catch (e) {
        // Check if this is a payment-related error
        if (e.toString().contains("Payment details not found")) {
          // We may still be able to display the order without payment details
          // Attempt to fetch basic order info without requiring payment
          try {
            final basicOrderDetail =
                await OrderService.fetchServedOrderDetail(widget.orderId);

            if (mounted) {
              setState(() {
                _orderDetail = basicOrderDetail;
                _isLoading = false;
              });
            }
          } catch (nestedError) {
            // If even this fails, show the original error
            if (mounted) {
              setState(() {
                _errorMessage = e.toString();
                _isLoading = false;
              });
            }
          }
        } else {
          // For non-payment errors, display them directly
          if (mounted) {
            setState(() {
              _errorMessage = e.toString();
              _isLoading = false;
            });
          }
        }
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

  Future<void> _cancelPayment() async {
    if (_orderDetail == null || _orderDetail!.payment == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this payment?'),
            const SizedBox(height: 8),
            Text(
              'Payment Reference: ${_orderDetail!.payment!.paymentReference}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Amount: ${_orderDetail!.payment!.formattedTotalAmount}'),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, Keep Payment'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel Payment'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Canceling payment...'),
            ],
          ),
        ),
      );

      // Call API to cancel payment
      final success = await OrderService.cancelPayment(
        _orderDetail!.payment!.id,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment canceled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const NavRailMainCashier(initialIndex: 2),
            ),
          );
          // Instead of just calling onOrderUpdated, let's handle the refresh more directly
          // This gives us more control over error handling during refresh
          // await _handleRefreshAfterPaymentCancel();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text('Failed to cancel payment: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _cancelPayment(); // Retry
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  // New method to handle the refresh after payment cancellation
  Future<void> _handleRefreshAfterPaymentCancel() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // First notify the parent that the list needs updating
      widget.onOrderUpdated();

      // Then fetch the updated order details
      try {
        final orderDetail =
            await OrderService.fetchCompletedOrderDetail(widget.orderId);

        if (mounted) {
          setState(() {
            _orderDetail = orderDetail;
            _isLoading = false;
          });
        }
      } catch (e) {
        // Special handling for "Payment details not found" error
        if (e.toString().contains("Payment details not found")) {
          // This is expected after canceling payment - the order still exists but payment is gone
          // Let's just refetch the entire order
          await _fetchOrderDetail();
        } else {
          // For other errors, display them
          if (mounted) {
            setState(() {
              _errorMessage = e.toString();
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              "Failed to refresh order after payment cancellation: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading details',
                style: TextStyle(fontSize: 18, color: Colors.red[700]),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_errorMessage!, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchOrderDetail,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_orderDetail == null) {
      return const Center(child: Text('No order details found'));
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true, // Always shows the draggable thumb
      thickness: 20.0, // Very thick (20px) for excellent visibility
      radius: const Radius.circular(10), // Rounded corners for modern look
      trackVisibility: true, // Shows the background track
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Order Completed',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _orderDetail!.orderNumber,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Print buttons
                      Row(
                        children: [
                          // ElevatedButton.icon(
                          //   onPressed: _previewReceipt,
                          //   icon: const Icon(Icons.preview, size: 16),
                          //   label: const Text('Preview'),
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Colors.blue,
                          //     foregroundColor: Colors.white,
                          //   ),
                          // ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _printReceipt,
                            icon: const Icon(Icons.print, size: 16),
                            label: const Text('Print Receipt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Add cancel payment button in the same row
                          if (_orderDetail!.payment != null &&
                              _orderDetail!.payment!.isEditable)
                            ElevatedButton.icon(
                              onPressed: _cancelPayment,
                              icon: const Icon(Icons.cancel, size: 16),
                              label: const Text('Cancel Payment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Payment button
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Info

            // Items
            Text(
              'Order Items',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Items list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _orderDetail!.items.length,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemBuilder: (context, index) {
                final item = _orderDetail!.items[index];
                return _buildItemCard(item);
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20), //
              child: _buildInfoCard(),
            ),
            const SizedBox(height: 16),
            // Scroll control buttons
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16), // 👈 left & right padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton.small(
                    heroTag: "scrollUpBtn",
                    onPressed: _scrollToTop,
                    backgroundColor: Colors.green,
                    child: const Icon(
                      Icons.arrow_upward,
                      size: 20,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton.small(
                    heroTag: "scrollDownBtn",
                    onPressed: _scrollToBottom,
                    backgroundColor: Colors.green,
                    child: const Icon(
                      Icons.arrow_downward,
                      size: 20,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _printReceipt() async {
    if (_orderDetail == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: true, // Allow closing
        builder: (context) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Preparing receipt...'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(
                  child: Text('Please wait while we prepare your receipt')),
            ],
          ),
        ),
      );

      await ReceiptService.printReceipt(_orderDetail!);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt sent to printer successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Print Error'),
              ],
            ),
            content: Text('Failed to print receipt: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _printReceipt(); // Retry
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _previewReceipt() async {
    if (_orderDetail == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: true, // Allow closing
        builder: (context) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Preparing receipt...'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(
                  child: Text('Please wait while we prepare your receipt')),
            ],
          ),
        ),
      );

      await ReceiptService.previewReceipt(_orderDetail!);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Preview Error'),
              ],
            ),
            content: Text('Failed to preview receipt: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _previewReceipt(); // Retry
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _recordPayment() async {
    if (_orderDetail == null) return;

    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        totalAmount: double.parse(_orderDetail!.grandTotal.toString()),
        onPayment: (amountReceived, paymentMethodsData, notes, discountAmount,
            discountPercentage) async {
          await _processPayment(amountReceived, paymentMethodsData, notes,
              discountAmount, discountPercentage);
        },
      ),
    );
  }

  Future<void> _processPayment(
    double amountReceived,
    List<Map<String, dynamic>> paymentMethodsData,
    String notes,
    double discountAmount,
    double discountPercentage,
  ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Recording payment...'),
            ],
          ),
        ),
      );

      final success = await OrderService.recordPayment(
        orderId: _orderDetail!.id,
        totalAmount: double.parse(_orderDetail!.total.toString()),
        amountReceived: amountReceived,
        paymentMethods: paymentMethodsData,
        paymentNotes: notes.isNotEmpty ? notes : null,
        discount: discountAmount,
        discountValue: discountPercentage,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment recorded successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh order details
          widget.onOrderUpdated();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Payment Error'),
              ],
            ),
            content: Text('Failed to record payment: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _recordPayment(); // Retry
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildInfoCard() {
    final order = _orderDetail!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                    'Table', '${order.tableNumber} (${order.tableLocation})'),
              ),
              if (order.covers != null)
                Expanded(
                  child: _buildInfoRow('Covers', order.covers.toString()),
                ),
            ],
          ),
          _buildInfoRow('Waiter', order.waiterName),
          // _buildInfoRow('Order Type', order.orderType.toUpperCase()),
          // _buildInfoRow('Status', order.status.toUpperCase()),

          // Payment Information
          if (order.isPaid) ...[
            const Divider(),
            Text(
              'Payment Information',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Payment Ref', order.payment!.paymentReference),

            // Payment Methods
            if (order.paymentMethods.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Payment Methods:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              ...order.paymentMethods.map((method) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${method.displayMethodType}'
                          '${(method.clientName != null && method.clientName!.isNotEmpty) ? ' (${method.clientName})' : ''}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          method.formattedAmount,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            const SizedBox(height: 8),
            _buildInfoRow(
                'Amount Received', order.payment!.formattedAmountReceived),
            if (order.hasChange)
              _buildInfoRow('Change', order.payment!.formattedChangeAmount),
          ],

          const Divider(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show discount only if greater than 0
              if (double.tryParse(order.discount) != null &&
                  double.parse(order.discount) > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      order.formattedTotal,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
              ],

              // Always show subtotal if no discount
              // if (double.tryParse(order.discount) == null ||
              //     double.parse(order.discount) == 0) ...[
              //   Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       const Text(
              //         'Subtotal:',
              //         style:
              //             TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              //       ),
              //       Text(
              //         order.formattedSubtotal,
              //         style: const TextStyle(
              //             fontSize: 16, fontWeight: FontWeight.w500),
              //       ),
              //     ],
              //   ),
              //   const SizedBox(height: 5),
              // ],

              // Show VAT if available
              // if (order.vat != null && double.parse(order.vat!) > 0) ...[
              //   Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       const Text(
              //         'VAT:',
              //         style:
              //             TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              //       ),
              //       Text(
              //         order.formattedVat,
              //         style: const TextStyle(
              //             fontSize: 16, fontWeight: FontWeight.w500),
              //       ),
              //     ],
              //   ),
              //   const SizedBox(height: 5),
              // ],

              // Show Service Fee if available
              if (order.serviceFee != null &&
                  double.parse(order.serviceFee!) > 0) ...[
                // const Divider(thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Service Fee:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      order.formattedServiceFee,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
              ],
              if (order.discount != null &&
                  double.parse(order.discount) > 0) ...[
                // const Divider(thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discount:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      '- ${order.formattedDiscount}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
              // Show Grand Total if different from total
              if (order.grandTotal != null &&
                  double.parse(order.grandTotal!) !=
                      double.parse(order.total)) ...[
                // const Divider(thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      order.formattedGrandTotal,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // const Divider(thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      order.formattedTotal,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
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
                if (item.accompanimentName != null &&
                    item.accompanimentName!.isNotEmpty)
                  Text(
                    'with ${item.accompanimentName}',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (item.hasComment)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.comment,
                            size: 14, color: Colors.orange[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.comment!,
                            style: TextStyle(
                              color: Colors.orange[700],
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
          ),
          Text(
            'Qty: ${item.quantity}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Text(
            item.formattedTotalPrice,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
