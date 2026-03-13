import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_detail_model.dart';
import 'package:kozo/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:kozo/services/auth_service.dart';
import 'package:kozo/models/user_model.dart';

class BillReceiptServices {
  // Constants for consistent styling
  static const double _pageWidth = 226.77;
  static const double _fontSize = 8.0;
  static const double _headerFontSize = 40.0;
  static const double _titleFontSize = 12.0;
  static const double _smallFontSize = 8.0;
  static const double _padding = 1.0;

  static Future<void> printReceipt(OrderDetail orderDetail) async {
    try {
      // List printers first so the PDF can include the printer name
      final printers = await Printing.listPrinters();
      final receiptPrinter = printers
          .where((printer) =>
              printer.name.toLowerCase() == PrinterNames.receipt.toLowerCase())
          .firstOrNull;

      final printerName = receiptPrinter?.name ?? 'Not selected';

      final pdf = pw.Document();
      final logoImage = await _loadLogoImage();
      final hasLogo = logoImage.isNotEmpty;

      // Fetch logged-in user for header/footer info
      final User? user = await AuthService.getCurrentUser();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(_pageWidth, double.infinity, marginAll: 8),
          build: (pw.Context context) {
            return _buildReceiptContent(
              orderDetail,
              hasLogo ? pw.MemoryImage(logoImage) : null,
              user, // pass user
              printerName,
            );
          },
        ),
      );

