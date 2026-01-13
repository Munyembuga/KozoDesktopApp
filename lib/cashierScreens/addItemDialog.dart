// File: lib/widgets/add_item_dialog.dart

import 'package:flutter/material.dart';
import 'package:kozo/models/table_model.dart';
import '../models/order_detail_model.dart';
import '../models/category_model.dart';
import '../models/cart_item_model.dart' hide Specification;
import '../services/order_service.dart';
import '../constants/app_constants.dart';
import 'widgets/accompaniment_dialog.dart';
import 'widgets/add_note_dialog.dart';
import 'widgets/prep_order_dialog.dart'; // Add import for prep order dialog
import 'widgets/pressure_selection_dialog.dart'; // Import pressure selection dialog

class AddItemDialog extends StatefulWidget {
  final OrderDetail orderDetail;
  final Function(List<CartItem>) onAddItems; // This remains the same

  const AddItemDialog({
    super.key,
    required this.orderDetail,
    required this.onAddItems,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  // State variables
  List<Category> _categories = [];
  List<MenuItem> _availableItems = [];
  List<CartItem> _cartItems = []; // Local cart for this dialog
  bool _isLoadingTables = false;
  Category? _selectedCategory;

  // Scroll controllers
  final ScrollController _categoriesScrollController = ScrollController();
  final ScrollController _itemsScrollController = ScrollController();
  final ScrollController _cartScrollController = ScrollController();
  final ScrollController _specificationsScrollController = ScrollController();
  List<TableModel> _tables = [];

  // Loading states
  bool _isLoadingCategories = false;
  bool _isLoadingItems = false;

  // For expandable specifications
  int? _expandedItemId;
  Map<int, List<Specification>> _itemSpecifications = {};
  Map<int, Specification?> _selectedSpecifications = {};
  Map<int, bool> _loadingSpecifications = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _categoriesScrollController.dispose();
    _itemsScrollController.dispose();
    _cartScrollController.dispose();
    _specificationsScrollController.dispose();
    super.dispose();
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

  Future<void> _fetchCategories() async {
    try {
      setState(() {
        _isLoadingCategories = true;
      });

      final categories = await OrderService.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
        print("Failed to fetch categories: $e");
        _showErrorSnackBar('Please try again later.');
      }
    }
  }

  Future<void> _fetchItemsByCategory(int categoryId) async {
    try {
      setState(() {
        _isLoadingItems = true;
        _availableItems.clear();
        _expandedItemId = null;
        _itemSpecifications.clear();
        _selectedSpecifications.clear();
        _loadingSpecifications.clear();
      });

      final items = await OrderService.fetchItemsByCategory(categoryId);
      if (mounted) {
        setState(() {
          _availableItems = items;
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingItems = false;
        });
        print("Failed to fetch items: $e");
        _showErrorSnackBar('Please try again later.');
      }
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
      final specifications = await OrderService.fetchSpecifications(item.id);
      setState(() {
        _itemSpecifications[item.id] = specifications.cast<Specification>();
        _loadingSpecifications[item.id] = false;
      });

      if (specifications.isEmpty) {
        _showErrorSnackBar('No specifications found for this item');
        setState(() {
          _expandedItemId = null;
        });
      } else {
        // Show specifications dialog instead of expanding inline
        _showSpecificationsDialog(item, _itemSpecifications[item.id]!);
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
                              childAspectRatio: 2.5,
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

  // Add this method to handle auto-assigning prep orders
  void _autoAssignPrepOrders() {
    setState(() {
      for (int i = 0; i < _cartItems.length; i++) {
        _cartItems[i] = _cartItems[i].copyWith(prepOrder: 1);
      }
    });

    _showSuccessSnackBar('All items set to "Cource First"');
  }

  // Add method to update Cource order for an item
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
      _showSuccessSnackBar('Cource order set for item');
    } else {
      _showSuccessSnackBar('Cource order removed from item');
    }
  }

  // Add method to update pressure for an item
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

  // Add method to show Cource order dialog
  void _showPrepOrderDialog(BuildContext context, CartItem cartItem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PrepOrderDialog(
          cartItem: cartItem,
          cartLength: _cartItems.length, // Pass the cart length
          onSavePrepOrder: (prepOrder) {
            _updateItemPrepOrder(
                cartItem.id, cartItem.specificationId ?? 0, prepOrder);
          },
        );
      },
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
      case 5:
        return 'Cource 5';
      default:
        if (prepOrder == _cartItems.length) {
          return 'Cource last';
        }
        return 'Preparation order: $prepOrder';
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

  // Helper method to get specification for a cart item
  Specification? _getSpecificationForCartItem(CartItem cartItem) {
    if (cartItem.specificationId == null) return null;

    final itemSpecs = _itemSpecifications[cartItem.id] ?? [];
    try {
      return itemSpecs.firstWhere(
        (spec) => spec.id == cartItem.specificationId,
      );
    } catch (e) {
      return null;
    }
  }

  // Add method to show pressure dialog
  void _showPressureDialog(
      BuildContext context, CartItem cartItem, Specification spec) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PressureSelectionDialog(
          cartItem: cartItem,
          pressureOptions: spec.pressureCooking,
          onSavePressure: (pressureId) {
            _updateItemPressure(
                cartItem.id, cartItem.specificationId ?? 0, pressureId);
          },
        );
      },
    );
  }

  void _addToCartWithSpecification(MenuItem item, Specification spec) {
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
          prepOrder: 1, // Default to "Course first"
          requiresPressure: spec.needsPressureCooking,
        ));
      }
    });

    _showSuccessSnackBar(
        '${item.itemName} - ${spec.specificationName} added to cart');

    // Keep specifications open for multiple selections
    // Don't collapse expanded item after adding
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _updateCartItemQuantity(int index, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        final cartItem = _cartItems[index];

        // Check stock before updating quantity
        if (cartItem.specificationId != null) {
          // Find the specification to check stock
          final itemSpecs = _itemSpecifications[cartItem.id] ?? [];
          final spec = itemSpecs.firstWhere(
            (s) => s.id == cartItem.specificationId,
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
    });
  }

  void _handleAddAllToOrder() {
    if (_cartItems.isNotEmpty) {
      widget.onAddItems(_cartItems);
      Navigator.of(context).pop();
    }
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
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

  double get _totalCartPrice {
    return _cartItems.fold(
        0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  int get _totalCartItems {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1200,
        height: 700,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_shopping_cart,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add Items to Order ${widget.orderDetail.orderNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_cartItems.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_cart,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$_totalCartItems items',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Row(
                children: [
                  // Left side - Categories and Items
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Categories Header
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.category,
                                  color: AppColors.primary),
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
                                        color:
                                            AppColors.primary.withOpacity(0.3)),
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
                                            _availableItems.clear();
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
                            border: Border(
                                bottom: BorderSide(color: Colors.grey[300]!)),
                          ),
                          child: _isLoadingCategories
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : Scrollbar(
                                  controller: _categoriesScrollController,
                                  thumbVisibility: true,
                                  thickness: 20.0,
                                  radius: const Radius.circular(20),
                                  trackVisibility: true,
                                  child: ListView.builder(
                                    controller: _categoriesScrollController,
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

                        // Items section
                        Expanded(
                          child: _selectedCategory == null
                              ? _buildWelcomeScreen()
                              : _isLoadingItems
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : _availableItems.isEmpty
                                      ? const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.inventory_2_outlined,
                                                  size: 64, color: Colors.grey),
                                              SizedBox(height: 16),
                                              Text(
                                                'No items found in this category',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _buildItemsList(),
                        ),
                      ],
                    ),
                  ),

                  // Right side - Cart
                  Container(
                    width: 350,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border:
                          Border(left: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Column(
                      children: [
                        // Cart Header
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
                          child: Row(
                            children: [
                              const Icon(Icons.shopping_cart,
                                  color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Cart (${_cartItems.length} items)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (_cartItems.isNotEmpty)
                                TextButton(
                                  onPressed: _clearCart,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Clear',
                                      style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                        ),

                        // Make entire cart content scrollable including footer
                        Expanded(
                          child: Scrollbar(
                            controller: _cartScrollController,
                            thumbVisibility: true,
                            thickness: 20.0,
                            radius: const Radius.circular(10),
                            trackVisibility: true,
                            child: SingleChildScrollView(
                              controller: _cartScrollController,
                              child: Column(
                                children: [
                                  // Add Auto-assign Prep Orders button at the top of the cart if cart has items
                                  if (_cartItems.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: _autoAssignPrepOrders,
                                              icon: const Icon(Icons.schedule),
                                              label: const Text(
                                                  'Auto-assign Preparation Order'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.blue[700],
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Cart Items
                                  _cartItems.isEmpty
                                      ? const SizedBox(
                                          height: 300,
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                    Icons
                                                        .shopping_cart_outlined,
                                                    size: 64,
                                                    color: Colors.grey),
                                                SizedBox(height: 16),
                                                Text(
                                                  'Your cart is empty',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Select items and specifications\nto add them to your cart',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          padding: const EdgeInsets.all(16),
                                          itemCount: _cartItems.length,
                                          itemBuilder: (context, index) {
                                            final cartItem = _cartItems[index];
                                            return Card(
                                              margin: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                cartItem
                                                                    .itemName,
                                                                style:
                                                                    const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                              Text(
                                                                cartItem
                                                                    .categoryName,
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                          .grey[
                                                                      600],
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons.close,
                                                              color: Colors.red,
                                                              size: 18),
                                                          onPressed: () =>
                                                              _removeFromCart(
                                                                  index),
                                                          constraints:
                                                              const BoxConstraints(),
                                                          padding:
                                                              EdgeInsets.zero,
                                                        ),
                                                      ],
                                                    ),

                                                    // Preparation Order indicator
                                                    if (cartItem.prepOrder !=
                                                            null &&
                                                        cartItem.prepOrder! > 0)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8),
                                                        margin: const EdgeInsets
                                                            .only(
                                                            top: 8, bottom: 8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.blue[50],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          border: Border.all(
                                                              color: Colors
                                                                  .blue[200]!),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.schedule,
                                                                size: 16,
                                                                color: Colors
                                                                    .blue[700]),
                                                            const SizedBox(
                                                                width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                _getPrepOrderText(
                                                                    cartItem
                                                                        .prepOrder!),
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                          .blue[
                                                                      700],
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                    // Comment section
                                                    if (cartItem.comment !=
                                                            null &&
                                                        cartItem.comment!
                                                            .isNotEmpty)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8),
                                                        margin: const EdgeInsets
                                                            .only(
                                                            top: 8, bottom: 8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.amber[50],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          border: Border.all(
                                                              color: Colors
                                                                  .amber[200]!),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.comment,
                                                                size: 16,
                                                                color: Colors
                                                                        .amber[
                                                                    700]),
                                                            const SizedBox(
                                                                width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                'Note: ${cartItem.comment}',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                          .amber[
                                                                      700],
                                                                  fontStyle:
                                                                      FontStyle
                                                                          .italic,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                    // Pressure Cooking indicator
                                                    if (cartItem
                                                            .requiresPressure &&
                                                        cartItem.selectedPressureId !=
                                                            null)
                                                      Builder(
                                                        builder: (context) {
                                                          final spec =
                                                              _getSpecificationForCartItem(
                                                                  cartItem);
                                                          return Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8),
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 8,
                                                                    bottom: 8),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .deepPurple[50],
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                              border: Border.all(
                                                                  color: Colors
                                                                          .deepPurple[
                                                                      200]!),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                    Icons
                                                                        .thermostat,
                                                                    size: 16,
                                                                    color: Colors
                                                                            .deepPurple[
                                                                        700]),
                                                                const SizedBox(
                                                                    width: 8),
                                                                Expanded(
                                                                  child: Text(
                                                                    spec != null
                                                                        ? _getPressureText(
                                                                            cartItem.selectedPressureId!,
                                                                            spec.pressureCooking)
                                                                        : 'Temperature: Selected',
                                                                    style:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                              .deepPurple[
                                                                          700],
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),

                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'RWF ${cartItem.price.toStringAsFixed(0)}',
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.green,
                                                          ),
                                                        ),
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            IconButton(
                                                              icon: const Icon(
                                                                  Icons.remove,
                                                                  size: 16),
                                                              onPressed: () =>
                                                                  _updateCartItemQuantity(
                                                                      index,
                                                                      cartItem.quantity -
                                                                          1),
                                                              constraints:
                                                                  const BoxConstraints(),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(4),
                                                              style: IconButton
                                                                  .styleFrom(
                                                                backgroundColor:
                                                                    Colors.grey[
                                                                        200],
                                                              ),
                                                            ),
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4),
                                                              child: Text(
                                                                  '${cartItem.quantity}',
                                                                  style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold)),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                  Icons.add,
                                                                  size: 16),
                                                              onPressed: () =>
                                                                  _updateCartItemQuantity(
                                                                      index,
                                                                      cartItem.quantity +
                                                                          1),
                                                              constraints:
                                                                  const BoxConstraints(),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(4),
                                                              style: IconButton
                                                                  .styleFrom(
                                                                backgroundColor:
                                                                    Colors.grey[
                                                                        200],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),

                                                    // Action buttons
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        // Add Note button
                                                        Expanded(
                                                          child:
                                                              TextButton.icon(
                                                            onPressed: () =>
                                                                _showCommentDialog(
                                                                    context,
                                                                    cartItem,
                                                                    index),
                                                            icon: Icon(
                                                              cartItem.comment !=
                                                                          null &&
                                                                      cartItem
                                                                          .comment!
                                                                          .isNotEmpty
                                                                  ? Icons
                                                                      .edit_note
                                                                  : Icons
                                                                      .add_comment,
                                                              size: 16,
                                                              color: AppColors
                                                                  .primary,
                                                            ),
                                                            label: Text(
                                                              cartItem.comment !=
                                                                          null &&
                                                                      cartItem
                                                                          .comment!
                                                                          .isNotEmpty
                                                                  ? 'Edit Note'
                                                                  : 'Add Note',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                color: AppColors
                                                                    .primary,
                                                              ),
                                                            ),
                                                            style: TextButton
                                                                .styleFrom(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4),
                                                              minimumSize:
                                                                  Size.zero,
                                                              tapTargetSize:
                                                                  MaterialTapTargetSize
                                                                      .shrinkWrap,
                                                              backgroundColor:
                                                                  AppColors
                                                                      .primary
                                                                      .withOpacity(
                                                                          0.1),
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            6),
                                                              ),
                                                            ),
                                                          ),
                                                        ),

                                                        const SizedBox(
                                                            width: 8),

                                                        // Add Prep Order button
                                                        Expanded(
                                                          child:
                                                              TextButton.icon(
                                                            onPressed: () =>
                                                                _showPrepOrderDialog(
                                                                    context,
                                                                    cartItem),
                                                            icon: Icon(
                                                              cartItem.prepOrder !=
                                                                          null &&
                                                                      cartItem.prepOrder! >
                                                                          0
                                                                  ? Icons
                                                                      .edit_calendar
                                                                  : Icons
                                                                      .schedule,
                                                              size: 16,
                                                              color: Colors
                                                                  .blue[700],
                                                            ),
                                                            label: Text(
                                                              cartItem.prepOrder !=
                                                                          null &&
                                                                      cartItem.prepOrder! >
                                                                          0
                                                                  ? 'Edit Order'
                                                                  : 'Prep Order',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .blue[700],
                                                              ),
                                                            ),
                                                            style: TextButton
                                                                .styleFrom(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4),
                                                              minimumSize:
                                                                  Size.zero,
                                                              tapTargetSize:
                                                                  MaterialTapTargetSize
                                                                      .shrinkWrap,
                                                              backgroundColor:
                                                                  Colors
                                                                      .blue[50],
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            6),
                                                              ),
                                                            ),
                                                          ),
                                                        ),

                                                        // Pressure button (only show if item requires pressure)
                                                        if (cartItem
                                                            .requiresPressure)
                                                          Builder(
                                                            builder: (context) {
                                                              final spec =
                                                                  _getSpecificationForCartItem(
                                                                      cartItem);
                                                              if (spec ==
                                                                      null ||
                                                                  spec.pressureCooking
                                                                      .isEmpty) {
                                                                return const SizedBox
                                                                    .shrink();
                                                              }
                                                              return Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  const SizedBox(
                                                                      width: 8),
                                                                  TextButton
                                                                      .icon(
                                                                    onPressed: () => _showPressureDialog(
                                                                        context,
                                                                        cartItem,
                                                                        spec),
                                                                    icon: Icon(
                                                                      cartItem.selectedPressureId !=
                                                                              null
                                                                          ? Icons
                                                                              .thermostat
                                                                          : Icons
                                                                              .thermostat_outlined,
                                                                      size: 16,
                                                                      color: Colors
                                                                              .deepPurple[
                                                                          700],
                                                                    ),
                                                                    label: Text(
                                                                      cartItem.selectedPressureId !=
                                                                              null
                                                                          ? 'Edit'
                                                                          : 'Temperature',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Colors
                                                                            .deepPurple[700],
                                                                      ),
                                                                    ),
                                                                    style: TextButton
                                                                        .styleFrom(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              8,
                                                                          vertical:
                                                                              4),
                                                                      minimumSize:
                                                                          Size.zero,
                                                                      tapTargetSize:
                                                                          MaterialTapTargetSize
                                                                              .shrinkWrap,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .deepPurple[50],
                                                                      shape:
                                                                          RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(6),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                  // Cart Summary and Actions - now inside the scrollable area
                                  if (_cartItems.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border(
                                            top: BorderSide(
                                                color: Colors.grey[300]!)),
                                      ),
                                      child: Column(
                                        children: [
                                          // Total Summary
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.blue[200]!),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text('Total Items:'),
                                                    Text(
                                                      '$_totalCartItems',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text('Total Amount:'),
                                                    Text(
                                                      'RWF ${_totalCartPrice.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.blue,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Action Buttons
                                          Column(
                                            children: [
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed:
                                                      _cartItems.isNotEmpty
                                                          ? _handleAddAllToOrder
                                                          : null,
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 16),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Add All Items to Order',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                width: double.infinity,
                                                child: TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 16),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      side: BorderSide(
                                                          color: Colors
                                                              .grey[300]!),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Cancel',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Add extra space at the bottom for better scrolling
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
                  ),
                ],
              ),
            ),
          ],
        ),
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
                _availableItems.clear();
                _expandedItemId = null;
              } else {
                // Select new category
                _selectedCategory = category;
                _availableItems.clear();
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
            'Select Category to Add Items',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose a category above to view available menu items',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    const int itemsPerRow = 4;
    List<List<MenuItem>> rows = [];

    // Group items into rows of 4
    for (int i = 0; i < _availableItems.length; i += itemsPerRow) {
      int end = (i + itemsPerRow < _availableItems.length)
          ? i + itemsPerRow
          : _availableItems.length;
      rows.add(_availableItems.sublist(i, end));
    }

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
                '${_availableItems.length} items',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Items with Specifications
        Expanded(
          child: Scrollbar(
            controller: _itemsScrollController,
            thumbVisibility: true,
            thickness: 20.0,
            radius: const Radius.circular(4),
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _itemsScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (int rowIndex = 0;
                      rowIndex < rows.length;
                      rowIndex++) ...[
                    // Build each row
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
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
                ],
              ),
            ),
          ),
        ),
      ],
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
              ],
            ),
          ),
        ));
  }

  // Update the _buildSpecificationCard method to display stock information
  Widget _buildSpecificationCard(MenuItem item, Specification spec) {
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
                    _showAccompanimentDialog(item, spec);
                  } else {
                    _addToCartWithSpecification(item, spec);
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
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
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isOutOfStock || hasZeroQuantity
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

                // Price and stock info
                const SizedBox(height: 2),
                Text(
                  'RWF ${spec.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOutOfStock || hasZeroQuantity
                        ? Colors.grey[600]
                        : AppColors.primary,
                  ),
                ),

                // Stock quantity if available
                if (spec.requiresStockTracking && spec.stockInfo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    isOutOfStock || hasZeroQuantity
                        ? 'Out of Stock'
                        : hasLowStock
                            ? 'Low: ${spec.stockInfo!.quantity.toInt()}'
                            : 'Qty: ${spec.stockInfo!.quantity.toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isOutOfStock || hasZeroQuantity
                          ? Colors.red[700]
                          : hasLowStock
                              ? Colors.orange[700]
                              : Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                // Accompaniments indicator if available (compact)
                if (spec.hasAccompaniments && isClickable) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${spec.accompaniments.length} add-on${spec.accompaniments.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ));
  }

  void _showAccompanimentDialog(MenuItem item, Specification spec) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AccompanimentDialog(
          item: item,
          spec: spec,
          discount: null, // No discount in add item dialog
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
    // Create accompaniments description
    String accompanimentText = '';
    List<int> selectedAccompanimentIds = [];

    if (selectedAccompaniments.isNotEmpty) {
      final selectedNames = spec.accompaniments
          .where((acc) => selectedAccompaniments[acc.id] == true)
          .map((acc) => acc.accompanimentName)
          .toList();

      selectedAccompanimentIds = selectedAccompaniments.keys
          .where((id) => selectedAccompaniments[id] == true)
          .toList();

      if (selectedNames.isNotEmpty) {
        accompanimentText = ' (with ${selectedNames.join(', ')})';
      }
    }

    setState(() {
      // Check for existing item with same specification and accompaniments
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
          price: spec.price,
          specificationId: spec.id,
          accompanimentsIds: selectedAccompanimentIds.isNotEmpty
              ? selectedAccompanimentIds
              : null,
        ));
      }
    });

    _showSuccessSnackBar(
        '${item.itemName} - ${spec.specificationName}$accompanimentText added to cart');
  }

  void _showCommentDialog(BuildContext context, CartItem cartItem, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddNoteDialog(
          cartItem: cartItem,
          onSaveNote: (comment) {
            setState(() {
              // Use copyWith to preserve all properties including pressure
              _cartItems[index] = _cartItems[index].copyWith(
                comment: comment.isEmpty ? null : comment,
              );
            });
          },
        );
      },
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
}
