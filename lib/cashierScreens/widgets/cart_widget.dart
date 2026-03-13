import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:kozo/models/table_model.dart';
import 'package:kozo/models/waiter_model.dart';
import 'package:kozo/services/order_service.dart';

import '../../constants/app_constants.dart';
import '../../models/category_model.dart';
import '../../models/cart_item_model.dart' hide Specification;
import 'add_note_dialog.dart';
import 'prep_order_dialog.dart'; // Import the new dialog
import 'pressure_selection_dialog.dart'; // Import the pressure selection dialog

class CartWidget extends StatelessWidget {
  final List<CartItem> cartItems;
  final List<Waiter> waiters;
  final List<TableModel> tables;
  final List<SpecialClient> specialClients;
  final SpecialClient? selectedClient;
  final Waiter? selectedWaiter;
  final TableModel? selectedTable;
  final String covers;
  final bool isLoadingWaiters;
  final bool isLoadingTables;
  final List<ClientDiscount> clientDiscounts;
  final Map<int, List<Specification>> itemSpecifications;
  final Function(int, {int? specificationId}) onRemoveFromCart;
  final Function(int, int, {int? specificationId}) onUpdateQuantity;
  final Function(Waiter?) onWaiterChanged;
  final Function(TableModel?) onTableChanged;
  final Function(SpecialClient?) onClientChanged;
  final Function(String) onCoversChanged;
  final Function(int, int, String) onUpdateItemComment;
  final Function(int, int, int) onUpdateItemPrepOrder;
  final Function(int, int, int?) onUpdateItemPressure; // Add pressure callback
  final VoidCallback onAutoAssignPrepOrders; // Add this parameter
  final VoidCallback onProcessOrder;
  final double Function() calculateOriginalTotal;
  final double Function() calculateTotalDiscount;

  const CartWidget({
    Key? key,
    required this.cartItems,
    required this.waiters,
    required this.tables,
    required this.specialClients,
    required this.selectedClient,
    required this.selectedWaiter,
    required this.selectedTable,
    required this.covers,
    required this.isLoadingWaiters,
    required this.isLoadingTables,
    required this.clientDiscounts,
    required this.itemSpecifications,
    required this.onRemoveFromCart,
    required this.onUpdateQuantity,
    required this.onWaiterChanged,
    required this.onTableChanged,
    required this.onClientChanged,
    required this.onCoversChanged,
    required this.onUpdateItemComment,
    required this.onUpdateItemPrepOrder,
    required this.onUpdateItemPressure, // Add pressure callback
    required this.onAutoAssignPrepOrders, // Add this parameter
    required this.onProcessOrder,
    required this.calculateOriginalTotal,
    required this.calculateTotalDiscount,
  }) : super(key: key);

  // Add method to get specification for a cart item
  Specification? _getSpecificationForCartItem(CartItem cartItem) {
    if (cartItem.specificationId == null) return null;

    final itemSpecs = itemSpecifications[cartItem.id] ?? [];
    try {
      return itemSpecs.firstWhere(
        (spec) => spec.id == cartItem.specificationId,
      );
    } catch (e) {
      return null;
    }
  }

  // Add method to get available stock for a cart item
  int _getAvailableStock(CartItem cartItem) {
    final spec = _getSpecificationForCartItem(cartItem);
    if (spec?.requiresStockTracking == true && spec?.stockInfo != null) {
      return spec!.stockInfo!.quantity.toInt();
    }
    return -1; // Unlimited stock
  }

  // Add method to check if quantity can be increased
  bool _canIncreaseQuantity(CartItem cartItem) {
    final availableStock = _getAvailableStock(cartItem);
    if (availableStock == -1) return true; // Unlimited stock
    return cartItem.quantity < availableStock;
  }

  // Add method to show stock error message
  void _showStockError(BuildContext context, int availableStock) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Cannot add more items. Only $availableStock available in stock.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ScrollController _scrollController = ScrollController();

