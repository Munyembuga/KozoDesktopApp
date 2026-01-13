import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:kozo/utils/constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Utility class to handle printer-related operations
class PrinterUtils {
  /// Get a printer by its name
  /// Returns null if the printer is not found
  static Future<Printer?> getPrinterByName(String name) async {
    try {
      final printers = await Printing.listPrinters();
      // Use .where and .firstOrNull instead of .firstWhere with orElse: () => null
      return printers
          .where((printer) => printer.name.toUpperCase() == name.toUpperCase())
          .firstOrNull;
    } catch (e) {
      debugPrint('Error finding printer "$name": $e');
      return null;
    }
  }

  /// Get the kitchen printer
  static Future<Printer?> getKitchenPrinter() async {
    return await getPrinterByName(PrinterNames.kitchen);
  }

  /// Get the bar printer
  static Future<Printer?> getBarPrinter() async {
    return await getPrinterByName(PrinterNames.bar);
  }

  /// Get the receipt printer
  static Future<Printer?> getReceiptPrinter() async {
    return await getPrinterByName(PrinterNames.receipt);
  }

  /// List all available printers
  static Future<List<String>> getAvailablePrinterNames() async {
    try {
      final printers = await Printing.listPrinters();
      return printers.map((printer) => printer.name).toList();
    } catch (e) {
      debugPrint('Error listing printers: $e');
      return [];
    }
  }

  /// Print a simple test page to check printer connectivity
  static Future<bool> printTestPage(String printerName) async {
    try {
      final printer = await getPrinterByName(printerName);
      if (printer == null) {
        debugPrint('Printer "$printerName" not found');
        return false;
      }

      // Print a simple test page
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (_) {
          final pdf = pw.Document();
          pdf.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Test Page',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text('Printer: $printerName'),
                      pw.SizedBox(height: 10),
                      pw.Text('Date: ${DateTime.now()}'),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'If you can read this, your printer is working correctly!',
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
          return pdf.save();
        },
        name: 'Test Page',
      );
      return true;
    } catch (e) {
      debugPrint('Error printing test page to "$printerName": $e');
      return false;
    }
  }
}
