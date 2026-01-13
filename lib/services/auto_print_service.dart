import 'package:flutter/foundation.dart';
import 'package:kozo/cashierScreens/served_order_detail.dart';
import 'package:kozo/models/order_detail_model.dart';
import 'package:kozo/services/bar_receipt_service.dart';
import 'package:kozo/services/kitchen_receipt_service.dart';
import 'package:kozo/services/order_service.dart';
import 'package:kozo/services/printer_utils.dart';
import 'package:kozo/services/return_receipt_service.dart';
import 'package:kozo/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service to handle automatic printing of kitchen and bar receipts
class AutoPrintService {
  /// Process automatic printing based on the order response
  static Future<void> processAutoPrint({
    required int orderId,
    required String orderNumber,
    List<int>? kitchenItemIds,
    List<int>? barItemIds,
  }) async {
    try {
      // Better debug logging for the received item IDs
      debugPrint(
          '🧾 Auto-print initiated for order #$orderNumber (ID: $orderId)');
      debugPrint(
          '👨‍🍳 Kitchen items to print: ${kitchenItemIds?.join(', ') ?? 'None'}');
      debugPrint('🍸 Bar items to print: ${barItemIds?.join(', ') ?? 'None'}');

      // Check if the required printers are available
      final kitchenPrinter = await PrinterUtils.getKitchenPrinter();
      final barPrinter = await PrinterUtils.getBarPrinter();

      debugPrint('Kitchen printer found: ${kitchenPrinter != null}');
      debugPrint('Bar printer found: ${barPrinter != null}');

      // If printers aren't available, we'll still try to print but it will show a dialog

      // First, fetch the complete order detail to have all necessary data
      final orderDetail = await OrderService.fetchServedOrderDetail(orderId);

      // Process kitchen items if present and kitchen printer is available
      if (kitchenItemIds != null && kitchenItemIds.isNotEmpty) {
        await _printKitchenItems(orderId, orderDetail, kitchenItemIds);
      }

      // Process bar items if present and bar printer is available
      if (barItemIds != null && barItemIds.isNotEmpty) {
        await _printBarItems(orderId, orderDetail, barItemIds);
      }
    } catch (e) {
      debugPrint('❌ AutoPrintService error: $e');
      // We don't throw here to prevent disrupting the order flow
      // The user can always print manually if automatic printing fails
    }
  }