    return Container(
      width: 500,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Cart header - fixed at top
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Cart (${cartItems.length} items)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (selectedClient != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Client: ${selectedClient!.clientName}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Everything below the header is scrollable
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              thickness: 20.0,
              radius: const Radius.circular(10),
              trackVisibility: true,
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: cartItems.isEmpty
                    ? const SizedBox(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Your cart is empty',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Add Auto-assign Prep Orders button at the top of the cart
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: onAutoAssignPrepOrders,
                                    icon: const Icon(Icons.schedule),
                                    label: const Text(
                                        'Auto-assign Preparation Order'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[700],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Cart items list
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              final cartItem = cartItems[index];
                              final spec =
                                  _getSpecificationForCartItem(cartItem);
                              final availableStock =
                                  _getAvailableStock(cartItem);
                              final canIncrease =
                                  _canIncreaseQuantity(cartItem);

                              return Card(
                                margin:
                                    const EdgeInsets.only(bottom: 8, right: 30),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              cartItem.itemName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close,
                                                color: Colors.red),
                                            onPressed: () => onRemoveFromCart(
                                                cartItem.id,
                                                specificationId:
                                                    cartItem.specificationId),
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        cartItem.categoryName,
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12),
                                      ),
                                      if (cartItem.price > 0)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Price: RWF ${cartItem.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            if (cartItem.description
                                                .contains('Original:'))
                                              Text(
                                                cartItem.description
                                                    .split('|')
                                                    .where((part) => part
                                                        .contains('Original:'))
                                                    .first
                                                    .trim(),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            if (cartItem.description
                                                .contains('Discount:'))
                                              Text(
                                                cartItem.description
                                                    .split('|')
                                                    .where((part) => part
                                                        .contains('Discount:'))
                                                    .first
                                                    .trim(),
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                      const SizedBox(height: 8),

                                      // Preparation Order indicator
                                      if (cartItem.prepOrder != null &&
                                          cartItem.prepOrder! > 0)
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: Colors.blue[200]!),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.schedule,
                                                  size: 16,
                                                  color: Colors.blue[700]),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _getPrepOrderText(
                                                      cartItem.prepOrder!),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue[700],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // Comment section
                                      if (cartItem.comment != null &&
                                          cartItem.comment!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.amber[50],
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: Colors.amber[200]!),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.comment,
                                                  size: 16,
                                                  color: Colors.amber[700]),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Note: ${cartItem.comment}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.amber[700],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // Pressure Cooking indicator
                                      if (cartItem.requiresPressure &&
                                          cartItem.selectedPressureId != null &&
                                          spec != null &&
                                          spec.hasPressureOptions)
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[50],
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: Colors.orange[200]!),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.local_fire_department,
                                                  size: 16,
                                                  color: Colors.orange[700]),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _getPressureText(
                                                      cartItem
                                                          .selectedPressureId!,
                                                      spec.pressureCooking),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.orange[700],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove),
                                                onPressed: () =>
                                                    onUpdateQuantity(
                                                  cartItem.id,
                                                  cartItem.quantity - 1,
                                                  specificationId:
                                                      cartItem.specificationId,
                                                ),
                                                constraints:
                                                    const BoxConstraints(),
                                                padding:
                                                    const EdgeInsets.all(4),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.grey),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                    '${cartItem.quantity}'),
                                              ),
                                              // Updated add button with stock validation
                                              Tooltip(
                                                message: !canIncrease &&
                                                        availableStock > 0
                                                    ? 'Stock limit reached'
                                                    : availableStock <= 0
                                                        ? 'Out of stock'
                                                        : 'Add one more',
                                                child: IconButton(
                                                  icon: Icon(
                                                    Icons.add,
                                                    color: canIncrease
                                                        ? Colors.black
                                                        : Colors.grey[400],
                                                  ),
                                                  onPressed: () {
                                                    if (canIncrease) {
                                                      onUpdateQuantity(
                                                        cartItem.id,
                                                        cartItem.quantity + 1,
                                                        specificationId: cartItem
                                                            .specificationId,
                                                      );
                                                    } else {
                                                      _showStockError(context,
                                                          availableStock);
                                                    }
                                                  },
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Action Buttons Row
                                          Row(
                                            children: [
                                              // Add Prep Order button
                                              TextButton.icon(
                                                onPressed: () =>
                                                    _showPrepOrderDialog(
                                                        context, cartItem),
                                                icon: Icon(
                                                  cartItem.prepOrder != null &&
                                                          cartItem.prepOrder! >
                                                              0
                                                      ? Icons.edit_calendar
                                                      : Icons.schedule,
                                                  size: 16,
                                                  color: Colors.blue[700],
                                                ),
                                                label: Text(
                                                  cartItem.prepOrder != null &&
                                                          cartItem.prepOrder! >
                                                              0
                                                      ? 'Edit Order'
                                                      : 'Prep Order',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue[700],
                                                  ),
                                                ),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              // Pressure Cooking button - only show if item requires pressure
                                              if (cartItem.requiresPressure &&
                                                  spec != null &&
                                                  spec.hasPressureOptions)
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _showPressureDialog(
                                                          context,
                                                          cartItem,
                                                          spec),
                                                  icon: Icon(
                                                    cartItem.selectedPressureId !=
                                                            null
                                                        ? Icons
                                                            .local_fire_department
                                                        : Icons
                                                            .local_fire_department_outlined,
                                                    size: 16,
                                                    color: Colors.orange[700],
                                                  ),
                                                  label: Text(
                                                    cartItem.selectedPressureId !=
                                                            null
                                                        ? 'Edit Temperature'
                                                        : 'Temperature',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.orange[700],
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                ),

                                              if (cartItem.requiresPressure &&
                                                  spec != null &&
                                                  spec.hasPressureOptions)
                                                const SizedBox(width: 8),

                                              // Add Note button
                                              TextButton.icon(
                                                onPressed: () =>
                                                    _showCommentDialog(
                                                        context, cartItem),
                                                icon: Icon(
                                                  cartItem.comment != null &&
                                                          cartItem.comment!
                                                              .isNotEmpty
                                                      ? Icons.edit_note
                                                      : Icons.add_comment,
                                                  size: 16,
                                                  color: AppColors.primary,
                                                ),
                                                label: Text(
                                                  cartItem.comment != null &&
                                                          cartItem.comment!
                                                              .isNotEmpty
                                                      ? 'Edit Note'
                                                      : 'Add Note',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Add stock information display
                                      if (spec?.requiresStockTracking == true &&
                                          spec?.stockInfo != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: availableStock <= 0
                                                ? Colors.red[50]
                                                : availableStock <= 5
                                                    ? Colors.orange[50]
                                                    : Colors.green[50],
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: availableStock <= 0
                                                  ? Colors.red[200]!
                                                  : availableStock <= 5
                                                      ? Colors.orange[200]!
                                                      : Colors.green[200]!,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.inventory_2,
                                                size: 16,
                                                color: availableStock <= 0
                                                    ? Colors.red[700]
                                                    : availableStock <= 5
                                                        ? Colors.orange[700]
                                                        : Colors.green[700],
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  availableStock <= 0
                                                      ? 'Out of Stock'
                                                      : 'Available: $availableStock',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: availableStock <= 0
                                                        ? Colors.red[700]
                                                        : availableStock <= 5
                                                            ? Colors.orange[700]
                                                            : Colors.green[700],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Footer section (now part of the scrollable content)
                          if (cartItems.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(right: 30),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                    top: BorderSide(color: Colors.grey[300]!)),
                              ),
                              child: Column(
                                children: [
                                  // Total Items and Amount
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total Items:',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${cartItems.fold(0, (sum, item) => sum + item.quantity)}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  if (cartItems.any((item) => item.price > 0))
                                    Column(
                                      children: [
                                        // Show original total
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Subtotal:',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            Text(
                                              'RWF ${calculateOriginalTotal().toStringAsFixed(2)}',
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        // Show discount amount if any
                                        if (calculateTotalDiscount() > 0)
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Discount:',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.green),
                                              ),
                                              Text(
                                                '- RWF ${calculateTotalDiscount().toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        // Show final total
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total Amount:',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'RWF ${cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity)).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 16),

                                  // Three sections in one row: Special Client, Waiter, and Table
                                  Row(
                                    children: [
                                      // // Special Client Section
                                      // Expanded(
                                      //   child: Container(
                                      //     padding: const EdgeInsets.all(8),
                                      //     margin:
                                      //         const EdgeInsets.only(right: 4),
                                      //     decoration: BoxDecoration(
                                      //       color: Colors.purple[50],
                                      //       borderRadius:
                                      //           BorderRadius.circular(8),
                                      //       border: Border.all(
                                      //           color: Colors.purple[200]!),
                                      //     ),
                                      //     child: Column(
                                      //       crossAxisAlignment:
                                      //           CrossAxisAlignment.start,
                                      //       children: [
                                      //         const Text(
                                      //           'Special Client',
                                      //           style: TextStyle(
                                      //             fontWeight: FontWeight.bold,
                                      //             fontSize: 12,
                                      //             color: Colors.purple,
                                      //           ),
                                      //         ),
                                      //         const SizedBox(height: 4),
                                      //         DropdownSearch<SpecialClient?>(
                                      //           selectedItem: selectedClient,
                                      //           items: (filter,
                                      //               infiniteScrollProps) {
                                      //             return [
                                      //               null,
                                      //               ...specialClients
                                      //             ];
                                      //           },
                                      //           itemAsString:
                                      //               (SpecialClient? client) =>
                                      //                   client?.clientName ??
                                      //                   'None',
                                      //           compareFn: (SpecialClient? a,
                                      //               SpecialClient? b) {
                                      //             if (a == null && b == null)
                                      //               return true;
                                      //             if (a == null || b == null)
                                      //               return false;
                                      //             return a.id == b.id;
                                      //           },
                                      //           decoratorProps:
                                      //               DropDownDecoratorProps(
                                      //             decoration: InputDecoration(
                                      //               labelText: 'Select Client',
                                      //               border: OutlineInputBorder(
                                      //                 borderRadius:
                                      //                     BorderRadius.circular(
                                      //                         8),
                                      //               ),
                                      //               contentPadding:
                                      //                   const EdgeInsets
                                      //                       .symmetric(
                                      //                       horizontal: 12,
                                      //                       vertical: 8),
                                      //             ),
                                      //           ),
                                      //           popupProps: PopupProps.menu(
                                      //             showSearchBox: true,
                                      //             searchFieldProps:
                                      //                 TextFieldProps(
                                      //               decoration: InputDecoration(
                                      //                 hintText:
                                      //                     'Search clients...',
                                      //                 prefixIcon:
                                      //                     Icon(Icons.search),
                                      //                 border:
                                      //                     OutlineInputBorder(
                                      //                   borderRadius:
                                      //                       BorderRadius
                                      //                           .circular(8),
                                      //                 ),
                                      //               ),
                                      //             ),
                                      //             menuProps: MenuProps(
                                      //               borderRadius:
                                      //                   BorderRadius.circular(
                                      //                       8),
                                      //               elevation: 2,
                                      //             ),
                                      //             itemBuilder: (context, item,
                                      //                 isDisabled, isSelected) {
                                      //               return Container(
                                      //                 padding: const EdgeInsets
                                      //                     .symmetric(
                                      //                     horizontal: 16,
                                      //                     vertical: 12),
                                      //                 child: Row(
                                      //                   children: [
                                      //                     Expanded(
                                      //                       child: Text(
                                      //                         item?.clientName ??
                                      //                             'None',
                                      //                         style: TextStyle(
                                      //                           fontWeight: isSelected
                                      //                               ? FontWeight
                                      //                                   .bold
                                      //                               : FontWeight
                                      //                                   .normal,
                                      //                           color: item ==
                                      //                                   null
                                      //                               ? Colors.grey[
                                      //                                   600]
                                      //                               : Colors
                                      //                                   .black,
                                      //                         ),
                                      //                       ),
                                      //                     ),
                                      //                     if (item == null)
                                      //                       Icon(
                                      //                         Icons.clear,
                                      //                         size: 16,
                                      //                         color: Colors
                                      //                             .grey[600],
                                      //                       ),
                                      //                   ],
                                      //                 ),
                                      //               );
                                      //             },
                                      //           ),
                                      //           onChanged: onClientChanged,
                                      //         ),
                                      //       ],
                                      //     ),
                                      //   ),
                                      // ),

                                      // Waiter Section
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.blue[200]!),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Waiter',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              isLoadingWaiters
                                                  ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    )
                                                  : InkWell(
                                                      onTap: () =>
                                                          _showWaiterSelectionDialog(
                                                              context,
                                                              waiters,
                                                              selectedWaiter,
                                                              onWaiterChanged),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 12,
                                                                vertical: 12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          border: Border.all(
                                                              color: Colors
                                                                  .grey[400]!),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                selectedWaiter
                                                                        ?.name ??
                                                                    'Select Waiter',
                                                                style:
                                                                    TextStyle(
                                                                  color: selectedWaiter !=
                                                                          null
                                                                      ? Colors
                                                                          .black
                                                                      : Colors.grey[
                                                                          600],
                                                                  fontSize: 14,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            Icon(
                                                                Icons
                                                                    .arrow_drop_down,
                                                                color: Colors
                                                                    .grey[600]),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Table Section
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          margin:
                                              const EdgeInsets.only(left: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.green[200]!),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Table',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Colors.green,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              isLoadingTables
                                                  ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    )
                                                  : DropdownSearch<TableModel>(
                                                      selectedItem:
                                                          selectedTable,
                                                      items: (filter,
                                                              infiniteScrollProps) =>
                                                          tables,
                                                      itemAsString:
                                                          (TableModel table) =>
                                                              table.tableName,
                                                      compareFn: (TableModel? a,
                                                              TableModel? b) =>
                                                          a?.id == b?.id,
                                                      decoratorProps:
                                                          DropDownDecoratorProps(
                                                        decoration:
                                                            InputDecoration(
                                                          labelText:
                                                              'Select Table',
                                                          hintText:
                                                              'Select a table',
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                        ),
                                                      ),
                                                      popupProps:
                                                          PopupPropsMultiSelection
                                                              .menu(
                                                        showSearchBox: true,
                                                        containerBuilder:
                                                            (context,
                                                                popupWidget) {
                                                          return Container(
                                                            margin: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        20),
                                                            child: popupWidget,
                                                          );
                                                        },
                                                        scrollbarProps:
                                                            ScrollbarProps(
                                                          thickness: 8,
                                                          radius:
                                                              Radius.circular(
                                                                  10),
                                                          thumbVisibility: true,
                                                          trackVisibility: true,
                                                          interactive: true,
                                                          padding:
                                                              EdgeInsets.only(
                                                                  right: 4),
                                                        ),
                                                        searchFieldProps:
                                                            TextFieldProps(
                                                          decoration:
                                                              InputDecoration(
                                                            hintText:
                                                                'Search tables...',
                                                            prefixIcon: Icon(
                                                                Icons.search),
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                          ),
                                                        ),
                                                        menuProps: MenuProps(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          elevation: 2,
                                                        ),
                                                        itemBuilder: (context,
                                                            item,
                                                            isDisabled,
                                                            isSelected) {
                                                          return Container(
                                                            margin: const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 15,
                                                                vertical:
                                                                    4), // space outside each item
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical:
                                                                        8), // internal padding
                                                            decoration:
                                                                BoxDecoration(
                                                              color: isSelected
                                                                  ? Colors
                                                                      .green[50]
                                                                  : Colors
                                                                      .white, // optional: highlight selected
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    item.tableName,
                                                                    style:
                                                                        TextStyle(
                                                                      fontWeight: isSelected
                                                                          ? FontWeight
                                                                              .bold
                                                                          : FontWeight
                                                                              .normal,
                                                                    ),
                                                                  ),
                                                                ),
                                                                // Add space for scrollbar
                                                                const SizedBox(
                                                                    width: 55),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                      onChanged: onTableChanged,
                                                      validator:
                                                          (TableModel? value) {
                                                        if (value == null) {
                                                          return 'Please select a table';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Covers Section
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          margin:
                                              const EdgeInsets.only(left: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.orange[200]!),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Covers',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              TextFormField(
                                                initialValue: covers,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: 'Enter covers',
                                                  hintText: 'e.g. 4',
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 8),
                                                ),
                                                onChanged: onCoversChanged,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: cartItems.isNotEmpty &&
                                              selectedWaiter != null &&
                                              selectedTable != null
                                          ? onProcessOrder
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                      ),
                                      child: Text(
                                        selectedWaiter == null
                                            ? 'Select Waiter to Continue'
                                            : selectedTable == null
                                                ? 'Select Table to Continue'
                                                : 'Process Order',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),

                                  // Add some padding at the bottom for better scrolling
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get preparation order text
  String _getPrepOrderText(int prepOrder) {
    switch (prepOrder) {
      case 1:
        return 'Cource 1';
      case 2:
        return 'Cource 2';
      case 3:
        return 'Cource 3';
      case 4:
        return 'Cource 4';
      default:
        return 'Cource order: $prepOrder';
    }
  }

  // Helper method to get pressure cooking text
  String _getPressureText(
      int pressureId, List<PressureCooking> pressureOptions) {
    try {
      final pressure = pressureOptions.firstWhere(
        (p) => p.pressureId == pressureId,
      );
      return 'Temperature: ${pressure.pressureLevel.toUpperCase()}';
    } catch (e) {
      return 'Temperature: Selected';
    }
  }

  void _showCommentDialog(BuildContext context, CartItem cartItem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddNoteDialog(
          cartItem: cartItem,
          onSaveNote: (comment) {
            onUpdateItemComment(
                cartItem.id, cartItem.specificationId ?? 0, comment);
          },
        );
      },
    );
  }

  void _showPrepOrderDialog(BuildContext context, CartItem cartItem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PrepOrderDialog(
          cartItem: cartItem,
          cartLength: cartItems.length, // Pass the current cart length
          onSavePrepOrder: (prepOrder) {
            onUpdateItemPrepOrder(
                cartItem.id, cartItem.specificationId ?? 0, prepOrder);
          },
        );
      },
    );
  }

  void _showPressureDialog(
      BuildContext context, CartItem cartItem, Specification spec) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PressureSelectionDialog(
          cartItem: cartItem,
          pressureOptions: spec.pressureCooking,
          onSavePressure: (pressureId) {
            onUpdateItemPressure(
                cartItem.id, cartItem.specificationId ?? 0, pressureId);
          },
        );
      },
    );
  }

  void _showWaiterSelectionDialog(BuildContext context, List<Waiter> waiters,
      Waiter? selectedWaiter, Function(Waiter?) onWaiterChanged) {
    // Create a list with the default waiter option
    final allWaiters = [
      Waiter(id: -1, name: '(Self-handled)'),
      ...waiters,
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final ScrollController waiterScrollController = ScrollController();
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text('Select Waiter'),
            ],
          ),
          content: SizedBox(
            width: 320,
            height: 400,
            child: Scrollbar(
              controller: waiterScrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 12.0,
              radius: const Radius.circular(6),
              child: ListView.builder(
                controller: waiterScrollController,
                padding: const EdgeInsets.only(right: 20),
                itemCount: allWaiters.length,
                itemBuilder: (context, index) {
                  final waiter = allWaiters[index];
                  final isSelected = selectedWaiter?.id == waiter.id;

                  return Card(
                    color: isSelected ? Colors.blue[100] : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isSelected ? Colors.blue[700] : Colors.grey[300],
                        child: Icon(
                          waiter.id == -1 ? Icons.person_off : Icons.person,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                      title: Text(
                        waiter.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.blue[700] : Colors.black,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Colors.blue[700])
                          : null,
                      onTap: () {
                        onWaiterChanged(waiter);
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
