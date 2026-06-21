import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/order_detail_model.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../reportToptab/payment_dialog.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final VoidCallback? onOrderUpdated;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.onOrderUpdated,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderDetail? _orderDetail;
  bool _isLoading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPartialPaymentOrderDetail();
    _loadUserRole();
  }

  // Load the user's role
  Future<void> _loadUserRole() async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (mounted) {
        setState(() {
          _userRole = currentUser?.role.toLowerCase();
        });
      }
    } catch (e) {
      print('Error loading user role: $e');
    }
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

  // ADD THIS METHOD - This is the key fix!
  @override
  void didUpdateWidget(OrderDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If orderId changed, fetch new order details
    if (oldWidget.orderId != widget.orderId) {
      _fetchPartialPaymentOrderDetail();
    }
  }

  Future<void> _fetchPartialPaymentOrderDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final orderDetail =
          await OrderService.fetchPartialPaymentOrderDetail(widget.orderId);

      if (mounted) {
        setState(() {
          _orderDetail = orderDetail;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true, // Always shows the draggable thumb
          thickness: 20.0, // Very thick (20px) for excellent visibility
          radius: const Radius.circular(10), // Rounded corners for modern look
          trackVisibility: true, // Shows the background track
          child: SingleChildScrollView(
            controller: _scrollController,
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
                  'Error loading order details',
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
                  onPressed: _fetchPartialPaymentOrderDetail,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_orderDetail == null) {
      return Center(
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true, // Always shows the draggable thumb
          thickness: 20.0, // Very thick (20px) for excellent visibility
          radius: const Radius.circular(10), // Rounded corners for modern look
          trackVisibility: true, // Shows the background track
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Order not found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The requested order could not be found or may have been removed.',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true, // Always shows the draggable thumb
      thickness: 20.0, // Very thick (20px) for excellent visibility
      radius: const Radius.circular(10), // Rounded corners for modern look
      trackVisibility: true, // Shows the background track
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //added padding to the _buildOrderHeader
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildOrderHeader(),
            ),

            const SizedBox(height: 24),
            // _buildOrderInfo(),
            const SizedBox(height: 24),
            if (_orderDetail!.payment != null) ...[
              //added padding to the _buildOrderHeader_buildPaymentInfo(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildPaymentInfo(),
              ),
              const SizedBox(height: 24),
            ],
            //added padding to the _buildOrderItems()
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildOrderItems(),
            ),
            const SizedBox(height: 24),
            //added padding to the _buildOrderSummary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildOrderSummary(),
            ),
            const SizedBox(height: 24),
            //added padding to the _buildOrderHeader
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildActionButtons(),
            ),

            // Scroll control buttons
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: "scrollTopBtn",
                  onPressed: _scrollToTop,
                  backgroundColor: Colors.green,
                  tooltip: "Scroll to top",
                  child: const Icon(Icons.arrow_upward,
                      size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  heroTag: "scrollBottomBtn",
                  onPressed: _scrollToBottom,
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _orderDetail!.orderNumber,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${_orderDetail!.createdAt}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _orderDetail!.status.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Table',
                  _orderDetail!.tableDisplay,
                  Icons.table_restaurant,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Location',
                  _orderDetail!.tableLocation,
                  Icons.location_on,
                ),
              ),
              if (_orderDetail!.covers != null)
                Expanded(
                  child: _buildInfoItem(
                    'Covers',
                    _orderDetail!.covers.toString(),
                    Icons.people,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Waiter',
                  _orderDetail!.waiterName,
                  Icons.person,
                ),
              ),
            ],
          ),
          if (_orderDetail!.clientName != null) ...[
            const SizedBox(height: 16),
            _buildInfoItem(
              'Client',
              _orderDetail!.clientName!,
              Icons.person_outline,
            ),
          ],
          if (_orderDetail!.orderNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoItem(
              'Notes',
              _orderDetail!.orderNotes,
              Icons.note,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo() {
    final payment = _orderDetail!.payment!;
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  payment.isPartialPayment ? Icons.payment : Icons.payments,
                  color:
                      payment.isPartialPayment ? Colors.orange : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  payment.isPartialPayment
                      ? 'Partial Payment Information'
                      : 'Payment Information',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: payment.isPartialPayment
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: payment.isPartialPayment
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.green.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Reference:'),
                      Text(
                        payment.paymentReference,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount Received:'),
                      Text(
                        payment.formattedAmountReceived,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (payment.hasRemainingAmount) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remaining Amount:'),
                        Text(
                          payment.formattedRemainingAmount,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Status:'),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: payment.isPartialPayment
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          payment.paymentStatus?.toUpperCase() ?? 'PAID',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: payment.isPartialPayment
                                ? Colors.orange[700]
                                : Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_orderDetail!.paymentMethods.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Payment Methods Used:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...(_orderDetail!.paymentMethods.map((method) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getPaymentMethodIcon(method.methodType),
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            method.displayMethodType,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          method.formattedAmount,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ))),
            ],
          ],
        ));
  }

  IconData _getPaymentMethodIcon(String methodType) {
    switch (methodType.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'mobile':
      case 'mobile_money':
        return Icons.phone_android;
      case 'bank_transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  Widget _buildOrderItems() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items (${_orderDetail!.items.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _orderDetail!.items.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = _orderDetail!.items[index];
              return _buildOrderItemCard(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${item.quantity}x',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.specificationName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.formattedTotalPrice,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.formattedUnitPrice} each',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  _orderDetail!.formattedSubtotal,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Discount:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  _orderDetail!.formattedDiscount,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            // Show VAT if available
            if (_orderDetail!.vat != null &&
                double.parse(_orderDetail!.vat!) > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'VAT:',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    _orderDetail!.formattedVat,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            // Show Service Fee if available
            if (_orderDetail!.serviceFee != null &&
                double.parse(_orderDetail!.serviceFee!) > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Service Fee:',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    _orderDetail!.formattedServiceFee,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _orderDetail!.grandTotal != null &&
                          double.parse(_orderDetail!.grandTotal!) !=
                              double.parse(_orderDetail!.total)
                      ? 'Grand Total:'
                      : 'Total:',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _orderDetail!.grandTotal != null &&
                          double.parse(_orderDetail!.grandTotal!) !=
                              double.parse(_orderDetail!.total)
                      ? _orderDetail!.formattedGrandTotal
                      : _orderDetail!.formattedTotal,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ));
  }

  // Get current user role
  String? _userRole;

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Add Record Remaining Payment button for partial payments (only for non-waiters)
        if (_orderDetail!.payment != null &&
            _orderDetail!.payment!.isPartialPayment &&
            _orderDetail!.payment!.hasRemainingAmount &&
            _userRole != 'waiter') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _recordRemainingPayment(),
              icon: const Icon(Icons.payment, size: 20),
              label: Text(
                  'Record Remaining Payment (${_orderDetail!.payment!.formattedRemainingAmount})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (_orderDetail!.status == 'pending') ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _acceptOrder(),
                  icon: const Icon(Icons.check),
                  label: const Text('Marks as delivered'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_orderDetail!.status == 'accepted' ||
            _orderDetail!.status == 'preparing' ||
            _orderDetail!.status == 'ready') ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => {},
              icon: const Icon(Icons.delivery_dining),
              label: const Text('Mark as Delivered'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
        // if (_orderDetail!.status == 'served') ...[
        //   Container(
        //     width: double.infinity,
        //     padding: const EdgeInsets.symmetric(vertical: 16),
        //     decoration: BoxDecoration(
        //       color: Colors.green.withOpacity(0.1),
        //       borderRadius: BorderRadius.circular(8),
        //       border: Border.all(color: Colors.green),
        //     ),
        //     child: const Row(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //         Icon(Icons.check_circle, color: Colors.green),
        //         SizedBox(width: 8),
        //         Text(
        //           'Order Delivered',
        //           style: TextStyle(
        //             color: Colors.green,
        //             fontWeight: FontWeight.bold,
        //             fontSize: 16,
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ],
      ],
    );
  }

  Color _getStatusColor() {
    switch (_orderDetail!.status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _acceptOrder() async {
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
              Text('Marking order as delivered...'),
            ],
          ),
        ),
      );

      await OrderService.markOrderAsServed(_orderDetail!.id);

      // Hide loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Order ${_orderDetail!.orderNumber} marked as delivered'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh parent list and current details
        widget.onOrderUpdated?.call();
        await _fetchPartialPaymentOrderDetail(); // Refresh the details
      }
    } catch (e) {
      // Hide loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark order as delivered: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _recordRemainingPayment() async {
    if (_orderDetail?.payment == null ||
        !_orderDetail!.payment!.hasRemainingAmount) return;

    // Check user role - don't allow waiters to record payments
    if (_userRole == 'waiter') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to record payments'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final remainingAmount =
        double.parse(_orderDetail!.payment!.remainingAmount!);

    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        totalAmount: remainingAmount,
        onPayment: (amountReceived,
            paymentMethodsData,
            notes,
            discountAmount,
            discountPercentage,
            identificationType,
            phoneOrTin,
            customerName,
            purchaseCode) async {
          await _processPayment(
            amountReceived,
            paymentMethodsData,
            notes,
            discountAmount,
            discountPercentage,
            identificationType,
            phoneOrTin,
            customerName,
            purchaseCode,
          );
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
    String identificationType,
    String phoneOrTin,
    String customerName,
    String purchaseCode,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Recording remaining payment...'),
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
              content: Text('Remaining payment recorded successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh order details and parent list
          widget.onOrderUpdated?.call();
          await _fetchPartialPaymentOrderDetail();
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
            content: Text('Failed to record remaining payment: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _recordRemainingPayment(); // Retry
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }
}
