
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/auth_service.dart';
import '../models/user_model.dart';
import '../../../core/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      _user = result['user'];
      final token = result['token'];
      
      await _storage.write(key: 'jwt_token', value: token);
      
      _isAuthenticated = true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
     await _storage.delete(key: 'jwt_token');
     _user = null;
     _isAuthenticated = false;
     notifyListeners();
  }

  Future<void> checkAuth() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      // Ideally verify token with API or decode it
      // For now just assume authenticated if token exists
      _isAuthenticated = true;
      notifyListeners();
      
      try {
        _user = await _authService.getUser();
        notifyListeners();
      } catch (e) {
        print('Error fetching user profile: $e');
        // Maybe force logout if fetching user fails (e.g. token expired)?
        // For now, keep authenticated but without user data, or handle gracefully.
      }
    }
  }
}
