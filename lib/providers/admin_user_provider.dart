import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/paginated_response.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';


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
    if (data == null) return [];
    List<User> userList = [];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        try {
          userList.add(User.fromJson(item));
        } catch (e) {
          print('Error parsing individual User item: $e for item $item');
        }
      } else {
        print('Skipping unexpected item type in User list: $item');
      }
    }
    return userList;
  }


  // جلب جميع المستخدمين (للأدمن) - الصفحة الأولى
  Future<void> fetchAllUsers(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');
      // Optional: check user type is Admin

      final paginatedResponse = await _apiService.fetchAllUsers(token!, page: 1);
      // print('Fetched initial admin users response: $paginatedResponse'); // Debug print

      // استخدم التابع المساعد للتحويل الآمن
      _users = _convertDynamicListToUserList(paginatedResponse.data);


      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
      print('API Exception during fetchAllUsers: ${e.toString()}');
    } catch (e) {
      _error = 'Failed to load users: ${e.toString()}';
      print('Unexpected error during fetchAllUsers: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // جلب الصفحات التالية من المستخدمين
  Future<void> fetchMoreUsers(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    // _error = null; // قد لا تريد مسح الخطأ هنا
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchAllUsers(token, page: nextPage);
      // print('Fetched more admin users response: $paginatedResponse'); // Debug print

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
    // حاول إيجاد المستخدم في القائمة المحملة حالياً
    final existingUser = _users.firstWhereOrNull((user) => user.userId == userId);
    if (existingUser != null) {
      return existingUser;
    }

    // إذا لم يوجد في القائمة، اذهب لجلبه من API
    // لا نغير حالة التحميل الرئيسية هنا، يمكن استخدام حالة تحميل منفصلة
    // setState(() { _isFetchingSingleUser = true; }); notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final user = await _apiService.fetchSingleUserAdmin(token, userId);
      // لا تضيفه للقائمة هنا لتجنب خلط Pagination

      return user;
    } on ApiException catch (e) {
      print('API Exception during fetchSingleAdminUser: ${e.message}');
      _error = e.message; // يمكن تعيين الخطأ العام
      return null;
    } catch (e) {
      print('Unexpected error during fetchSingleAdminUser: ${e.toString()}');
      _error = 'Failed to load user details: ${e.toString()}';
      return null;
    } finally {
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

      final newUser = await _apiService.createNewUser(token, userData);
      // print('Created new user: $newUser'); // Debug print

      _users.insert(0, newUser); // أضف المستخدم الجديد في بداية القائمة

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

      final updatedUser = await _apiService.updateUser(token, userId, userData);
      // print('Updated user: $updatedUser'); // Debug print


      // العثور على المستخدم في القائمة المحلية وتحديثه
      final index = _users.indexWhere((user) => user.userId == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      } else {
        // إذا لم يتم العثور على المستخدم في القائمة المحلية (ربما في صفحة أخرى لم يتم جلبها)، قم بإعادة جلب القائمة
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