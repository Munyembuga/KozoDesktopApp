import 'package:flutter/material.dart';
import 'package:virtual_keyboard_multi_language/virtual_keyboard_multi_language.dart';
import '../../constants/app_constants.dart';
import '../../models/cart_item_model.dart';

class AddNoteDialog extends StatefulWidget {
  final CartItem cartItem;
  final Function(String) onSaveNote;

  const AddNoteDialog({
    Key? key,
    required this.cartItem,
    required this.onSaveNote,
  }) : super(key: key);

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  late TextEditingController _commentController;

  // Virtual keyboard state
  bool _showKeyboard = false;
  FocusNode _commentFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _commentController.text = widget.cartItem.comment ?? '';
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.comment, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Add Note for Specification',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 350,
                  height: _showKeyboard ? 160 : 280, // Adjusted heights
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item info
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.cartItem.itemName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              // const SizedBox(height: 2),
                              // Text(
                              //   widget.cartItem.categoryName,
                              //   style: TextStyle(
                              //     color: Colors.grey[600],
                              //     fontSize: 11,
                              //   ),
                              // ),
                              // if (widget.cartItem.price > 0) ...[
                              //   const SizedBox(height: 2),
                              //   Text(
                              //     'Price: RWF ${widget.cartItem.price.toStringAsFixed(2)}',
                              //     style: TextStyle(
                              //       color: AppColors.primary,
                              //       fontSize: 11,
                              //       fontWeight: FontWeight.w500,
                              //     ),
                              //   ),
                              // ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Comment input
                        Text(
                          'Special instructions:',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _commentController,
                          focusNode: _commentFocus,
                          keyboardType:
                              TextInputType.none, // Disable system keyboard
                          decoration: InputDecoration(
                            hintText:
                                'e.g., Extra spicy, No onions, Well done, etc.',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: AppColors.primary, width: 2),
                            ),
                          ),
                          maxLines: _showKeyboard ? 2 : 3,
                          maxLength: 200,
                          onTap: () {
                            setState(() {
                              _showKeyboard = true;
                            });
                          },
                        ),

                        // Hide keyboard button
                        if (_showKeyboard)
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showKeyboard = false;
                                });
                              },
                              icon: const Icon(Icons.keyboard_hide, size: 16),
                              label: const Text(
                                'Hide Keyboard',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),

                        // Examples (only show when keyboard is hidden)
                        if (!_showKeyboard)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Examples:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '• "Make it extra spicy"\n• "No onions please"\n• "Well done"',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  if (widget.cartItem.comment != null &&
                      widget.cartItem.comment!.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onSaveNote('');
                      },
                      child: Text(
                        'Remove Note',
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onSaveNote(_commentController.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Save Note'),
                  ),
                ],
              ),
            ),
          ),

          // Virtual keyboard
          if (_showKeyboard)
            SizedBox(
              height: 300,
              child: Container(
                color: const Color(0xFF162334), // background color
                child: VirtualKeyboard(
                  height: 300,
                  textColor: Colors.white,
                  fontSize: 25,
                  type: VirtualKeyboardType.Alphanumeric,
                  postKeyPress: _onKeyPress,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Handle virtual keyboard key press
  void _onKeyPress(VirtualKeyboardKey key) {
    if (key.keyType == VirtualKeyboardKeyType.String) {
      final text = _commentController.text;
      final textSelection = _commentController.selection;
      final newText = text.replaceRange(
        textSelection.start,
        textSelection.end,
        key.text ?? '',
      );
      final newSelection =
          TextSelection.collapsed(offset: textSelection.start + 1);
      _commentController.value = TextEditingValue(
        text: newText,
        selection: newSelection,
      );
    } else if (key.keyType == VirtualKeyboardKeyType.Action) {
      switch (key.action) {
        case VirtualKeyboardKeyAction.Backspace:
          final text = _commentController.text;
          final textSelection = _commentController.selection;
          final selectionLength = textSelection.end - textSelection.start;

          // There is a selection
          if (selectionLength > 0) {
            final newText = text.replaceRange(
              textSelection.start,
              textSelection.end,
              '',
            );
            _commentController.text = newText;
            _commentController.selection = TextSelection.collapsed(
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
          _commentController.text = newText;
          _commentController.selection = TextSelection.collapsed(
            offset: newStart,
          );
          break;
        case VirtualKeyboardKeyAction.Space:
          final text = _commentController.text;
          final textSelection = _commentController.selection;
          final newText = text.replaceRange(
            textSelection.start,
            textSelection.end,
            ' ',
          );
          _commentController.text = newText;
          _commentController.selection = TextSelection.collapsed(
            offset: textSelection.start + 1,
          );
          break;
        case VirtualKeyboardKeyAction.Return:
          // Add a line break for comments
          final text = _commentController.text;
          final textSelection = _commentController.selection;
          final newText = text.replaceRange(
            textSelection.start,
            textSelection.end,
            '\n',
          );
          _commentController.text = newText;
          _commentController.selection = TextSelection.collapsed(
            offset: textSelection.start + 1,
          );
          break;
        default:
      }
    }
  }

  // Helper method for UTF-16 surrogate pair detection
  bool _isUtf16Surrogate(int value) {
    return value & 0xF800 == 0xD800;
  }
}
