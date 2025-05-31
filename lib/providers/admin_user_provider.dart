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

  // جلب جميع المستخدمين (للأدمن)
  Future<void> fetchAllUsers(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');
      // Optional: check user type is Admin

      final paginatedResponse = await _apiService.fetchAllUsers(token!, page: 1);
      print(paginatedResponse);
      _users.addAll((paginatedResponse.data ?? []) as Iterable<User>);
      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load users: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreUsers(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchAllUsers(token, page: nextPage);
      print(paginatedResponse);
      _users.addAll((paginatedResponse.data ?? []) as Iterable<User>);
      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('Error fetching more users: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching more users: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
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
      print(newUser);

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

      final updatedUser = await _apiService.updateUser(token, userId, userData);
      print(updatedUser);

      final index = _users.indexWhere((user) => user.userId == userId);
      if (index != -1) {
        _users[index] = updatedUser;
      } else {
        // إذا تم تحديث شيء في صفحة أخرى غير محملة، قد تحتاج لإعادة جلب القائمة
        // أو التعامل مع هذا السيناريو بشكل مختلف (مثلاً جلب المستخدم الفردي وعرضه)
        fetchAllUsers(context); // خيار بسيط هو إعادة جلب القائمة
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
extension ListAdminUserExtension on List<User> {
  User? firstWhereOrNull(bool Function(User) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}