import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

class DesktopReceiptPrinter extends StatefulWidget {
  @override
  _DesktopReceiptPrinterState createState() => _DesktopReceiptPrinterState();
}

class _DesktopReceiptPrinterState extends State<DesktopReceiptPrinter> {
  // Sample receipt data
  final String restaurantName = "DELICIOUS RESTAURANT";
  final String address =
      "123 Main Street\nCity, State 12345\nPhone: (555) 123-4567";
  final String receiptNumber = "R001234";
  final String tableNumber = "Table 5";
  final String serverName = "John Doe";
  final DateTime orderTime = DateTime.now();

  final List<OrderItem> orderItems = [
    OrderItem("Burger Deluxe", 2, 12.99),
    OrderItem("French Fries", 2, 4.50),
    OrderItem("Coca Cola", 2, 2.99),
    OrderItem("Caesar Salad", 1, 8.99),
    OrderItem("Chocolate Cake", 1, 6.99),
  ];

  double get subtotal =>
      orderItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get tax => subtotal * 0.08; // 8% tax
  double get total => subtotal + tax;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Desktop Receipt Printer (58mm)'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              thickness: 8.0,
              radius: const Radius.circular(5),
              trackVisibility: true,
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: Center(
                    child: Container(
                      width: 240, // Slightly wider for desktop preview
                      margin: EdgeInsets.all(20),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: _buildReceiptContent(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _previewReceipt,
                  icon: Icon(Icons.preview),
                  label: Text('Preview'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _printReceipt,
                  icon: Icon(Icons.print),
                  label: Text('Print Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _selectPrinter,
                  icon: Icon(Icons.print),
                  label: Text('Printer Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Restaurant Header
        Text(
          restaurantName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          address,
          style: TextStyle(fontSize: 11, fontFamily: 'Courier'),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),

        // Divider
        _buildDivider(),

        // Receipt Info
        _buildReceiptInfo(),

        // Items Header
        _buildDivider(),
        _buildItemsHeader(),
        _buildDivider(),

        // Order Items
        ...orderItems.map((item) => _buildOrderItem(item)),

        // Totals Section
        _buildDivider(),
        _buildTotalsSection(),
        _buildDivider(),

        // Footer
        SizedBox(height: 12),
        Text(
          'Thank you for dining with us!',
          style: TextStyle(fontSize: 11, fontFamily: 'Courier'),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Please come again!',
          style: TextStyle(fontSize: 11, fontFamily: 'Courier'),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '--------------------------------',
        style: TextStyle(fontSize: 9, fontFamily: 'Courier'),
      ),
    );
  }

  Widget _buildReceiptInfo() {
    return Column(
      children: [
        _buildReceiptRow('Receipt #:', receiptNumber),
        _buildReceiptRow('Table:', tableNumber),
        _buildReceiptRow('Server:', serverName),
        _buildReceiptRow('Date:', _formatDate(orderTime)),
        _buildReceiptRow('Time:', _formatTime(orderTime)),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontFamily: 'Courier')),
          Text(value, style: TextStyle(fontSize: 11, fontFamily: 'Courier')),
        ],
      ),
    );
  }

  Widget _buildItemsHeader() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text('Item',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier')),
        ),
        Expanded(
          flex: 1,
          child: Text('Qty',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier'),
              textAlign: TextAlign.center),
        ),
        Expanded(
          flex: 2,
          child: Text('Total',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier'),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  item.name,
                  style: TextStyle(fontSize: 10, fontFamily: 'Courier'),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${item.quantity}',
                  style: TextStyle(fontSize: 10, fontFamily: 'Courier'),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 10, fontFamily: 'Courier'),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          if (item.quantity > 1)
            Padding(
              padding: EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  Text(
                    '\$${item.price.toStringAsFixed(2)} each',
                    style: TextStyle(
                        fontSize: 9,
                        fontFamily: 'Courier',
                        color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Column(
      children: [
        _buildTotalRow('Subtotal:', '\$${subtotal.toStringAsFixed(2)}', false),
        _buildTotalRow('Tax (8%):', '\$${tax.toStringAsFixed(2)}', false),
        SizedBox(height: 4),
        _buildTotalRow('TOTAL:', '\$${total.toStringAsFixed(2)}', true),
      ],
    );
  }

  Widget _buildTotalRow(String label, String amount, bool isTotal) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 13 : 11,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Courier',
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 13 : 11,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  // Generate PDF for 58mm thermal printer
  Future<Uint8List> _generatePDF() async {
    final pdf = pw.Document();

    // 58mm = 164 points (at 72 DPI), but we'll use 160 for margins
    const double pageWidth = 160;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, double.infinity, marginAll: 8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Restaurant Header
              pw.Text(
                restaurantName,
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                address.replaceAll('\n', ' • '),
                style: pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),

              // Divider
              pw.Text('--------------------------------',
                  style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),

              // Receipt Info
              _buildPDFReceiptInfo(),
              pw.SizedBox(height: 4),
              pw.Text('--------------------------------',
                  style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),

              // Items Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                      flex: 3,
                      child: pw.Text('Item',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(
                      flex: 1,
                      child: pw.Text('Qty',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center)),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text('Total',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('--------------------------------',
                  style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),

              // Order Items
              ...orderItems.map((item) => _buildPDFOrderItem(item)),

              // Totals
              pw.SizedBox(height: 4),
              pw.Text('--------------------------------',
                  style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),
              _buildPDFTotalsSection(),
              pw.SizedBox(height: 4),
              pw.Text('--------------------------------',
                  style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 8),

              // Footer
              pw.Text(
                'Thank you for dining with us!',
                style: pw.TextStyle(fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Please come again!',
                style: pw.TextStyle(fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 16),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPDFReceiptInfo() {
    return pw.Column(
      children: [
        _buildPDFReceiptRow('Receipt #:', receiptNumber),
        _buildPDFReceiptRow('Table:', tableNumber),
        _buildPDFReceiptRow('Server:', serverName),
        _buildPDFReceiptRow('Date:', _formatDate(orderTime)),
        _buildPDFReceiptRow('Time:', _formatTime(orderTime)),
      ],
    );
  }

  pw.Widget _buildPDFReceiptRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  pw.Widget _buildPDFOrderItem(OrderItem item) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text(item.name, style: pw.TextStyle(fontSize: 8)),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text('${item.quantity}',
                    style: pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                    '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.right),
              ),
            ],
          ),
          if (item.quantity > 1)
            pw.Padding(
              padding: pw.EdgeInsets.only(left: 4, top: 1),
              child: pw.Row(
                children: [
                  pw.Text('\$${item.price.toStringAsFixed(2)} each',
                      style: pw.TextStyle(fontSize: 7)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFTotalsSection() {
    return pw.Column(
      children: [
        _buildPDFTotalRow(
            'Subtotal:', '\$${subtotal.toStringAsFixed(2)}', false),
        _buildPDFTotalRow('Tax (8%):', '\$${tax.toStringAsFixed(2)}', false),
        pw.SizedBox(height: 2),
        _buildPDFTotalRow('TOTAL:', '\$${total.toStringAsFixed(2)}', true),
      ],
    );
  }

  pw.Widget _buildPDFTotalRow(String label, String amount, bool isTotal) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 10 : 9,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontSize: isTotal ? 10 : 9,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Preview the receipt PDF
  void _previewReceipt() async {
    try {
      final pdfBytes = await _generatePDF();
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Receipt_$receiptNumber',
      );
    } catch (e) {
      _showErrorDialog('Preview Error', 'Failed to generate preview: $e');
    }
  }

  // Print the receipt directly
  void _printReceipt() async {
    try {
      final pdfBytes = await _generatePDF();

      // For demonstration, we'll show a success dialog
      // In a real app, you would use the following code to print:
      /*
      await Printing.directPrintPdf(
        printer: await Printing.pickPrinter(context: context),
        onLayout: (format) async => pdfBytes,
        name: 'Receipt_$receiptNumber',
        format: PdfPageFormat(160, double.infinity, marginAll: 8), // 58mm width
      );
      */

      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog('Print Error', 'Failed to print: $e');
    }
  }

  // Open printer selection dialog
  void _selectPrinter() async {
    try {
      final printer = await Printing.pickPrinter(context: context);
      if (printer != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Printer Selected'),
            content: Text(
                'Selected printer: ${printer.name}\n\nYou can now print receipts to this printer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showErrorDialog(
          'Printer Selection Error', 'Failed to select printer: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text('Receipt printed successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Order Item Model
class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem(this.name, this.quantity, this.price);
}

// Main App
class DesktopRestaurantReceiptApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Desktop Receipt Printer (58mm)',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: DesktopReceiptPrinter(),
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() {
  runApp(DesktopRestaurantReceiptApp());
}
