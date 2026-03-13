import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kozo/cashierScreens/login_screen.dart';
import 'package:kozo/cashierScreens/widgets/accompaniment_dialog.dart';
import 'package:kozo/models/table_model.dart';
import 'package:kozo/navRailscreen/navRailMainWaiter.dart';
import 'package:kozo/services/auto_print_service.dart';
import 'package:kozo/services/waiter_order_services.dart';
import 'package:kozo/waiterScreen/widget/waiter_cart_widget.dart';
import '../constants/app_constants.dart';
import '../models/category_model.dart';
import '../models/cart_item_model.dart' hide Specification;

class Waitermakeneworder extends StatefulWidget {
  const Waitermakeneworder({super.key});

  @override
  State<Waitermakeneworder> createState() => _WaitermakeneworderState();
}

class _WaitermakeneworderState extends State<Waitermakeneworder> {
  final ScrollController _rightScrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _itemsGridController = ScrollController();
  final ScrollController _specificationsController = ScrollController();
  List<Category> _categories = [];
  List<MenuItem> _menuItems = [];
  List<CartItem> _cartItems = [];
  List<ClientDiscount> _clientDiscounts = [];
  List<TableModel> _tables = [];
  Category? _selectedCategory;
  TableModel? _selectedTable;
  bool _isLoadingItems = false;
  bool _isLoadingTables = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _orderNotesController = TextEditingController();
  int? _expandedItemId;
  Map<int, List<Specification>> _itemSpecifications = {};
  Map<int, Specification?> _selectedSpecifications = {};
  Map<int, bool> _loadingSpecifications = {};

  // Date and Time selectors for order
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Order type and notes
  String _selectedOrderType = 'dine_in'; // Default to dine_in
  String _orderNotes = '';

  // Covers for the order
  String _covers = '';

