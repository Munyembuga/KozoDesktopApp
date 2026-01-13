import 'dart:async';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:kozo/models/table_model.dart';
import 'package:kozo/models/waiter_model.dart';
import 'package:kozo/navRailscreen/navRailMainCashier.dart';
import 'package:kozo/utils/constants.dart';
import '../constants/app_constants.dart';
import '../services/order_service.dart';
import '../models/category_model.dart';
import '../models/cart_item_model.dart';
import 'login_screen.dart';
import 'widgets/cart_widget.dart';

class MakeNewOrderScreen extends StatefulWidget {
  const MakeNewOrderScreen({super.key});

  @override
  State<MakeNewOrderScreen> createState() => _MakeNewOrderScreenState();
}

class _MakeNewOrderScreenState extends State<MakeNewOrderScreen> {
  List<Category> _categories = [];
  List<MenuItem> _menuItems = [];
  List<CartItem> _cartItems = [];
  List<SpecialClient> _specialClients = [];
  List<ClientDiscount> _clientDiscounts = [];
  List<Waiter> _waiters = [];
  List<TableModel> _tables = [];
  Category? _selectedCategory;
  SpecialClient? _selectedClient;
  Waiter? _selectedWaiter;
  TableModel? _selectedTable;
  bool _isLoadingItems = false;
  bool _isLoadingWaiters = false;
  bool _isLoadingTables = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int? _expandedItemId;
  Map<int, List<Specification>> _itemSpecifications = {};
  Map<int, Specification?> _selectedSpecifications = {};
  Map<int, bool> _loadingSpecifications = {};

