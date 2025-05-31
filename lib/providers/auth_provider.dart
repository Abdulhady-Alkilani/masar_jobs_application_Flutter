import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart'; // تأكد من مسار ApiService الصحيح
import 'package:shared_preferences/shared_preferences.dart'; // تأكد من الاستيراد

class AuthProvider extends ChangeNotifier {
  // ... (حقول أخرى مثل _user, _token, _isLoading) ...

  String? _error; // حقل خاص لتخزين رسالة الخطأ

  // ... (Getters أخرى) ...

  String? get error => _error; // Getter عام للوصول إلى الخطأ من الخارج

  // ... (باقي كود الكلاس) ...
  User? _user; // بيانات المستخدم المسجل دخوله حاليًا
  String? _token; // التوكن الخاص بالمستخدم المسجل دخوله حاليًا
  bool _isLoading = false; // لحالة التحميل في الواجهة

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _token != null; // هل المستخدم مصادق عليه؟

  final ApiService _apiService = ApiService(); // إنشاء مثيل من ApiService

  // تابع للتحقق من حالة المصادقة عند بدء التطبيق
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _token = await _apiService.getAuthToken(); // جلب التوكن المخزن

    if (_token != null) {
      try {
        _user = await _apiService.fetchCurrentUser(_token!); // جلب بيانات المستخدم باستخدام التوكن
        print(_user);
        // في حالة النجاح، المستخدم والتوكن موجودان
      } catch (e) {
        // إذا فشل جلب المستخدم (مثال: التوكن منتهي الصلاحية أو غير صالح)
        print('Failed to fetch user with saved token: $e');
        await _apiService.removeAuthToken(); // إزالة التوكن غير الصالح
        _token = null;
        _user = null;
      }
    } else {
      // لا يوجد توكن مخزن
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // تابع لتسجيل الدخول
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authResponse = await _apiService.loginUser(email, password);
      print(authResponse);
      _user = authResponse.user;
      _token = authResponse.accessToken;
      // ApiService يقوم بحفظ التوكن في SharedPreferences تلقائياً عند النجاح

      _isLoading = false;
      notifyListeners();

    } on ApiException catch (e) {
      _isLoading = false;
      notifyListeners();
      // رمي الخطأ ليتم معالجته في الواجهة (لعرض رسائل الخطأ)
      throw e;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw ApiException(0, 'An unexpected error occurred: ${e.toString()}');
    }
  }

  // تابع لتسجيل حساب جديد
  Future<void> register(String firstName, String lastName, String username, String email, String password, String passwordConfirmation, String phone, String type) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authResponse = await _apiService.registerUser(firstName, lastName, username, email, password, passwordConfirmation, phone, type);
      print(authResponse);
      _user = authResponse.user;
      _token = authResponse.accessToken;
      // ApiService يقوم بحفظ التوكن في SharedPreferences تلقائياً عند النجاح

      _isLoading = false;
      notifyListeners();

    } on ApiException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw ApiException(0, 'An unexpected error occurred: ${e.toString()}');
    }
  }

  // تابع لتسجيل الخروج
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_token != null) {
        await _apiService.logoutUser(_token!); // استدعاء API لتسجيل الخروج
        // ApiService يقوم بإزالة التوكن من SharedPreferences تلقائياً
      }
    } on ApiException catch (e) {
      print('Error during API logout: $e');
      // قد ترغب في تجاهل أخطاء API هنا وإزالة التوكن محلياً على أي حال
    } catch (e) {
      print('Unexpected error during API logout: $e');
    }

    _user = null;
    _token = null;
    _isLoading = false;
    notifyListeners();
  }

  // ... (باقي كود AuthProvider قبل هذا، بما في ذلك تعريف _user, _token, _isLoading, _error ومثيل _apiService) ...


  /// تحديث الملف الشخصي للمستخدم الحالي.
  /// تستخدم مسار PUT /api/v1/profile.
  /// يتم استدعاؤها من واجهة تعديل الملف الشخصي.
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    // تحقق من وجود التوكن قبل محاولة الاتصال بـ API المحمي
    if (_token == null) {
      // هذا لا ينبغي أن يحدث إذا كانت الواجهة محمية بشكل صحيح
      throw ApiException(401, 'User not authenticated.');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedProfile = await _apiService.updateUserProfile(_token!, profileData);
      print(updatedProfile);

      // تحديث بيانات الملف الشخصي في كائن المستخدم المخزن محلياً
      if (_user != null) {
        _user = _user!.copyWith(profile: updatedProfile); // يفترض وجود copyWith في موديل User
        // البديل: إعادة جلب المستخدم بالكامل بعد التحديث لضمان مزامنة جميع العلاقات
        // await fetchCurrentUser(_token!); // هذا قد يكون أفضل لضمان اتساق البيانات
      }

      _error = null; // مسح الخطأ في حالة النجاح
      _isLoading = false;
      notifyListeners();

    } on ApiException catch (e) {
      _error = e.message; // تعيين الخطأ من API
      _isLoading = false;
      notifyListeners();
      throw e; // رمي الخطأ للواجهة لمعالجته (مثل عرض رسائل التحقق)
    } catch (e) {
      _error = 'Failed to update profile: ${e.toString()}'; // خطأ غير متوقع
      _isLoading = false;
      notifyListeners();
      throw ApiException(0, _error!); // رمي خطأ موحد
    }
  }


  /// تحديث مهارات المستخدم الحالي (مزامنة).
  /// تستخدم مسار POST /api/v1/profile/skills.
  /// يتم استدعاؤها من واجهة تعديل المهارات.
  /// `skillIds` يمكن أن تكون List<int> ([1, 2, 3]) أو Map<String, Map<String, dynamic>>
  /// مثل: {"1": {"Stage": "مبتدئ"}, "5": {"Stage": "متقدم"}}
  /// تحديث الملف الشخصي للمستخدم الحالي.
  /// تستخدم مسار PUT /api/v1/profile.
  /// يتم استدعاؤها من واجهة تعديل الملف الشخصي.
  /// profileData: Map تحتوي على البيانات المراد تحديثها (اسم أول، اسم أخير، هاتف، حقول الملف الشخصي).
  Future<void> updateUserProfile1(Map<String, dynamic> profileData) async { // <--- تعريف البارامتر الصحيح (بارامتر واحد اسمه profileData)
    // تحقق من وجود التوكن قبل محاولة الاتصال بـ API المحمي
    if (_token == null) {
      throw ApiException(401, 'User not authenticated.');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // استخدام الـ profileData التي تم تمريرها كبارامتر للدالة
      final updatedProfile = await _apiService.updateUserProfile(_token!, profileData); // <--- استخدام قيمة البارامتر profileData

      // تحديث بيانات الملف الشخصي في كائن المستخدم المخزن محلياً
      if (_user != null) {
        // نستخدم copyWith لتحديث جزء profile في كائن المستخدم
        // لكن API قد يعيد كائن User كامل بعد التحديث، لذا قد يكون تحديث _user مباشرةً أفضل
        // _user = _user!.copyWith(profile: updatedProfile); // إذا كان API يعيد Profile فقط
        // أو الأفضل:
        // await fetchCurrentUser(_token!); // إعادة جلب المستخدم بالكامل بعد التحديث لضمان مزامنة جميع العلاقات
        // أو إذا كان API يعيد كائن المستخدم كاملاً بعد التحديث:
        _user = updatedProfile as User; // <--- إذا كان API يعيد User كاملاً
        print(_user);

      }

      _error = null; // مسح الخطأ في حالة النجاح
      _isLoading = false;
      notifyListeners();

    } on ApiException catch (e) {
      _error = e.message; // تعيين الخطأ من API
      _isLoading = false;
      notifyListeners();
      throw e; // رمي الخطأ للواجهة لمعالجته (مثل عرض رسائل التحقق)
    } catch (e) {
      _error = 'Failed to update profile: ${e.toString()}'; // خطأ غير متوقع
      _isLoading = false;
      notifyListeners();
      throw ApiException(0, _error!); // رمي خطأ موحد
    }
  }

// ... (باقي كود AuthProvider بعد هذا) ...


// ملاحظة: إذا لم يكن لديك التابع copyWith في موديل User، يمكنك إضافته أو استخدام طريقة أخرى لتحديث جزء من الكائن.
// مثال بسيط لـ copyWith (أضفه داخل كلاس User في lib/models/user.dart):
/*
  User copyWith({
    int? userId,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    bool? emailVerified,
    String? phone,
    String? photo,
    String? status,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    Profile? profile, // <-- هذا هو ما نحتاجه
    List<Skill>? skills,
    Company? company,
  }) {
    return User(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      phone: phone ?? this.phone,
      photo: photo ?? this.photo,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profile: profile ?? this.profile, // <-- تحديث هنا
      skills: skills ?? this.skills,
      company: company ?? this.company,
    );
  }
*/
  
}