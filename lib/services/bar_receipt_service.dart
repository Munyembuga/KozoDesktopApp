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

class BarReceiptService {
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

  static Future<bool> printBarReceipt(
      KitchenItemsResponse response, OrderDetail orderDetail,
      [List<KitchenItem>? selectedItems]) async {
    try {
      debugPrint(
          '🍹 Starting bar receipt print for order: ${orderDetail.orderNumber}');

      // List printers first so the PDF can show the selected printer name
      final printers = await Printing.listPrinters();
      debugPrint(
          '🖨️ Available printers: ${printers.map((p) => p.name).join(", ")}');
      debugPrint('🔍 Looking for bar printer: ${PrinterNames.bar}');

      final barPrinter = printers
          .where((printer) =>
              printer.name.toUpperCase() == PrinterNames.bar.toUpperCase())
          .firstOrNull;

      final printerName = barPrinter?.name ?? 'Not selected';

      final pdf = pw.Document();
      final logoImage = await _loadLogoImage();
      final hasLogo = logoImage.isNotEmpty;

      // Use selected items if provided, otherwise use all items
      final itemsToPrint = selectedItems ?? response.kitchenItems;
      debugPrint('📄 Preparing PDF for ${itemsToPrint.length} bar items');

      // Create a modified response with only selected items
      final filteredResponse = KitchenItemsResponse(
        success: response.success,
        hasKitchenItems: itemsToPrint.isNotEmpty,
        kitchenItems: itemsToPrint,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(226.77, double.infinity, marginAll: 8),
          build: (pw.Context context) {
            return _buildBarReceiptContent(
              filteredResponse,
              orderDetail,
              hasLogo ? pw.MemoryImage(logoImage) : null,
              printerName,
            );
          },
        ),
      );

      // Find the bar printer and print to it directly
      // We already listed printers above and resolved `barPrinter`.
      bool printSuccess = false;
      if (barPrinter != null) {
        debugPrint('✅ Found bar printer: ${barPrinter.name}');
        printSuccess = await Printing.directPrintPdf(
          printer: barPrinter,
          onLayout: (_) => pdf.save(),
          name: 'Bar_${orderDetail.orderNumber}',
        );
        debugPrint(
            '✅ Bar print result: ${printSuccess ? "SUCCESS" : "FAILED"} for printer: ${barPrinter.name}');
      } else {
        debugPrint('⚠️ Bar printer "${PrinterNames.bar}" not found');
        debugPrint(
            'Available printers: ${printers.map((p) => p.name).join(", ")}');

        // Fall back to printer selection dialog if bar printer not found
        printSuccess = await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Bar_${orderDetail.orderNumber}',
        );
        debugPrint(
            '📄 Used printer selection dialog instead. Result: ${printSuccess ? "SUCCESS" : "CANCELED"}');
      }

      // Update the print status of the items
      if (printSuccess) {
        await _updatePrintStatus(itemsToPrint, orderDetail.id);
        debugPrint(
            '✅ Bar receipt process completed for order: ${orderDetail.orderNumber}');
      }

      return printSuccess;
    } catch (e) {
      debugPrint('❌ Bar receipt print failed: $e');
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
        print('Failed to update print status: ${response.statusCode}');
        print('Response body: ${response.body}');
      } else {
        print('Print status updated successfully for ${itemIds.length} items');
      }
    } catch (e) {
      print('Error updating print status: $e');
    }
  }

  static pw.Widget _buildBarReceiptContent(
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
          pw.SizedBox(height: 10),
        ],

        // Order Info
        _buildBarInfoRow('Date:', dateFormatter.format(now)),
        _buildBarInfoRow('Order:', orderDetail.orderNumber),

        _buildBarInfoRow('Waiter:', orderDetail.waiterName),
        // Printer name (when known) shown under waiter name
        if (printerName != null) _buildBarInfoRow('Printer:', printerName),
        if (orderDetail.clientName != null)
          _buildBarInfoRow('Client:', orderDetail.clientName!),

        pw.SizedBox(height: 4),
        _buildDivider(),
        pw.SizedBox(height: 6),

        // Bar Items
        ..._buildBarItemsList(response),

        pw.SizedBox(height: 8),

        pw.SizedBox(height: 16),
        pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              _buildBarInfoRowTable(
                'Table:',
                orderDetail.tableNumber.toString(),
              ),
              pw.SizedBox(height: 8), // spacing between rows
              pw.Text(
                'Enjoy your drinks!',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.blue,
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 8),
      ],
    );
  }

  static List<pw.Widget> _buildBarItemsList(
    KitchenItemsResponse response,
  ) {
    // First, sort items by prepare_status to ensure consistent order
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
                        style: pw.TextStyle(
                          fontSize: _fontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
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
                        color: PdfColors.blue,
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
                        color: PdfColors.orange,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

        widgets.add(pw.SizedBox(height: 2));
      }

      // Add a bigger divider between preparation status groups
      widgets.add(pw.SizedBox(height: 6));
      widgets.add(_buildDivider());
      widgets.add(pw.SizedBox(height: 8));
    }

    return widgets;
  }

  static pw.Widget _buildBarInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8)),
          pw.SizedBox(width: 5),
          pw.Text(value, style: pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
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

  static pw.Widget _buildDivider() {
    return pw.Text(
      '----------------------------------------------------',
      style: pw.TextStyle(fontSize: 8, color: PdfColors.blue),
    );
  }

  static Future<bool> previewBarReceipt(
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
                  border: pw.Border.all(color: PdfColors.blue),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: _buildBarReceiptContent(
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

      final result = await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Bar_Receipt_Preview_${orderDetail.orderNumber}',
      );
      return result;
    } catch (e) {
      debugPrint('❌ Failed to preview bar receipt: $e');
      return false;
    }
  }

  // Helper function to get status label
  static String _getPrepStatusLabel(int status) {
    switch (status) {
      case 0:
        return "NO SPECIFIC ORDER";
      case 1:
        return "PREPARE FIRST";
      case 2:
        return "PREPARE SECOND";
      case 3:
        return "PREPARE THIRD";
      case 4:
        return "PREPARE FOURTH";
      case 5:
        return "PREPARE FIFTH";
      case 6:
        return "PREPARE SIXTH";
      case 7:
        return "PREPARE LAST";
      default:
        return "PREPARATION ORDER: $status";
    }
  }
}
