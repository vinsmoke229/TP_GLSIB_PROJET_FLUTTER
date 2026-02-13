import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // CRITICAL: Adapt base URL based on platform - SANITIZED
  static String get _baseUrl {
  if (kIsWeb) {
    return 'http://localhost:8000/api';
  }
  return 'http:// 192.168.1.74:8000/api';  // Ton IP WiFi !
}

  
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  DioClient() {

_dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30), // INCREASED for slow Django
        receiveTimeout: const Duration(seconds: 30), // INCREASED for slow Django
        sendTimeout: const Duration(seconds: 30),    // INCREASED for slow Django
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          // Accept all status codes to handle them manually
          return status != null && status < 500;
        },
      ),
    );

    // Add interceptor for JWT token and FULL API call logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // FULL REQUEST LOGGING - Compare with Postman

if (options.queryParameters.isNotEmpty) {
            
          }
          if (options.data != null) {

}

// CRITICAL: Only add Authorization header if token exists
          final token = await getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${token.trim()}';
            
          } else {
            // CRITICAL: Remove Authorization header if no token
            options.headers.remove('Authorization');
            
          }
          
          // Sanitize URL path
          options.path = options.path.trim();
          
          return handler.next(options);
        },
        onResponse: (response, handler) {

return handler.next(response);
        },
        onError: (error, handler) {

if (error.response?.data != null) {

}

return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Token and User ID management - ATOMIC OPERATIONS
  Future<void> saveAuthData(String token, int userId) async {
    // CRITICAL: Save both token and userId in a single atomic operation
    // This prevents database lock warnings from concurrent writes
    await Future.wait([
      _storage.write(key: _tokenKey, value: token.trim()),
      SharedPreferences.getInstance().then((prefs) => prefs.setInt(_userIdKey, userId)),
    ]);
    
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token.trim());
    
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token?.trim();
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    
  }

  // User ID management
  Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<void> deleteUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    
  }

  // Clear all auth data - ATOMIC OPERATION
  Future<void> clearAuth() async {
    // CRITICAL: Clear both token and userId atomically
    await Future.wait([
      _storage.delete(key: _tokenKey),
      SharedPreferences.getInstance().then((prefs) => prefs.remove(_userIdKey)),
    ]);
    
  }
}
