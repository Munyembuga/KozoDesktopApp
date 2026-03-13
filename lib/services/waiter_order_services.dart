import 'package:dio/dio.dart';
import 'package:kozo/models/paymentMethodModel.dart';
import 'package:kozo/utils/constants.dart';
import '../models/order_model.dart';
import '../models/order_detail_model.dart';
import '../models/waiter_model.dart';
import '../models/table_model.dart';
import '../models/category_model.dart';
import '../models/cart_item_model.dart' hide Specification;
import '../models/kitchen_item_model.dart';
import 'auth_service.dart';

class WaiterOrderServices {
  static const String baseUrl = AppConfig.baseUrl;
  static final Dio _dio = Dio();

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

  static Future<List<Order>> fetchPendingOrders({
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
        '$baseUrl/Orders/check_order',
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

  static Future<OrderDetail> fetchOrderDetail(int orderId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/Orders/check_orderDetail',
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
    int? tableId,
    String? orderSearch,
  }) async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      Map<String, dynamic> requestData = {
        'dateFrom': dateFrom ?? '',
        'dateTo': dateTo ?? '',
        'waiterId': currentUser.id,
        'tableId': tableId?.toString() ?? '',
        'orderSearch': orderSearch ?? '',
      };

      final response = await _dio.post(
        '$baseUrl/Orders/waiter_delived_order',
        data: requestData,
      );
      print(" Response data&&&&&&&&&&&&&&&&&&&&&&&&&&&: $requestData");
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
        print('Response data*******hhhhhhhhhhhh*********: $data'); // Debug log
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

  static Future<List<Order>> fetchPartialPaymentOrders({
    int? tableId,
  }) async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      Map<String, dynamic> requestData = {};

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

  static Future<List<Order>> fetchCompletedOrders({
    String? dateFrom,
    String? dateTo,
    String? paymentMethod,
    String? orderSearch,
  }) async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      Map<String, dynamic> requestData = {
        'dateFrom': dateFrom ?? '',
        'dateTo': dateTo ?? '',
        'waiterId': currentUser.id,
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
        if (data['success'] == true) {
          return OrderDetail.fromJson(data['data']);
        } else {
          throw Exception(
              'Failed to fetch completed order details: ${data['message'] ?? 'Unknown error'}');
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
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<bool> recordPayment({
    required int orderId,
    required double totalAmount,
    required double amountReceived,
    required List<Map<String, dynamic>> paymentMethods,
    String? paymentNotes,
    double? discount,
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
        'discount': discount?.toString() ?? '',
        'paymentMethods': paymentMethods,
        'cashierId': currentUser.id.toString(),
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

  static Future<Map<String, dynamic>> processOrder({
    required int? tableId,
    String? orderType,
    String? orderNotes,
    String? covers,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      Map<String, dynamic> requestData = {
        'tableId': tableId?.toString() ?? '',
        'orderType': orderType ?? 'dine_in',
        'orderNotes': orderNotes ?? '',
        'waiterId': currentUser.id.toString(),
        'items': items,
        'covers': covers ?? '',
      };

      print('🔍 Processing order with requestwwwwwwww: $requestData');

      final response = await _dio.post(
        '$baseUrl/Orders/waiter_make_order',
        data: requestData,
      );

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

      // Prepare the request body with the new format
      final requestBody = {
        'orderId': orderId.toString(),
        'cashierId': finalCashierId.toString(),
        'newItems': items,
      };

      print('AddItemToOrder Request Body: ${requestBody}');

      final response = await _dio.post(
        '$baseUrl/Orders/add_new_item',
        data: requestBody,
      );
      print("AddItemToOrder Response Status: ${response.statusCode}");
      print('AddItemToOrder Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          print('Items added to order successfully');
          return {
            'success': true,
            'message': data['message'] ?? 'Items added to order successfully',
            'data': data['data'],
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
          return {
            'success': true,
            'message': data['message'] ?? 'Items returned successfully',
            'data': data['data'],
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
