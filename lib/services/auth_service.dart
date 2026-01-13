import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kozo/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = AppConfig.baseUrl;
  static const String userKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';

  static Future<Map<String, dynamic>> login(String pin) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/auth'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);
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
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
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
