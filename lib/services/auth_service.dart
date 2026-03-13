import 'dart:convert';
import 'dart:io';
import 'package:kozo/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = AppConfig.baseUrl;
  static const String userKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';

  static Future<Map<String, dynamic>> login(String pin) async {
    try {
      print('Attempting login to: $baseUrl/users/auth');

      // Create HttpClient with proper settings
      final httpClient = HttpClient();
      httpClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

      final request =
          await httpClient.postUrl(Uri.parse('$baseUrl/users/auth'));
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.headers.set('Accept', 'application/json');
      request.headers.set('Accept-Charset', 'utf-8');
      request.headers.set('Accept-Encoding',
          'identity'); // Disable compression to avoid gzip issues

      request.write(jsonEncode({'pin': pin}));

      final response = await request.close();

      // Read raw bytes first
      final bytes = await response.fold<List<int>>(
        <int>[],
        (List<int> previous, List<int> element) => previous..addAll(element),
      );

      // Try to decode as UTF-8
      String responseBody;
      try {
        responseBody = utf8.decode(bytes);
      } catch (e) {
        // If UTF-8 fails, try latin1
        responseBody = latin1.decode(bytes);
      }

      print('Response status code: ${response.statusCode}');
      print('Response body: $responseBody');

      // Close the client
      httpClient.close();

      if (responseBody.isEmpty) {
        return {
          'success': false,
          'message':
              'Server returned empty response (Status: ${response.statusCode})',
        };
      }

      // Handle redirect responses
      if (response.statusCode == 301 || response.statusCode == 302) {
        return {
          'success': false,
          'message': 'Server redirect detected. Please check the API URL.',
        };
      }

      final data = jsonDecode(responseBody);
      print("user login successful respond data:$data");
      if (response.statusCode == 200 && data['success'] == true) {
        final user = User.fromJson(data['user']);
        await _saveUserData(user);
        return {
          'success': true,
          'message': data['message'],
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e, stackTrace) {
      print('Login error: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(user.toJson()));
    await prefs.setBool(isLoggedInKey, true);
  }

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(userKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(isLoggedInKey) ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
    await prefs.setBool(isLoggedInKey, false);
  }
}