  /// Handle printing of kitchen items
  static Future<void> _printKitchenItems(
      int orderId, OrderDetail orderDetail, List<int> itemIds) async {
    try {
      // Prepare and send API request to get kitchen items
      final body = jsonEncode({
        'itemIds': itemIds,
        'orderId': orderId.toString(),
      });

      final url = Uri.parse('${AppConfig.baseUrl}/Orders/show_kichen_item');
      final headers = {'Content-Type': 'application/json'};

      // Print request data in terminal
      debugPrint("📤 Sending request to: $url");
      debugPrint("📋 Request Headers: $headers");
      debugPrint("📝 Request Body: $body");

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      // Print response data in terminal
      debugPrint("📥 Response Status Code: ${response.statusCode}");
      debugPrint("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint("✅ Decoded Response: $jsonResponse");

        final kitchenItemsResponse =
            KitchenItemsResponse.fromJson(jsonResponse);

        if (kitchenItemsResponse.hasKitchenItems) {
          // Print kitchen receipt
          final printResult = await KitchenReceiptService.printKitchenReceipt(
              kitchenItemsResponse, orderDetail);

          if (printResult) {
            debugPrint(
                '✅ AUTO PRINT SUCCESS: Kitchen receipt for order: ${orderDetail.orderNumber} printed successfully');
          } else {
            debugPrint(
                '⚠️ AUTO PRINT NOTICE: Kitchen receipt printing completed with issues for order: ${orderDetail.orderNumber}');
          }
        } else {
          debugPrint(
              '⚠️ No kitchen items found to print for order: ${orderDetail.orderNumber}');
        }
      } else {
        debugPrint(
            '❌ Failed to fetch kitchen items for auto-print: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Error in auto-printing kitchen items: $e');
    }
  }

  /// Handle printing of bar items
  static Future<void> _printBarItems(
      int orderId, OrderDetail orderDetail, List<int> itemIds) async {
    try {
      // Prepare and send API request to get bar items
      final body = jsonEncode({
        'itemIds': itemIds,
        'orderId': orderId.toString(),
      });

      final url = Uri.parse('${AppConfig.baseUrl}/Orders/show_bar_item');
      final headers = {'Content-Type': 'application/json'};

      // Print request data in terminal
      debugPrint("📤 Sending request to: $url");
      debugPrint("📋 Request Headers: $headers");
      debugPrint("📝 Request Body: $body");

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      // Print response data in terminal
      debugPrint("📥 Response Status Code: ${response.statusCode}");
      debugPrint("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint("✅ Decoded Response: $jsonResponse");

        final barItemsResponse = BarItemsResponse.fromJson(jsonResponse);

        if (barItemsResponse.hasBarItems) {
          // Convert to kitchen items format for compatibility with printer service
          final kitchenResponse = KitchenItemsResponse(
            success: barItemsResponse.success,
            hasKitchenItems: barItemsResponse.hasBarItems,
            kitchenItems: barItemsResponse.barItems,
          );

          // Print bar receipt
          final printResult = await BarReceiptService.printBarReceipt(
              kitchenResponse, orderDetail);

          if (printResult) {
            debugPrint(
                '✅ AUTO PRINT SUCCESS: Bar receipt for order: ${orderDetail.orderNumber} printed successfully');
          } else {
            debugPrint(
                '⚠️ AUTO PRINT NOTICE: Bar receipt printing completed with issues for order: ${orderDetail.orderNumber}');
          }
        } else {
          debugPrint(
              '⚠️ No bar items found to print for order: ${orderDetail.orderNumber}');
        }
      } else {
        debugPrint(
            '❌ Failed to fetch bar items for auto-print: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Error in auto-printing bar items: $e');
    }
  }

  /// Process automatic printing for returned items
  static Future<void> processReturnItemsAutoPrint({
    required int orderId,
    required String orderNumber,
    required List<dynamic> returnedItemsKitchen,
    required List<dynamic> returnedItemsBar,
  }) async {
    try {
      debugPrint(
          '🧾 Auto-print for RETURNED items initiated for order #$orderNumber (ID: $orderId)');
      debugPrint(
          '👨‍🍳 Kitchen items returned: ${returnedItemsKitchen.length}');
      debugPrint('🍸 Bar items returned: ${returnedItemsBar.length}');

      // Check if the required printers are available
      final kitchenPrinter = await PrinterUtils.getKitchenPrinter();
      final barPrinter = await PrinterUtils.getBarPrinter();

      debugPrint('Kitchen printer found: ${kitchenPrinter != null}');
      debugPrint('Bar printer found: ${barPrinter != null}');

      // Fetch the complete order detail to have all necessary data
      final orderDetail = await OrderService.fetchServedOrderDetail(orderId);

      // Process kitchen returned items if present
      if (returnedItemsKitchen.isNotEmpty) {
        final kitchenItems = returnedItemsKitchen
            .map((item) => ReturnedItem.fromJson(item))
            .toList();

        await ReturnReceiptService.printKitchenReturnReceipt(
            kitchenItems, orderDetail);
      }

      // Process bar returned items if present
      if (returnedItemsBar.isNotEmpty) {
        final barItems = returnedItemsBar
            .map((item) => ReturnedItem.fromJson(item))
            .toList();

        await ReturnReceiptService.printBarReturnReceipt(barItems, orderDetail);
      }
    } catch (e) {
      debugPrint('❌ AutoPrintService error for returned items: $e');
      // We don't throw here to prevent disrupting the order flow
    }
  }
}
