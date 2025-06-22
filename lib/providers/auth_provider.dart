// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  // --- حالة المصادقة والتحميل والخطأ ---
  User? _user; // بيانات المستخدم المسجل دخوله حاليًا
  String? _token; // التوكن الخاص بالمستخدم المسجل دخوله حاليًا
  bool _isLoading = false; // لحالة التحميل العامة في Provider
  String? _error; // حقل خاص لتخزين رسالة الخطأ

  // --- Getters للوصول إلى الحالة ---
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _token != null;
  String? get error => _error;

  // --- مثيل خدمة API ---
  final ApiService _apiService = ApiService();

  // --- توابع Authentication ---

  /// التحقق من حالة المصادقة عند بدء التطبيق.
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _token = await _apiService.getAuthToken();
      if (_token != null) {
        _user = await _apiService.fetchCurrentUser(_token!);
        _error = null;
      } else {
        _user = null;
        _error = null;
      }
    } catch (e) {
      print('Failed to fetch user with saved token: $e');
      await _apiService.removeAuthToken();
      _token = null;
      _user = null;
      _error = 'Failed to authenticate with saved token.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تسجيل مستخدم جديد.
  Future<void> register(String firstName, String lastName, String username, String email, String password, String passwordConfirmation, String phone, String type) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authResponse = await _apiService.registerUser(firstName, lastName, username, email, password, passwordConfirmation, phone, type);
      _user = authResponse.user;
      _token = authResponse.accessToken;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'An unexpected error occurred during registration: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تسجيل دخول المستخدم.
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authResponse = await _apiService.loginUser(email, password);
      _user = authResponse.user;
      _token = authResponse.accessToken;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'An unexpected error occurred during login: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تسجيل خروج المستخدم.
  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_token != null) {
        await _apiService.logoutUser(_token!);
      }
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      _user = null;
      _token = null;
      _error = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- توابع تحديث بيانات المستخدم ---

  // **** بداية التعديل المطلوب ****

  /// تحديث الملف الشخصي للمستخدم الحالي.
  /// هذا التابع يستدعي API ويقوم بتحديث كائن المستخدم المحلي بالبيانات الجديدة مباشرة.
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    if (_token == null) {
      throw ApiException(401, 'User not authenticated.');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. استدعاء التابع المعدل في ApiService الذي يعيد كائن User كاملاً
      final User updatedUser = (await _apiService.updateUserProfile(_token!, profileData)) as User;

      // 2. تحديث كائن المستخدم المحلي في الـ Provider بالكائن المحدث القادم من الـ API
      _user = updatedUser;

      _error = null; // مسح الخطأ في حالة النجاح

    } on ApiException catch (e) {
      _error = e.message;
      // لا ترمي الخطأ هنا ما لم تكن الواجهة بحاجة ماسة لمعالجته بشكل خاص
    } catch (e) {
      _error = 'Failed to update profile: ${e.toString()}';
    } finally {
      // 3. تأكد من إيقاف التحميل وإعلام الواجهة بالتغييرات في جميع الحالات
      _isLoading = false;
      notifyListeners();
    }
  }

  // **** نهاية التعديل المطلوب ****

  /// تحديث مهارات المستخدم الحالي (مزامنة).
  Future<void> syncUserSkills(dynamic skillsToSync) async {
    if (_token == null) {
      throw ApiException(401, 'User not authenticated.');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUserWithSkills = await _apiService.syncUserSkills(_token!, skillsToSync);
      _user = updatedUserWithSkills; // تحديث المستخدم المحلي بالمهارات الجديدة
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to sync skills: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}