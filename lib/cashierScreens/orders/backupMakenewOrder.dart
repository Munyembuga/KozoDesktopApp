import 'dart:async';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:kozo/models/cart_item_model.dart';
import 'package:kozo/models/category_model.dart';
import 'package:kozo/models/table_model.dart';
import 'package:kozo/models/waiter_model.dart';
import 'package:kozo/services/order_service.dart';
import 'package:kozo/utils/constants.dart';

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
  List<Specification> _specifications = [];
  List<Waiter> _waiters = [];
  List<TableModel> _tables = [];
  Category? _selectedCategory;
  SpecialClient? _selectedClient;
  Specification? _selectedSpecification;
  MenuItem? _selectedItemForSpec;
  Waiter? _selectedWaiter;
  TableModel? _selectedTable;
  bool _isLoadingCategories = false;
  bool _isLoadingItems = false;
  bool _isLoadingClients = false;
  bool _isLoadingSpecifications = false;
  bool _isLoadingWaiters = false;
  bool _isLoadingTables = false;
  String _searchQuery = '';
  String _clientSearchQuery = '';
  String _specificationSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _clientSearchController = TextEditingController();
  final TextEditingController _specificationSearchController =
      TextEditingController();
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
    _clientSearchController.dispose();
    _specificationSearchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await OrderService.fetchCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      _showErrorSnackBar('Failed to fetch categories: $e');
    }
  }

  Future<void> _fetchSpecialClients() async {
    setState(() {
      _isLoadingClients = true;
    });

    try {
      final clients = await OrderService.fetchSpecialClients();
      setState(() {
        _specialClients = clients;
        _isLoadingClients = false;
      });
      print("Fetched special clients: ${clients.length}");
    } catch (e) {
      setState(() {
        _isLoadingClients = false;
      });
      _showErrorSnackBar('Failed to fetch special clients: $e');
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
      _showErrorSnackBar('Failed to fetch client discount: $e');
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
      _showErrorSnackBar('Failed to fetch waiters: $e');
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
      _showErrorSnackBar('Failed to fetch tables: $e');
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
      _showErrorSnackBar('Failed to fetch items: $e');
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
      _showErrorSnackBar('Failed to fetch specifications: $e');
    }
  }

  void _clearSpecificationSelection() {
    setState(() {
      _selectedItemForSpec = null;
      _specifications.clear();
      _selectedSpecification = null;
      _specificationSearchQuery = '';
      _specificationSearchController.clear();
    });
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
          orderItems.add({
            'itemId': cartItem.id,
            'specificationId': spec.id,
            'quantity': cartItem.quantity,
            'price': cartItem.price,
            'total': cartItem.price * cartItem.quantity,
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
                const NavRailMain(initialIndex: 2), // Pass initial index
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

  void _addToCart(MenuItem item) {
    setState(() {
      final existingIndex =
          _cartItems.indexWhere((cartItem) => cartItem.id == item.id);
      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(CartItem(
          id: item.id,
          itemName: item.itemName,
          categoryId: item.categoryId,
          categoryName: item.categoryName,
          description: item.description,
          imagePath: item.imagePath,
          quantity: 1,
          price: 0.0,
        ));
      }
    });
    _showSuccessSnackBar('${item.itemName} added to cart');
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
      final cartKey = '${item.id}_${spec.id}';
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

  List<SpecialClient> get _filteredClients {
    if (_clientSearchQuery.isEmpty) return _specialClients;
    return _specialClients
        .where((client) =>
            client.clientName
                .toLowerCase()
                .contains(_clientSearchQuery.toLowerCase()) ||
            client.phone.contains(_clientSearchQuery))
        .toList();
  }

  List<Specification> get _filteredSpecifications {
    if (_specificationSearchQuery.isEmpty) return _specifications;
    return _specifications
        .where((spec) => spec.specificationName
            .toLowerCase()
            .contains(_specificationSearchQuery.toLowerCase()))
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
          // Left side - Categories and Items
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Search and Category Dropdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border:
                        Border(bottom: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Column(
                    children: [
                      // Search Bar

                      const SizedBox(height: 16),

                      // Category Dropdown - Always show (not hidden during search)
                      DropdownSearch<Category>(
                        selectedItem: _selectedCategory,
                        items: (filter, infiniteScrollProps) =>
                            _filteredCategories,
                        itemAsString: (Category category) =>
                            category.displayName,
                        compareFn: (Category? a, Category? b) => a?.id == b?.id,
                        decoratorProps: DropDownDecoratorProps(
                          decoration: InputDecoration(
                            labelText: 'Select Category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search categories...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          menuProps: MenuProps(
                            borderRadius: BorderRadius.circular(8),
                            elevation: 8,
                          ),
                          itemBuilder: (context, item, isDisabled, isSelected) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Text(
                                item.displayName,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                        onChanged: (Category? newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                            _menuItems.clear();
                            // Clear search when category changes
                            _searchController.clear();
                            _isSearching = false;
                            _searchResults.clear();
                          });
                          if (newValue != null) {
                            _fetchItemsByCategory(newValue.id);
                          }
                        },
                        validator: (Category? value) {
                          if (value == null) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                // Menu Items

                Expanded(
                  child: Column(
                    children: [
                      // Search TextField
                      Padding(
                        padding: const EdgeInsets.all(16),
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

                      // Main content area
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
                                ? _searchResults.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.search_off,
                                                size: 64, color: Colors.grey),
                                            SizedBox(height: 16),
                                            Text(
                                              'No items found for "${_searchController.text}"',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: _searchResults.length,
                                        itemBuilder: (context, index) {
                                          final item = _searchResults[index];
                                          return _buildMenuItemCard(item);
                                        },
                                      )
                                : _isLoadingItems
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : _menuItems.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'Select a category to view items',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey),
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.all(16),
                                            itemCount: _menuItems.length,
                                            itemBuilder: (context, index) {
                                              final item = _menuItems[index];
                                              return _buildMenuItemCard(item);
                                            },
                                          ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          // Right side - Cart
          Container(
            width: 600,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(left: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
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
                            'Cart (${_cartItems.length} items)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_selectedClient != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Client: ${_selectedClient!.clientName}',
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
                Expanded(
                  child: _cartItems.isEmpty
                      ? const Center(
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
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final cartItem = _cartItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          onPressed: () =>
                                              _removeFromCart(cartItem.id),
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () => _updateQuantity(
                                                cartItem.id,
                                                cartItem.quantity - 1,
                                              ),
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: const EdgeInsets.all(4),
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
                                              child:
                                                  Text('${cartItem.quantity}'),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () => _updateQuantity(
                                                cartItem.id,
                                                cartItem.quantity + 1,
                                              ),
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: const EdgeInsets.all(4),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (_cartItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Column(
                      children: [
                        // Total Items and Amount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Items:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_cartItems.fold(0, (sum, item) => sum + item.quantity)}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (_cartItems.any((item) => item.price > 0))
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'RWF ${_cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity)).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),

                        // Three sections: Waiter, Table, Client
                        Row(
                          children: [
                            // Waiter Section
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    _isLoadingWaiters
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : DropdownSearch<Waiter>(
                                            selectedItem: _selectedWaiter,
                                            items:
                                                (filter, infiniteScrollProps) {
                                              // Create a "Cashier" option and put it at the top
                                              final defaultWaiter = Waiter(
                                                  id: -1,
                                                  name:
                                                      'Cashier (Self-handled)');
                                              return [
                                                defaultWaiter,
                                                ..._waiters
                                              ];
                                            },
                                            itemAsString: (Waiter waiter) =>
                                                waiter.name,
                                            compareFn: (Waiter? a, Waiter? b) =>
                                                a?.id == b?.id, // Match by ID

                                            decoratorProps:
                                                DropDownDecoratorProps(
                                              decoration: InputDecoration(
                                                labelText: 'Select Waiter',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12),
                                              ),
                                            ),

                                            popupProps: PopupProps.menu(
                                              showSearchBox: true,
                                              searchFieldProps: TextFieldProps(
                                                decoration: InputDecoration(
                                                  hintText: 'Search waiters...',
                                                  prefixIcon:
                                                      Icon(Icons.search),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                              ),
                                              menuProps: MenuProps(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                elevation: 2,
                                              ),
                                              itemBuilder: (context, item,
                                                  isDisabled, isSelected) {
                                                return Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 12),
                                                  child: Text(
                                                    item.name,
                                                    style: TextStyle(
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),

                                            onChanged: (Waiter? newValue) {
                                              setState(() {
                                                _selectedWaiter = newValue;
                                              });
                                            },

                                            validator: (Waiter? value) {
                                              if (value == null) {
                                                return 'Please select a waiter';
                                              }
                                              return null;
                                            },
                                          ),
                                  ],
                                ),
                              ),
                            ),

                            // Table Section
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    _isLoadingTables
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : DropdownSearch<TableModel>(
                                            selectedItem: _selectedTable,
                                            items:
                                                (filter, infiniteScrollProps) {
                                              return _tables;
                                            },
                                            itemAsString: (TableModel table) =>
                                                table.tableName,
                                            compareFn: (TableModel? a,
                                                    TableModel? b) =>
                                                a?.id ==
                                                b?.id, // Assuming TableModel has an id field

                                            decoratorProps:
                                                DropDownDecoratorProps(
                                              decoration: InputDecoration(
                                                labelText: 'Select Table',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12),
                                              ),
                                            ),

                                            popupProps: PopupProps.menu(
                                              showSearchBox: true,
                                              searchFieldProps: TextFieldProps(
                                                decoration: InputDecoration(
                                                  hintText: 'Search tables...',
                                                  prefixIcon:
                                                      Icon(Icons.search),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                              ),
                                              menuProps: MenuProps(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                elevation: 2,
                                              ),
                                              itemBuilder: (context, item,
                                                  isDisabled, isSelected) {
                                                return Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 12),
                                                  child: Text(
                                                    item.tableName,
                                                    style: TextStyle(
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),

                                            onChanged: (TableModel? newValue) {
                                              setState(() {
                                                _selectedTable = newValue;
                                              });
                                            },

                                            validator: (TableModel? value) {
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
                            // Client Section
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.orange[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Special Client',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                        if (_selectedClient != null &&
                                            _clientDiscounts.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${_clientDiscounts.length} discounts',
                                              style: const TextStyle(
                                                fontSize: 8,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    DropdownSearch<SpecialClient?>(
                                      selectedItem: _selectedClient,
                                      items: (filter, infiniteScrollProps) {
                                        // Include a null option at the top for "No Special Client"
                                        return [null, ..._specialClients];
                                      },
                                      itemAsString: (SpecialClient? client) =>
                                          client?.clientName ??
                                          'No Special Client',
                                      compareFn:
                                          (SpecialClient? a, SpecialClient? b) {
                                        // Handle null comparison
                                        if (a == null && b == null) return true;
                                        if (a == null || b == null)
                                          return false;
                                        return a.id == b.id;
                                      },

                                      decoratorProps: DropDownDecoratorProps(
                                        decoration: InputDecoration(
                                          labelText: 'Special Client',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 12),
                                        ),
                                      ),

                                      popupProps: PopupProps.menu(
                                        showSearchBox: true,
                                        searchFieldProps: TextFieldProps(
                                          decoration: InputDecoration(
                                            hintText: 'Search clients...',
                                            prefixIcon: Icon(Icons.search),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        menuProps: MenuProps(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          elevation: 2,
                                        ),
                                        itemBuilder: (context, item, isDisabled,
                                            isSelected) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item?.clientName ??
                                                        'No Special Client',
                                                    style: TextStyle(
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      color: item == null
                                                          ? Colors.grey[600]
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                if (item == null)
                                                  Icon(
                                                    Icons.clear,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),

                                      onChanged: (SpecialClient? newValue) {
                                        setState(() {
                                          // Remove discounts from current cart items if changing client
                                          if (_selectedClient != null &&
                                              newValue != _selectedClient) {
                                            _removeDiscountsFromCartItems();
                                          }

                                          _selectedClient = newValue;
                                          _clientDiscounts.clear();
                                        });

                                        if (newValue != null) {
                                          _fetchClientDiscount(newValue.id);
                                        } else {
                                          // Clear discounts if no client selected
                                          _removeDiscountsFromCartItems();
                                        }
                                      },

                                      // No validator needed since this is optional
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
                            onPressed: _cartItems.isNotEmpty &&
                                    _selectedWaiter != null &&
                                    _selectedTable != null
                                ? _processOrder
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              _selectedWaiter == null
                                  ? 'Select Waiter to Continue'
                                  : _selectedTable == null
                                      ? 'Select Table to Continue'
                                      : 'Process Order',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    final isExpanded = _expandedItemId == item.id;
    final specifications = _itemSpecifications[item.id] ?? [];
    final isLoadingSpecs = _loadingSpecifications[item.id] ?? false;
    final selectedSpec = _selectedSpecifications[item.id];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: item.imagePath.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: NetworkImage(
                      '${AppConfig.baseUrl}/uploads/${item.imagePath}',
                    ),
                  )
                : const CircleAvatar(
                    child: Icon(Icons.restaurant_menu),
                  ),
            title: Text(item.itemName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description.isNotEmpty
                      ? item.description
                      : item.categoryName,
                ),
                if (_isSearching)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Category: ${item.categoryName}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _toggleItemSpecifications(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: isExpanded ? Colors.orange : Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: isExpanded
                  ? const Text('Hide', style: TextStyle(fontSize: 12))
                  : const Icon(Icons.arrow_drop_down),
            ),
          ),

          // Expandable Specifications Section
          if (isExpanded) ...[
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Specifications for: ${item.itemName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isLoadingSpecs)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (specifications.isNotEmpty) ...[
                    // Specification Dropdown
                    DropdownSearch<Specification>(
                      selectedItem: selectedSpec,
                      items: (filter, infiniteScrollProps) => specifications,
                      itemAsString: (Specification spec) =>
                          spec.specificationName,
                      compareFn: (Specification? a, Specification? b) =>
                          a?.id == b?.id,
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: 'Select Specification',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search specifications...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        menuProps: MenuProps(
                          borderRadius: BorderRadius.circular(8),
                          elevation: 8,
                        ),
                        itemBuilder: (context, spec, isDisabled, isSelected) {
                          final discount =
                              _getDiscountForItem(item.id, spec.id);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(spec.specificationName),
                                      Text(
                                        'Price:RWF ${spec.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (discount != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${discount.discountType == "amount" ? "- RWF ${discount.discountAmount}" : "-${discount.discountAmount}%"}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      onChanged: (Specification? newValue) {
                        setState(() {
                          _selectedSpecifications[item.id] = newValue;
                        });
                      },
                      validator: (Specification? value) {
                        if (value == null) {
                          return 'Please select a specification';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Add to Cart Button
                    if (selectedSpec != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final discount =
                                _getDiscountForItem(item.id, selectedSpec.id);
                            _addToCartWithSpecification(
                                item, selectedSpec, discount);
                            setState(() {
                              _expandedItemId = null;
                              _selectedSpecifications[item.id] = null;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Add to Cart',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No specifications available for this item',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
