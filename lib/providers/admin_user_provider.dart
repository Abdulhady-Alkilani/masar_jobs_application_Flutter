import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart'; // تأكد من المسار
import '../models/paginated_response.dart'; // تأكد من المسار
import '../services/api_service.dart'; // تأكد من المسار
import '../providers/auth_provider.dart'; // تأكد من المسار


class AdminUserProvider extends ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int? _lastPage;
  bool _isFetchingMore = false;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMorePages => _lastPage == null || _currentPage < _lastPage!;

  final ApiService _apiService = ApiService();

  // تابع مساعدة للتحويل الآمن من List<dynamic> إلى List<User>
  List<User> _convertDynamicListToUserList(List<dynamic>? data) {
    if (data == null) return []; // إذا كانت القائمة الأصلية null، أعد قائمة فارغة

    List<User> userList = [];
    for (final item in data) {
      // تحقق مما إذا كان العنصر هو خريطة قبل محاولة فك ترميزه كـ User
      if (item is Map<String, dynamic>) {
        try {
          // حاول فك ترميز العنصر كـ User
          userList.add(User.fromJson(item));
        } catch (e) {
          // إذا فشل فك ترميز عنصر واحد، قم بتسجيل الخطأ وتجاهل هذا العنصر
          print('Error parsing individual User item: $e for item $item');
        }
      } else {
        // إذا لم يكن العنصر خريطة، قم بتسجيل الخطأ وتجاهله
        print('Skipping unexpected item type in User list: $item');
      }
    }
    return userList; // أعد القائمة التي تم بناؤها بأمان
  }


  // جلب جميع المستخدمين (للأدمن) - الصفحة الأولى
  // في AdminUserProvider
  Future<void> fetchAllUsers(BuildContext context) async {
    // ...
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    print("AdminUserProvider: Fetching users with token: $token"); // <-- أضف هذا
    if (token == null) {
      _error = 'Token is null, cannot fetch users.';
      notifyListeners();
      return;
    }
    // ...
  }

  // جلب الصفحات التالية من المستخدمين
  Future<void> fetchMoreUsers(BuildContext context) async {
    // لا تجلب المزيد إذا كنت تحمل بالفعل أو لا يوجد المزيد من الصفحات
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    // _error = null; // قد لا تريد مسح الخطأ هنا
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchAllUsers(token, page: nextPage);

      // استخدم التابع المساعد للتحويل الآمن للإضافة
      _users.addAll(_convertDynamicListToUserList(paginatedResponse.data));


      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('API Exception during fetchMoreAdminUsers: ${e.message}');
    } catch (e) {
      print('Unexpected error during fetchMoreAdminUsers: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // جلب مستخدم واحد بواسطة الأدمن (لشاشة التفاصيل)
  Future<User?> fetchSingleUser(BuildContext context, int userId) async {
    // حاول إيجاد المستخدم في القائمة المحملة حالياً أولاً
    final existingUser = _users.firstWhereOrNull((user) => user.userId == userId);
    if (existingUser != null) {
      return existingUser;
    }

    // إذا لم يوجد في القائمة، اذهب لجلبه من API
    // لا نغير حالة التحميل الرئيسية هنا
    // bool _isFetchingSingleUser = false; // تعريف حالة تحميل فردية إذا لزم الأمر

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      // استخدام تابع ApiService لجلب مستخدم واحد
      final user = await _apiService.fetchSingleUserAdmin(token, userId);
      // لا تضيفه للقائمة هنا لتجنب خلط Pagination

      return user;
    } on ApiException catch (e) {
      print('API Exception during fetchSingleAdminUser: ${e.message}');
      _error = e.message; // يمكن تعيين الخطأ العام هنا إذا فشل جلب التفاصيل
      return null; // أعد null للإشارة إلى الفشل
    } catch (e) {
      print('Unexpected error during fetchSingleAdminUser: ${e.toString()}');
      _error = 'Failed to load user details: ${e.toString()}';
      return null; // أعد null للإشارة إلى الفشل
    } finally {
      // يمكن تحديث حالة تحميل العنصر الفردي هنا
      // setState(() { _isFetchingSingleUser = false; }); notifyListeners();
    }
  }


  // إنشاء مستخدم جديد (بواسطة الأدمن)
  Future<void> createUser(BuildContext context, Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      // استخدام تابع ApiService لإنشاء مستخدم
      final newUser = await _apiService.createNewUser(token, userData);
      // print('Created new user: $newUser'); // Debug print

      // أضف المستخدم الجديد في بداية القائمة المحلية
      _users.insert(0, newUser);

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to create user: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحديث مستخدم (بواسطة الأدمن)
  Future<void> updateUser(BuildContext context, int userId, Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      // استخدام تابع ApiService لتحديث مستخدم
      final updatedUser = await _apiService.updateUser(token, userId, userData);
      // print('Updated user: $updatedUser'); // Debug print


      // العثور على المستخدم في القائمة المحلية وتحديثه
      final index = _users.indexWhere((user) => user.userId == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      } else {
        // إذا لم يتم العثور على المستخدم في القائمة المحلية (ربما في صفحة أخرى لم يتم جلبها)، قم بإعادة جلب القائمة
        // هذا غير فعال لقوائم كبيرة، لكنه يضمن تحديث الواجهة
        fetchAllUsers(context); // إعادة جلب لتحديث القائمة المعروضة
      }

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to update user: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // حذف مستخدم (بواسطة الأدمن)
  Future<void> deleteUser(BuildContext context, int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      // استخدام تابع ApiService لحذف مستخدم
      await _apiService.deleteUser(token, userId);

      // إزالة المستخدم من القائمة المحلية
      _users.removeWhere((user) => user.userId == userId);

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to delete user: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


// TODO: إضافة توابع جلب الموارد المرتبطة بمستخدم (للأدمن) إذا لزم الأمر
// بناءً على AdminUserDetailScreen، أنت تعرض:
// - طلبات التوظيف (MyApplications)
// - تسجيلات الدورات (MyEnrollments)
// - فرص العمل التي أنشأها (ManagedJobs)
// - الدورات التي أنشأها (ManagedCourses)
// - المقالات التي أنشأها (ManagedArticles)
// ستحتاج توابع في AdminUserProvider (أو Providers أخرى) لجلب هذه القوائم الخاصة بمستخدم محدد (userId)
// وربما تابع في ApiService لكل نوع resource لجلبها بناءً على user_id.
// (مثال: ApiService.fetchUserApplicationsAdmin(token, userId))


// TODO: إضافة توابع جلب فرص العمل لشركة محددة (بواسطة الأدمن) - تم تنفيذها بالفعل في هذا الملف
// Future<void> fetchJobsByCompany(BuildContext context, int companyId, {int page = 1}) { ... }
// TODO: أضف تابع fetchMoreJobsByCompany (إذا لزم التمرير اللانهائي)
/*
  Future<void> fetchMoreJobsByCompany(BuildContext context, int companyId) async { ... }
  */


// TODO: إضافة توابع جلب الدورات لشركة محددة (بواسطة الأدمن) - مشابهة لوظائف الشركة
/*
  Future<void> fetchCoursesByCompany(BuildContext context, int companyId, {int page = 1}) async { ... }
  Future<void> fetchMoreCoursesByCompany(BuildContext context, int companyId) async { ... }
  */


}

// Simple extension for List<User>
extension ListUserExtension on List<User> {
  User? firstWhereOrNull(bool Function(User) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}