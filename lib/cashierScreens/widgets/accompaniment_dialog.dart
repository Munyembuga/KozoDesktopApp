import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/category_model.dart';

class AccompanimentDialog extends StatefulWidget {
  final dynamic item; // MenuItem
  final Specification spec;
  final dynamic discount; // ClientDiscount
  final Function(dynamic, Specification, dynamic, Map<int, bool>) onConfirm;

  const AccompanimentDialog({
    super.key,
    required this.item,
    required this.spec,
    this.discount,
    required this.onConfirm,
  });

  @override
  State<AccompanimentDialog> createState() => _AccompanimentDialogState();
}

class _AccompanimentDialogState extends State<AccompanimentDialog> {
  Map<int, bool> selectedAccompaniments = {};

  @override
  void initState() {
    super.initState();
    // Pre-select required accompaniments but allow them to be unchecked
    for (var accompaniment in widget.spec.accompaniments) {
      selectedAccompaniments[accompaniment.id] = accompaniment.isRequiredBool;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
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
                      Icons.restaurant,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Accompaniments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${widget.item.itemName} - ${widget.spec.specificationName}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
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

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer,
                              color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.spec.specificationName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (widget.discount != null) ...[
                                  Text(
                                    'Original: RWF ${widget.spec.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  Text(
                                    'Discounted: RWF ${_calculateDiscountedPrice().toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ] else
                                  Text(
                                    'Price: RWF ${widget.spec.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (widget.discount != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${widget.discount!.discountType == "amount" ? "-RWF${widget.discount!.discountAmount.toInt()}" : "-${widget.discount!.discountAmount.toInt()}%"}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Accompaniments header
                    Row(
                      children: [
                        const Icon(Icons.checklist, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Choose your accompaniments:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Info text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Required items are pre-selected but can be unchecked if not needed',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Accompaniments list
                    ...widget.spec.accompaniments.map((accompaniment) {
                      final isSelected =
                          selectedAccompaniments[accompaniment.id] ?? false;
                      final isRequired = accompaniment.isRequiredBool;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isRequired
                                ? (isSelected
                                    ? Colors.red[300]!
                                    : Colors.red[200]!)
                                : (isSelected
                                    ? AppColors.primary.withOpacity(0.5)
                                    : Colors.grey[300]!),
                            width: isSelected ? 2 : 1,
                          ),
                          color: isSelected
                              ? (isRequired ? Colors.red[50] : Colors.blue[50])
                              : Colors.grey[50],
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (isRequired
                                            ? Colors.red
                                            : AppColors.primary)
                                        .withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                selectedAccompaniments[accompaniment.id] =
                                    !isSelected;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Custom checkbox
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isRequired
                                              ? Colors.red
                                              : AppColors.primary)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isRequired
                                            ? Colors.red
                                            : (isSelected
                                                ? AppColors.primary
                                                : Colors.grey),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  // Accompaniment name
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          accompaniment.accompanimentName,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? Colors.black87
                                                : Colors.black54,
                                          ),
                                        ),
                                        if (isRequired) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red[100],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              'Usually Required',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Status indicator
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isRequired
                                            ? Colors.red[100]
                                            : Colors.blue[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Selected',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isRequired
                                              ? Colors.red[700]
                                              : Colors.blue[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 8),

                    // Selection summary
                    if (selectedAccompaniments.values
                        .any((selected) => selected))
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 16, color: Colors.green[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Selected accompaniments:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getSelectedAccompanimentsText(),
                              style: TextStyle(
                                color: Colors.green[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onConfirm(
                          widget.item,
                          widget.spec,
                          widget.discount,
                          selectedAccompaniments,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_shopping_cart, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Add to Cart',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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

  double _calculateDiscountedPrice() {
    if (widget.discount == null) return widget.spec.price;

    if (widget.discount!.discountType == 'amount') {
      return widget.spec.price - widget.discount!.discountAmount;
    } else {
      return widget.spec.price * (1 - widget.discount!.discountAmount / 100);
    }
  }

  String _getSelectedAccompanimentsText() {
    final selectedNames = widget.spec.accompaniments
        .where((acc) => selectedAccompaniments[acc.id] == true)
        .map((acc) => acc.accompanimentName)
        .toList();

    if (selectedNames.isEmpty) {
      return 'None selected';
    }

    return selectedNames.join(', ');
  }
}
