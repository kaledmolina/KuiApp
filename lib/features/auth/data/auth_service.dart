
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/api/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        // Adjust based on actual API response structure
        // Assuming { "token": "...", "user": { ... } }
        return {
          'token': data['access_token'],
          'user': User.fromJson(data['user']),
        };
      } else {
        throw Exception('Failed to login: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // Server responded with error
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      } else {
        // Network or other error
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