      // Use the previously resolved receiptPrinter (if any) to print
      if (receiptPrinter != null) {
        // Print directly to the receipt printer
        await Printing.directPrintPdf(
          printer: receiptPrinter,
          onLayout: (_) => pdf.save(),
          name: 'Receipt_${orderDetail.orderNumber}',
        );
        debugPrint('Printed directly to LOCAL printer: ${receiptPrinter.name}');
      } else {
        // Fall back to printer selection dialog if receipt printer not found
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Receipt_${orderDetail.orderNumber}',
        );
        debugPrint(
            'Available printers: ${printers.map((p) => p.name).join(", ")}');
        debugPrint('Looking for printer: ${PrinterNames.receipt}');
        debugPrint('LOCAL printer not found, skipping print');
      }
    } catch (e) {
      throw Exception('Failed to print receipt: $e');
    }
  }

  static pw.Widget _buildReceiptContent(OrderDetail orderDetail,
      [pw.ImageProvider? logoImage, User? user, String? printerName]) {
    return pw.Center(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.start,
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
            pw.SizedBox(height: 8),
          ],

          // Business Header
          _buildHeader(user),
          pw.SizedBox(height: 8),

          // Divider
          pw.SizedBox(height: 4),

          // Order Information Section
          _buildOrderInfo(orderDetail, user, printerName),
          pw.SizedBox(height: 4),

          // Items Section
          ..._buildItemsList(orderDetail),

          // Totals Section
          pw.SizedBox(height: 4),
          _buildTotalsSection(orderDetail),
          pw.SizedBox(height: 4),

          // Payment Section (if paid)
          if (orderDetail.isPaid) ...[
            pw.SizedBox(height: 8),
            _buildPaymentSection(orderDetail),
          ],

          // Footer
          pw.SizedBox(height: 12),
          _buildFooter(orderDetail, user),
        ],
      ),
    );
  }

  static pw.Widget _buildHeader(User? user) {
    final String location = (user?.location?.trim().isNotEmpty ?? false)
        ? user!.location!.trim()
        : '17 KN 14 Ave, Kigali, Rwanda';
    final String telephone = (user?.telephone?.trim().isNotEmpty ?? false)
        ? user!.telephone!.trim()
        : '+250798979779';

    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // pw.Text(
        //   'KOZO',
        //   style: pw.TextStyle(
        //     fontSize: _headerFontSize,
        //     fontWeight: pw.FontWeight.bold,
        //   ),
        //   textAlign: pw.TextAlign.center,
        // ),
        // pw.SizedBox(height: 6),

        // pw.SizedBox(height: 6),
        pw.Text(
          location,
          style: pw.TextStyle(fontSize: _fontSize),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Tel: $telephone',
          style: pw.TextStyle(fontSize: _fontSize),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 6),
      ],
    );
  }

  static pw.Widget _buildOrderInfo(OrderDetail orderDetail, User? user,
      [String? printerName]) {
    return pw.Column(
      children: [
        _buildInfoRow('Opened By ', orderDetail.waiterName),
        // Printer name displayed under waiter when available
        if (printerName != null) _buildInfoRow('Printer ', printerName),
        _buildInfoRow('Printed By ',
            user != null ? user.fullName : orderDetail.waiterName),
        pw.SizedBox(height: 6),
        _buildInfoRowBold(
          'Date',
          orderDetail.createdAt,
        ),
        pw.SizedBox(height: 6),
        _buildInfoRowBold(
          'Table ',
          orderDetail.tableNumber,
        ),
        //display covers if available
        if (orderDetail.covers != null)
          _buildInfoRowBold(
            'Covers ',
            orderDetail.covers.toString(),
          ),
        _buildInfoRow('Receipt Number ', orderDetail.orderNumber),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        // mainAxisAlignment: pw.MainAxisAlignment.,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9)),
          pw.SizedBox(width: 5),
          pw.Text(value, style: pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRowBold(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        // mainAxisAlignment: pw.MainAxisAlignment.,
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 5),
          pw.Text(value, style: pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  // static pw.Widget _buildItemsHeader() {
  //   return pw.Row(
  //     // mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  //     children: [
  //       pw.Expanded(
  //         flex: 2,
  //         child: pw.Text(
  //           'Item',
  //           style: pw.TextStyle(
  //             fontSize: 9,
  //             fontWeight: pw.FontWeight.bold,
  //           ),
  //           textAlign: pw.TextAlign.start,
  //         ),
  //       ),
  //       pw.SizedBox(width: 1),
  //       pw.Expanded(
  //         flex: 1,
  //         child: pw.Text(
  //           'Qty',
  //           style: pw.TextStyle(
  //             fontSize: 9,
  //             fontWeight: pw.FontWeight.bold,
  //           ),
  //           textAlign: pw.TextAlign.start,
  //         ),
  //       ),
  //       pw.SizedBox(width: 1),
  //       pw.Expanded(
  //         flex: 2,
  //         child: pw.Text(
  //           'Total',
  //           style: pw.TextStyle(
  //             fontSize: 9,
  //             fontWeight: pw.FontWeight.bold,
  //           ),
  //           textAlign: pw.TextAlign.start,
  //         ),
  //       ),
  //       pw.SizedBox(width: 1),
  //     ],
  //   );
  // }

  static List<pw.Widget> _buildItemsList(OrderDetail orderDetail) {
    // Group items by name and specification ID (more reliable than name)
    final Map<String, Map<String, dynamic>> groupedItems = {};

    for (var item in orderDetail.items) {
      // Use menuItemId and specificationId for more accurate grouping
      final key = '${item.menuItemId}__${item.specificationId}';

      final existingItem = groupedItems[key];
      if (existingItem != null) {
        // Update existing group
        existingItem['quantity'] =
            (existingItem['quantity'] as int) + item.quantity;

        // Parse and update total price
        double currentTotal =
            _parsePrice(existingItem['formattedTotalPrice'] as String);
        double itemTotal = _parsePrice(item.formattedTotalPrice);
        existingItem['formattedTotalPrice'] =
            _formatPrice(currentTotal + itemTotal);
      } else {
        // Create new group
        groupedItems[key] = {
          'itemName': item.itemName,
          'quantity': item.quantity,
          'specificationName': item.specificationName,
          'accompanimentName': item.accompanimentName,
          'formattedTotalPrice': item.formattedTotalPrice,
        };
      }
    }

    // Convert grouped items to widgets list
    List<pw.Widget> itemWidgets =
        groupedItems.values.map((item) => _buildOrderItem(item)).toList();

    // Add service fee as a line item if available
    if (orderDetail.serviceFee != null &&
        double.parse(orderDetail.serviceFee!) > 0) {
      itemWidgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  '1', // Always quantity 1 for service fee
                  style: pw.TextStyle(fontSize: _fontSize),
                  textAlign: pw.TextAlign.start,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Service Fee',
                  style: pw.TextStyle(fontSize: _fontSize),
                  textAlign: pw.TextAlign.start,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  orderDetail.formattedServiceFee,
                  style: pw.TextStyle(fontSize: _fontSize),
                  textAlign: pw.TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return itemWidgets;
  }

  // Helper method to parse price from formatted string
  static double _parsePrice(String formattedPrice) {
    // Debug the input string
    print('Parsing price: $formattedPrice');

    // Remove currency symbol (case-insensitive), commas, and trim whitespace
    String numericString = formattedPrice
        .replaceAll(RegExp(r'RWF|Rwf', caseSensitive: false), '')
        .replaceAll(',', '')
        .trim();

    // Try to parse and handle failure
    double? result = double.tryParse(numericString);
    if (result == null) {
      print('Failed to parse price from: "$numericString"');
      return 0.0;
    }

    return result;
  }

  // Helper method to format price back to string
  static String _formatPrice(double price) {
    return 'RWF ${price.toInt()}';
  }

  static pw.Widget _buildOrderItem(Map<String, dynamic> item) {
    // Access properties safely with null checks
    final String itemName = item['itemName'] as String? ?? '';
    final int quantity = item['quantity'] as int? ?? 0;
    final String totalPrice = item['formattedTotalPrice'] as String? ?? '0 Rwf';
    final String specName = item['specificationName'] as String? ?? '';
    final String? accompanimentName = item['accompanimentName'] as String?;

    // Use specification name if available, otherwise fallback to item name
    final String displayName = (specName.isNotEmpty) ? specName : itemName;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  '$quantity',
                  style: pw.TextStyle(fontSize: _fontSize),
                  textAlign: pw.TextAlign.start,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  displayName, // Use specification name instead of item name
                  style: pw.TextStyle(fontSize: _fontSize),
                  textAlign: pw.TextAlign.start,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  totalPrice,
                  style: pw.TextStyle(fontSize: _fontSize),
                  textAlign: pw.TextAlign.left,
                ),
              ),
            ],
          ),
          if (accompanimentName != null && accompanimentName.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 4, top: 1),
              child: pw.Text(
                'with $accompanimentName',
                style: pw.TextStyle(
                  fontSize: _smallFontSize,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalsSection(OrderDetail orderDetail) {
    // Calculate subtotal = order total + service fee
    double subtotal = double.parse(orderDetail.total);
    if (orderDetail.serviceFee != null &&
        double.parse(orderDetail.serviceFee!) > 0) {
      subtotal += double.parse(orderDetail.serviceFee!);
    }

    // Format the subtotal
    String formattedSubtotal = 'RWF ${subtotal.toInt()}';

    return pw.Column(
      children: [
        // Always show subtotal first (now includes service fee)
        _buildTotalRow('Subtotal:', formattedSubtotal, false),

        // Show discount if greater than 0
        if (double.parse(orderDetail.discount) > 0) ...[
          _buildTotalRow(
              'Discount:', '-${orderDetail.formattedDiscount}', false),
        ],

        // Note: Service Fee is now shown in the items list, so we don't need to repeat it here

        pw.SizedBox(height: 2),

        // Show Grand Total if different from total, otherwise show total
        if (orderDetail.grandTotal != null &&
            double.parse(orderDetail.grandTotal!) !=
                double.parse(orderDetail.total)) ...[
          _buildTotalRow('TOTAL:', orderDetail.formattedGrandTotal, true),
        ] else ...[
          _buildTotalRow('TOTAL:', orderDetail.formattedTotal, true),
        ], // Show VAT if available and greater than 0
        if (orderDetail.vat != null && double.parse(orderDetail.vat!) > 0) ...[
          _buildTotalRow('VAT:', orderDetail.formattedVat, false),
        ],
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, String amount, bool isTotal) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        // mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? _titleFontSize : 9,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontSize: isTotal ? _titleFontSize : 9,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentSection(OrderDetail orderDetail) {
    return pw.Column(
      children: [
        pw.Text(
          'PAYMENT DETAILS',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.start,
        ),

        pw.SizedBox(height: 4),

        // Payment Methods (each method forced to a full-width line)
        ...orderDetail.paymentMethods.map(
          (method) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1),
            child: pw.Container(
              width: double.infinity,
              child: pw.Row(
                children: [
                  pw.Text(
                    method.displayMethodType,
                    style: pw.TextStyle(fontSize: _fontSize + 1),
                  ),
                  pw.SizedBox(width: 5),
                  pw.Text(
                    method.formattedAmount,
                    style: pw.TextStyle(fontSize: _fontSize + 1),
                  ),
                ],
              ),
            ),
          ),
        ),

        pw.SizedBox(height: 6),
        pw.SizedBox(height: 4),

        // Amount Received and Change
        pw.Row(
          // mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Amount:',
              style: pw.TextStyle(
                fontSize: _fontSize + 1,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(width: 5),
            pw.Text(
              orderDetail.payment!.formattedAmountReceived,
              style: pw.TextStyle(
                fontSize: _fontSize + 1,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),

        if (orderDetail.hasChange) ...[
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Change:',
                style: pw.TextStyle(
                  fontSize: _fontSize + 1,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                ),
              ),
              pw.Text(
                orderDetail.payment!.formattedChangeAmount,
                style: pw.TextStyle(
                  fontSize: _fontSize + 1,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                ),
              ),
            ],
          ),
        ],

        // Payment Notes if available
        if (orderDetail.payment!.paymentNotes.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(2),
            ),
            child: pw.Text(
              'Notes: ${orderDetail.payment!.paymentNotes}',
              style: pw.TextStyle(
                fontSize: _smallFontSize + 1,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildFooter(OrderDetail orderDetail, [User? user]) {
    // Render Momo/Payment codes one per line
    final codes = user?.paymentCodes ?? [];

    return pw.Column(
      crossAxisAlignment: pw
          .CrossAxisAlignment.start, // ensures left alignment for column items
      children: [
        pw.SizedBox(height: 8),
        pw.Align(
          alignment: pw.Alignment.centerLeft, // aligns entire block to left
          child: pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start, // left-aligns text inside column
            children: [
              if (codes.isNotEmpty) ...[
                ...codes.map(
                  (p) => pw.Text(
                    '${p.name.toUpperCase()}: ${p.code}',
                    style: pw.TextStyle(
                      fontSize: _titleFontSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.left,
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
              pw.Text(
                'Thank you for your custom, we look forward to welcoming you back soon!',
                style: pw.TextStyle(
                  fontSize: _titleFontSize,
                  fontWeight: pw.FontWeight.normal,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Removed dashed line as requested

  static Future<void> previewReceipt(OrderDetail orderDetail) async {
    try {
      final pdf = pw.Document();
      final logoImage = await _loadLogoImage();
      final hasLogo = logoImage.isNotEmpty;

      // Fetch logged-in user for header/footer info
      final User? user = await AuthService.getCurrentUser();

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
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: _padding),
                  child: _buildReceiptContent(
                    orderDetail,
                    hasLogo ? pw.MemoryImage(logoImage) : null,
                    user, // pass user
                    null,
                  ),
                ),
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Receipt_Preview_${orderDetail.orderNumber}',
      );
    } catch (e) {
      throw Exception('Failed to preview receipt: $e');
    }
  }

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
}
