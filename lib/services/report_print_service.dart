import 'package:kozo/models/categories_sold_item.dart';
import 'package:kozo/utils/constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';

class ReportPrintService {
  // Constants for consistent styling
  static const double _pageWidth = 226.77; // Receipt width in points
  static const double _fontSize = 10.0;
  static const double _headerFontSize = 20.0;
  static const double _titleFontSize = 12.0;
  static const double _smallFontSize = 7.0;

  // Main method to print summary report
  static Future<void> printSummaryReport({
    required String fromDate,
    required String toDate,
    required Map<String, dynamic>? wholeSummary,
    required List<dynamic>? paymentBreakdown,
    required List<dynamic>? categoryRevenue,
    required List<dynamic>? taxRevenue,
    required List<dynamic>? discountSummary,
    List<dynamic>? depositDetails,
    List<CategorySoldSummary>? categorySoldItems, // Add this parameter
  }) async {
    try {
      // Get current user info
      String printedBy = "Unknown user";
      try {
        final currentUser = await AuthService.getCurrentUser();
        if (currentUser != null) {
          if (currentUser.fullName != null && currentUser.fullName.isNotEmpty) {
            printedBy = currentUser.fullName;
          } else {
            printedBy = "User ID: ${currentUser.id}";
          }
        }
      } catch (e) {
        print("Could not get user info: $e");
      }

      final pdf = pw.Document();
      final logoImage = await _loadLogoImage();
      final hasLogo = logoImage.isNotEmpty;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(_pageWidth, double.infinity, marginAll: 8),
          build: (pw.Context context) {
            return _buildReportContent(
              fromDate,
              toDate,
              wholeSummary,
              paymentBreakdown,
              categoryRevenue,
              taxRevenue,
              discountSummary,
              hasLogo ? pw.MemoryImage(logoImage) : null,
              printedBy,
              depositDetails,
              categorySoldItems, // Pass this parameter
            );
          },
        ),
      );

      // Find the receipt printer and print to it directly
      final printers = await Printing.listPrinters();
      final receiptPrinter = printers
          .where((printer) =>
              printer.name.toLowerCase() == PrinterNames.receipt.toLowerCase())
          .firstOrNull;

      final reportName =
          'Z_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';

