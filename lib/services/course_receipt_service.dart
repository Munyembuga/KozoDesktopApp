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

class CourseReceiptService {
  static const double _fontSize = 12.0;
  static const double _headerFontSize = 25.0;

  // Load the logo image
  static Future<Uint8List> _loadLogoImage() async {
    try {
      return (await rootBundle.load('assets/logo.png')).buffer.asUint8List();
    } catch (e) {
      print('Logo not found: $e');
      return Uint8List(0);
    }
  }

  static Future<bool> printCourseReceipt(String courseNumber,
      List<OrderItem> courseItems, OrderDetail orderDetail) async {
    try {
      debugPrint('🍽️ Starting course receipt print for course: $courseNumber');

      final pdf = pw.Document();
      final logoImage = await _loadLogoImage();
      final hasLogo = logoImage.isNotEmpty;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
              marginAll: 5),
          build: (pw.Context context) {
            return _buildCourseReceiptContent(
              courseNumber,
              courseItems,
              orderDetail,
              hasLogo ? pw.MemoryImage(logoImage) : null,
            );
          },
        ),
      );

      // Find the kitchen printer and print to it directly
      final printers = await Printing.listPrinters();
      debugPrint(
          '🖨️ Available printers: ${printers.map((p) => p.name).join(", ")}');

      final kitchenPrinter = printers
          .where((printer) =>
              printer.name.toLowerCase() == PrinterNames.kitchen.toLowerCase())
          .firstOrNull;

      bool printSuccess = false;
      if (kitchenPrinter != null) {
        // Print directly to the kitchen printer
        debugPrint(
            '✅ Found kitchen printer for course: ${kitchenPrinter.name}');
        printSuccess = await Printing.directPrintPdf(
          printer: kitchenPrinter,
          onLayout: (_) => pdf.save(),
          name: 'Course_${courseNumber}_${orderDetail.orderNumber}',
        );
        debugPrint(
            '🍽️ Course print to kitchen printer result: ${printSuccess ? "SUCCESS" : "FAILED"}');
      } else {
        // Fall back to printer selection dialog if kitchen printer not found
        debugPrint(
            '❌ Kitchen printer not found, using selection dialog instead');
        debugPrint(
            'Available printers: ${printers.map((p) => p.name).join(", ")}');
        printSuccess = await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Course_${courseNumber}_${orderDetail.orderNumber}',
        );
        debugPrint(
            '🍽️ Course print via dialog result: ${printSuccess ? "SUCCESS" : "FAILED"}');
      }

      return printSuccess;
    } catch (e) {
      debugPrint('❌ Course receipt print failed: $e');
      throw Exception('Failed to print course receipt: $e');
    }
  }

  static pw.Widget _buildCourseReceiptContent(
      String courseNumber, List<OrderItem> courseItems, OrderDetail orderDetail,
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
        ],

        pw.SizedBox(height: 8),

        // Order Info
        _buildCourseInfoRow('Date:', dateFormatter.format(now)),
        _buildCourseInfoRow('Order:', orderDetail.orderNumber),
        _buildCourseInfoRow('Waiter:', orderDetail.waiterName),
        if (orderDetail.clientName != null)
          _buildCourseInfoRow('Client:', orderDetail.clientName!),

        pw.SizedBox(height: 4),
        _buildDivider(),
        pw.SizedBox(height: 6),

        pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            '${courseNumber.toUpperCase()} AWAY',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),

        pw.SizedBox(height: 16),

        pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              _buildCourseInfoRowTable(
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

  static pw.Widget _buildCourseInfoRowTable(String label, String value) {
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

  static pw.Widget _buildCourseInfoRow(String label, String value) {
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

  static Future<void> previewCourseReceipt(String courseNumber,
      List<OrderItem> courseItems, OrderDetail orderDetail) async {
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
                child: _buildCourseReceiptContent(
                  courseNumber,
                  courseItems,
                  orderDetail,
                  hasLogo ? pw.MemoryImage(logoImage) : null,
                ),
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Course_${courseNumber}_Preview_${orderDetail.orderNumber}',
      );
    } catch (e) {
      throw Exception('Failed to preview course receipt: $e');
    }
  }
}
