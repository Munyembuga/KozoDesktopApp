import 'package:dio/dio.dart';
import 'package:kozo/models/paymentMethodModel.dart';
import 'package:kozo/services/auto_print_service.dart';
import 'package:kozo/utils/constants.dart';
import '../models/order_model.dart';
import '../models/order_detail_model.dart';
import '../models/waiter_model.dart';
import '../models/table_model.dart';
import '../models/category_model.dart';
import '../models/cart_item_model.dart' hide Specification;
import '../models/kitchen_item_model.dart';
import 'auth_service.dart';

class OrderService {
  static const String baseUrl = AppConfig.baseUrl;
  static final Dio _dio = Dio();
  static Future<List<PaymentMethod>> fetchPaymentMethods() async {
    try {
      final response = await _dio.get('$baseUrl/Orders/payment_method');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> methodsData = data['data'];
          return methodsData
              .map((methodJson) => PaymentMethod.fromJson(methodJson))
              .toList();
        } else {
          throw Exception(
              'Failed to fetch payment methods: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch payment methods: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch payment methods: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<List<Waiter>> fetchWaiters() async {
    try {
      final response = await _dio.get('$baseUrl/Orders/show_waiter');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> waitersData = data['data'];
          return waitersData
              .map((waiterJson) => Waiter.fromJson(waiterJson))
              .toList();
        } else {
          throw Exception(
              'Failed to fetch waiters: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to fetch waiters: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch waiters: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<List<TableModel>> fetchTables() async {
    try {
      final response = await _dio.get('$baseUrl/Orders/show_available_table');

      if (response.statusCode == 200) {
        final data = response.data;
        print('Response data&&&&&&&&&&&&&&&&&&&&&&&: $data');
        print('Response data: $data');
        if (data['success'] == true) {
          final List<dynamic> tablesData = data['data'];
          return tablesData
              .map((tableJson) => TableModel.fromJson(tableJson))
              .toList();
        } else {
          throw Exception(
              'Failed to fetch tables: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to fetch tables: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch tables: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<List<TableModel>> fetchTablesOccupied() async {
    try {
      final response = await _dio.get('$baseUrl/Orders/show_occupied_table');

      if (response.statusCode == 200) {
        final data = response.data;
        print('Response data*****************: $data');
        print('Response data: $data');
        if (data['success'] == true) {
          final List<dynamic> tablesData = data['data'];
          return tablesData
              .map((tableJson) => TableModel.fromJson(tableJson))
              .toList();
        } else {
          throw Exception(
              'Failed to fetch tables: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to fetch tables: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch tables: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<List<Order>> fetchPartialPaymentOrders({
    int? waiterId,
    int? tableId,
  }) async {
    try {
      Map<String, dynamic> requestData = {};

      if (waiterId != null) {
        requestData['waiterId'] = waiterId.toString();
      }

      if (tableId != null) {
        requestData['tableId'] = tableId.toString();
      }

      final response = await _dio.post(
        '$baseUrl/Orders/cashier_partially_paid',
        data: requestData.isNotEmpty ? requestData : null,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print("response data&&&&&: $data");
        if (data['success'] == true) {
          final List<dynamic> ordersData = data['data'];
          return ordersData
              .map((orderJson) => Order.fromJson(orderJson))
              .toList();
        } else {
          throw Exception(
              'Failed to fetch orders: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to fetch orders: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch orders: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<OrderDetail> fetchPartialPaymentOrderDetail(int orderId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/Orders/cashier_partially_paid_detail',
        data: {
          'orderId': orderId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return OrderDetail.fromJson(data['data']);
        } else {
          throw Exception(
              'Failed to fetch order details: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch order details: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch order details: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<bool> markOrderAsServed(int orderId) async {
    try {
      // Get current user from SharedPreferences
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final response = await _dio.post(
        '$baseUrl/Orders/save_mark_order',
        data: {
          'orderId': orderId.toString(),
          'status': 'served',
          'cashierId': currentUser.id.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return true;
        } else {
          throw Exception(
              'Failed to mark order as served: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to mark order as served: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to mark order as served: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      // Get current user from SharedPreferences
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final response = await _dio.post(
        '$baseUrl/Orders/save_mark_order',
        data: {
          'orderId': orderId.toString(),
          'status': status,
          'cashierId': currentUser.id.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return true;
        } else {
          throw Exception(
              'Failed to update order status: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to update order status: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to update order status: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<List<Order>> fetchServedOrders({
    String? dateFrom,
    String? dateTo,
    int? waiterId,
    int? tableId,
    String? orderSearch,
  }) async {
    try {
      Map<String, dynamic> requestData = {
        'dateFrom': dateFrom ?? '',
        'dateTo': dateTo ?? '',
        'waiterId': waiterId?.toString() ?? '',
        'tableId': tableId?.toString() ?? '',
        'orderSearch': orderSearch ?? '',
      };

      final response = await _dio.post(
        '$baseUrl/Orders/show_served_orders',
        data: requestData,
      );
      print("requestData::::::::::::::::::::::::::::::: $requestData");
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> ordersData = data['data'];
          return ordersData
              .map((orderJson) => Order.fromJson(orderJson))
              .toList();
        } else {
          throw Exception(
              'Failed to fetch served orders: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch served orders: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch served orders: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<List<Order>> fetchDifferentOrder(
      {required String orderId}) async {
    try {
      Map<String, dynamic> requestData = {
        'orderId': orderId,
      };

      final response = await _dio.post(
        '$baseUrl/Orders/show_different_order.php',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> ordersData = data['data'];
          return ordersData
              .map((orderJson) => Order.fromJson(orderJson))
              .toList();
        } else {
          throw Exception(
              'Failed to fetch served orders: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch served orders: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch served orders: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<OrderDetail> fetchServedOrderDetail(int orderId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/Orders/show_served_orders_detail',
        data: {
          'orderId': orderId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('Response data******hhhhhhhhhhhh**********: $data'); // Debug log
        print('Response status code: ${response.statusCode}'); // Debug log
        if (data['success'] == true) {
          return OrderDetail.fromJson(data['data']);
        } else {
          throw Exception(
              'Failed to fetch served order details: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch served order details: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch served order details: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<List<Order>> fetchCompletedOrders({
    String? dateFrom,
    String? dateTo,
    int? waiterId,
    String? paymentMethod,
    String? orderSearch,
  }) async {
    try {
      Map<String, dynamic> requestData = {
        'dateFrom': dateFrom ?? '',
        'dateTo': dateTo ?? '',
        'waiterId': waiterId?.toString() ?? '',
        'paymentMethod': paymentMethod ?? '',
        'orderSearch': orderSearch ?? '',
      };

      final response = await _dio.post(
        '$baseUrl/Orders/Completed_orders',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> ordersData = data['data'];
          return ordersData
              .map((orderJson) => Order.fromJson(orderJson))
              .toList();
        } else {
          throw Exception(
              'Failed to fetch completed orders: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch completed orders: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch completed orders: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<OrderDetail> fetchCompletedOrderDetail(int orderId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/Orders/Completed_Orders_Detail',
        data: {
          'orderId': orderId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Debug logging to help diagnose issues
        print('Completed order detail response: $data');

        if (data['success'] == true) {
          // Check if the data is valid before parsing
          if (data['data'] != null) {
            try {
              return OrderDetail.fromJson(data);
            } catch (parseError) {
              print('Error parsing order detail: $parseError');
              throw Exception('Failed to parse order details: $parseError');
            }
          } else {
            throw Exception('Order details data is empty');
          }
        } else {
          // Better error message that includes the API message
          String errorMsg = data['message'] ?? 'Unknown error';
          throw Exception('Failed to fetch completed order details: $errorMsg');
        }
      } else {
        throw Exception(
            'Failed to fetch completed order details: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception(
            'Failed to fetch completed order details: ${e.message}');
      }
    } catch (e) {
      // Better error message with the original exception details
      print('Unexpected error in fetchCompletedOrderDetail: $e');
      if (e.toString().contains('Payment details')) {
        // If this is a payment-related error, make it more user-friendly
        throw Exception(
            'Order found but payment details are not available. The payment may have been canceled.');
      } else {
        throw Exception('Unexpected error: $e');
      }
    }
  }

  static Future<bool> recordPayment({
    required int orderId,
    required double totalAmount,
    required double amountReceived,
    required List<Map<String, dynamic>> paymentMethods,
    String? paymentNotes,
    double? discountValue, // Percentage discount (e.g., 10 for 10%)
    double? discount, // Absolute discount amount
  }) async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final changeAmount = amountReceived - totalAmount;

      Map<String, dynamic> requestData = {
        'orderId': orderId.toString(),
        'totalAmount': totalAmount.toString(),
        'amountReceived': amountReceived.toString(),
        'changeAmount': changeAmount.toString(),
        'paymentNotes': paymentNotes ?? '',
        'discountValue': discountValue?.toString() ?? '',
        'discount': discount?.toString() ?? '',
        'paymentMethods': paymentMethods,
        'cashierId': currentUser.id.toString(),
        // Client information is included directly in payment methods now
      };

      print('Recording payment with request: $requestData');

      final response = await _dio.post(
        '$baseUrl/Orders/record_payment',
        data: requestData,
      );

      print('💳 Payment response status: ${response.statusCode}');
      print('💳 Payment response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          print('✅ Payment recorded successfully');
          return true;
        } else {
          throw Exception(
              'Failed to record payment: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to record payment: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to record payment: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<List<Category>> fetchCategories() async {
    try {
      final response = await _dio.get('$baseUrl/Orders/get_categories');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> categoriesData = data['data'];
          return categoriesData
              .map((categoryJson) => Category.fromJson(categoryJson))
              .toList();
        } else {
          throw Exception(
              'Failed to fetch categories: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch categories: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch categories: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<List<MenuItem>> fetchItemsByCategory(int categoryId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/Orders/show_item_by_category',
        data: {
          'categoryId': categoryId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> itemsData = data['data'];
          return itemsData
              .map((itemJson) => MenuItem.fromJson(itemJson))
              .toList();
        } else {
          throw Exception(
              'Failed to fetch items: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to fetch items: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch items: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<List<Specification>> fetchSpecifications(int itemId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/Orders/show_Specification',
        data: {
          'itemId': itemId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print("Response data&&&&&: $data");
        if (data['success'] == true) {
          final List<dynamic> specificationsData = data['data'];
          return specificationsData
              .map((specJson) => Specification.fromJson(specJson))
              .toList();
        } else {
          throw Exception(
              'Failed to fetch specifications: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch specifications: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch specifications: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<List<SpecialClient>> fetchSpecialClients() async {
    try {
      final response = await _dio.get('$baseUrl/Orders/Get_special_client');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> clientsData = data['data'];
          return clientsData
              .map((clientJson) => SpecialClient.fromJson(clientJson))
              .toList();
        } else {
          throw Exception(
              'Failed to fetch special clients: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch special clients: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch special clients: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<ClientDiscountResponse> fetchClientDiscount(
      int clientId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/Orders/show_client_discount',
        data: {
          'clientId': clientId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return ClientDiscountResponse.fromJson(data);
        } else {
          throw Exception(
              'Failed to fetch client discount: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch client discount: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch client discount: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchKitchenItems(
      List<int> itemIds) async {
    try {
      final response = await _dio.post(
        '$baseUrl/Orders/show_kichen_item',
        data: {
          'itemIds': itemIds,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          print('Kitchen items data: $data');
          return {
            'hasKitchenItems': data['hasKitchenItems'] ?? false,
            'kitchenItems': (data['kitchenItems'] as List<dynamic>?)
                    ?.map((item) => KitchenItem.fromJson(item))
                    .toList() ??
                [],
          };
        } else {
          throw Exception(
              'Failed to fetch kitchen items: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch kitchen items: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch kitchen items: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchBarItems(
      List<int> itemIds, String orderId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/Orders/show_bar_item',
        data: {
          'itemIds': itemIds,
          'orderId': orderId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          print('Bar items data: $data');
          return {
            'hasKitchenItems': data['hasKitchenItems'] ?? false,
            'kitchenItems': (data['kitchenItems'] as List<dynamic>?)
                    ?.map((item) => KitchenItem.fromJson(item))
                    .toList() ??
                [],
          };
        } else {
          throw Exception(
              'Failed to fetch bar items: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch bar items: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch bar items: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<Map<String, dynamic>> processOrder({
    required int? tableId,
    required String handlerType, // "waiter" or "cashier"
    required int? handlerId,
    int? clientId,
    String? orderType,
    String? orderNotes,
    String? createdAt,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      Map<String, dynamic> requestData = {
        'tableId': tableId?.toString() ?? '',
        'handlerType': handlerType,
        'handlerId': handlerId?.toString() ?? '',
        'clientId': clientId?.toString() ?? '',
        'orderType': orderType ?? 'dine_in',
        'orderNotes': orderNotes ?? '',
        'cashierId': currentUser.id.toString(),
        'items': items,
        'createdAt': createdAt ?? '',
      };

      print('🔍 Processing order with requestwwwwwwww: $requestData');

      final response = await _dio.post(
        '$baseUrl/Orders/save_cashier_order',
        data: requestData,
      );

      print("url: $baseUrl/Orders/save_cashier_order");
      print('📦 Order response status: ${response.statusCode}');
      print('📦 Order response data: ${response.data}');

      print('📦 Order response status: ${response.statusCode}');
      print('📦 Order response data: ${response.data}');

      final data = response.data;
      print("data:::: $data");
      if (data['success'] == true) {
        print('✅ Order processed successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Order processed successfully',
          'order_number': data['order_number'] ?? '',
          'order_id': data['order_id'] ?? data['orderId'] ?? '',
          'handler_name': data['handler_name'] ?? 'Self-handled',
          'handler_type': data['handler_type'] ?? handlerType,
          'table_info': data['table_info'] ?? 'Unknown table',
          'subtotal': data['subtotal'] ?? 0,
          'discount': data['discount'] ?? 0,
          'total': data['total'] ?? 0,
          'client_name': data['client_name'],
          'discount_details': data['discount_details'] ?? [],
          'hasKitchenItems': data['hasKitchenItems'] ?? false,
          'kitchenItems': data['kitchenItemIds'] ?? [],
          'hasBarItems': data['hasBarItems'] ?? false,
          'barItems': data['barItemIds'] ?? [],
        };
      } else {
        // Extract the specific error message from the API response
        String apiMessage = data['message'] ?? 'Unknown error';
        print('❌ API returned error: $apiMessage');
        throw Exception('Failed to process order: $apiMessage');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to process order: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<Map<String, dynamic>> addItemToOrder({
    required int orderId,
    required List<Map<String, dynamic>> items,
    int? cashierId,
  }) async {
    try {
      // Get current user if cashierId not provided
      int finalCashierId = cashierId ?? 0;
      if (finalCashierId == 0) {
        final currentUser = await AuthService.getCurrentUser();
        finalCashierId = currentUser?.id ?? 0;
      }

      // Prepare the request body
      final requestBody = {
        'orderId': orderId.toString(),
        'cashierId': finalCashierId.toString(),
        'newItems': items,
      };

      print('📝 AddItemToOrder Request Body: $requestBody');

      final response = await _dio.post(
        '$baseUrl/Orders/add_new_item',
        data: requestBody,
      );

      print("📡 AddItemToOrder Response Status: ${response.statusCode}");
      print('📦 AddItemToOrder Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          print('✅ Items added to order successfully');
          return {
            'success': true,
            'message': data['message'] ?? 'Items added to order successfully',
            'additional_subtotal': data['additional_subtotal'] ?? 0,
            'additional_discount': data['additional_discount'] ?? 0,
            'new_subtotal': data['new_subtotal'] ?? 0,
            'new_discount': data['new_discount'] ?? 0,
            'new_total': data['new_total'] ?? 0,
            'new_vat': data['new_vat'] ?? 0,
            'new_service_fee': data['new_service_fee'] ?? 0,
            'new_grand_total': data['new_grand_total'] ?? 0,
            'hasKitchenItems': data['hasKitchenItems'] ?? false,
            'kitchenItems': data['kitchenItemIds'] ?? [],
            'hasBarItems': data['hasBarItems'] ?? false,
            'barItems': data['barItemIds'] ?? [],
          };
        } else {
          throw Exception(
              'Failed to add items to order: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to add items to order: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to add items to order: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<Map<String, dynamic>> processItemReturn({
    required int orderId,
    required List<Map<String, dynamic>> returnItems,
  }) async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      Map<String, dynamic> requestData = {
        'orderId': orderId.toString(),
        'userId': currentUser.id.toString(),
        'returnItems': returnItems,
      };

      print('🔍 Processing item return with request: $requestData');

      final response = await _dio.post(
        '$baseUrl/Orders/return_item',
        data: requestData,
      );

      print('📦 Return items response status: ${response.statusCode}');
      print('📦 Return items response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          print('✅ Items returned successfully');

          // Process automatic printing for returned items
          if ((data['returned_items_kitchen'] != null &&
                  (data['returned_items_kitchen'] as List).isNotEmpty) ||
              (data['returned_items_bar'] != null &&
                  (data['returned_items_bar'] as List).isNotEmpty)) {
            AutoPrintService.processReturnItemsAutoPrint(
              orderId: orderId,
              orderNumber: data['order_number'] ?? orderId.toString(),
              returnedItemsKitchen: data['returned_items_kitchen'] ?? [],
              returnedItemsBar: data['returned_items_bar'] ?? [],
            );
          }

          return {
            'success': true,
            'message': data['message'] ?? 'Items returned successfully',
            'total_return_value': data['total_return_value'] ?? 0,
            'new_subtotal': data['new_subtotal'] ?? 0,
            'new_discount': data['new_discount'] ?? 0,
            'new_total': data['new_total'] ?? 0,
            'new_vat': data['new_vat'] ?? 0,
            'new_service_fee': data['new_service_fee'] ?? 0,
            'new_grand_total': data['new_grand_total'] ?? 0,
            'returned_items': data['returned_items'] ?? [],
            'returned_items_kitchen': data['returned_items_kitchen'] ?? [],
            'returned_items_bar': data['returned_items_bar'] ?? [],
            'items_returned_count': data['items_returned_count'] ?? 0,
            'hasKitchenItems': data['hasKitchenItems'] ?? false,
            'kitchenItems': data['kitchenItemIds'] ?? [],
            'hasBarItems': data['hasBarItems'] ?? false,
            'barItems': data['barItemIds'] ?? [],
          };
        } else {
          throw Exception(
              'Failed to return items: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to return items: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to return items: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<List<String>> fetchReturnReasons() async {
    try {
      print(
          '📋 Fetching return reasons from: $baseUrl/Orders/getReturnReason');
      final response = await _dio.get('$baseUrl/Orders/getReturnReason');
      print('📋 Return reasons response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> reasonsData = data['data'];
          return reasonsData
              .map((reason) => reason['reason_name'].toString())
              .toList();
        } else {
          throw Exception(
              'Failed to fetch return reasons: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to fetch return reasons: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to fetch return reasons: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<List<MenuItem>> searchMenuItems(String searchTerm) async {
    try {
      final response = await _dio.post(
        '$baseUrl/Orders/search_menu_item',
        data: {
          'searchTerm': searchTerm,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> itemsData = data['data'];
          return itemsData
              .map((itemJson) => MenuItem.fromJson(itemJson))
              .toList();
        } else {
          throw Exception(
              'Failed to search menu items: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to search menu items: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to search menu items: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<bool> removeServiceFee(int orderId) async {
    try {
      // Get current user from SharedPreferences
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final requestData = {
        'orderId': orderId.toString(),
        'userId': currentUser.id.toString(),
      };

      print("Request Data for removing service fee: $requestData");

      final response = await _dio.post(
        '$baseUrl/Orders/remove_service',
        data: requestData,
      );

      print('Remove Service Fee Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return true;
        } else {
          throw Exception(
              'Failed to remove service fee: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to remove service fee: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to remove service fee: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<bool> addBackServiceFee(int orderId) async {
    try {
      // Get current user from SharedPreferences
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final requestData = {
        'orderId': orderId.toString(),
        'userId': currentUser.id.toString(),
      };

      print("Request Data for adding back service fee: $requestData");

      final response = await _dio.post(
        '$baseUrl/Orders/addBackServiceFee',
        data: requestData,
      );

      print('Add Back Service Fee Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return true;
        } else {
          throw Exception(
              'Failed to add back service fee: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to add back service fee: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to add back service fee: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<bool> applyDiscount({
    required int orderId,
    required double discountValue,
  }) async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final response = await _dio.post(
        '$baseUrl/Orders/applyDiscount',
        data: {
          'orderId': orderId,
          'discountValue': discountValue,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return true;
        } else {
          throw Exception(
              'Failed to apply discount: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to apply discount: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to apply discount: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // Method to transfer an item from one order to another
  static Future<Map<String, dynamic>> transferItem({
    required int sourceOrderId,
    required int sourceItemId,
    required int quantity,
    int? targetOrderId,
    int? tableId,
    int? handlerId,
  }) async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Determine if this is a transfer to existing order or new order creation
      final bool isExistingOrderTransfer = targetOrderId != null;

      final Map<String, dynamic> requestData = {
        'sourceOrderId': sourceOrderId.toString(),
        'sourceItemId': sourceItemId.toString(),
        'quantity': quantity.toString(),
        'userId': handlerId?.toString() ?? currentUser.id.toString(),
      };

      // Add targetOrderId for existing order transfer
      if (isExistingOrderTransfer) {
        requestData['targetOrderId'] = targetOrderId.toString();
      }
      // Add tableId for new order creation
      else if (tableId != null) {
        requestData['tableId'] = tableId.toString();
      }

      print('Transfer Item Request Body: $requestData');

      final response = await _dio.post(
        '$baseUrl/Orders/Transifer_item.php',
        data: requestData,
      );

      print('Transfer Item Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown response from server',
          'order_number': data['order_number'],
          'order_id': data['order_id'],
        };
      } else {
        throw Exception('Failed to transfer item: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to transfer item: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<bool> cancelPayment(int paymentId) async {
    try {
      // Get current user from SharedPreferences
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final response = await _dio.post(
        '$baseUrl/Orders/Delete_payment',
        data: {
          'paymentId': paymentId.toString(),
        },
      );

      print('Cancel Payment Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return true;
        } else {
          throw Exception(
              'Failed to cancel payment: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to cancel payment: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your connection.');
      } else {
        throw Exception('Failed to cancel payment: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}

class SpecialClient {
  final int id;
  final String clientName;
  final String phone;

  SpecialClient({
    required this.id,
    required this.clientName,
    required this.phone,
  });

  factory SpecialClient.fromJson(Map<String, dynamic> json) {
    return SpecialClient(
      id: int.tryParse(json['id'].toString()) ?? 0,
      clientName: json['client_name'].toString(),
      phone: json['phone'].toString(),
    );
  }
}

class ClientDiscountResponse {
  final bool success;
  final String clientName;
  final List<ClientDiscount> discounts;

  ClientDiscountResponse({
    required this.success,
    required this.clientName,
    required this.discounts,
  });

  factory ClientDiscountResponse.fromJson(Map<String, dynamic> json) {
    return ClientDiscountResponse(
      success: json['success'] ?? false,
      clientName: json['client_name']?.toString() ?? '',
      discounts: (json['discounts'] as List<dynamic>?)
              ?.map((discountJson) => ClientDiscount.fromJson(discountJson))
              .toList() ??
          [],
    );
  }
}

class ClientDiscount {
  final int id;
  final int clientId;
  final int itemId;
  final int specificationId;
  final String discountType;
  final String discountValue;
  final String validFrom;
  final String validTo;
  final String status;
  final String createdAt;
  final String clientName;
  final String itemName;
  final String specificationName;

  ClientDiscount({
    required this.id,
    required this.clientId,
    required this.itemId,
    required this.specificationId,
    required this.discountType,
    required this.discountValue,
    required this.validFrom,
    required this.validTo,
    required this.status,
    required this.createdAt,
    required this.clientName,
    required this.itemName,
    required this.specificationName,
  });

  factory ClientDiscount.fromJson(Map<String, dynamic> json) {
    return ClientDiscount(
      id: int.tryParse(json['id'].toString()) ?? 0,
      clientId: int.tryParse(json['client_id'].toString()) ?? 0,
      itemId: int.tryParse(json['item_id'].toString()) ?? 0,
      specificationId: int.tryParse(json['specification_id'].toString()) ?? 0,
      discountType: json['discount_type']?.toString() ?? '',
      discountValue: json['discount_value']?.toString() ?? '0',
      validFrom: json['valid_from']?.toString() ?? '',
      validTo: json['valid_to']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? '',
      specificationName: json['specification_name']?.toString() ?? '',
    );
  }

  double get discountAmount {
    return double.tryParse(discountValue) ?? 0.0;
  }
}