  // Search functionality variables
  bool _isSearching = false;
  bool _isLoadingSearch = false;
  List<MenuItem> _searchResults = [];
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchSpecialClients();
    _fetchWaiters();
    _fetchTables();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await OrderService.fetchCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print("Failed to fetch categories: $e");
      _showErrorSnackBar('Please try again later.');
    }
  }

  Future<void> _fetchSpecialClients() async {
    try {
      final clients = await OrderService.fetchSpecialClients();
      setState(() {
        _specialClients = clients;
      });
      print("Fetched special clients: ${clients.length}");
    } catch (e) {
      print("Failed to fetch special clients: $e");
      _showErrorSnackBar('Please try again later.');
    }
  }

  Future<void> _fetchClientDiscount(int clientId) async {
    try {
      final discountResponse = await OrderService.fetchClientDiscount(clientId);
      setState(() {
        _clientDiscounts = discountResponse.discounts;
      });
      // Apply discounts to existing cart items
      _applyDiscountsToCartItems();
    } catch (e) {
      print("Failed to fetch client discount: $e");
      _showErrorSnackBar('Please try again later.');
    }
  }

  void _applyDiscountsToCartItems() {
    setState(() {
      for (int i = 0; i < _cartItems.length; i++) {
        final cartItem = _cartItems[i];

        // Check if this cart item has a specification (contains " - " in itemName)
        if (cartItem.itemName.contains(' - ')) {
          // Extract specification name from cart item name
          final specName = cartItem.itemName.split(' - ').last;

          // Find the specification ID for this item
          final itemSpecs = _itemSpecifications[cartItem.id] ?? [];
          final spec = itemSpecs.firstWhere(
            (s) => s.specificationName == specName,
            orElse: () => Specification(
                id: 0, specificationName: '', price: 0.0, status: 'inactive'),
          );

          if (spec.id != 0) {
            // Find discount for this item and specification
            final discount = _getDiscountForItem(cartItem.id, spec.id);

            if (discount != null) {
              // Calculate new price with discount
              double newPrice = spec.price;
              if (discount.discountType == 'amount') {
                newPrice = spec.price - discount.discountAmount;
              } else {
                newPrice = spec.price * (1 - discount.discountAmount / 100);
              }

              // Update cart item with new price and description
              _cartItems[i] = CartItem(
                id: cartItem.id,
                itemName: cartItem.itemName,
                categoryId: cartItem.categoryId,
                categoryName: cartItem.categoryName,
                description:
                    '${cartItem.description.split('|').first.trim()} | Original:  RWF ${spec.price.toStringAsFixed(2)} | Discount: ${discount.discountType == "amount" ? "RWF ${discount.discountAmount}" : "${discount.discountAmount}%"}',
                imagePath: cartItem.imagePath,
                quantity: cartItem.quantity,
                price: newPrice,
              );
            }
          }
        }
      }
    });

    if (_clientDiscounts.isNotEmpty) {
      _showSuccessSnackBar(
          'Discounts applied to ${_cartItems.where((item) => item.description.contains('Discount:')).length} cart items');
    }
  }

  void _removeDiscountsFromCartItems() {
    setState(() {
      for (int i = 0; i < _cartItems.length; i++) {
        final cartItem = _cartItems[i];

        // Check if this cart item has a specification and discount
        if (cartItem.itemName.contains(' - ') &&
            cartItem.description.contains('Original:')) {
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
            // Reset to original price without discount
            _cartItems[i] = CartItem(
              id: cartItem.id,
              itemName: cartItem.itemName,
              categoryId: cartItem.categoryId,
              categoryName: cartItem.categoryName,
              description: cartItem.description.split('|').first.trim(),
              imagePath: cartItem.imagePath,
              quantity: cartItem.quantity,
              price: spec.price,
            );
          }
        }
      }
    });
  }

  Future<void> _fetchWaiters() async {
    setState(() {
      _isLoadingWaiters = true;
    });

    try {
      final waiters = await OrderService.fetchWaiters();
      setState(() {
        _waiters = waiters;
        _isLoadingWaiters = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingWaiters = false;
      });
      print("Failed to fetch waiters: $e");
      _showErrorSnackBar('Please try again later.');
    }
  }

  Future<void> _fetchTables() async {
    setState(() {
      _isLoadingTables = true;
    });

    try {
      final tables = await OrderService.fetchTables();
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
      final items = await OrderService.fetchItemsByCategory(categoryId);
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
    if (_expandedItemId == item.id) {
      // Collapse if already expanded
      setState(() {
        _expandedItemId = null;
      });
      return;
    }

    setState(() {
      _expandedItemId = item.id;
      _loadingSpecifications[item.id] = true;
      _selectedSpecifications[item.id] = null;
    });

    try {
      final specifications = await OrderService.fetchSpecifications(item.id);
      setState(() {
        _itemSpecifications[item.id] = specifications;
        _loadingSpecifications[item.id] = false;
      });

      if (specifications.isEmpty) {
        _showErrorSnackBar('No specifications found for this item');
      }
    } catch (e) {
      setState(() {
        _loadingSpecifications[item.id] = false;
      });
      print("Failed to fetch specifications: $e");
      _showErrorSnackBar('Please try again later.');
    }
  }

  Future<void> _processOrder() async {
    // Validation
    if (_cartItems.isEmpty) {
      _showErrorSnackBar('Cart is empty. Please add items to continue.');
      return;
    }

    if (_selectedWaiter == null) {
      _showErrorSnackBar('Please select a waiter.');
      return;
    }

    if (_selectedTable == null) {
      _showErrorSnackBar('Please select a table.');
      return;
    }

    // Check if all cart items have prices (specifications selected)
    bool hasItemsWithoutPrice = _cartItems.any((item) => item.price <= 0);
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

      // Determine handler type and ID
      String handlerType = _selectedWaiter!.id == -1 ? 'cashier' : 'waiter';
      int? handlerId = _selectedWaiter!.id == -1 ? null : _selectedWaiter!.id;

      // Prepare items for the API
      List<Map<String, dynamic>> orderItems = [];

      for (var cartItem in _cartItems) {
        // Extract specification info from cart item
        String specName = '';
        if (cartItem.itemName.contains(' - ')) {
          specName = cartItem.itemName.split(' - ').last;
        }

        // Find the specification ID
        final itemSpecs = _itemSpecifications[cartItem.id] ?? [];
        final spec = itemSpecs.firstWhere(
          (s) => s.specificationName == specName,
          orElse: () => Specification(
              id: 0, specificationName: '', price: 0.0, status: 'inactive'),
        );

        if (spec.id != 0) {
          // Send original price from specification, not the discounted price from cart
          // Let the backend handle discount calculations to avoid double discount
          orderItems.add({
            'itemId': cartItem.id,
            'specificationId': spec.id,
            'quantity': cartItem.quantity,
            'price': spec.price, // Use original price from specification
            'total': spec.price * cartItem.quantity, // Use original total
          });
        }
      }

      // Process the order
      final result = await OrderService.processOrder(
        tableId: _selectedTable!.id,
        handlerType: handlerType,
        handlerId: handlerId,
        clientId: _selectedClient?.id,
        items: orderItems,
      );

      // Hide loading
      Navigator.of(context).pop();

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order has been successfully processed!'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Handle undo action
              },
            ),
          ),
        );
        _clearOrder();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                const NavRailMainCashier(initialIndex: 2), // Pass initial index
          ),
        );
        // Show success dialog
        // showDialog(
        //   context: context,
        //   builder: (context) => AlertDialog(
        //     title: const Text('Order Processed'),
        //     content: Column(
        //       mainAxisSize: MainAxisSize.min,
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Text('Order has been successfully processed!'),
        //         const SizedBox(height: 8),
        //         if (result['orderId'] != null)
        //           Text('Order ID: ${result['orderId']}'),
        //         const SizedBox(height: 8),
        //         Text('Table: ${_selectedTable!.tableName}'),
        //         Text('Handler: ${_selectedWaiter!.name}'),
        //         if (_selectedClient != null)
        //           Text('Client: ${_selectedClient!.clientName}'),
        //         Text(
        //             'Total Items: ${_cartItems.fold(0, (sum, item) => sum + item.quantity)}'),
        //         Text(
        //             'Total Amount: \$${_cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity)).toStringAsFixed(2)}'),
        //       ],
        //     ),
        //     actions: [
        //       TextButton(
        //         onPressed: () {
        //           Navigator.of(context).pop();
        //           _clearOrder();
        //         },
        //         child: const Text('New Order'),
        //       ),
        //       ElevatedButton(
        //         onPressed: () {
        //           Navigator.of(context).pop();
        //           Navigator.of(context).pop(); // Go back to main screen
        //         },
        //         style: ElevatedButton.styleFrom(
        //           backgroundColor: AppColors.primary,
        //           foregroundColor: Colors.white,
        //         ),
        //         child: const Text('Done'),
        //       ),
        //     ],
        //   ),
        // );
      }
    } catch (e) {
      // Hide loading if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      _showErrorSnackBar(
          'Failed to process order: Selected table is not available. Please select a different table.');
    }
  }

  void _clearOrder() {
    setState(() {
      _cartItems.clear();
      _selectedCategory = null;
      _selectedClient = null;
      _selectedWaiter = null;
      _selectedTable = null;
      _menuItems.clear();
      _clientDiscounts.clear();
      _expandedItemId = null;
      _itemSpecifications.clear();
      _selectedSpecifications.clear();
      _loadingSpecifications.clear();
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
          cartItem.id == item.id &&
          cartItem.description.contains(spec.specificationName));

      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity++;
      } else {
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
        ));
      }
    });
    _showSuccessSnackBar(
        '${item.itemName} - ${spec.specificationName} added to cart');
  }

  void _removeFromCart(int itemId) {
    setState(() {
      _cartItems.removeWhere((item) => item.id == itemId);
    });
  }

  void _updateQuantity(int itemId, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _cartItems.removeWhere((item) => item.id == itemId);
      } else {
        final index = _cartItems.indexWhere((item) => item.id == itemId);
        if (index >= 0) {
          _cartItems[index].quantity = newQuantity;
        }
      }
    });
  }

  List<Category> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories
        .where((category) => category.categoryName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
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
      final results = await OrderService.searchMenuItems(searchTerm.trim());
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
            flex: 2,
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
                      : ListView.builder(
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
          CartWidget(
            cartItems: _cartItems,
            waiters: _waiters,
            tables: _tables,
            selectedClient: _selectedClient,
            selectedWaiter: _selectedWaiter,
            selectedTable: _selectedTable,
            isLoadingWaiters: _isLoadingWaiters,
            isLoadingTables: _isLoadingTables,
            clientDiscounts: _clientDiscounts,
            itemSpecifications: _itemSpecifications,
            specialClients: _specialClients,
            onRemoveFromCart: _removeFromCart,
            onUpdateQuantity: _updateQuantity,
            onWaiterChanged: (Waiter? newValue) {
              setState(() {
                _selectedWaiter = newValue;
              });
            },
            onTableChanged: (TableModel? newValue) {
              setState(() {
                _selectedTable = newValue;
              });
            },
            onClientChanged: (SpecialClient? newValue) {
              setState(() {
                if (_selectedClient != null && newValue != _selectedClient) {
                  _removeDiscountsFromCartItems();
                }
                _selectedClient = newValue;
                _clientDiscounts.clear();
              });
              if (newValue != null) {
                _fetchClientDiscount(newValue.id);
              } else {
                _removeDiscountsFromCartItems();
              }
            },
            onProcessOrder: _processOrder,
            calculateOriginalTotal: _calculateOriginalTotal,
            calculateTotalDiscount: _calculateTotalDiscount,
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
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
      ),
    );
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
              const Icon(Icons.fastfood, color: AppColors.primary),
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
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final item = _menuItems[index];
              return _buildItemCard(item);
            },
          ),

          // Show specifications below the grid if an item is expanded
          if (_expandedItemId != null) ...[
            const SizedBox(height: 16),
            _buildExpandedSpecifications(),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(MenuItem item) {
    final isExpanded = _expandedItemId == item.id;

    return Card(
      elevation: isExpanded ? 6 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isExpanded
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _toggleItemSpecifications(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isExpanded
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                  ),
                  child: item.imagePath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '${AppConfig.baseUrl}/uploads/${item.imagePath}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.restaurant_menu,
                                size: 40,
                                color: Colors.grey,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.restaurant_menu,
                          size: 40,
                          color: Colors.grey,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              // Item Name
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isExpanded ? AppColors.primary : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
              // Expand Button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _toggleItemSpecifications(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isExpanded ? Colors.orange : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isExpanded ? 'Hide Options' : 'View Options',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSpecifications() {
    final expandedItem =
        _menuItems.firstWhere((item) => item.id == _expandedItemId);
    final specifications = _itemSpecifications[_expandedItemId!] ?? [];
    final isLoadingSpecs = _loadingSpecifications[_expandedItemId!] ?? false;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Options for ${expandedItem.itemName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        expandedItem.categoryName,
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
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Specifications Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: isLoadingSpecs
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading options...'),
                        ],
                      ),
                    ),
                  )
                : specifications.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No options available for this item',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
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
                              crossAxisCount: 2,
                              childAspectRatio: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: specifications.length,
                            itemBuilder: (context, index) {
                              final spec = specifications[index];
                              return _buildSpecificationCard(
                                  expandedItem, spec);
                            },
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

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

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          _addToCartWithSpecification(item, spec, discount);
          setState(() {
            _expandedItemId = null;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      spec.specificationName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (discount != null) ...[
                      Text(
                        'Was: RWF ${spec.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        'Now: RWF ${finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else
                      Text(
                        'RWF ${spec.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (discount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${discount.discountType == "amount" ? "-RWF${discount.discountAmount.toInt()}" : "-${discount.discountAmount.toInt()}%"}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final item = _searchResults[index];
              return _buildSearchItemCard(item);
            },
          ),

          // Show specifications below the search results if an item is expanded
          if (_expandedItemId != null) ...[
            const SizedBox(height: 16),
            _buildExpandedSpecifications(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchItemCard(MenuItem item) {
    final isExpanded = _expandedItemId == item.id;

    return Card(
      elevation: isExpanded ? 6 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isExpanded
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _toggleItemSpecifications(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isExpanded
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                  ),
                  child: item.imagePath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://kigalisportlounge.hdev.rw/API_TEST/uploads/${item.imagePath}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.restaurant_menu,
                                size: 40,
                                color: Colors.grey,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.restaurant_menu,
                          size: 40,
                          color: Colors.grey,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              // Item Name and Category
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isExpanded ? AppColors.primary : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              // Expand Button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _toggleItemSpecifications(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isExpanded ? Colors.orange : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isExpanded ? 'Hide Options' : 'View Options',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