  // Search functionality variables
  bool _isSearching = false;
  bool _isLoadingSearch = false;
  List<MenuItem> _searchResults = [];
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchTables();
  }

  @override
  void dispose() {
    _rightScrollController.dispose();
    _categoryScrollController.dispose();
    _itemsGridController.dispose();
    _specificationsController.dispose();
    _searchController.dispose();
    _orderNotesController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await WaiterOrderServices.fetchCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print("Failed to fetch categories: $e");
      _showErrorSnackBar('Please try again later.');
    }
  }

  Future<void> _fetchTables() async {
    setState(() {
      _isLoadingTables = true;
    });

    try {
      final tables = await WaiterOrderServices.fetchTables();
      setState(() {
        _tables = tables;
        _isLoadingTables = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTables = false;
      });
      print("Failed to fetch tables: $e");
      _showErrorSnackBar('Please try again later.');
    }
  }

  Future<void> _fetchItemsByCategory(int categoryId) async {
    setState(() {
      _isLoadingItems = true;
    });

    try {
      final items = await WaiterOrderServices.fetchItemsByCategory(categoryId);
      setState(() {
        _menuItems = items;
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingItems = false;
      });
      print("Failed to fetch items: $e");
      _showErrorSnackBar('Please try again later.');
    }
  }

  Future<void> _toggleItemSpecifications(MenuItem item) async {
    // Set the item as expanded for fetching specifications
    setState(() {
      _expandedItemId = item.id;
      _loadingSpecifications[item.id] = true;
      _selectedSpecifications[item.id] = null;
    });

    try {
      final specificationsResponse =
          await WaiterOrderServices.fetchSpecifications(item.id);
      final specifications = specificationsResponse.cast<Specification>();
      setState(() {
        _itemSpecifications[item.id] = specifications;
        _loadingSpecifications[item.id] = false;
      });

      if (specifications.isEmpty) {
        _showErrorSnackBar('No specifications found for this item');
        setState(() {
          _expandedItemId = null;
        });
      } else {
        // Show the specifications dialog
        _showSpecificationsDialog(item, specifications);
      }
    } catch (e) {
      setState(() {
        _loadingSpecifications[item.id] = false;
        _expandedItemId = null;
      });
      print("Failed to fetch specifications: $e");
      _showErrorSnackBar('Please try again later.');
    }
  }

  void _showSpecificationsDialog(
      MenuItem item, List<Specification> specifications) {
    // Create a dedicated ScrollController for this dialog
    final ScrollController dialogScrollController = ScrollController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Options for ${item.itemName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              item.categoryName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _expandedItemId = null;
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Specifications Content - Using Expanded to allow proper scrolling
                Expanded(
                  child: Scrollbar(
                    controller: dialogScrollController,
                    thumbVisibility: true,
                    thickness: 20.0,
                    radius: const Radius.circular(10),
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: dialogScrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 20),
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose your option:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: specifications.length,
                            itemBuilder: (context, index) {
                              final spec = specifications[index];
                              return _buildSpecificationCard(item, spec);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _expandedItemId = null;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Reset expanded state when dialog is closed
      setState(() {
        _expandedItemId = null;
      });

      // Dispose of the scroll controller when dialog is closed
      dialogScrollController.dispose();
    });
  }

  Future<void> _processOrder() async {
    // Validation
    if (_cartItems.isEmpty) {
      _showErrorSnackBar('Cart is empty. Please add items to continue.');
      return;
    }

    if (_selectedTable == null) {
      _showErrorSnackBar('Please select a table.');
      return;
    }

    // Check if all cart items have prices (specifications selected)
    bool hasItemsWithoutPrice = _cartItems.any((item) => item.price < 0);
    if (hasItemsWithoutPrice) {
      _showErrorSnackBar(
          'Some items do not have specifications selected. Please select specifications for all items.');
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Cource items for the API
      List<Map<String, dynamic>> orderItems = [];

      for (var cartItem in _cartItems) {
        // Use the specificationId directly from the cart item
        if (cartItem.specificationId != null && cartItem.specificationId! > 0) {
          // Cource the item data - ensure all numeric values are passed as numbers, not strings
          Map<String, dynamic> itemData = {
            'itemId': cartItem.id,
            'specificationId': cartItem.specificationId!,
            'quantity': cartItem.quantity,
            'price': cartItem.price,
            'total': cartItem.price * cartItem.quantity,
          };

          // Add order_status if available
          if (cartItem.prepOrder != null && cartItem.prepOrder! > 0) {
            itemData['order_status'] = cartItem.prepOrder;
          }

          // Add accompaniments_id if available
          if (cartItem.accompanimentsIds != null &&
              cartItem.accompanimentsIds!.isNotEmpty) {
            itemData['accompaniments_id'] = cartItem.accompanimentsIds!.first;
          }

          // Add comment if available
          if (cartItem.comment != null && cartItem.comment!.isNotEmpty) {
            itemData['comment'] = cartItem.comment!;
          }

          // Add pressure_id if pressure cooking is selected
          if (cartItem.selectedPressureId != null) {
            itemData['pressure_id'] = cartItem.selectedPressureId!;
          }

          orderItems.add(itemData);

          // Debug print to verify each item is being processed
          print(
              'Processing cart item: ${cartItem.itemName}, ItemID: ${cartItem.id}, SpecID: ${cartItem.specificationId}, Qty: ${cartItem.quantity}');
        } else {
          print(
              'Skipping cart item without valid specification: ${cartItem.itemName}');
        }
      }

      print('Total order items to send: ${orderItems.length}');
      print('Order items data: $orderItems');

      // Combine selected date and time into a single DateTime
      final DateTime orderDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Format the date for API
      final String formattedOrderDateTime =
          "${orderDateTime.year}-${orderDateTime.month.toString().padLeft(2, '0')}-${orderDateTime.day.toString().padLeft(2, '0')} "
          "${orderDateTime.hour.toString().padLeft(2, '0')}:${orderDateTime.minute.toString().padLeft(2, '0')}:00";

      // Print the full request data being sent as JSON
      final requestJson = {
        'table_id': _selectedTable!.id,
        'order_type': _selectedOrderType,
        'order_notes': _orderNotes,
        'order_date_time': formattedOrderDateTime,
        'covers': _covers,
        'items': orderItems,
      };
      print('========== WAITER ORDER REQUEST (JSON) ==========');
      print(jsonEncode(requestJson));
      print('=================================================');

      // Process the order - ensure all IDs are integers
      final result = await WaiterOrderServices.processOrder(
        tableId: _selectedTable!.id,
        orderType: _selectedOrderType,
        orderNotes: _orderNotes,
        covers: _covers,
        items: orderItems,
      );

      print("Order created for: $formattedOrderDateTime");
      print("Order response data: $result");

      // Hide loading
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Handle automatic printing if order was successful
      if (result['success'] == true) {
        // Extract data for auto printing - ensure these are cast as integers
        int orderId = int.parse(result['order_id'].toString());
        String orderNumber = result['order_number'].toString();

        // Properly extract kitchen items from the response
        List<int>? kitchenItemIds;
        if (result['hasKitchenItems'] == true &&
            result['kitchenItems'] != null) {
          kitchenItemIds = (result['kitchenItems'] as List)
              .map((item) => int.parse(item.toString()))
              .toList();
        }
        print("kitchenItemIds: $kitchenItemIds");

        // Properly extract bar items from the response
        List<int>? barItemIds;
        if (result['hasBarItems'] == true && result['barItems'] != null) {
          barItemIds = (result['barItems'] as List)
              .map((item) => int.parse(item.toString()))
              .toList();
        }
        print("barItemIds: $barItemIds");

        // Process automatic printing in the background
        AutoPrintService.processAutoPrint(
          orderId: orderId,
          orderNumber: orderNumber,
          kitchenItemIds: kitchenItemIds,
          barItemIds: barItemIds,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Order #$orderNumber has been successfully processed!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        _clearOrder();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const NavRailMainWaiter(initialIndex: 2),
          ),
        );
      } else {
        // Order was not successful, show the error message from the API
        String errorMessage =
            result['message'] ?? 'Failed to process order. Please try again.';
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      // Hide loading if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Display the actual error message instead of a generic one
      print("Order processing error: $e");

      // Extract the most relevant part of the error message
      String errorMsg = e.toString();
      if (errorMsg.contains("type 'String' is not a subtype of type 'int'")) {
        _showErrorSnackBar(
            'Error: There was a type mismatch when processing your order. Please try again.');
      } else if (errorMsg.contains("table") &&
          errorMsg.contains("not available")) {
        _showErrorSnackBar(
            'Selected table is not available. Please select a different table.');
      } else {
        _showErrorSnackBar('Error processing order: ${e.toString()}');
      }
    }
  }

  void _clearOrder() {
    setState(() {
      _cartItems.clear();
      _selectedCategory = null;
      _selectedTable = null;
      _menuItems.clear();
      _clientDiscounts.clear();
      _expandedItemId = null;
      _itemSpecifications.clear();
      _selectedSpecifications.clear();
      _loadingSpecifications.clear();
      _selectedOrderType = 'dine_in';
      _orderNotes = '';
      _covers = '';
      _orderNotesController.clear();
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _handleLogout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  ClientDiscount? _getDiscountForItem(int itemId, int specificationId) {
    try {
      return _clientDiscounts.firstWhere(
        (discount) =>
            discount.itemId == itemId &&
            discount.specificationId == specificationId,
      );
    } catch (e) {
      return null;
    }
  }

  double _calculateOriginalTotal() {
    double total = 0.0;
    for (var cartItem in _cartItems) {
      if (cartItem.itemName.contains(' - ')) {
        // Extract specification name from cart item name
        final specName = cartItem.itemName.split(' - ').last;
        // Find the specification for this item
        final itemSpecs = _itemSpecifications[cartItem.id] ?? [];
        final spec = itemSpecs.firstWhere(
          (s) => s.specificationName == specName,
          orElse: () => Specification(
              id: 0, specificationName: '', price: 0.0, status: 'inactive'),
        );
        if (spec.id != 0) {
          total += spec.price * cartItem.quantity;
        }
      }
    }
    return total;
  }

  double _calculateTotalDiscount() {
    double originalTotal = _calculateOriginalTotal();
    double discountedTotal =
        _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    return originalTotal - discountedTotal;
  }

  void _addToCartWithSpecification(
      MenuItem item, Specification spec, ClientDiscount? discount) {
    double finalPrice = spec.price;
    if (discount != null) {
      if (discount.discountType == 'amount') {
        finalPrice = spec.price - discount.discountAmount;
      } else {
        finalPrice = spec.price * (1 - discount.discountAmount / 100);
      }
    }

    setState(() {
      final existingIndex = _cartItems.indexWhere((cartItem) =>
          cartItem.id == item.id && cartItem.specificationId == spec.id);

      if (existingIndex >= 0) {
        // Check stock before increasing quantity
        if (spec.requiresStockTracking && spec.stockInfo != null) {
          final currentQuantity = _cartItems[existingIndex].quantity;
          if (currentQuantity >= spec.stockInfo!.quantity) {
            _showErrorSnackBar(
                'Cannot add more items. Only ${spec.stockInfo!.quantity.toInt()} available in stock.');
            return;
          }
        }
        _cartItems[existingIndex].quantity++;
      } else {
        // Check stock before adding new item
        if (spec.requiresStockTracking && spec.stockInfo != null) {
          if (spec.stockInfo!.quantity < 1) {
            _showErrorSnackBar('Item is out of stock.');
            return;
          }
        }

        // Set default preparation order to 1 (Course first) for all items
        _cartItems.add(CartItem(
          id: item.id,
          itemName: '${item.itemName} - ${spec.specificationName}',
          categoryId: item.categoryId,
          categoryName: item.categoryName,
          description:
              '${item.description} | Original: RWF ${spec.price.toStringAsFixed(2)}${discount != null ? " | Discount: ${discount.discountType == "amount" ? "RWF ${discount.discountAmount}" : "${discount.discountAmount}%"}" : ""}',
          imagePath: item.imagePath,
          quantity: 1,
          price: finalPrice,
          specificationId: spec.id,
          accompanimentsIds: null,
          comment: null,
          prepOrder: 1, // Default to "Course first"
          requiresPressure: spec.needsPressureCooking,
        ));
      }
    });
    _showSuccessSnackBar(
        '${item.itemName} - ${spec.specificationName} added to cart');
  }

  void _removeFromCart(int itemId, {int? specificationId}) {
    setState(() {
      if (specificationId != null) {
        // Remove specific specification variant
        _cartItems.removeWhere((item) =>
            item.id == itemId && item.specificationId == specificationId);
      } else {
        // Remove all variants of this item (fallback for backward compatibility)
        _cartItems.removeWhere((item) => item.id == itemId);
      }
    });
  }

  void _updateQuantity(int itemId, int newQuantity, {int? specificationId}) {
    setState(() {
      if (newQuantity <= 0) {
        // Remove the item if quantity is 0 or less
        if (specificationId != null) {
          _cartItems.removeWhere((item) =>
              item.id == itemId && item.specificationId == specificationId);
        } else {
          _cartItems.removeWhere((item) => item.id == itemId);
        }
      } else {
        // Find the cart item to update
        final index = _cartItems.indexWhere((item) =>
            item.id == itemId &&
            (specificationId == null ||
                item.specificationId == specificationId));

        if (index >= 0) {
          final cartItem = _cartItems[index];

          // Check stock before updating quantity (only for increases)
          if (newQuantity > cartItem.quantity && specificationId != null) {
            final itemSpecs = _itemSpecifications[itemId] ?? [];
            final spec = itemSpecs.firstWhere(
              (s) => s.id == specificationId,
              orElse: () => Specification(
                  id: 0, specificationName: '', price: 0.0, status: 'inactive'),
            );

            if (spec.requiresStockTracking && spec.stockInfo != null) {
              if (newQuantity > spec.stockInfo!.quantity) {
                _showErrorSnackBar(
                    'Cannot update quantity. Only ${spec.stockInfo!.quantity.toInt()} available in stock.');
                return;
              }
            }
          }

          _cartItems[index].quantity = newQuantity;
        }
      }
    });
  }

  Future<void> _searchMenuItems(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isLoadingSearch = true;
      _isSearching = true;
    });

    try {
      final results =
          await WaiterOrderServices.searchMenuItems(searchTerm.trim());
      setState(() {
        _searchResults = results;
        _isLoadingSearch = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSearch = false;
      });
      _showErrorSnackBar('Failed to search menu items: $e');
    }
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();

    // Only trigger search if length is 3 or more
    if (value.length >= 3) {
      _searchTimer = Timer(const Duration(milliseconds: 500), () {
        _searchMenuItems(value);
      });
    } else if (value.isEmpty) {
      // Clear search if input is empty
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
    }
  }

  void _triggerManualSearch() {
    final searchTerm = _searchController.text.trim();
    if (searchTerm.isNotEmpty) {
      _searchMenuItems(searchTerm);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults.clear();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Helper function to compare two lists for equality
  bool _listsEqual(List<int> list1, List<int> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  // Method to select date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Method to select time
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Create New Order',
          style: TextStyle(color: Colors.white),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.primary),
                          const SizedBox(width: 8.0),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: AppColors.primary),
                          const SizedBox(width: 8.0),
                          Text(
                            '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${_cartItems.length}'),
              child: const Icon(Icons.shopping_cart, color: Colors.white),
            ),
            onPressed: () {
              // Show cart summary
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 18),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side - Categories, Items, and Search
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Categories Header - Always visible
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (_selectedCategory != null) ...[
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Selected: ${_selectedCategory!.displayName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = null;
                                    _menuItems.clear();
                                    _expandedItemId = null;
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Categories Grid - Always visible
                Container(
                  height: 120, // Fixed height for categories
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                  ),
                  child: _categories.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : Scrollbar(
                          controller: _categoryScrollController,
                          thumbVisibility: true,
                          thickness: 20.0, // Thicker scrollbar for categories
                          radius: const Radius.circular(10),
                          trackVisibility: true,
                          child: ListView.builder(
                            controller: _categoryScrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected =
                                  _selectedCategory?.id == category.id;
                              return Container(
                                width: 100,
                                margin: const EdgeInsets.only(
                                    right: 12, top: 8, bottom: 8),
                                child: _buildHorizontalCategoryCard(
                                    category, isSelected),
                              );
                            },
                          ),
                        ),
                ),

                // Search Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border:
                        Border(bottom: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search menu items ...',
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _triggerManualSearch,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),

                // Main Content Area
                Expanded(
                  child: _isLoadingSearch
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Searching menu items...')
                            ],
                          ),
                        )
                      : _isSearching
                          ? _buildSearchResults()
                          : _selectedCategory == null
                              ? _buildWelcomeScreen()
                              : _buildItemsGrid(),
                ),
              ],
            ),
          ),
          // Right side - Cart
          Expanded(
            flex: 2,
            child: SizedBox(
              height: MediaQuery.of(context).size.height - kToolbarHeight,
              child: WaiterCartWidget(
                cartItems: _cartItems,
                tables: _tables,
                selectedTable: _selectedTable,
                covers: _covers,
                isLoadingTables: _isLoadingTables,
                itemSpecifications: _itemSpecifications,
                onRemoveFromCart: _removeFromCart,
                onUpdateQuantity: _updateQuantity,
                onUpdateItemComment: (itemId, specificationId, comment) {
                  setState(() {
                    final index = _cartItems.indexWhere((item) =>
                        item.id == itemId &&
                        item.specificationId == specificationId);
                    if (index >= 0) {
                      _cartItems[index] = _cartItems[index].copyWith(
                        comment: comment.isEmpty ? null : comment,
                      );
                    }
                  });

                  if (comment.isNotEmpty) {
                    _showSuccessSnackBar('Note added to specification');
                  } else {
                    _showSuccessSnackBar('Note removed from specification');
                  }
                },
                onUpdateItemPrepOrder: _updateItemPrepOrder,
                onUpdateItemPressure: _updateItemPressure,
                onAutoAssignPrepOrders:
                    _autoAssignPrepOrders, // Add new handler

                onTableChanged: (TableModel? newValue) {
                  setState(() {
                    _selectedTable = newValue;
                  });
                },
                onCoversChanged: (String newValue) {
                  setState(() {
                    _covers = newValue;
                  });
                },
                onProcessOrder: _processOrder,
                calculateOriginalTotal: _calculateOriginalTotal,
                calculateTotalDiscount: _calculateTotalDiscount,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCategoryCard(Category category, bool isSelected) {
    return Card(
        elevation: isSelected ? 6 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? const BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              if (_selectedCategory?.id == category.id) {
                // If already selected, deselect
                _selectedCategory = null;
                _menuItems.clear();
                _expandedItemId = null;
              } else {
                // Select new category
                _selectedCategory = category;
                _menuItems.clear();
                _expandedItemId = null;
                _fetchItemsByCategory(category.id);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.primary.withOpacity(0.1),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey.withOpacity(0.1),
                        Colors.grey.withOpacity(0.05),
                      ],
                    ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 20,
                    color: isSelected ? AppColors.primary : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    category.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Order Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select a category above to view menu items\nor search for specific items',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tip: You can search for items without selecting a category',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid() {
    return Column(
      children: [
        // Items Header
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: Row(
            children: [
              // const Icon(Icons.fastfood, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Items in ${_selectedCategory?.displayName ?? 'Category'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(
                '${_menuItems.length} items',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Items List with Specifications
        Expanded(
          child: _isLoadingItems
              ? const Center(child: CircularProgressIndicator())
              : _menuItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon(
                          //   Icons.inventory_2_outlined,
                          //   size: 64,
                          //   color: Colors.grey[400],
                          // ),
                          // const SizedBox(height: 16),
                          Text(
                            'No items found in this category',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildItemsList(),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    const int itemsPerRow = 4;
    List<List<MenuItem>> rows = [];

    // Group items into rows of 4
    for (int i = 0; i < _menuItems.length; i += itemsPerRow) {
      int end = (i + itemsPerRow < _menuItems.length)
          ? i + itemsPerRow
          : _menuItems.length;
      rows.add(_menuItems.sublist(i, end));
    }

    return NotificationListener<ScrollNotification>(
      // This prevents scroll events from propagating to parent scrollable widgets
      onNotification: (ScrollNotification notification) {
        // Return true to cancel the notification bubbling
        return true;
      },
      child: Scrollbar(
        controller: _itemsGridController,
        thumbVisibility: true,
        thickness: 20.0,
        radius: const Radius.circular(5),
        trackVisibility: true,
        child: SingleChildScrollView(
          controller: _itemsGridController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(children: [
            for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
              // Build each row
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 2,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                ),
                itemCount: rows[rowIndex].length,
                itemBuilder: (context, index) {
                  final item = rows[rowIndex][index];
                  return _buildItemCard(item);
                },
              ),
              // Add spacing between rows
              if (rowIndex < rows.length - 1) const SizedBox(height: 12),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildItemCard(MenuItem item) {
    final isLoading = _loadingSpecifications[item.id] ?? false;

    return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: isLoading ? null : () => _toggleItemSpecifications(item),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Name
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.itemName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLoading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_circle_outline,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (item.description.isNotEmpty)
                        Expanded(
                          child: Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                // Action hint at the bottom
                // Container(
                //   padding: const EdgeInsets.symmetric(vertical: 4),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       Icon(
                //         Icons.touch_app,
                //         size: 12,
                //         color: Colors.grey[500],
                //       ),
                //       const SizedBox(width: 4),
                //       Text(
                //         'Tap to view options',
                //         style: TextStyle(
                //           fontSize: 10,
                //           color: Colors.grey[500],
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
        ));
  }

  Widget _buildSearchItemCard(MenuItem item) {
    final isLoading = _loadingSpecifications[item.id] ?? false;

    return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: isLoading ? null : () => _toggleItemSpecifications(item),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Name and Category
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.itemName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLoading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_circle_outline,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.categoryName,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (item.description.isNotEmpty)
                        Expanded(
                          child: Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                // Action hint at the bottom
                // Container(
                //   padding: const EdgeInsets.symmetric(vertical: 4),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       Icon(
                //         Icons.touch_app,
                //         size: 12,
                //         color: Colors.grey[500],
                //       ),
                //       const SizedBox(width: 4),
                //       Text(
                //         'Tap to view options',
                //         style: TextStyle(
                //           fontSize: 10,
                //           color: Colors.grey[500],
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
        ));
  }

  // Widget _buildSpecificationCard(MenuItem item, Specification spec) {
  //   final discount = _getDiscountForItem(item.id, spec.id);
  //   double finalPrice = spec.price;

  //   if (discount != null) {
  //     if (discount.discountType == 'amount') {
  //       finalPrice = spec.price - discount.discountAmount;
  //     } else {
  //       finalPrice = spec.price * (1 - discount.discountAmount / 100);
  //     }
  //   }

  //   final bool isOutOfStock = spec.isOutOfStock;
  //   final bool hasLowStock = spec.hasLowStock;
  //   final bool isClickable = spec.isAvailable;

  //   return Card(
  //       elevation: 2,
  //       child: InkWell(
  //         onTap: isClickable
  //             ? () {
  //                 if (spec.hasAccompaniments) {
  //                   _showAccompanimentDialog(item, spec, discount);
  //                 } else {
  //                   _addToCartWithSpecification(item, spec, discount);
  //                 }
  //               }
  //             : null,
  //         borderRadius: BorderRadius.circular(8),
  //         child: Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(8),
  //             gradient: LinearGradient(
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight,
  //               colors: [
  //                 isOutOfStock ? Colors.grey[200]! : Colors.white,
  //                 isOutOfStock
  //                     ? Colors.grey[100]!
  //                     : Colors.grey.withOpacity(0.05),
  //               ],
  //             ),
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           spec.specificationName,
  //                           style: TextStyle(
  //                             fontSize: 13,
  //                             fontWeight: FontWeight.bold,
  //                             color: isOutOfStock
  //                                 ? Colors.grey[600]
  //                                 : Colors.black,
  //                           ),
  //                           maxLines: 1,
  //                           overflow: TextOverflow.ellipsis,
  //                         ),
  //                         Text(
  //                           'RWF ${spec.price.toStringAsFixed(2)}',
  //                           style: TextStyle(
  //                             fontSize: 12,
  //                             fontWeight: FontWeight.bold,
  //                             color: isOutOfStock
  //                                 ? Colors.grey[600]
  //                                 : AppColors.primary,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   const SizedBox(width: 8),
  //                   Column(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     crossAxisAlignment: CrossAxisAlignment.end,
  //                     children: [
  //                       Container(
  //                         padding: const EdgeInsets.all(6),
  //                         decoration: BoxDecoration(
  //                           color: isOutOfStock
  //                               ? Colors.grey[400]
  //                               : spec.hasAccompaniments
  //                                   ? Colors.orange
  //                                   : AppColors.primary,
  //                           borderRadius: BorderRadius.circular(8),
  //                         ),
  //                         child: Icon(
  //                           spec.hasAccompaniments ? Icons.settings : Icons.add,
  //                           color: Colors.white,
  //                           size: 16,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),

  //               // Stock information
  //               // if (spec.requiresStockTracking && spec.stockInfo != null) ...[
  //               //   const SizedBox(height: 8),
  //               //   Container(
  //               //     padding:
  //               //         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //               //     decoration: BoxDecoration(
  //               //       color: isOutOfStock
  //               //           ? Colors.red[100]
  //               //           : hasLowStock
  //               //               ? Colors.orange[100]
  //               //               : Colors.green[100],
  //               //       borderRadius: BorderRadius.circular(12),
  //               //       border: Border.all(
  //               //         color: isOutOfStock
  //               //             ? Colors.red[300]!
  //               //             : hasLowStock
  //               //                 ? Colors.orange[300]!
  //               //                 : Colors.green[300]!,
  //               //       ),
  //               //     ),
  //               //     child: Row(
  //               //       mainAxisSize: MainAxisSize.min,
  //               //       children: [
  //               //         Icon(
  //               //           isOutOfStock
  //               //               ? Icons.inventory_2_outlined
  //               //               : hasLowStock
  //               //                   ? Icons.warning_amber_rounded
  //               //                   : Icons.check_circle_outline,
  //               //           size: 12,
  //               //           color: isOutOfStock
  //               //               ? Colors.red[700]
  //               //               : hasLowStock
  //               //                   ? Colors.orange[700]
  //               //                   : Colors.green[700],
  //               //         ),
  //               //         const SizedBox(width: 4),
  //               //         Text(
  //               //           isOutOfStock
  //               //               ? 'Out of Stock'
  //               //               : hasLowStock
  //               //                   ? 'Low Stock: ${spec.stockInfo!.quantity.toStringAsFixed(0)}'
  //               //                   : 'Stock: ${spec.stockInfo!.quantity.toStringAsFixed(0)}',
  //               //           style: TextStyle(
  //               //             fontSize: 10,
  //               //             color: isOutOfStock
  //               //                 ? Colors.red[700]
  //               //                 : hasLowStock
  //               //                     ? Colors.orange[700]
  //               //                     : Colors.green[700],
  //               //             fontWeight: FontWeight.bold,
  //               //           ),
  //               //         ),
  //               //       ],
  //               //     ),
  //               //   ),
  //               // ],

  //               // Show accompaniments indicator if available
  //               if (spec.hasAccompaniments && isClickable) ...[
  //                 const SizedBox(height: 8),
  //                 Container(
  //                   padding:
  //                       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                   decoration: BoxDecoration(
  //                     color: Colors.orange[100],
  //                     borderRadius: BorderRadius.circular(12),
  //                     border: Border.all(color: Colors.orange[300]!),
  //                   ),
  //                   child: Row(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Icon(Icons.restaurant,
  //                           size: 12, color: Colors.orange[700]),
  //                       const SizedBox(width: 4),
  //                       Text(
  //                         '${spec.accompaniments.length} accompaniment${spec.accompaniments.length > 1 ? 's' : ''}',
  //                         style: TextStyle(
  //                           fontSize: 10,
  //                           color: Colors.orange[700],
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],

  //               // Out of stock overlay
  //               // if (isOutOfStock) ...[
  //               //   const SizedBox(height: 8),
  //               //   Container(
  //               //     width: double.infinity,
  //               //     padding: const EdgeInsets.symmetric(vertical: 6),
  //               //     decoration: BoxDecoration(
  //               //       color: Colors.red[50],
  //               //       borderRadius: BorderRadius.circular(6),
  //               //       border: Border.all(color: Colors.red[200]!),
  //               //     ),
  //               //     child: Row(
  //               //       mainAxisAlignment: MainAxisAlignment.center,
  //               //       children: [
  //               //         Icon(Icons.block, size: 14, color: Colors.red[700]),
  //               //         const SizedBox(width: 4),
  //               //         Text(
  //               //           'Currently Unavailable',
  //               //           style: TextStyle(
  //               //             fontSize: 11,
  //               //             color: Colors.red[700],
  //               //             fontWeight: FontWeight.bold,
  //               //           ),
  //               //         ),
  //               //       ],
  //               //     ),
  //               //   ),
  //               // ],
  //             ],
  //           ),
  //         ),
  //       ));
  // }
  Widget _buildSpecificationCard(MenuItem item, Specification spec) {
    final discount = _getDiscountForItem(item.id, spec.id);
    double finalPrice = spec.price;

    if (discount != null) {
      if (discount.discountType == 'amount') {
        finalPrice = spec.price - discount.discountAmount;
      } else {
        finalPrice = spec.price * (1 - discount.discountAmount / 100);
      }
    }

    final bool isOutOfStock = spec.isOutOfStock;
    final bool hasLowStock = spec.hasLowStock;
    // Add check for zero or negative quantity
    final bool hasZeroQuantity = spec.requiresStockTracking &&
        spec.stockInfo != null &&
        spec.stockInfo!.quantity <= 0;
    final bool isClickable = spec.isAvailable && !hasZeroQuantity;

    return Card(
        elevation: 2,
        child: InkWell(
          onTap: isClickable
              ? () {
                  if (spec.hasAccompaniments) {
                    _showAccompanimentDialog(item, spec, discount);
                  } else {
                    _addToCartWithSpecification(item, spec, discount);
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isOutOfStock || hasZeroQuantity
                      ? Colors.grey[200]!
                      : Colors.white,
                  isOutOfStock || hasZeroQuantity
                      ? Colors.grey[100]!
                      : Colors.grey.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row with name and button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spec.specificationName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isOutOfStock || hasZeroQuantity
                              ? Colors.grey[600]
                              : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isOutOfStock || hasZeroQuantity
                            ? Colors.grey[400]
                            : spec.hasAccompaniments
                                ? Colors.orange
                                : AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        spec.hasAccompaniments ? Icons.settings : Icons.add,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ],
                ),

                // Price and stock info
                const SizedBox(height: 2),
                Text(
                  'RWF ${spec.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isOutOfStock || hasZeroQuantity
                        ? Colors.grey[600]
                        : AppColors.primary,
                  ),
                ),

                // Stock quantity if available
                if (spec.requiresStockTracking && spec.stockInfo != null)
                  Text(
                    isOutOfStock || hasZeroQuantity
                        ? 'Out of Stock'
                        : hasLowStock
                            ? 'Low: ${spec.stockInfo!.quantity.toInt()}'
                            : 'Qty: ${spec.stockInfo!.quantity.toInt()}',
                    style: TextStyle(
                      fontSize: 9,
                      color: isOutOfStock || hasZeroQuantity
                          ? Colors.red[700]
                          : hasLowStock
                              ? Colors.orange[700]
                              : Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                // Accompaniments indicator if available (compact)
                if (spec.hasAccompaniments && isClickable)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${spec.accompaniments.length} add-on${spec.accompaniments.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ));
  }

  void _showAccompanimentDialog(
      MenuItem item, Specification spec, ClientDiscount? discount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AccompanimentDialog(
          item: item,
          spec: spec,
          discount: discount,
          onConfirm: _addToCartWithSpecificationAndAccompaniments,
        );
      },
    );
  }

  void _addToCartWithSpecificationAndAccompaniments(
      dynamic item,
      Specification spec,
      dynamic discount,
      Map<int, bool> selectedAccompaniments) {
    double finalPrice = spec.price;
    if (discount != null) {
      if (discount.discountType == 'amount') {
        finalPrice = spec.price - discount.discountAmount;
      } else {
        finalPrice = spec.price * (1 - discount.discountAmount / 100);
      }
    }

    // Create accompaniments description
    String accompanimentText = '';
    if (selectedAccompaniments.isNotEmpty) {
      final selectedNames = spec.accompaniments
          .where((acc) => selectedAccompaniments[acc.id] == true)
          .map((acc) => acc.accompanimentName)
          .toList();

      if (selectedNames.isNotEmpty) {
        accompanimentText = ' (with ${selectedNames.join(', ')})';
      }
    }

    setState(() {
      // Create a unique identifier for this cart item variant
      final selectedAccompanimentIds = selectedAccompaniments.keys
          .where((id) => selectedAccompaniments[id] == true)
          .toList();

      final existingIndex = _cartItems.indexWhere((cartItem) =>
          cartItem.id == item.id &&
          cartItem.specificationId == spec.id &&
          _listsEqual(
              cartItem.accompanimentsIds ?? [], selectedAccompanimentIds));

      if (existingIndex >= 0) {
        // Check stock before increasing quantity
        if (spec.requiresStockTracking && spec.stockInfo != null) {
          final currentQuantity = _cartItems[existingIndex].quantity;
          if (currentQuantity >= spec.stockInfo!.quantity) {
            _showErrorSnackBar(
                'Cannot add more items. Only ${spec.stockInfo!.quantity.toInt()} available in stock.');
            return;
          }
        }
        _cartItems[existingIndex].quantity++;
      } else {
        // Check stock before adding new item
        if (spec.requiresStockTracking && spec.stockInfo != null) {
          if (spec.stockInfo!.quantity < 1) {
            _showErrorSnackBar('Item is out of stock.');
            return;
          }
        }

        _cartItems.add(CartItem(
          id: item.id,
          itemName:
              '${item.itemName} - ${spec.specificationName}$accompanimentText',
          categoryId: item.categoryId,
          categoryName: item.categoryName,
          description:
              '${item.description} | Original: RWF ${spec.price.toStringAsFixed(2)}${discount != null ? " | Discount: ${discount.discountType == "amount" ? "RWF ${discount.discountAmount}" : "${discount.discountAmount}%"}" : ""}',
          imagePath: item.imagePath,
          quantity: 1,
          price: finalPrice,
          specificationId: spec.id,
          accompanimentsIds: selectedAccompaniments.keys
              .where((id) => selectedAccompaniments[id] == true)
              .toList(),
          comment: null, // Can be added later with comment dialog
          prepOrder: 1, // Default to "Course first"
          requiresPressure: spec.needsPressureCooking,
        ));
      }
    });

    _showSuccessSnackBar(
        '${item.itemName} - ${spec.specificationName}$accompanimentText added to cart');
  }

  // Modify the auto-assign prep orders method to handle existing items
  void _autoAssignPrepOrders() {
    // Here we'll reset all items to "Cource first"
    setState(() {
      for (int i = 0; i < _cartItems.length; i++) {
        _cartItems[i] = _cartItems[i].copyWith(prepOrder: 1);
      }
    });

    _showSuccessSnackBar('All items set to "Cource First"');
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        // Search Results Header
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search Results for "${_searchController.text}"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _clearSearch,
                icon: const Icon(Icons.clear, color: Colors.grey),
              ),
            ],
          ),
        ),
        // Search Results List
        Expanded(
          child: _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No items found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : _buildSearchItemsList(),
        ),
      ],
    );
  }

  Widget _buildSearchItemsList() {
    const int itemsPerRow = 3;
    List<List<MenuItem>> rows = [];

    // Group search results into rows of 3
    for (int i = 0; i < _searchResults.length; i += itemsPerRow) {
      int end = (i + itemsPerRow < _searchResults.length)
          ? i + itemsPerRow
          : _searchResults.length;
      rows.add(_searchResults.sublist(i, end));
    }

    return NotificationListener<ScrollNotification>(
      // This prevents scroll events from propagating to parent scrollable widgets
      onNotification: (ScrollNotification notification) {
        // Return true to cancel the notification bubbling
        return true;
      },
      child: Scrollbar(
        controller: _itemsGridController,
        thumbVisibility: true,
        thickness: 8.0,
        radius: const Radius.circular(5),
        trackVisibility: true,
        child: SingleChildScrollView(
          controller: _itemsGridController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(children: [
            for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
              // Build each row
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                ),
                itemCount: rows[rowIndex].length,
                itemBuilder: (context, index) {
                  final item = rows[rowIndex][index];
                  return _buildItemCard(item);
                },
              ),

              // Show specifications after this row if any item in this row is expanded
              if (_expandedItemId != null &&
                  rows[rowIndex].any((item) => item.id == _expandedItemId)) ...[
                const SizedBox(height: 16),
                // _buildExpandedSpecifications(),
                const SizedBox(height: 16),
              ] else if (rowIndex <
                  rows.length -
                      1) // Add spacing between rows if not the last row
                const SizedBox(height: 12),
            ],
          ]),
        ),
      ),
    );
  }

  void _updateItemPrepOrder(int itemId, int specificationId, int prepOrder) {
    setState(() {
      final index = _cartItems.indexWhere((item) =>
          item.id == itemId && item.specificationId == specificationId);
      if (index >= 0) {
        _cartItems[index] = _cartItems[index].copyWith(
          prepOrder: prepOrder > 0 ? prepOrder : null,
        );
      }
    });

    if (prepOrder > 0) {
      _showSuccessSnackBar('Preparation order set for item');
    } else {
      _showSuccessSnackBar('Preparation order removed from item');
    }
  }

  void _updateItemPressure(int itemId, int specificationId, int? pressureId) {
    setState(() {
      final index = _cartItems.indexWhere((item) =>
          item.id == itemId && item.specificationId == specificationId);
      if (index >= 0) {
        _cartItems[index] = _cartItems[index].copyWith(
          selectedPressureId: pressureId,
        );
      }
    });

    if (pressureId != null) {
      _showSuccessSnackBar('Temperature cooking option selected');
    } else {
      _showSuccessSnackBar('Temperature cooking option removed');
    }
  }
}
