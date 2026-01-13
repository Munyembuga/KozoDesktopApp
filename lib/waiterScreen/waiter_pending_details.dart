import 'package:flutter/material.dart';
import 'package:kozo/services/waiter_order_services.dart';
import '../../constants/app_constants.dart';
import '../../models/order_detail_model.dart';

class WaiterPendingDetails extends StatefulWidget {
  final int orderId;
  final VoidCallback? onOrderUpdated;

  const WaiterPendingDetails({
    super.key,
    required this.orderId,
    this.onOrderUpdated,
  });

  @override
  State<WaiterPendingDetails> createState() => _WaiterPendingDetailsState();
}

class _WaiterPendingDetailsState extends State<WaiterPendingDetails> {
  OrderDetail? _orderDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  // ADD THIS METHOD - This is the key fix!
  @override
  void didUpdateWidget(WaiterPendingDetails oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If orderId changed, fetch new order details
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

      final orderDetail =
          await WaiterOrderServices.fetchOrderDetail(widget.orderId);

      if (mounted) {
        setState(() {
          _orderDetail = orderDetail;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching order details: $e");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Future<void> _cancelOrder() async {
  //   try {
  //     // Show confirmation dialog
  //     final confirm = await showDialog<bool>(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: const Row(
  //           children: [
  //             Icon(Icons.warning, color: Colors.orange),
  //             SizedBox(width: 8),
  //             Text('Cancel Order'),
  //           ],
  //         ),
  //         content: Text(
  //           'Are you sure you want to cancel order ${_orderDetail!.orderNumber}?\n\nThis action cannot be undone.',
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(false),
  //             child: const Text('No, Keep Order'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () => Navigator.of(context).pop(true),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.red,
  //               foregroundColor: Colors.white,
  //             ),
  //             child: const Text('Yes, Cancel Order'),
  //           ),
  //         ],
  //       ),
  //     );

  //     if (confirm != true) return;

  //     // Show loading
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (context) => const AlertDialog(
  //         content: Row(
  //           children: [
  //             CircularProgressIndicator(),
  //             SizedBox(width: 16),
  //             Text('Cancelling order...'),
  //           ],
  //         ),
  //       ),
  //     );

  //     final success =
  //         await WaiterOrderServices.fetchCompletedOrders(widget.orderId);

  //     // Hide loading
  //     if (mounted) {
  //       Navigator.of(context).pop();
  //     }

  //     if (success) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Order cancelled successfully'),
  //             backgroundColor: Colors.green,
  //           ),
  //         );

  //         // Call the callback to refresh parent orders list
  //         widget.onOrderUpdated?.call();

  //         // Don't try to refresh this order detail since it's cancelled
  //         // Instead, show a cancelled state or clear the selection
  //         if (mounted) {
  //           setState(() {
  //             _orderDetail = null; // Clear the order detail
  //             _errorMessage = "This order has been cancelled";
  //           });
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     // Hide loading if still showing
  //     if (mounted && Navigator.canPop(context)) {
  //       Navigator.of(context).pop();
  //     }

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Failed to cancel order: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
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
              onPressed: _fetchOrderDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_orderDetail == null) {
      return const Center(
        child: Text('Order not found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeader(),
          const SizedBox(height: 24),
          _buildOrderInfo(),
          const SizedBox(height: 24),
          _buildOrderItems(),
          const SizedBox(height: 24),
          _buildOrderSummary(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
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
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                " RWF ${_orderDetail!.formattedTotal}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_orderDetail!.status == 'served') ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Order Delivered',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ] else if (_orderDetail!.status.toLowerCase() == 'pending') ...[
          // Cancel Order Button for pending orders
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => {},
              icon: const Icon(Icons.cancel, size: 20),
              label: const Text('Cancel Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
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
}
