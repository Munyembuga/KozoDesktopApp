import 'package:flutter/material.dart';
import 'package:virtual_keyboard_multi_language/virtual_keyboard_multi_language.dart';

class DiscountDialog extends StatefulWidget {
  final double totalAmount;
  final Function(double, double) onApplyDiscount;

  const DiscountDialog({
    Key? key,
    required this.totalAmount,
    required this.onApplyDiscount,
  }) : super(key: key);

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  final TextEditingController discountController = TextEditingController();
  bool showKeyboard = true;
  double discountPercentage = 0.0;
  double discountAmount = 0.0;
  double finalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    finalAmount = widget.totalAmount;
  }

  @override
  void dispose() {
    discountController.dispose();
    super.dispose();
  }

  void _calculateDiscount() {
    // Parse the discount percentage, default to 0 if invalid
    discountPercentage = double.tryParse(discountController.text) ?? 0.0;

    // Ensure discount percentage is not negative
    if (discountPercentage < 0) discountPercentage = 0;

    // Cap discount at 100%
    if (discountPercentage > 100) discountPercentage = 100;

    // Calculate discount amount
    discountAmount = (widget.totalAmount * discountPercentage) / 100;

    // Calculate final amount
    finalAmount = widget.totalAmount - discountAmount;

    // Round to 2 decimal places for display purposes
    discountAmount = double.parse(discountAmount.toStringAsFixed(2));
    finalAmount = double.parse(finalAmount.toStringAsFixed(2));

    setState(() {});
  }

  // Handle virtual keyboard key press
  void _onKeyboardPress(VirtualKeyboardKey key) {
    if (key.keyType == VirtualKeyboardKeyType.String) {
      final text = discountController.text;
      final textSelection = discountController.selection;
      final newText = text.replaceRange(
        textSelection.start,
        textSelection.end,
        key.text ?? '',
      );
      final newSelection =
          TextSelection.collapsed(offset: textSelection.start + 1);
      discountController.value = TextEditingValue(
        text: newText,
        selection: newSelection,
      );
    } else if (key.keyType == VirtualKeyboardKeyType.Action) {
      switch (key.action) {
        case VirtualKeyboardKeyAction.Backspace:
          final text = discountController.text;
          final textSelection = discountController.selection;
          final selectionLength = textSelection.end - textSelection.start;

          // There is a selection
          if (selectionLength > 0) {
            final newText = text.replaceRange(
              textSelection.start,
              textSelection.end,
              '',
            );
            discountController.text = newText;
            discountController.selection = TextSelection.collapsed(
              offset: textSelection.start,
            );
            return;
          }

          // The cursor is at the beginning
          if (textSelection.start == 0) return;

          // Delete the previous character
          final previousCodeUnit = text.codeUnitAt(textSelection.start - 1);
          final offset = _isUtf16Surrogate(previousCodeUnit) ? 2 : 1;
          final newStart = textSelection.start - offset;
          final newText = text.replaceRange(
            newStart,
            textSelection.start,
            '',
          );
          discountController.text = newText;
          discountController.selection = TextSelection.collapsed(
            offset: newStart,
          );
          break;
        case VirtualKeyboardKeyAction.Space:
          // Skip space for numeric input
          break;
        case VirtualKeyboardKeyAction.Return:
          // Skip return for numeric input
          break;
        default:
      }
    }
    _calculateDiscount();
  }

  // Helper method for UTF-16 surrogate pair detection
  bool _isUtf16Surrogate(int value) {
    return value & 0xF800 == 0xD800;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6, // Reduced width
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.discount, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Apply Discount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Order total and discount input section
            Row(
              children: [
                // Left column with total and input field
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Total: RWF ${widget.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () {
                          setState(() {
                            showKeyboard = true;
                          });
                        },
                        child: TextField(
                          controller: discountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Discount %',
                            hintText: 'Tap to enter',
                            border: OutlineInputBorder(),
                            suffixText: '%',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          onChanged: (_) => _calculateDiscount(),
                          showCursor: true,
                          readOnly: true,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right column with summary box
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Discount:',
                              style: TextStyle(fontSize: 13),
                            ),
                            Text(
                              'RWF ${discountAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Final:',
                              style: TextStyle(fontSize: 13),
                            ),
                            Text(
                              'RWF ${finalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Compact virtual keyboard
            if (showKeyboard) ...[
              const SizedBox(height: 12),
              Container(
                height: 220, // Reduced height
                decoration: BoxDecoration(
                  color: const Color(0xFF162334),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: VirtualKeyboard(
                        height: 200,
                        textColor: Colors.white,
                        fontSize: 22, // Slightly smaller font
                        type: VirtualKeyboardType.Numeric,
                        postKeyPress: (key) => _onKeyboardPress(key),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.black26,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            icon: const Icon(
                              Icons.keyboard_hide,
                              color: Colors.white70,
                              size: 16,
                            ),
                            label: const Text(
                              'Hide Keyboard',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            onPressed: () => {},
                            // onPressed: () => setState(() {
                            //   showKeyboard = false;
                            // }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: discountPercentage > 0
                      ? () {
                          widget.onApplyDiscount(
                              discountPercentage, discountAmount);
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  child: const Text('Apply Discount'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
