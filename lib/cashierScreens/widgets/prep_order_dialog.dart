import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/cart_item_model.dart';

class PrepOrderDialog extends StatefulWidget {
  final CartItem cartItem;
  final Function(int) onSavePrepOrder;
  final int cartLength; // Add cartLength parameter

  const PrepOrderDialog({
    Key? key,
    required this.cartItem,
    required this.onSavePrepOrder,
    required this.cartLength, // Make cartLength required
  }) : super(key: key);

  @override
  State<PrepOrderDialog> createState() => _PrepOrderDialogState();
}

class _PrepOrderDialogState extends State<PrepOrderDialog> {
  late int _selectedPrepOrder;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedPrepOrder = widget.cartItem.prepOrder ?? 0;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: const Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set Cource Order',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.cartItem.itemName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Cource order options - scrollable when cart has many items
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 20,
                radius: const Radius.circular(6),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      _buildPrepOrderOption(0, 'No specific order'),
                      for (int i = 1; i <= widget.cartLength; i++)
                        _buildPrepOrderOption(i, _getOrderText(i)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    widget.onSavePrepOrder(_selectedPrepOrder);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get order text based on position
  String _getOrderText(int position) {
    switch (position) {
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
        if (position == widget.cartLength) {
          return 'Cource last';
        }
        // For positions beyond 5, use ordinal suffixes
        return 'Cource ${position}${_getOrdinalSuffix(position)}';
    }
  }

  // Helper to get ordinal suffix (th, st, nd, rd)
  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return 'th';
    }

    switch (number % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Widget _buildPrepOrderOption(int value, String label) {
    return RadioListTile<int>(
      title: Text(label),
      value: value,
      groupValue: _selectedPrepOrder,
      onChanged: (int? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedPrepOrder = newValue;
          });
        }
      },
      activeColor: AppColors.primary,
      dense: true,
    );
  }
}
