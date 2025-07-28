// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  // --- الحالة ---
  User? _user;
  String? _token;
  bool _isLoading = true; // ابدأ بـ true لتجنب مشاكل التهيئة الأولية
  String? _error;

  // --- Getters ---
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _token != null;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  // --- دوال المصادقة ---

  /// التحقق من حالة المصادقة عند بدء التطبيق.
  Future<void> checkAuthStatus() async {
    try {
      _token = await _apiService.getAuthToken();
      if (_token != null) {
        _user = await _apiService.fetchCurrentUser(_token!);
      } else {
        _user = null;
      }
    } catch (e) {
      print('Failed to authenticate with saved token: $e');
      await _apiService.removeAuthToken();
      _token = null;
      _user = null;
    } finally {
      // بعد انتهاء كل شيء، أوقف التحميل الأولي
      _isLoading = false;
      notifyListeners();
    }
  }

// في AuthProvider
  Future<void> register(String firstName, String lastName, String username, String email, String password, String passwordConfirmation, String phone, String type) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    print("AuthProvider: [REGISTER] Process started for email: $email");

    try {
      print("AuthProvider: [REGISTER] Calling ApiService.registerUser...");
      final authResponse = await _apiService.registerUser(firstName, lastName, username, email, password, passwordConfirmation, phone, type);
      print("AuthProvider: [REGISTER] API call successful. Token received.");

      _user = authResponse.user;
      _token = authResponse.accessToken;
      print("AuthProvider: [REGISTER] User and token stored locally. User type: ${_user?.type}");

    } catch (e) {
      print("AuthProvider: [REGISTER] An error occurred: $e");
      _user = null;
      _token = null;
      rethrow;
    } finally {
      _isLoading = false;
      print("AuthProvider: [REGISTER] Process finished. IsAuthenticated: $isAuthenticated");
      notifyListeners();
    }
  }

  // في AuthProvider
// في ملف: lib/providers/auth_provider.dart
// داخل كلاس: AuthProvider

// في AuthProvider
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    print("AuthProvider: [LOGIN] Process started for email: $email");

    try {
      print("AuthProvider: [LOGIN] Calling ApiService.loginUser...");
      final authResponse = await _apiService.loginUser(email, password);
      print("AuthProvider: [LOGIN] API call successful. Token received.");

      _user = authResponse.user;
      _token = authResponse.accessToken;
      print("AuthProvider: [LOGIN] User and token stored locally. User type: ${_user?.type}");
      return true; // Indicate success
    } catch (e) {
      print("AuthProvider: [LOGIN] An error occurred: $e");
      _user = null;
      _token = null;
      rethrow; // Rethrow the exception to be caught in the UI
    } finally {
      _isLoading = false;
      print("AuthProvider: [LOGIN] Process finished. IsAuthenticated: $isAuthenticated");
      notifyListeners();
    }
  }

  /// تسجيل خروج المستخدم.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    final oldToken = _token;
    _user = null;
    _token = null;
    notifyListeners(); // أعلم الواجهة فوراً بالتغيير

    try {
      if (oldToken != null) {
        await _apiService.logoutUser(oldToken);
      }
    } catch (e) {
      print('Error during logout API call: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- توابع تحديث بيانات المستخدم ---

  /// تحديث الملف الشخصي للمستخدم الحالي.
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    if (_token == null) throw ApiException(401, 'User not authenticated.');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateUserProfile(_token!, profileData);
      final updatedUser = await _apiService.fetchCurrentUser(_token!);
      _user = updatedUser;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تحديث مهارات المستخدم الحالي.
  Future<void> syncUserSkills(dynamic skillsToSync) async {
    if (_token == null) throw ApiException(401, 'User not authenticated.');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUserWithSkills = await _apiService.syncUserSkills(_token!, skillsToSync);
      _user = updatedUserWithSkills;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}