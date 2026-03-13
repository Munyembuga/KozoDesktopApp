import 'package:dio/dio.dart';
import 'package:http/http.dart';
import 'package:kozo/models/categories_sold_item.dart';
import 'package:kozo/utils/constants.dart';

class ReportService {
  final Dio _dio = Dio();
  final String _baseUrl = '${AppConfig.baseUrl}/Orders';

  ReportService() {
    _dio.options.headers['Content-Type'] = 'application/json';
    // You can add more global configuration for Dio here
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  // Get summary statistics for a cashier
  Future<Map<String, dynamic>> getSummaryStats({
    required int cashierId,
    required String dateTimeFrom,
    required String dateTimeTo,
    String paymentMethodFilter = "",
  }) async {
    try {
      final requestData = {
        "cashierId": cashierId,
        "dateTimeFrom": dateTimeFrom,
        "dateTimeTo": dateTimeTo,
        "paymentMethodFilter": paymentMethodFilter
      };

      // 👇 Print the request details
      print("Request URL: $_baseUrl/getCashierSummaryStats");
      print("Request Body*******************************: $requestData");

      final response = await _dio.post(
        '$_baseUrl/getCashierSummaryStats',
        data: requestData,
      );

      // 👇 Print response details (optional for debugging)
      print("Response status: ${response.statusCode}");
      print("Response data: ${response.data}");

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(
              'API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load summary stats: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print("Dio error: ${e.message}");
      throw _handleDioError(e);
    }
  }

  // Get payment methods breakdown for a cashier
  Future<List<dynamic>> getPaymentMethodsBreakdown({
    required int cashierId,
    required String dateTimeFrom,
    required String dateTimeTo,
    String paymentMethodFilter = "",
  }) async {
    try {
      final requestData = {
        "cashierId": cashierId,
        "dateTimeFrom": dateTimeFrom,
        "dateTimeTo": dateTimeTo,
        "paymentMethodFilter": paymentMethodFilter
      };

      print("Request URL: $_baseUrl/getCashierPaymentMethodsBreakdown");
      print("Request Body: $requestData");

      final response = await _dio.post(
        '$_baseUrl/getCashierPaymentMethodsBreakdown',
        data: requestData,
      );

      print("Response status: ${response.statusCode}");
      print("Response data: ${response.data}");

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return data['methods'];
        } else {
          throw Exception(
              'API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to load payment breakdown: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get completed orders for a cashier
  Future<List<dynamic>> getCompletedOrders({
    required int cashierId,
    required String dateTimeFrom,
    required String dateTimeTo,
    String paymentMethodFilter = "",
  }) async {
    try {
      final requestData = {
        "cashierId": cashierId,
        "dateTimeFrom": dateTimeFrom,
        "dateTimeTo": dateTimeTo,
        "paymentMethodFilter": paymentMethodFilter,
      };

      print("Request Data for Completed Orders: $requestData");

      final response = await _dio.post(
        '$_baseUrl/getCashierCompletedOrders',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return data['orders'];
        } else {
          throw Exception(
              'API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to load completed orders: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get unpaid orders for a cashier
  Future<List<dynamic>> getUnpaidOrders({
    required int cashierId,
    required String dateTimeFrom,
    required String dateTimeTo,
    String paymentMethodFilter = "",
  }) async {
    try {
      final requestData = {
        "cashierId": cashierId,
        "dateTimeFrom": dateTimeFrom,
        "dateTimeTo": dateTimeTo,
        "paymentMethodFilter": paymentMethodFilter,
      };

      print("Request Data for Unpaid Orders: $requestData");

      final response = await _dio.post(
        '$_baseUrl/getCashierUnpaidOrders',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return data['unpaid_orders'];
        } else {
          throw Exception(
              'API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load unpaid orders: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get category revenue breakdown
  Future<List<dynamic>> getCategoryRevenue({
    required String dateTimeFrom,
    required String dateTimeTo,
  }) async {
    try {
      final requestData = {
        "dateTimeFrom": dateTimeFrom,
        "dateTimeTo": dateTimeTo,
      };

      print("Request Data for Category Revenue: $requestData");

      final response = await _dio.post(
        '$_baseUrl/cashier_getCategory_Revenue',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(
              'API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to load category revenue: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get whole summary revenue data
  Future<List<dynamic>> getWholeSummary({
    required String dateTimeFrom,
    required String dateTimeTo,
  }) async {
    try {
      final requestData = {
        "dateTimeFrom": dateTimeFrom,
        "dateTimeTo": dateTimeTo,
      };

      print("Request Data for Whole Summary: $requestData");

      final response = await _dio.post(
        '$_baseUrl/getWholeSummary',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(
              'API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load whole summary: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get tax revenue breakdown
  Future<List<dynamic>> getTaxRevenue({
    required String dateTimeFrom,
    required String dateTimeTo,
  }) async {
    try {
      final requestData = {
        "dateTimeFrom": dateTimeFrom,
        "dateTimeTo": dateTimeTo,
      };

      print("Request Data for Tax Revenue: $requestData");

      final response = await _dio.post(
        '$_baseUrl/cashier_tax_revenue',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(
              'API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load tax revenue: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get discount summary breakdown
  Future<List<dynamic>> getDiscountSummary({
    required String dateTimeFrom,
    required String dateTimeTo,
  }) async {
    try {
      final requestData = {
        "dateTimeFrom": dateTimeFrom,
        "dateTimeTo": dateTimeTo,
      };

      print("Request Data for Discount Summary: $requestData");

      final response = await _dio.post(
        '$_baseUrl/discountSummary',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(
              'API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to load discount summary: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Check if printing is allowed for the given date range
  Future<bool> isPrintingAllowed({
    required String dateTimeFrom,
    required String dateTimeTo,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/allow_print',
        data: {
          'dateTimeFrom': dateTimeFrom,
          'dateTimeTo': dateTimeTo,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Check the canPrint field in the response
        if (data['success'] == true) {
          return data['canPrint'] == true;
        }
        return false;
      } else {
        return false;
      }
    } catch (e) {
      print('Error checking if printing is allowed: $e');
      return false;
    }
  }

  // Get all deposits
  Future<Map<String, dynamic>> getAllDeposits({
    required String dateTimeFrom,
    required String dateTimeTo,
  }) async {
    try {
      final requestData = {
        "dateTimeFrom": dateTimeFrom,
        "dateTimeTo": dateTimeTo,
      };

      print("Request Data for Deposits: $requestData");

      final response = await _dio.post(
        'https://kozo.hdev.rw/API_TEST/Orders/Get_all_deposite',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(
              'API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load deposits: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<CategorySoldSummary>> getCategorySoldItems({
    required String dateTimeFrom,
    required String dateTimeTo,
  }) async {
    try {
      final requestData = {
        "dateTimeFrom": dateTimeFrom,
        "dateTimeTo": dateTimeTo,
      };

      print("Request Data for Category Sold Items: $requestData");

      final response = await _dio.post(
        '${AppConfig.baseUrl}/Orders/getCategorySoldItems',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> categoriesJson = data['data'] ?? [];
          return categoriesJson
              .map((category) => CategorySoldSummary.fromJson(category))
              .toList();
        } else {
          throw Exception(
              'API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Failed to load category sold items: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Helper method to handle Dio errors
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
            'Connection timeout. Please check your internet connection.');
      case DioExceptionType.badResponse:
        return Exception(
            'Server returned error ${e.response?.statusCode}: ${e.response?.statusMessage}');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.connectionError:
        return Exception(
            'Connection error. Please check your internet connection.');
      default:
        return Exception('An error occurred: ${e.message}');
    }
  }
}
