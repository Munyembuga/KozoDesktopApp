// import 'package:flutter/widgets.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:intl/intl.dart';
// import 'package:kozo/models/order_detail_model.dart';
// import 'package:kozo/waiterScreen/waiter_delivery_details.dart';

// class WaiterKitchenReceiptServices {
//   static const double _fontSize = 8.0;
//   static const double _headerFontSize = 10.0;

//   static Future<void> printKitchenReceipt(
//       KitchenItemsResponse response, OrderDetail orderDetail,
//       [List<KitchenItem>? selectedItems]) async {
//     try {
//       final pdf = pw.Document();

//       // Use selected items if provided, otherwise use all items
//       final itemsToPrint = selectedItems ?? response.kitchenItems;

//       // Create a modified response with only selected items
//       final filteredResponse = KitchenItemsResponse(
//         success: response.success,
//         hasKitchenItems: itemsToPrint.isNotEmpty,
//         kitchenItems: itemsToPrint,
//       );

//       pdf.addPage(
//         pw.Page(
//           pageFormat: PdfPageFormat(160, double.infinity, marginAll: 8),
//           build: (pw.Context context) {
//             return _buildKitchenReceiptContent(filteredResponse, orderDetail);
//           },
//         ),
//       );

//       await Printing.layoutPdf(
//         onLayout: (PdfPageFormat format) async => pdf.save(),
//         name: 'Kitchen_Receipt_${orderDetail.orderNumber}',
//       );
//     } catch (e) {
//       throw Exception('Failed to print kitchen receipt: $e');
//     }
//   }

//   static pw.Widget _buildKitchenReceiptContent(
//       KitchenItemsResponse response, OrderDetail orderDetail) {
//     final now = DateTime.now();
//     final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         // Header
//         _buildHeader(),

//         pw.SizedBox(height: 8),
//         _buildDivider(),
//         pw.SizedBox(height: 6),

//         // Order Info
//         _buildKitchenInfoRow('Date:', dateFormatter.format(now)),
//         _buildKitchenInfoRow('Order:', orderDetail.orderNumber),
//         _buildKitchenInfoRow('Table:',
//             '${orderDetail.tableNumber} (${orderDetail.tableLocation})'),
//         _buildKitchenInfoRow('Waiter:', orderDetail.waiterName),
//         if (orderDetail.clientName != null)
//           _buildKitchenInfoRow('Client:', orderDetail.clientName!),

//         pw.SizedBox(height: 6),
//         _buildDivider(),
//         pw.SizedBox(height: 8),

//         // Kitchen Items Header
//         pw.Text(
//           'KITCHEN ITEMS:',
//           style: pw.TextStyle(
//             fontSize: 10,
//             fontWeight: pw.FontWeight.bold,
//           ),
//         ),
//         pw.SizedBox(height: 4),
//         _buildDivider(),
//         pw.SizedBox(height: 6),

//         // Kitchen Items
//         ..._buildKitchenItemsList(response),

//         pw.SizedBox(height: 8),
//         _buildDivider(),
//         // pw.SizedBox(height: 8),

//         // Footer
//         // pw.Column(
//         //   mainAxisAlignment: pw.MainAxisAlignment.start,
//         //   children: [
//         //     pw.Text('*** KITCHEN COPY ***',
//         //         style: pw.TextStyle(
//         //           fontSize: 10,
//         //           fontWeight: pw.FontWeight.bold,
//         //         ),
//         //         textAlign: pw.TextAlign.start),
//         //     pw.SizedBox(height: 4),
//         //     pw.Text(
//         //       'Please prepare the above items',
//         //       style: pw.TextStyle(fontSize: 8),
//         //     ),
//         //     pw.SizedBox(height: 8),
//         //     pw.Text(
//         //       'Time: ${DateFormat('HH:mm:ss').format(now)}',
//         //       style: pw.TextStyle(fontSize: 8),
//         //     ),
//         //   ],
//         // ),

//         pw.SizedBox(height: 16),
//         // _buildDivider(),
//         pw.SizedBox(height: 8),
//         pw.Center(
//           child: pw.Text(
//             'Thank you!',
//             style: pw.TextStyle(fontSize: 9),
//           ),
//         ),
//         pw.SizedBox(height: 8),
//         pw.Text(
//           'Powered by Giant Tec House',
//           style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
//           textAlign: pw.TextAlign.start,
//         ),
//       ],
//     );
//   }

//   static List<pw.Widget> _buildKitchenItemsList(
//     KitchenItemsResponse response,
//   ) {
//     // Group items by category
//     Map<String, List<KitchenItem>> itemsByCategory = {};
//     for (var item in response.kitchenItems) {
//       itemsByCategory.putIfAbsent(item.categoryName, () => []);
//       itemsByCategory[item.categoryName]!.add(item);
//     }

//     // Calculate total amount
//     double totalAmount = 0.0;
//     for (var item in response.kitchenItems) {
//       // Parse the totalPrice to a double
//       double price = double.tryParse(item.totalPrice.toString()) ?? 0.0;
//       totalAmount += price;
//     }

//     List<pw.Widget> widgets = [];

