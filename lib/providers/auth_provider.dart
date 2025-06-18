import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart'; // تأكد من الاستيراد

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
  bool get isAuthenticated => _user != null && _token != null; // هل المستخدم مصادق عليه؟
  String? get error => _error; // Getter عام للوصول إلى الخطأ

  // --- مثيل خدمة API ---
  final ApiService _apiService = ApiService();

  // --- إدارة التوكن في SharedPreferences (معالجة داخل ApiService حالياً) ---
  // التوابع saveAuthToken, getAuthToken, removeAuthToken هي الآن جزء من ApiService
  // لا تحتاج لإعادة تعريفها هنا.

  // --- توابع Authentication ---

  /// التحقق من حالة المصادقة عند بدء التطبيق (جلب التوكن المخزن وجلب بيانات المستخدم)
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    _error = null; // مسح الخطأ عند بدء عملية جديدة
    notifyListeners();

    try {
      _token = await _apiService.getAuthToken(); // جلب التوكن المخزن من SP

      if (_token != null) {
        // إذا وجد توكن، حاول جلب بيانات المستخدم
        _user = await _apiService.fetchCurrentUser(_token!);
        // إذا نجح الجلب، _user و _token موجودان ويتم تعيين _error إلى null (ضمن try)
        _error = null; // تأكيد مسح الخطأ في حالة النجاح

      } else {
        // لا يوجد توكن مخزن، المستخدم غير مصادق عليه
        _user = null;
        _error = null; // مسح الخطأ
      }

    } catch (e) {
      // إذا فشل جلب المستخدم (مثال: التوكن منتهي الصلاحية أو غير صالح)
      print('Failed to fetch user with saved token: $e');
      await _apiService.removeAuthToken(); // إزالة التوكن غير الصالح محلياً
      _token = null; // مسح التوكن في Provider
      _user = null; // مسح المستخدم في Provider
      _error = 'Failed to authenticate with saved token.'; // تعيين الخطأ

    } finally {
      _isLoading = false; // إنهاء حالة التحميل
      notifyListeners(); // إعلام المستمعين بتغير حالة المصادقة والتحميل والخطأ
    }
  }

  /// تسجيل مستخدم جديد.
  /// يستدعي API لإنشاء المستخدم.
  /// يحفظ التوكن وينشئ المستخدم في Provider عند النجاح.
  Future<void> register(String firstName, String lastName, String username, String email, String password, String passwordConfirmation, String phone, String type) async {
    _isLoading = true;
    _error = null; // مسح الخطأ عند بدء عملية جديدة
    notifyListeners();

    try {
      final authResponse = await _apiService.registerUser(firstName, lastName, username, email, password, passwordConfirmation, phone, type);
      // ApiService.registerUser يقوم بحفظ التوكن في SharedPreferences تلقائياً عند النجاح ويعيد AuthResponse

      _user = authResponse.user; // تعيين المستخدم من الاستجابة
      _token = authResponse.accessToken; // تعيين التوكن من الاستجابة
      _error = null; // مسح الخطأ في حالة النجاح

    } on ApiException catch (e) {
      _error = e.message; // تعيين الخطأ من API
      // رمي الخطأ ليتم معالجته في الواجهة (لعرض رسائل التحقق)
      throw e;
    } catch (e) {
      _error = 'An unexpected error occurred during registration: ${e.toString()}'; // تعيين الخطأ لأي استثناء آخر
      throw ApiException(0, _error!); // رمي خطأ موحد
    } finally {
      _isLoading = false; // إنهاء حالة التحميل
      notifyListeners(); // إعلام المستمعين
    }
  }

  /// تسجيل دخول المستخدم.
  /// يستدعي API لتسجيل الدخول.
  /// يحفظ التوكن وينشئ المستخدم في Provider عند النجاح.
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null; // مسح الخطأ عند بدء عملية جديدة
    notifyListeners();

    try {
      final authResponse = await _apiService.loginUser(email, password);
      // ApiService.loginUser يقوم بحفظ التوكن في SharedPreferences تلقائياً عند النجاح ويعيد AuthResponse

      _user = authResponse.user; // تعيين المستخدم من الاستجابة
      _token = authResponse.accessToken; // تعيين التوكن من الاستجابة
      _error = null; // مسح الخطأ في حالة النجاح

    } on ApiException catch (e) {
      _error = e.message; // تعيين الخطأ من API
      // رمي الخطأ ليتم معالجته في الواجهة (لعرض رسائل التحقق)
      throw e;
    } catch (e) {
      _error = 'An unexpected error occurred during login: ${e.toString()}'; // تعيين الخطأ لأي استثناء آخر
      throw ApiException(0, _error!); // رمي خطأ موحد
    } finally {
      _isLoading = false; // إنهاء حالة التحميل
      notifyListeners(); // إعلام المستمعين
    }
  }

  /// تسجيل خروج المستخدم.
  /// يستدعي API لتسجيل الخروج وإبطال التوكن في Backend.
  /// يزيل التوكن والمستخدم من Provider ومن SharedPreferences.
  Future<void> logout() async {
    _isLoading = true;
    _error = null; // مسح الخطأ عند بدء عملية جديدة
    notifyListeners();

    try {
      if (_token != null) {
        // استدعاء API لتسجيل الخروج، ApiService.logoutUser يقوم بإزالة التوكن من SharedPreferences تلقائياً
        await _apiService.logoutUser(_token!);
      }
      // مسح المستخدم والتوكن في Provider بغض النظر عن نتيجة استدعاء API (الأمان أولاً)
      _user = null;
      _token = null;
      _error = null; // مسح الخطأ في حالة النجاح

    } on ApiException catch (e) {
      print('API Exception during logout: ${e.message}');
      // قد لا تعين _error هنا لأن المستخدم يريد تسجيل الخروج على أي حال
      // إزالة التوكن والمستخدم تتم في finally
    } catch (e) {
      print('Unexpected error during logout: ${e.toString()}');
      // قد لا تعين _error هنا
      // إزالة التوكن والمستخدم تتم في finally
    } finally {
      _user = null; // تأكيد المسح
      _token = null; // تأكيد المسح
      _isLoading = false; // إنهاء حالة التحميل
      notifyListeners(); // إعلام المستمعين
    }
  }

  // --- توابع تحديث بيانات المستخدم ---

  /// تحديث الملف الشخصي للمستخدم الحالي. /// تحديث الملف الشخصي للمستخدم الحالي.
  //   /// تستخدم مسار PUT /api/v1/profile.
  //   /// يتم استدعاؤها من واجهة تعديل الملف الشخصي.
  //   /// profileData: Map تحتوي على البيانات المراد تحديثها (اسم أول، اسم أخير، هاتف، حقول الملف الشخصي).
    Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
      if (_token == null) {
        throw ApiException(401, 'User not authenticated.');
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        // استدعاء API للتحديث
        // ApiService.updateUserProfile يعيد كائن Profile بناءً على تعريفه السابق
        final updatedProfile = await _apiService.updateUserProfile(_token!, profileData);
        print(updatedProfile);

        // بعد نجاح التحديث، أعد جلب كامل بيانات المستخدم لضمان مزامنة جميع الحقول والعلاقات.
        // هذا هو الأسلوب الأكثر موثوقية لتحديث الواجهة بعد التعديل.
        // استدعاء fetchCurrentUser على مثيل ApiService وتمرير التوكن
        await _apiService.fetchCurrentUser(_token!); // <--- التصحيح هنا


        _error = null;
        // حالة التحميل سيتم تعيينها إلى false في نهاية fetchCurrentUser

      } on ApiException catch (e) {
        _error = e.message;
        _isLoading = false;
        notifyListeners();
        throw e;
      } catch (e) {
        _error = 'Failed to update profile: ${e.toString()}';
        _isLoading = false;
        notifyListeners();
        throw ApiException(0, _error!);
      }
    }


  /// تحديث مهارات المستخدم الحالي (مزامنة).
  /// تستخدم مسار POST /api/v1/profile/skills.
  /// يتم استدعاؤها من واجهة تعديل المهارات.
  /// `skillIds` يمكن أن تكون List<int> ([1, 2, 3]) أو Map<String, Map<String, dynamic>>)
  /// مثل: {"1": {"Stage": "مبتدئ"}, "5": {"Stage": "متقدم"}})
  Future<void> syncUserSkills(dynamic skillsToSync) async { // <--- اسم البارامتر skillsToSync أو skillIds كلاهما صحيح
    // تحقق من وجود التوكن
    if (_token == null) {
      throw ApiException(401, 'User not authenticated.');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. استدعاء API لمزامنة المهارات
      // ApiService.syncUserSkills يعيد كائن User كامل مع المهارات المحدثة بناءً على التوثيق والموديلات.
      final updatedUserWithSkills = await _apiService.syncUserSkills(_token!, skillsToSync); // <--- استخدام البارامتر


      // 2. تحديث كائن المستخدم المخزن محلياً بالبيانات الجديدة
      _user = updatedUserWithSkills;

      _error = null; // مسح الخطأ في حالة النجاح
      _isLoading = false;
      notifyListeners();

    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      throw e;
    } catch (e) {
      _error = 'Failed to sync skills: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      throw ApiException(0, _error!);
    }
  }

// --- توابع Authentication (معالجة الأخطاء فيها كانت ناقصة، تم إضافتها الآن) ---
// ... (التوابع register, login, logout مع إضافة _error = null; و try-catch و notifyListeners في المكان الصحيح) ...

// --- توابع أخرى (إذا كانت موجودة في هذا Provider) ---
// ... (مثال: جلب بيانات المستخدم الحالي FetchCurrentUser موجود بالفعل) ...


// ملاحظة: copyWith في موديل User ضروري إذا كنت تقوم بتحديث أجزاء من _user يدوياً.
// إذا كنت دائماً تعيد تعيين _user بكائن كامل (مثل fetchCurrentUser أو API يعيد User كامل)،
// فقد لا تحتاج لـ copyWith في كلاس User.

}