import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kozo/cashierScreens/login_screen.dart';
import 'package:kozo/cashierScreens/widgets/accompaniment_dialog.dart';
import 'package:kozo/models/table_model.dart';
import 'package:kozo/models/waiter_model.dart';
import 'package:kozo/navRailscreen/navRailMainWaiter.dart';
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
  List<Waiter> _waiters = [];
  List<TableModel> _tables = [];
  Category? _selectedCategory;
  TableModel? _selectedTable;
  bool _isLoadingItems = false;
  bool _isLoadingWaiters = false;
  bool _isLoadingTables = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _orderNotesController = TextEditingController();
  int? _expandedItemId;
  Map<int, List<Specification>> _itemSpecifications = {};
  Map<int, Specification?> _selectedSpecifications = {};
  Map<int, bool> _loadingSpecifications = {};

  // Order type and notes
  String _selectedOrderType = 'dine_in'; // Default to dine_in
  String _orderNotes = '';

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
      final specificationsResponse =
          await WaiterOrderServices.fetchSpecifications(item.id);
      final specifications = specificationsResponse.cast<Specification>();
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

      // Prepare items for the API
      List<Map<String, dynamic>> orderItems = [];

      for (var cartItem in _cartItems) {
        // Use the specificationId directly from the cart item
        if (cartItem.specificationId != null && cartItem.specificationId! > 0) {
          // Prepare the item data
          Map<String, dynamic> itemData = {
            'itemId': cartItem.id,
            'specificationId': cartItem.specificationId!,
            'quantity': cartItem.quantity,
            'price': cartItem
                .price, // Use the price from cart item (which might include discounts)
            'total': cartItem.price * cartItem.quantity,
          };

          // Add accompaniments_id if available
          if (cartItem.accompanimentsIds != null &&
              cartItem.accompanimentsIds!.isNotEmpty) {
            // For single accompaniment, use the first one
            itemData['accompaniments_id'] = cartItem.accompanimentsIds!.first;
          }

          // Add comment if available
          if (cartItem.comment != null && cartItem.comment!.isNotEmpty) {
            itemData['comment'] = cartItem.comment!;
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

      // Process the order
      final result = await WaiterOrderServices.processOrder(
        tableId: _selectedTable!.id,
        clientId: null, // No client selection
        orderType: _selectedOrderType,
        orderNotes: _orderNotes,
        items: orderItems,
      );
      print(" result%%%%%%%%%%%%%%%%: $result ");
      // Hide loading
      Navigator.of(context).pop();

      // if (result['success'] == true) {
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
              const NavRailMainWaiter(initialIndex: 2), // Pass initial index
        ),
      );
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
      _selectedTable = null;
      _menuItems.clear();
      _expandedItemId = null;
      _itemSpecifications.clear();
      _selectedSpecifications.clear();
      _loadingSpecifications.clear();
      _selectedOrderType = 'dine_in';
      _orderNotes = '';
      _orderNotesController.clear();
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

  double _calculateOriginalTotal() {
    return _cartItems.fold(
        0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double _calculateTotalDiscount() {
    return 0.0; // No discounts in this version
  }

  void _addToCartWithSpecification(MenuItem item, Specification spec) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((cartItem) =>
          cartItem.id == item.id && cartItem.specificationId == spec.id);

      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(CartItem(
          id: item.id,
          itemName: '${item.itemName} - ${spec.specificationName}',
          categoryId: item.categoryId,
          categoryName: item.categoryName,
          description: item.description,
          imagePath: item.imagePath,
          quantity: 1,
          price: spec.price,
          specificationId: spec.id,
          accompanimentsIds: null,
          comment: null,
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
        // Update quantity for specific specification variant
        final index = _cartItems.indexWhere((item) =>
            item.id == itemId &&
            (specificationId == null ||
                item.specificationId == specificationId));
        if (index >= 0) {
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
                waiters: _waiters,
                tables: _tables,
                selectedClient: null, // No client selection
                selectedTable: _selectedTable,
                isLoadingWaiters: _isLoadingWaiters,
                isLoadingTables: _isLoadingTables,
                clientDiscounts: [], // Empty client discounts
                itemSpecifications: _itemSpecifications,
                specialClients: [], // Empty special clients
                onRemoveFromCart: _removeFromCart,
                onUpdateQuantity: _updateQuantity,
                onUpdateItemComment: (itemId, specificationId, comment) {
                  setState(() {
                    final index = _cartItems.indexWhere((item) =>
                        item.id == itemId &&
                        item.specificationId == specificationId);
                    if (index >= 0) {
                      _cartItems[index] = CartItem(
                        id: _cartItems[index].id,
                        itemName: _cartItems[index].itemName,
                        categoryId: _cartItems[index].categoryId,
                        categoryName: _cartItems[index].categoryName,
                        description: _cartItems[index].description,
                        imagePath: _cartItems[index].imagePath,
                        quantity: _cartItems[index].quantity,
                        price: _cartItems[index].price,
                        specificationId: _cartItems[index].specificationId,
                        accompanimentsIds: _cartItems[index].accompanimentsIds,
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

                onTableChanged: (TableModel? newValue) {
                  setState(() {
                    _selectedTable = newValue;
                  });
                },
                onClientChanged: (newValue) {
                  // Do nothing - client functionality is removed
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
        elevation: isSelected ? 4 : 2,
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
      onNotification: (ScrollNotification notification) {
        return true; // Prevent scroll bubbling
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
          child: Column(
            children: [
              for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
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
                if (_expandedItemId != null &&
                    rows[rowIndex]
                        .any((item) => item.id == _expandedItemId)) ...[
                  const SizedBox(height: 16),
                  _buildExpandedSpecifications(),
                  const SizedBox(height: 16),
                ] else if (rowIndex < rows.length - 1)
                  const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
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
      onNotification: (ScrollNotification notification) {
        return true; // Prevent scroll bubbling
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
          child: Column(
            children: [
              for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: rows[rowIndex].length,
                  itemBuilder: (context, index) {
                    final item = rows[rowIndex][index];
                    return _buildSearchItemCard(item);
                  },
                ),
                if (_expandedItemId != null &&
                    rows[rowIndex]
                        .any((item) => item.id == _expandedItemId)) ...[
                  const SizedBox(height: 16),
                  _buildExpandedSpecifications(),
                  const SizedBox(height: 16),
                ] else if (rowIndex < rows.length - 1)
                  const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(MenuItem item) {
    final isExpanded = _expandedItemId == item.id;

    return Card(
        elevation: isExpanded ? 4 : 2,
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
              ],
            ),
          ),
        ));
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
                // Expanded(
                //   flex: 3,
                //   child: Container(
                //     width: double.infinity,
                //     decoration: BoxDecoration(
                //       borderRadius: BorderRadius.circular(8),
                //       color: Colors.grey[100],
                //     ),
                //     child: item.imagePath.isNotEmpty
                //         ? ClipRRect(
                //             borderRadius: BorderRadius.circular(8),
                //             child: Image.network(
                //               'https://kigalisportlounge.hdev.rw/API/uploads/${item.imagePath}',
                //               fit: BoxFit.cover,
                //               errorBuilder: (context, error, stackTrace) {
                //                 return const Icon(
                //                   Icons.restaurant_menu,
                //                   size: 40,
                //                   color: Colors.grey,
                //                 );
                //               },
                //             ),
                //           )
                //         : const Icon(
                //             Icons.restaurant_menu,
                //             size: 40,
                //             color: Colors.grey,
                //           ),
                //   ),
                // ),
                // const SizedBox(height: 8),
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
              ],
            ),
          ),
        ));
  }

  Widget _buildExpandedSpecifications() {
    final expandedItem =
        _menuItems.firstWhere((item) => item.id == _expandedItemId);
    final specifications = _itemSpecifications[_expandedItemId!] ?? [];
    final isLoadingSpecs = _loadingSpecifications[_expandedItemId!] ?? false;

    return Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 30), // 👈 left & right only
        child: Container(
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
                Container(
                  constraints: BoxConstraints(
                    // Set a fixed height for the specifications area
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: Scrollbar(
                    controller: _specificationsController,
                    thumbVisibility: true,
                    thickness: 20.0,
                    radius: const Radius.circular(4),
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: _specificationsController,
                      padding: const EdgeInsets.all(16),
                      physics:
                          const ClampingScrollPhysics(), // Prevents parent scroll from being affected
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
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        childAspectRatio: 2,
                                        crossAxisSpacing: 5,
                                        mainAxisSpacing: 5,
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
                  ),
                ),
              ],
            )));
  }

  Widget _buildSpecificationCard(MenuItem item, Specification spec) {
    final bool isOutOfStock = spec.isOutOfStock;
    final bool hasLowStock = spec.hasLowStock;
    final bool isClickable = spec.isAvailable;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isClickable
            ? () {
                if (spec.hasAccompaniments) {
                  _showAccompanimentDialog(item, spec);
                } else {
                  _addToCartWithSpecification(item, spec);
                }
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isOutOfStock ? Colors.grey[200]! : Colors.white,
                isOutOfStock
                    ? Colors.grey[100]!
                    : Colors.grey.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spec.specificationName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color:
                                isOutOfStock ? Colors.grey[600] : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RWF ${spec.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock
                                ? Colors.grey[600]
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? Colors.grey[400]
                              : spec.hasAccompaniments
                                  ? Colors.orange
                                  : AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          spec.hasAccompaniments ? Icons.settings : Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Stock information
              // if (spec.requiresStockTracking && spec.stockInfo != null) ...[
              //   const SizedBox(height: 8),
              //   Container(
              //     padding:
              //         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //     decoration: BoxDecoration(
              //       color: isOutOfStock
              //           ? Colors.red[100]
              //           : hasLowStock
              //               ? Colors.orange[100]
              //               : Colors.green[100],
              //       borderRadius: BorderRadius.circular(12),
              //       border: Border.all(
              //         color: isOutOfStock
              //             ? Colors.red[300]!
              //             : hasLowStock
              //                 ? Colors.orange[300]!
              //                 : Colors.green[300]!,
              //       ),
              //     ),
              //     child: Row(
              //       mainAxisSize: MainAxisSize.min,
              //       children: [
              //         Icon(
              //           isOutOfStock
              //               ? Icons.inventory_2_outlined
              //               : hasLowStock
              //                   ? Icons.warning_amber_rounded
              //                   : Icons.check_circle_outline,
              //           size: 12,
              //           color: isOutOfStock
              //               ? Colors.red[700]
              //               : hasLowStock
              //                   ? Colors.orange[700]
              //                   : Colors.green[700],
              //         ),
              //         const SizedBox(width: 4),
              //         Text(
              //           isOutOfStock
              //               ? 'Out of Stock'
              //               : hasLowStock
              //                   ? 'Low Stock: ${spec.stockInfo!.quantity.toStringAsFixed(0)}'
              //                   : 'Stock: ${spec.stockInfo!.quantity.toStringAsFixed(0)}',
              //           style: TextStyle(
              //             fontSize: 10,
              //             color: isOutOfStock
              //                 ? Colors.red[700]
              //                 : hasLowStock
              //                     ? Colors.orange[700]
              //                     : Colors.green[700],
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ],

              // Show accompaniments indicator if available
              if (spec.hasAccompaniments && isClickable) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant,
                          size: 12, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(
                        '${spec.accompaniments.length} accompaniment${spec.accompaniments.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Out of stock overlay
              // if (isOutOfStock) ...[
              //   const SizedBox(height: 8),
              //   Container(
              //     width: double.infinity,
              //     padding: const EdgeInsets.symmetric(vertical: 6),
              //     decoration: BoxDecoration(
              //       color: Colors.red[50],
              //       borderRadius: BorderRadius.circular(6),
              //       border: Border.all(color: Colors.red[200]!),
              //     ),
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         Icon(Icons.block, size: 14, color: Colors.red[700]),
              //         const SizedBox(width: 4),
              //         Text(
              //           'Currently Unavailable',
              //           style: TextStyle(
              //             fontSize: 11,
              //             color: Colors.red[700],
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAccompanimentDialog(MenuItem item, Specification spec) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AccompanimentDialog(
          item: item,
          spec: spec,
          discount: null, // No discount
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
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(CartItem(
          id: item.id,
          itemName:
              '${item.itemName} - ${spec.specificationName}$accompanimentText',
          categoryId: item.categoryId,
          categoryName: item.categoryName,
          description: item.description,
          imagePath: item.imagePath,
          quantity: 1,
          price: finalPrice,
          specificationId: spec.id,
          accompanimentsIds: selectedAccompaniments.keys
              .where((id) => selectedAccompaniments[id] == true)
              .toList(),
          comment: null, // Can be added later with comment dialog
        ));
      }
    });

    _showSuccessSnackBar(
        '${item.itemName} - ${spec.specificationName}$accompanimentText added to cart');
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
}

// Extra methods to ensure type compatibility and maintain compilation after removing discount functionality
class ClientDiscount {
  final int id;
  final int itemId;
  final int specificationId;
  final String discountType;
  final double discountAmount;

  ClientDiscount({
    required this.id,
    required this.itemId,
    required this.specificationId,
    required this.discountType,
    required this.discountAmount,
  });
}
