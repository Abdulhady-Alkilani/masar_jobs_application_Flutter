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

  /// تسجيل مستخدم جديد.
  Future<void> register(String firstName, String lastName, String username, String email, String password, String passwordConfirmation, String phone, String type) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authResponse = await _apiService.registerUser(firstName, lastName, username, email, password, passwordConfirmation, phone, type);
      _user = authResponse.user;
      _token = authResponse.accessToken;
    } catch (e) {
      _user = null;
      _token = null;
      rethrow; // إعادة رمي الخطأ للواجهة لعرضه
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // في AuthProvider
// في ملف: lib/providers/auth_provider.dart
// داخل كلاس: AuthProvider

  /// تسجيل دخول المستخدم مع التحقق من حالته وتتبع العملية.
  Future<void> login(String email, String password) async {
    // الخطوة 1: إعلام الواجهة ببدء عملية التحميل
    _isLoading = true;
    _error = null; // مسح أي أخطاء سابقة
    notifyListeners();

    print("AuthProvider: 1. Login process started.");

    try {
      // الخطوة 2: استدعاء API لإرسال بيانات تسجيل الدخول
      print("AuthProvider: 2. Calling API with email: $email");
      final authResponse = await _apiService.loginUser(email, password);
      print("AuthProvider: 3. API call successful. Received user type: ${authResponse.user?.type}, status: ${authResponse.user?.status}");

      // الخطوة 3: التحقق من صلاحية الحساب (Business Logic)
      final userStatus = authResponse.user?.status;

      // التحقق إذا كان الحساب معلقاً
      if (userStatus == 'pending') {
        print("AuthProvider: 4a. User status is 'pending'. Aborting login.");
        await _apiService.removeAuthToken(); // إزالة التوكن إذا كان قد تم حفظه بالخطأ
        throw ApiException(403, 'حسابك لا يزال قيد المراجعة. يرجى الانتظار حتى يتم تفعيله.');
      }

      // التحقق إذا كان الحساب مرفوضاً أو محظوراً
      if (userStatus == 'rejected' || userStatus == 'banned') {
        print("AuthProvider: 4b. User status is '$userStatus'. Aborting login.");
        await _apiService.removeAuthToken();
        throw ApiException(403, 'تم رفض أو حظر هذا الحساب. يرجى التواصل مع الإدارة.');
      }

      // الخطوة 4: إذا تم اجتياز كل عمليات التحقق بنجاح
      print("AuthProvider: 5. All checks passed. Storing user and token.");
      _user = authResponse.user;
      _token = authResponse.accessToken;

    } catch (e) {
      // هذا سيلتقط أي خطأ، سواء من API (مثل كلمة مرور خاطئة)
      // أو من منطق التحقق الذي أضفناه (مثل حساب معلق)
      print("AuthProvider: 6. Caught an error during login: $e");

      // تأكد من مسح أي بيانات قديمة للمستخدم
      _user = null;
      _token = null;

      // أعد رمي الخطأ لتتمكن الواجهة (LoginScreen) من التقاطه وعرضه
      rethrow;
    } finally {
      // الخطوة الأخيرة: هذا الكود سيعمل دائماً، سواء نجحت العملية أم فشلت
      _isLoading = false;
      // طباعة الحالة النهائية للمصادقة
      print("AuthProvider: 7. Login process finished. isAuthenticated is now: $isAuthenticated");
      // إعلام الواجهة بانتهاء التحميل وتحديث الحالة (سواء كانت نجاحاً أو فشلاً)
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