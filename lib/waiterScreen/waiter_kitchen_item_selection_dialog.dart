// import 'package:flutter/material.dart';
// import 'waiter_delivery_details.dart';

// class WaiterKitchenItemSelectionDialog extends StatefulWidget {
//   final KitchenItemsResponse response;
//   final Function(List<KitchenItem>) onItemsSelected;

//   const WaiterKitchenItemSelectionDialog({
//     Key? key,
//     required this.response,
//     required this.onItemsSelected,
//   }) : super(key: key);

//   @override
//   State<WaiterKitchenItemSelectionDialog> createState() =>
//       _WaiterKitchenItemSelectionDialogState();
// }

// class _WaiterKitchenItemSelectionDialogState
//     extends State<WaiterKitchenItemSelectionDialog> {
//   // Use a more specific identifier to track each item independently
//   late Map<String, bool> selectedItems;

//   @override
//   void initState() {
//     super.initState();
//     // Initialize with all items selected by default
//     // Use a compound key that uniquely identifies each item
//     selectedItems = {
//       for (var item in widget.response.kitchenItems)
//         _getUniqueItemKey(item): true
//     };
//   }

//   // Generate a unique key for each item
//   String _getUniqueItemKey(KitchenItem item) {
//     // Create a compound key using all relevant properties to ensure uniqueness
//     return '${item.itemId}_${item.specificationId}_${item.quantity}_${item.totalPrice}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         width: 500,
//         constraints: const BoxConstraints(maxHeight: 600),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Select Kitchen Items to Print',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () => Navigator.of(context).pop(),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             _buildSelectionControls(),
//             const SizedBox(height: 16),
//             const Divider(),
//             Flexible(
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 itemCount: widget.response.kitchenItems.length,
//                 itemBuilder: (context, index) {
//                   final item = widget.response.kitchenItems[index];
//                   return _buildItemCheckbox(item, index);
//                 },
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 OutlinedButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: const Text('Cancel'),
//                 ),
//                 const SizedBox(width: 12),
//                 ElevatedButton(
//                   onPressed: () {
//                     final List<KitchenItem> selectedKitchenItems = widget
//                         .response.kitchenItems
//                         .where((item) =>
//                             selectedItems[_getUniqueItemKey(item)] == true)
//                         .toList();
//                     widget.onItemsSelected(selectedKitchenItems);
//                     Navigator.of(context).pop();
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                   ),
//                   child: const Text('Print Selected Items'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSelectionControls() {
//     return Row(
//       children: [
//         TextButton.icon(
//           onPressed: () {
//             setState(() {
//               for (var item in widget.response.kitchenItems) {
//                 selectedItems[_getUniqueItemKey(item)] = true;
//               }
//             });
//           },
//           icon: const Icon(Icons.check_box, size: 18),
//           label: const Text('Select All'),
//         ),
//         const SizedBox(width: 12),
//         TextButton.icon(
//           onPressed: () {
//             setState(() {
//               for (var item in widget.response.kitchenItems) {
//                 selectedItems[_getUniqueItemKey(item)] = false;
//               }
//             });
//           },
//           icon: const Icon(Icons.check_box_outline_blank, size: 18),
//           label: const Text('Deselect All'),
//         ),
//       ],
//     );
//   }

//   Widget _buildItemCheckbox(KitchenItem item, int index) {
//     final itemKey = _getUniqueItemKey(item);

//     return CheckboxListTile(
//       title: Row(
//         children: [
//           Text(
//             item.itemName,
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//           // Display index to differentiate between items with same spec
//           const SizedBox(width: 8),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//             decoration: BoxDecoration(
//               color: Colors.grey[200],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(
//               '#${index + 1}',
//               style: TextStyle(
//                 color: Colors.grey[700],
//                 fontSize: 12,
//               ),
//             ),
//           ),
//         ],
//       ),
//       subtitle: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Specification: ${item.specificationName}'),
//           Text('Quantity: ${item.quantity}'),
//           Text('Total: RWF ${item.totalPrice}'),
//         ],
//       ),
//       secondary: CircleAvatar(
//         backgroundColor: Colors.orange.withOpacity(0.2),
//         foregroundColor: Colors.orange,
//         child: Text('${item.quantity}'),
//       ),
//       value: selectedItems[itemKey] ?? true,
//       onChanged: (bool? value) {
//         setState(() {
//           selectedItems[itemKey] = value ?? false;
//         });
//       },
//     );
//   }
// }
