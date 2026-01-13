import 'package:dio/dio.dart';
import 'package:http/http.dart';
import 'package:kozo/utils/constants.dart';

class WaiterReportingServices {
  final Dio _dio = Dio();
  final String _baseUrl = '${AppConfig.baseUrl}/Orders';

  WaiterReportingServices() {
    _dio.options.headers['Content-Type'] = 'application/json';
    // You can add more global configuration for Dio here
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  // Get summary statistics for a waiter
  Future<Map<String, dynamic>> getSummaryStats({
    required int waiterId,
    required String dateTimeFrom,
    required String dateTimeTo,
    String paymentMethodFilter = "",
  }) async {
    try {
      final requestData = {
        "waiterId": waiterId,
        "dateTimeFrom": dateTimeFrom,
        "dateTimeTo": dateTimeTo,
        "paymentMethodFilter": paymentMethodFilter
      };

      // 👇 Print the request details
      print("Request URL: $_baseUrl/getWaiterSummaryStats");
      print("Request Body*******************************: $requestData");

      final response = await _dio.post(
        '$_baseUrl/getWaiterSummaryStats',
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

  // Get payment methods breakdown for a waiter
  Future<List<dynamic>> getPaymentMethodsBreakdown({
    required int waiterId,
    required String dateTimeFrom,
    required String dateTimeTo,
    String paymentMethodFilter = "",
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/getWaiterPaymentMethodsBreakdown',
        data: {
          "waiterId": waiterId,
          "dateTimeFrom": dateTimeFrom,
          "dateTimeTo": dateTimeTo,
          "paymentMethodFilter": paymentMethodFilter
        },
      );

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

  // Get completed orders for a waiter
  Future<List<dynamic>> getCompletedOrders({
    required int waiterId,
    required String dateTimeFrom,
    required String dateTimeTo,
    String paymentMethodFilter = "",
  }) async {
    try {
      final requestData = {
        "waiterId": waiterId,
        "dateTimeFrom": dateTimeFrom,
        "dateTimeTo": dateTimeTo,
        "paymentMethodFilter": paymentMethodFilter,
      };

      print("Request Data for Completed Orders: $requestData");

      final response = await _dio.post(
        '$_baseUrl/WaiterCompletedOrder',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print("Response Data for Completed Orders: $data"); // Debug print
        if (data['success'] == true) {
          // The API returns 'data' not 'orders'
          return data['data'];
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
    required int waiterId,
    required String dateTimeFrom,
    required String dateTimeTo,
    String paymentMethodFilter = "",
  }) async {
    try {
      final requestData = {
        "waiterId": waiterId,
        "dateTimeFrom": dateTimeFrom,
        "dateTimeTo": dateTimeTo,
        "paymentMethodFilter": paymentMethodFilter,
      };

      print("Request Data for Unpaid Orders: $requestData");

      final response = await _dio.post(
        '$_baseUrl/WaiterUnPaid',
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
        throw Exception('Failed to load unpaid orders: ${response.statusCode}');
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
