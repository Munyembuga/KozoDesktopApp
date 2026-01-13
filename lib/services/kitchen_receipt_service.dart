import 'package:flutter/widgets.dart';
import 'package:kozo/utils/constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:kozo/models/order_detail_model.dart';
import 'package:kozo/cashierScreens/served_order_detail.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class KitchenReceiptService {
  static const double _fontSize = 12.0;
  static const double _headerFontSize = 25.0;

  // Load the logo image
  static Future<Uint8List> _loadLogoImage() async {
    try {
      // Try to load from assets
      return (await rootBundle.load('assets/logo.png')).buffer.asUint8List();
    } catch (e) {
      // If logo is not available, return an empty image
      print('Logo not found: $e');
      return Uint8List(0);
    }
  }

  static Future<bool> printKitchenReceipt(
      KitchenItemsResponse response, OrderDetail orderDetail,
      [List<KitchenItem>? selectedItems]) async {
    try {
      debugPrint(
          '🍳 Starting kitchen receipt print for order: ${orderDetail.orderNumber}');

      // List printers first so we can include the printer name in the PDF
      final printers = await Printing.listPrinters();
      debugPrint(
          '🖨️ Available printers: ${printers.map((p) => p.name).join(", ")}');
      debugPrint('🔍 Looking for kitchen printer: ${PrinterNames.kitchen}');

      final kitchenPrinter = printers
          .where((printer) =>
              printer.name.toUpperCase() == PrinterNames.kitchen.toUpperCase())
          .firstOrNull;

      final printerName = kitchenPrinter?.name ?? 'Not selected';

      final pdf = pw.Document();
      final logoImage = await _loadLogoImage();
      final hasLogo = logoImage.isNotEmpty;

      // Use selected items if provided, otherwise use all items
      final itemsToPrint = selectedItems ?? response.kitchenItems;
      debugPrint('📄 Preparing PDF for ${itemsToPrint.length} kitchen items');

      // Create a modified response with only selected items
      final filteredResponse = KitchenItemsResponse(
        success: response.success,
        hasKitchenItems: itemsToPrint.isNotEmpty,
        kitchenItems: itemsToPrint,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
              marginAll: 5),
          build: (pw.Context context) {
            return _buildKitchenReceiptContent(
              filteredResponse,
              orderDetail,
              hasLogo ? pw.MemoryImage(logoImage) : null,
              printerName,
            );
          },
        ),
      );

      // Find the kitchen printer and print to it directly
      // We already listed printers above and resolved `kitchenPrinter`.
      // Use that reference here to do the actual print.
      bool printSuccess = false;
      if (kitchenPrinter != null) {
        debugPrint('✅ Found kitchen printer: ${kitchenPrinter.name}');

        // Print first copy
        printSuccess = await Printing.directPrintPdf(
          printer: kitchenPrinter,
          onLayout: (_) => pdf.save(),
          name: 'Kitchen_${orderDetail.orderNumber}',
        );
        debugPrint(
            '🍳 Kitchen print (copy 1) result: ${printSuccess ? "SUCCESS" : "FAILED"} for printer: ${kitchenPrinter.name}');

        // Print second copy if first was successful
        if (printSuccess) {
          await Future.delayed(
              const Duration(milliseconds: 500)); // Small delay between prints
          final secondPrintSuccess = await Printing.directPrintPdf(
            printer: kitchenPrinter,
            onLayout: (_) => pdf.save(),
            name: 'Kitchen_${orderDetail.orderNumber}_copy2',
          );
          debugPrint(
              '🍳 Kitchen print (copy 2) result: ${secondPrintSuccess ? "SUCCESS" : "FAILED"} for printer: ${kitchenPrinter.name}');
        }
      } else {
        debugPrint('❌ Kitchen printer "${PrinterNames.kitchen}" not found');
        debugPrint(
            'Available printers: ${printers.map((p) => p.name).join(", ")}');

        // Fall back to printer selection dialog if kitchen printer not found
        printSuccess = await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Kitchen_${orderDetail.orderNumber}',
        );
        debugPrint(
            '📄 Used printer selection dialog instead. Result: ${printSuccess ? "SUCCESS" : "CANCELED"}');
      }

      // Update the print status of the items
      if (printSuccess) {
        await _updatePrintStatus(itemsToPrint, orderDetail.id);
        debugPrint(
            '✅ Kitchen receipt process completed for order: ${orderDetail.orderNumber}');
      }

      return printSuccess;
    } catch (e) {
      debugPrint('❌ Kitchen receipt print failed: $e');
      return false;
    }
  }

  // Helper method to update print status
  static Future<void> _updatePrintStatus(
      List<KitchenItem> items, int orderId) async {
    try {
      // Extract order item IDs - using id which is order_item_id instead of menu_item_id
      final List<int> itemIds = items.map((item) => item.id).toList();

      // Prepare request body
      final requestBody = {
        'itemIds': itemIds,
        'orderId': orderId.toString(),
      };

      // Make API call
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/Orders/updateItemPrint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to update print status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      } else {
        debugPrint(
            'Print status updated successfully for ${itemIds.length} items');
      }
    } catch (e) {
      debugPrint('Error updating print status: $e');
    }
  }

  static pw.Widget _buildKitchenReceiptContent(
      KitchenItemsResponse response, OrderDetail orderDetail,
      [pw.ImageProvider? logoImage, String? printerName]) {
    final now = DateTime.now();
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo (if available)
        if (logoImage != null) ...[
          pw.Center(
            child: pw.Container(
              height: 50,
              width: 120,
              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
            ),
          ),
        ],

        pw.SizedBox(height: 6),

        // Order Info
        _buildKitchenInfoRow('Date:', dateFormatter.format(now)),
        _buildKitchenInfoRow('Order:', orderDetail.orderNumber),
        _buildKitchenInfoRow('Waiter:', orderDetail.waiterName),
        // Printer name shown under waiter name when printing
        if (printerName != null) _buildKitchenInfoRow('Printer:', printerName),
        if (orderDetail.clientName != null)
          _buildKitchenInfoRow('Client:', orderDetail.clientName!),

        pw.SizedBox(height: 4),
        _buildDivider(),
        pw.SizedBox(height: 6),

        // Kitchen Items
        ..._buildKitchenItemsList(response),

        pw.SizedBox(height: 16),
        // _buildDivider(),

        pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              _buildBarInfoRowTable(
                'Table:',
                orderDetail.tableNumber.toString(),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 8),
      ],
    );
  }

  static List<pw.Widget> _buildKitchenItemsList(
    KitchenItemsResponse response,
  ) {
    // First, sort items by prepareStatus to ensure consistent order
    final sortedItems = List.from(response.kitchenItems);
    sortedItems
        .sort((a, b) => (a.prepareStatus ?? 0).compareTo(b.prepareStatus ?? 0));

    // Group items by preparation status
    Map<int, List<KitchenItem>> itemsByPrepStatus = {};
    for (var item in sortedItems) {
      final status = item.prepareStatus ?? 0;
      itemsByPrepStatus.putIfAbsent(status, () => []);
      itemsByPrepStatus[status]!.add(item);
    }

    List<pw.Widget> widgets = [];

    // Process each preparation status group
    final sortedKeys = itemsByPrepStatus.keys.toList();
    sortedKeys.sort(); // Sort the keys numerically

    for (var prepStatus in sortedKeys) {
      final items = itemsByPrepStatus[prepStatus]!;

      // Add course number display at the beginning of each group
      widgets.add(pw.Center(
        child: pw.Text(
          _getPrepStatusLabel(prepStatus),
          style: pw.TextStyle(
            fontSize: _fontSize + 1,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ));
      widgets.add(pw.SizedBox(height: 4));

      // Process items in this preparation status group
      for (var item in items) {
        // Add item details
        widgets.add(
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(vertical: 1),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        '${item.quantity}',
                        style: pw.TextStyle(fontSize: _fontSize),
                        textAlign: pw.TextAlign.start,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        item.specificationName,
                        style: pw.TextStyle(fontSize: _fontSize),
                        textAlign: pw.TextAlign.start,
                      ),
                    ),
                  ],
                ),
                // Add accompaniment information if available
                if (item.hasAccompaniment)
                  pw.Padding(
                    padding: pw.EdgeInsets.only(left: 8, top: 2),
                    child: pw.Text(
                      'with ${item.accompanimentName}',
                      style: pw.TextStyle(
                        fontSize: _fontSize - 1,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                // Add comment information if available
                if (item.hasComment)
                  pw.Padding(
                    padding: pw.EdgeInsets.only(left: 8, top: 2),
                    child: pw.Text(
                      'Note: ${item.comment}',
                      style: pw.TextStyle(
                        fontSize: _fontSize - 1,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                // Add pressure cooking information if available
                if (item.hasPressure)
                  pw.Padding(
                    padding: pw.EdgeInsets.only(left: 8, top: 2),
                    child: pw.Text(
                      'Temperature: ${item.pressureLevel ?? ''}',
                      style: pw.TextStyle(
                        fontSize: _fontSize - 1,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

        widgets.add(pw.SizedBox(height: 2));
      }

      // Add course number display before the divider
      widgets.add(pw.SizedBox(height: 6));
      widgets.add(_buildDivider());
      widgets.add(pw.SizedBox(height: 8));
    }

    return widgets;
  }

  // Helper function to get status label
  static String _getPrepStatusLabel(int status) {
    switch (status) {
      case 0:
        return "NO SPECIFIC ORDER";
      case 1:
        return "COURCE 1";
      case 2:
        return "COURCE 2";
      case 3:
        return "COURCE 3";
      case 4:
        return "COURCE 4";
      case 5:
        return "COURCE 5";
      case 6:
        return "COURCE 6";
      case 7:
        return "COURCE 7";
      default:
        return "COURCE : $status";
    }
  }

  static pw.Widget _buildBarInfoRowTable(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.Text(label,
              style:
                  pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 5),
          pw.Text(value,
              style:
                  pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildKitchenInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10)),
          pw.SizedBox(width: 5),
          pw.Text(value, style: pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildDivider() {
    return pw.Text(
      '----------------------------------------------------------',
      style: pw.TextStyle(fontSize: 8),
    );
  }

  static Future<void> previewKitchenReceipt(
      KitchenItemsResponse response, OrderDetail orderDetail,
      [List<KitchenItem>? selectedItems]) async {
    try {
      final pdf = pw.Document();
      final logoImage = await _loadLogoImage();
      final hasLogo = logoImage.isNotEmpty;

      // Use selected items if provided, otherwise use all items
      final itemsToPrint = selectedItems ?? response.kitchenItems;

      // Create a modified response with only selected items
      final filteredResponse = KitchenItemsResponse(
        success: response.success,
        hasKitchenItems: itemsToPrint.isNotEmpty,
        kitchenItems: itemsToPrint,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Container(
                width: 280,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: _buildKitchenReceiptContent(
                  filteredResponse,
                  orderDetail,
                  hasLogo ? pw.MemoryImage(logoImage) : null,
                  null,
                ),
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Kitchen_Receipt_Preview_${orderDetail.orderNumber}',
      );
    } catch (e) {
      throw Exception('Failed to preview kitchen receipt: $e');
    }
  }
}
