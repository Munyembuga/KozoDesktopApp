import 'package:flutter/widgets.dart';
import 'package:kozo/utils/constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:kozo/models/order_detail_model.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class ReturnedItem {
  final String itemName;
  final int returnQuantity;
  final double returnValue;
  final String returnReason;
  final int menuItemId;

  ReturnedItem({
    required this.itemName,
    required this.returnQuantity,
    required this.returnValue,
    required this.returnReason,
    required this.menuItemId,
  });

  factory ReturnedItem.fromJson(Map<String, dynamic> json) {
    return ReturnedItem(
      itemName: json['item_name'] as String,
      returnQuantity: int.parse(json['return_quantity'].toString()),
      returnValue: double.parse(json['return_value'].toString()),
      returnReason: json['return_reason'] as String,
      menuItemId: int.parse(json['menu_item_id'].toString()),
    );
  }
}

class ReturnReceiptService {
  static const double _fontSize = 12.0;
  static const double _headerFontSize = 20.0;

  // Load the logo image
  static Future<Uint8List> _loadLogoImage() async {
    try {
      return (await rootBundle.load('assets/logo.png')).buffer.asUint8List();
    } catch (e) {
      debugPrint('Logo not found: $e');
      return Uint8List(0);
    }
  }

  static Future<bool> printKitchenReturnReceipt(
    List<ReturnedItem> returnedItems,
    OrderDetail orderDetail,
  ) async {
    try {
      debugPrint(
          '🍳 Starting kitchen return receipt print for order: ${orderDetail.orderNumber}');

      final pdf = pw.Document();
      final logoImage = await _loadLogoImage();
      final hasLogo = logoImage.isNotEmpty;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
              marginAll: 5),
          build: (pw.Context context) {
            return _buildKitchenReturnReceiptContent(
              returnedItems,
              orderDetail,
              hasLogo ? pw.MemoryImage(logoImage) : null,
            );
          },
        ),
      );

      // Find the kitchen printer
      final printers = await Printing.listPrinters();
      debugPrint(
          '🖨️ Available printers: ${printers.map((p) => p.name).join(", ")}');
      debugPrint('🔍 Looking for kitchen printer: ${PrinterNames.kitchen}');

      final kitchenPrinter = printers
          .where((printer) =>
              printer.name.toUpperCase() == PrinterNames.kitchen.toUpperCase())
          .firstOrNull;

      bool printSuccess = false;
      if (kitchenPrinter != null) {
        debugPrint('✅ Found kitchen printer: ${kitchenPrinter.name}');
        printSuccess = await Printing.directPrintPdf(
          printer: kitchenPrinter,
          onLayout: (_) => pdf.save(),
          name: 'Kitchen_Return_${orderDetail.orderNumber}',
        );
        debugPrint(
            '🍳 Kitchen return print result: ${printSuccess ? "SUCCESS" : "FAILED"}');
      } else {
        debugPrint('❌ Kitchen printer "${PrinterNames.kitchen}" not found');
        // Fall back to printer selection dialog
        printSuccess = await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Kitchen_Return_${orderDetail.orderNumber}',
        );
      }

      return printSuccess;
    } catch (e) {
      debugPrint('❌ Kitchen return receipt print failed: $e');
      return false;
    }
  }

  static pw.Widget _buildKitchenReturnReceiptContent(
      List<ReturnedItem> returnedItems, OrderDetail orderDetail,
      [pw.ImageProvider? logoImage]) {
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

        // Header
        // pw.Center(
        //   child: pw.Text(
        //     'KITCHEN RETURN',
        //     style: pw.TextStyle(
        //       fontSize: _headerFontSize,
        //       fontWeight: pw.FontWeight.bold,
        //     ),
        //   ),
        // ),

        // pw.SizedBox(height: 6),

        // Order Info
        _buildInfoRow('Date:', dateFormatter.format(now)),
        _buildInfoRow('Order:', orderDetail.orderNumber),
        _buildInfoRow('Waiter:', orderDetail.waiterName),
        if (orderDetail.clientName != null)
          _buildInfoRow('Client:', orderDetail.clientName!),
        _buildInfoRow('Table:', orderDetail.tableNumber.toString()),

        pw.SizedBox(height: 4),
        _buildDivider(),
        pw.SizedBox(height: 6),

        // Title for cancelled items
        pw.Text(
          'Cancelled Items:',
          style: pw.TextStyle(
            fontSize: _fontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),

        // Returned Items
        ...returnedItems.map((item) => _buildReturnedItemRow(item)),

        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildReturnedItemRow(ReturnedItem item) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 1,
              child: pw.Text(
                '${item.returnQuantity}x',
                style: pw.TextStyle(
                  fontSize: _fontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                item.itemName,
                style: pw.TextStyle(
                  fontSize: _fontSize,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 12),
          child: pw.Text(
            'Reason: ${_formatReason(item.returnReason)}',
            style: pw.TextStyle(
              fontSize: _fontSize - 2,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
        pw.SizedBox(height: 1),
        _buildDivider(),
        pw.SizedBox(height: 1),
      ],
    );
  }

  static Future<bool> printBarReturnReceipt(
    List<ReturnedItem> returnedItems,
    OrderDetail orderDetail,
  ) async {
    try {
      debugPrint(
          '🍸 Starting bar return receipt print for order: ${orderDetail.orderNumber}');

      final pdf = pw.Document();
      final logoImage = await _loadLogoImage();
      final hasLogo = logoImage.isNotEmpty;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
              marginAll: 5),
          build: (pw.Context context) {
            return _buildBarReturnReceiptContent(
              returnedItems,
              orderDetail,
              hasLogo ? pw.MemoryImage(logoImage) : null,
            );
          },
        ),
      );

      // Find the bar printer
      final printers = await Printing.listPrinters();
      debugPrint(
          '🖨️ Available printers: ${printers.map((p) => p.name).join(", ")}');
      debugPrint('🔍 Looking for bar printer: ${PrinterNames.bar}');

      final barPrinter = printers
          .where((printer) =>
              printer.name.toUpperCase() == PrinterNames.bar.toUpperCase())
          .firstOrNull;

      bool printSuccess = false;
      if (barPrinter != null) {
        debugPrint('✅ Found bar printer: ${barPrinter.name}');
        printSuccess = await Printing.directPrintPdf(
          printer: barPrinter,
          onLayout: (_) => pdf.save(),
          name: 'Bar_Return_${orderDetail.orderNumber}',
        );
        debugPrint(
            '🍸 Bar return print result: ${printSuccess ? "SUCCESS" : "FAILED"}');
      } else {
        debugPrint('❌ Bar printer "${PrinterNames.bar}" not found');
        // Fall back to printer selection dialog
        printSuccess = await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Bar_Return_${orderDetail.orderNumber}',
        );
      }

      return printSuccess;
    } catch (e) {
      debugPrint('❌ Bar return receipt print failed: $e');
      return false;
    }
  }

  static pw.Widget _buildBarReturnReceiptContent(
      List<ReturnedItem> returnedItems, OrderDetail orderDetail,
      [pw.ImageProvider? logoImage]) {
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
        _buildInfoRow('Date:', dateFormatter.format(now)),
        _buildInfoRow('Order:', orderDetail.orderNumber),
        _buildInfoRow('Waiter:', orderDetail.waiterName),
        if (orderDetail.clientName != null)
          _buildInfoRow('Client:', orderDetail.clientName!),
        _buildInfoRow('Table:', orderDetail.tableNumber.toString()),

        pw.SizedBox(height: 4),
        _buildDivider(),
        pw.SizedBox(height: 6),

        // Title for cancelled items
        pw.Text(
          'Cancelled Items:',
          style: pw.TextStyle(
            fontSize: _fontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),

        // Returned Items
        ...returnedItems.map((item) => _buildReturnedItemRow(item)),

        pw.SizedBox(height: 8),
      ],
    );
  }

  static String _formatReason(String reason) {
    switch (reason) {
      case 'customer_request':
        return 'Customer Request';
      case 'wrong_item':
        return 'Wrong Item';
      case 'quality_issue':
        return 'Quality Issue';
      case 'kitchen_error':
        return 'Kitchen Error';
      case 'damaged_item':
        return 'Damaged Item';
      default:
        return reason;
    }
  }

  static pw.Widget _buildInfoRow(String label, String value) {
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
      '----------------------------------------------------',
      style: pw.TextStyle(fontSize: 8),
    );
  }

  static Future<bool> previewKitchenReturnReceipt(
    List<ReturnedItem> returnedItems,
    OrderDetail orderDetail,
  ) async {
    try {
      final pdf = pw.Document();
      final logoImage = await _loadLogoImage();
      final hasLogo = logoImage.isNotEmpty;

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
                child: _buildKitchenReturnReceiptContent(
                  returnedItems,
                  orderDetail,
                  hasLogo ? pw.MemoryImage(logoImage) : null,
                ),
              ),
            );
          },
        ),
      );

      return await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Kitchen_Return_Preview_${orderDetail.orderNumber}',
      );
    } catch (e) {
      debugPrint('❌ Failed to preview kitchen return receipt: $e');
      return false;
    }
  }

  static Future<bool> previewBarReturnReceipt(
    List<ReturnedItem> returnedItems,
    OrderDetail orderDetail,
  ) async {
    try {
      final pdf = pw.Document();
      final logoImage = await _loadLogoImage();
      final hasLogo = logoImage.isNotEmpty;

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
                child: _buildBarReturnReceiptContent(
                  returnedItems,
                  orderDetail,
                  hasLogo ? pw.MemoryImage(logoImage) : null,
                ),
              ),
            );
          },
        ),
      );

      return await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Bar_Return_Preview_${orderDetail.orderNumber}',
      );
    } catch (e) {
      debugPrint('❌ Failed to preview bar return receipt: $e');
      return false;
    }
  }
}