      if (receiptPrinter != null) {
        // Print directly to the receipt printer
        await Printing.directPrintPdf(
          printer: receiptPrinter,
          onLayout: (_) => pdf.save(),
          name: reportName,
        );
        print(
            'Printed Z-Report directly to LOCAL printer: ${receiptPrinter.name}');
      } else {
        // Fall back to printer selection dialog if receipt printer not found
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: reportName,
        );
        print('Available printers: ${printers.map((p) => p.name).join(", ")}');
        print('Looking for printer: ${PrinterNames.receipt}');
        print('LOCAL printer not found, using selection dialog instead');
      }
    } catch (e) {
      throw Exception('Failed to print summary report: $e');
    }
  }

  // Method to download summary report as PDF
  static Future<String?> downloadSummaryReport({
    required String fromDate,
    required String toDate,
    required Map<String, dynamic>? wholeSummary,
    required List<dynamic>? paymentBreakdown,
    required List<dynamic>? categoryRevenue,
    required List<dynamic>? taxRevenue,
    required List<dynamic>? discountSummary,
    List<dynamic>? depositDetails,
    List<CategorySoldSummary>? categorySoldItems, // Add this parameter
  }) async {
    try {
      // Get current user info
      String printedBy = "Unknown user";
      try {
        final currentUser = await AuthService.getCurrentUser();
        if (currentUser != null) {
          printedBy = currentUser.fullName;
        }
      } catch (e) {
        print("Could not get user info: $e");
      }

      final pdf = pw.Document();
      final logoImage = await _loadLogoImage();
      final hasLogo = logoImage.isNotEmpty;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(_pageWidth, double.infinity, marginAll: 8),
          build: (pw.Context context) {
            return _buildReportContent(
              fromDate,
              toDate,
              wholeSummary,
              paymentBreakdown,
              categoryRevenue,
              taxRevenue,
              discountSummary,
              hasLogo ? pw.MemoryImage(logoImage) : null,
              printedBy,
              depositDetails,
              categorySoldItems, // Pass this parameter
            );
          },
        ),
      );

      // Generate filename with date range
      final fileName =
          'KOZO_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Save to a temporary file
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: fileName,
      );

      return fileName;
    } catch (e) {
      throw Exception('Failed to download summary report: $e');
    }
  }

  // Build the entire report content
  static pw.Widget _buildReportContent(
      String fromDate,
      String toDate,
      Map<String, dynamic>? wholeSummary,
      List<dynamic>? paymentBreakdown,
      List<dynamic>? categoryRevenue,
      List<dynamic>? taxRevenue,
      List<dynamic>? discountSummary,
      [pw.ImageProvider? logoImage,
      String? printedBy,
      List<dynamic>? depositDetails,
      List<CategorySoldSummary>? categorySoldItems]) {
    // Add this parameter
    // Add this parameter
    // Extract global service fee from the summary data
    double globalServiceFee = 0;
    if (wholeSummary != null) {
      globalServiceFee = double.tryParse(
              wholeSummary['total_service_fee']?.toString() ?? '0') ??
          0;
    }
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
            pw.SizedBox(height: 10),
          ],

          // Report Header
          _buildReportHeader(fromDate, toDate, printedBy),
          pw.SizedBox(height: 20),

          // Revenue Summary Section
          if (wholeSummary != null && wholeSummary.isNotEmpty) ...[
            _buildRevenueSummarySection(wholeSummary),
            pw.SizedBox(height: 20),
          ],

          // Payment Methods Section
          if (paymentBreakdown != null && paymentBreakdown.isNotEmpty) ...[
            _buildPaymentMethodsSection(paymentBreakdown),
            pw.SizedBox(height: 20),
          ],

          // Category Revenue Section
          if (categoryRevenue != null && categoryRevenue.isNotEmpty) ...[
            _buildCategoryRevenueSection(categoryRevenue, globalServiceFee),
            pw.SizedBox(height: 20),
          ],

          // Tax Revenue Section
          if (taxRevenue != null && taxRevenue.isNotEmpty) ...[
            _buildTaxRevenueSection(taxRevenue),
            pw.SizedBox(height: 20),
          ],

          // Discount Summary Section
          if (discountSummary != null && discountSummary.isNotEmpty) ...[
            _buildDiscountSummarySection(discountSummary),
            pw.SizedBox(height: 20),
          ],
          // Category Sold Items Section
          if (categorySoldItems != null && categorySoldItems.isNotEmpty) ...[
            _buildCategorySoldItemsSection(categorySoldItems),
            pw.SizedBox(height: 20),
          ],

          // Deposit Details Section - add before the footer
          if (depositDetails != null && depositDetails.isNotEmpty) ...[
            _buildDepositDetailsSection(depositDetails),
            pw.SizedBox(height: 20),
          ],

          // Footer
          _buildReportFooter(null),
        ],
      ),
    );
  }

  // Build the report header
  static pw.Widget _buildReportHeader(String fromDate, String toDate,
      [String? printedBy]) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey300,
            width: 1,
          ),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'Z-REPORT',
            style: pw.TextStyle(
              fontSize: _titleFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Period: $fromDate - $toDate',
            style: pw.TextStyle(
              fontSize: _fontSize,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: _fontSize,
            ),
            textAlign: pw.TextAlign.center,
          ),
          if (printedBy != null && printedBy.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              'Generated by: $printedBy',
              style: pw.TextStyle(
                fontSize: _fontSize,
                fontStyle: pw.FontStyle.italic,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // Build the report footer
  static pw.Widget _buildReportFooter(pw.Context? context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColors.grey300,
            width: 1,
          ),
        ),
      ),
      child: pw.Text(
        'Powered by TITAN TECH HUB Ltd',
        style: pw.TextStyle(
          fontSize: _smallFontSize,
          color: PdfColors.grey700,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Build Revenue Summary Section
  static pw.Widget _buildRevenueSummarySection(Map<String, dynamic> summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(' Summary'),
        pw.SizedBox(height: 10),
        buildInfoRow(
          title: 'Total Revenue (Excl.)',
          value: _formatCurrency(summary['total_exclusive'] ?? '0'),
        ),
        buildInfoRow(
          title: 'Total Revenue (Incl.)',
          value: _formatCurrency(summary['total_inclusive'] ?? '0'),
        ),
        // buildInfoRow(
        //   title: 'Service Fee',
        //   value: _formatCurrency(summary['total_service_fee'] ?? '0'),
        // ),
        buildInfoRow(
          title: 'Transactions',
          value: summary['total_transactions']?.toString() ?? '0',
        ),
        buildInfoRow(
          title: 'Total Spend',
          value: _formatCurrency(summary['total_spend'] ?? '0'),
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  // Reusable info row for payment method
  static pw.Widget _buildPaymentInfoRow({
    required String method,
    required String amount,
    required String transactions,
    bool isHeader = false,
    bool isTotal = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              method,
              style: pw.TextStyle(
                fontSize: _fontSize,
                fontWeight: isHeader || isTotal
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
              textAlign: pw.TextAlign.start,
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              transactions,
              style: pw.TextStyle(
                fontSize: _fontSize,
                fontWeight: isHeader || isTotal
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
                color: isTotal ? PdfColors.blue900 : PdfColors.grey700,
              ),
              textAlign: pw.TextAlign.start,
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              amount,
              style: pw.TextStyle(
                fontSize: _fontSize,
                fontWeight: isHeader || isTotal
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
              textAlign: pw.TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  // Build Payment Methods Section
  static pw.Widget _buildPaymentMethodsSection(List<dynamic> methods) {
    double totalAmount = 0;
    int totalTransactions = 0;

    for (var method in methods) {
      totalAmount += double.tryParse(method['total_amount'].toString()) ?? 0;
      totalTransactions += method['transaction_count'] as int? ?? 0;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Payment Methods Breakdown'),
        pw.SizedBox(height: 5),

        // Header Row
        // _buildPaymentInfoRow(
        //   method: "Method",
        //   transactions: "Transactions",
        //   amount: "Amount",
        //   isHeader: true,
        // ),
        // pw.Divider(),

        // Payment Methods Rows
        ...methods.map((method) {
          return _buildPaymentInfoRow(
            method: _getMethodName(method['method_type']),
            transactions: "${method['transaction_count']}",
            amount: _formatCurrency(method['total_amount']),
          );
        }).toList(),

        pw.Divider(),

        // Total Row
        _buildPaymentInfoRow(
          method: "Total",
          transactions: "$totalTransactions",
          amount: _formatCurrency(totalAmount),
          isTotal: true,
        ),

        pw.SizedBox(height: 5),
      ],
    );
  }

  // Build Category Revenue Section
  static pw.Widget _buildCategoryRevenueSection(
      List<dynamic> categories, double globalServiceFee) {
    // Calculate totals from categories
    double totalGrossRevenue = 0;

    for (var category in categories) {
      totalGrossRevenue +=
          double.tryParse(category['gross_revenue'].toString()) ?? 0;
    }

    // Calculate final total using global service fee
    double finalTotal = totalGrossRevenue + globalServiceFee;
    print("Service Fee: $globalServiceFee, Final Total: $finalTotal");
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Category Revenue Breakdown'),
        pw.SizedBox(height: 10),

        // List of categories
        ...categories.map((category) {
          return _buildCategoryInfoRow(
            title: category['category_name'] ?? 'Unknown',
            gross: _formatCurrency(category['gross_revenue']),
          );
        }).toList(),

        // pw.Divider(),

        // // Categories Total
        // _buildCategoryInfoRow(
        //   title: "CATEGORIES TOTAL",
        //   gross: _formatCurrency(totalGrossRevenue),
        //   isTotal: true,
        // ),

        pw.SizedBox(height: 5),

        // Service Fee as separate item
        _buildCategoryInfoRow(
          title: "Service Fee ",
          gross: "RWF ${globalServiceFee.toString()}",
        ),

        pw.Divider(),

        // Final Total
        _buildCategoryInfoRow(
          title: "FINAL TOTAL",
          gross: _formatCurrency(finalTotal),
          isTotal: true,
        ),
      ],
    );
  }

  /// Custom info row: title | amount
  static pw.Widget _buildCategoryInfoRow({
    required String title,
    required String gross,
    bool isTotal = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Title
          pw.Expanded(
            flex: 1, // Adjust as needed
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: _fontSize,
                fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),

          // Gross amount
          pw.Expanded(
            flex: 1, // Equal size with title, or increase if needed
            child: pw.Text(
              gross,
              style: pw.TextStyle(
                fontSize: _fontSize,
                fontWeight: pw.FontWeight.bold,
                color: isTotal ? PdfColors.blue900 : PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build Tax Revenue Section
  static pw.Widget _buildTaxRevenueSection(List<dynamic> taxData) {
    final tax = taxData.first;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Tax Revenue Breakdown'),
        pw.SizedBox(height: 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 5),
            // buildInfoRow(
            //   title: "For Date",
            //   value: tax['date'] ?? 'N/A',
            // ),
            buildInfoRow(
              title: "Net Tax Revenue",
              value: _formatCurrency(tax['net_tax']),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
      ],
    );
  }

  // Build Discount Summary Section
  static pw.Widget _buildDiscountSummarySection(List<dynamic> discountData) {
    // Calculate totals from all discount types
    double totalAmount = 0;
    int totalTransactions = 0;

    for (var item in discountData) {
      final amount = item['total_amount'];
      if (amount is String) {
        totalAmount += double.tryParse(amount) ?? 0;
      } else if (amount is num) {
        totalAmount += amount.toDouble();
      }
      totalTransactions += (item['transaction_count'] as int?) ?? 0;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Discount Summary'),
        pw.SizedBox(height: 10),

        // Table Header
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'Method',
                  style: pw.TextStyle(
                    fontSize: _fontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Count',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: _fontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'Amount',
                  textAlign: pw.TextAlign.left,
                  style: pw.TextStyle(
                    fontSize: _fontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Discount Rows
        ...discountData.map((item) => _buildDiscountRow(item)).toList(),

        // Total Row
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey400, width: 1),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontSize: _fontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  '$totalTransactions',
                  textAlign: pw.TextAlign.
                  center,
                  style: pw.TextStyle(
                    fontSize: _fontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  _formatCurrency(totalAmount),
                  textAlign: pw.TextAlign.left,
                  style: pw.TextStyle(
                    fontSize: _fontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 10),
      ],
    );
  }

  // Build individual discount row
  static pw.Widget _buildDiscountRow(Map<String, dynamic> item) {
    final String methodType = item['method_type'] ?? 'Unknown';
    final int transactionCount = item['transaction_count'] as int? ?? 0;
    final amount = item['total_amount'];
    double totalAmount = 0;
    if (amount is String) {
      totalAmount = double.tryParse(amount) ?? 0;
    } else if (amount is num) {
      totalAmount = amount.toDouble();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              methodType,
              style: pw.TextStyle(fontSize: _fontSize),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              '$transactionCount',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: _fontSize),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              _formatCurrency(totalAmount),
              textAlign: pw.TextAlign.left,
              style: pw.TextStyle(fontSize: _fontSize),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build section headers
  static pw.Widget _buildSectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: _titleFontSize,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  // Helper method to build summary cards
  static pw.Widget buildInfoRow({
    required String title,
    required String value,
    double fontSize = 12.0,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 1, // Adjust flex as needed
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: fontSize,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          flex: 1, // Adjust flex as needed
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build table cells
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: _fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  // Helper method to build discount metrics
  static pw.Widget _buildDiscountMetric({
    required String title,
    required String value,
    required PdfColor color,
  }) {
    return pw.Container(
      width: _pageWidth * 0.28, // Adjust width to fit receipt
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        color: color.shade(50),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: _fontSize,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: _fontSize + 2,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format currency
  static String _formatCurrency(dynamic amount) {
    final formatter = NumberFormat.currency(symbol: 'RWF ', decimalDigits: 0);
    if (amount is String) {
      return formatter.format(double.tryParse(amount) ?? 0);
    } else {
      return formatter.format(amount ?? 0);
    }
  }

  // Helper method to get payment method display name
  static String _getMethodName(String? methodType) {
    switch (methodType) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      default:
        return methodType ?? 'Unknown';
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

  // Get current user info
  static Future<String> _getUserInfo() async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser != null) {
        if (currentUser.fullName != null && currentUser.fullName.isNotEmpty) {
          return currentUser.fullName;
        } else {
          return "User ID: ${currentUser.id}";
        }
      }
      return "Unknown user";
    } catch (e) {
      print("Could not get user info: $e");
      return "Unknown user";
    }
  }

  // Helper method to build service info row
  static pw.Widget _buildServiceInfoRow({
    required String title,
    required String value,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        border: pw.Border.all(color: PdfColors.orange300),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: _fontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: _fontSize,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange700,
            ),
          ),
        ],
      ),
    );
  }

  // Build Deposit Details Section
  static pw.Widget _buildDepositDetailsSection(List<dynamic> depositDetails) {
    double totalAmount = 0;

    // Calculate total deposit amount
    for (var deposit in depositDetails) {
      totalAmount += double.tryParse(deposit['amount']?.toString() ?? '0') ?? 0;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Deposit Breakdown'),
        pw.SizedBox(height: 10),

        // Individual deposit rows
        for (var deposit in depositDetails) ...[
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                buildInfoRow(
                  title: 'Client',
                  value: deposit['client_name'] ?? 'Unknown',
                  fontSize: _fontSize,
                ),
                buildInfoRow(
                  title: 'Payment Method',
                  value: deposit['method_name'] ?? 'Unknown',
                  fontSize: _fontSize,
                ),
                buildInfoRow(
                  title: 'Amount',
                  value: _formatCurrency(deposit['amount']),
                  fontSize: _fontSize,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 5),
        ],

        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 5),

        // Total row
        buildInfoRow(
          title: 'TOTAL DEPOSITS',
          value: _formatCurrency(totalAmount),
          fontSize: _fontSize + 1,
        ),
      ],
    );
  }

  static pw.Widget _buildCategorySoldItemsSection(
      List<CategorySoldSummary> categorySoldItems) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Sold Items Breakdown'),
        pw.SizedBox(height: 10),

        // Create a section for each category
        ...categorySoldItems.map((category) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Category name with background
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 4, horizontal: 6),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                    child: pw.Text(
                      category.categoryName,
                      style: pw.TextStyle(
                        fontSize: _fontSize + 1,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  // Table header
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(
                          'Specification',
                          style: pw.TextStyle(
                            fontSize: _fontSize,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'Qty',
                          style: pw.TextStyle(
                            fontSize: _fontSize,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      // pw.Expanded(
                      //   flex: 2,
                      //   child: pw.Text(
                      //     'Price',
                      //     style: pw.TextStyle(
                      //       fontSize: _fontSize,
                      //       fontWeight: pw.FontWeight.bold,
                      //     ),
                      //     textAlign: pw.TextAlign.center,
                      //   ),
                      // ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(
                            fontSize: _fontSize,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  pw.Divider(color: PdfColors.grey400),

                  // Items list
                  ...category.items.map((item) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfColors.grey200,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              flex: 4,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    item.specificationName,
                                    style: pw.TextStyle(
                                      fontSize: _fontSize,
                                      fontWeight: pw.FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    _formatCurrency(item.price),
                                    style: pw.TextStyle(
                                      fontSize: _fontSize,
                                      fontWeight: pw.FontWeight.normal,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    item.quantitySold.toString(),
                                    style: pw.TextStyle(
                                      fontSize: _fontSize - 1,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // pw.Expanded(
                            //   flex: 1,
                            //   child: pw.Text(
                            //     '${item.quantitySold}',
                            //     style: pw.TextStyle(fontSize: _fontSize),
                            //     textAlign: pw.TextAlign.center,
                            //   ),
                            // ),
                            // pw.Expanded(
                            //   flex: 2,
                            //   child: pw.Text(
                            //     _formatCurrency(item.price),
                            //     style: pw.TextStyle(fontSize: _fontSize),
                            //     textAlign: pw.TextAlign.center,
                            //   ),
                            // ),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                _formatCurrency(item.totalRevenue),
                                style: pw.TextStyle(
                                  fontSize: _fontSize,
                                  fontWeight: pw.FontWeight.normal,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      )),

                  pw.Divider(color: PdfColors.grey400),

                  // Category total
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 5, horizontal: 3),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Total ${category.categoryName}:',
                          style: pw.TextStyle(
                            fontSize: _fontSize,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(width: 5),
                        pw.Text(
                          _formatCurrency(category.totalRevenue),
                          style: pw.TextStyle(
                            fontSize: _fontSize + 1,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // Helper method for table cells (modify the existing one or add this)
}
// Helper method for table cells (modify the existing one or add this)