//     itemsByCategory.forEach((category, items) {
//       // Items in category
//       for (var item in items) {
//         widgets.add(
//           pw.Padding(
//             padding: pw.EdgeInsets.symmetric(vertical: 1),
//             child: pw.Column(
//               children: [
//                 pw.Row(
//                   children: [
//                     pw.Expanded(
//                       flex: 2,
//                       child: pw.Text(
//                         item.specificationName,
//                         style: pw.TextStyle(fontSize: _fontSize),
//                         textAlign: pw.TextAlign.start,
//                       ),
//                     ),
//                     pw.Expanded(
//                       flex: 1,
//                       child: pw.Text(
//                         '${item.quantity}',
//                         style: pw.TextStyle(fontSize: _fontSize),
//                         textAlign: pw.TextAlign.start,
//                       ),
//                     ),
//                     pw.Expanded(
//                       flex: 3,
//                       child: pw.Text(
//                         'RWF ${item.totalPrice}',
//                         style: pw.TextStyle(fontSize: _fontSize),
//                         textAlign: pw.TextAlign.start,
//                       ),
//                     ),

//                     // pw.Expanded(
//                     //   flex: 2,
//                     //   child: pw.Text(
//                     //     'item.totalPrice',
//                     //     style: pw.TextStyle(fontSize: _fontSize),
//                     //     textAlign: pw.TextAlign.left,
//                     //   ),
//                     // ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//         widgets.add(pw.SizedBox(height: 3));
//       }
//       widgets.add(pw.SizedBox(height: 6));
//     });

//     // Add total section
//     widgets.add(_buildDivider());
//     widgets.add(pw.SizedBox(height: 4));
//     widgets.add(
//       pw.Padding(
//         padding: pw.EdgeInsets.symmetric(vertical: 2),
//         child: pw.Row(
//           children: [
//             pw.Text(
//               'TOTAL:',
//               style: pw.TextStyle(
//                 fontSize: _headerFontSize,
//                 fontWeight: pw.FontWeight.bold,
//               ),
//             ),
//             pw.SizedBox(width: 15),
//             pw.Text(
//               'RWF ${totalAmount.toStringAsFixed(0)}',
//               style: pw.TextStyle(
//                 fontSize: _headerFontSize,
//                 fontWeight: pw.FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//     widgets.add(pw.SizedBox(height: 4));

//     return widgets;
//   }

//   static pw.Widget _buildHeader() {
//     return pw.Column(
//       children: [
//         pw.Text(
//           'KIGALI SPORT LOUNGE',
//           style: pw.TextStyle(
//             fontSize: _headerFontSize,
//             fontWeight: pw.FontWeight.bold,
//           ),
//           textAlign: pw.TextAlign.center,
//         ),
//         pw.SizedBox(height: 6),
//         pw.Text(
//           'Tel: +250792400606',
//           style: pw.TextStyle(fontSize: _fontSize),
//           textAlign: pw.TextAlign.center,
//         ),
//         pw.SizedBox(height: 6),
//         pw.Text(
//           'TIN: 120808520',
//           style: pw.TextStyle(fontSize: _fontSize),
//           textAlign: pw.TextAlign.center,
//         ),
//         pw.SizedBox(height: 6),
//         pw.Text(
//           'KITCHEN ORDER ',
//           style: pw.TextStyle(
//               fontSize: _headerFontSize, fontWeight: pw.FontWeight.bold),
//           textAlign: pw.TextAlign.center,
//         ),
//       ],
//     );
//   }

//   static pw.Widget _buildKitchenInfoRow(String label, String value) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.symmetric(vertical: 1),
//       child: pw.Row(
//         children: [
//           pw.Text(label, style: pw.TextStyle(fontSize: 8)),
//           pw.SizedBox(width: 5),
//           pw.Text(value, style: pw.TextStyle(fontSize: 8)),
//         ],
//       ),
//     );
//   }

//   static pw.Widget _buildDivider() {
//     return pw.Text(
//       '----------------------------------------------------',
//       style: pw.TextStyle(fontSize: 8),
//     );
//   }

//   static Future<void> previewKitchenReceipt(
//       KitchenItemsResponse response, OrderDetail orderDetail,
//       [List<KitchenItem>? selectedItems]) async {
//     try {
//       final pdf = pw.Document();

//       // Use selected items if provided, otherwise use all items
//       final itemsToPrint = selectedItems ?? response.kitchenItems;

//       // Create a modified response with only selected items
//       final filteredResponse = KitchenItemsResponse(
//         success: response.success,
//         hasKitchenItems: itemsToPrint.isNotEmpty,
//         kitchenItems: itemsToPrint,
//       );

//       pdf.addPage(
//         pw.Page(
//           pageFormat: PdfPageFormat.a4,
//           build: (pw.Context context) {
//             return pw.Center(
//               child: pw.Container(
//                 width: 280,
//                 padding: const pw.EdgeInsets.all(20),
//                 decoration: pw.BoxDecoration(
//                   border: pw.Border.all(color: PdfColors.grey400),
//                   borderRadius: pw.BorderRadius.circular(8),
//                 ),
//                 child:
//                     _buildKitchenReceiptContent(filteredResponse, orderDetail),
//               ),
//             );
//           },
//         ),
//       );

//       await Printing.layoutPdf(
//         onLayout: (PdfPageFormat format) async => pdf.save(),
//         name: 'Kitchen_Receipt_Preview_${orderDetail.orderNumber}',
//       );
//     } catch (e) {
//       throw Exception('Failed to preview kitchen receipt: $e');
//     }
//   }
// }
