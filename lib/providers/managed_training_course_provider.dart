import 'package:flutter/material.dart';
import '../models/training_course.dart';
import '../models/paginated_response.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ManagedTrainingCourseProvider extends ChangeNotifier {
  List<TrainingCourse> _managedCourses = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int? _lastPage;
  bool _isFetchingMore = false;

  List<TrainingCourse> get managedCourses => _managedCourses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMorePages => _lastPage == null || _currentPage < _lastPage!;

  final ApiService _apiService = ApiService();

  // جلب الدورات التي نشرها المستخدم (المدير أو الاستشاري)
  Future<void> fetchManagedCourses(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      // Optional: check if user is manager or consultant
      // final userType = Provider.of<AuthProvider>(context, listen: false).user?.type;
      // if (token == null || !['مدير شركة', 'خبير استشاري'].contains(userType)) {
      //    throw ApiException(403, 'User not authorized to manage courses.');
      // }

      final paginatedResponse = await _apiService.fetchManagedCourses(token!, page: 1);
      print(paginatedResponse);
      _managedCourses.addAll((paginatedResponse.data ?? []) as Iterable<TrainingCourse>);
      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load managed courses: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreManagedCourses(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchManagedCourses(token, page: nextPage);
      print(paginatedResponse);
      _managedCourses.addAll((paginatedResponse.data ?? []) as Iterable<TrainingCourse>);
      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('Error fetching more managed courses: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching more courses: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }


  // إنشاء دورة جديدة بواسطة المستخدم (المدير أو الاستشاري)
  Future<void> createCourse(BuildContext context, Map<String, dynamic> courseData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final newCourse = await _apiService.createManagedCourse(token, courseData);
      print(newCourse);

      _managedCourses.insert(0, newCourse);

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to create course: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحديث دورة بواسطة المستخدم (المدير أو الاستشاري)
  Future<void> updateCourse(BuildContext context, int courseId, Map<String, dynamic> courseData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final updatedCourse = await _apiService.updateManagedCourse(token, courseId, courseData);
      print(updatedCourse);

      final index = _managedCourses.indexWhere((course) => course.courseId == courseId);
      if (index != -1) {
        _managedCourses[index] = updatedCourse;
      } else {
        fetchManagedCourses(context);
      }

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to update course: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // حذف دورة بواسطة المستخدم (المدير أو الاستشاري)
  Future<void> deleteCourse(BuildContext context, int courseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      await _apiService.deleteManagedCourse(token, courseId);

      _managedCourses.removeWhere((course) => course.courseId == courseId);

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to delete course: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Simple extension for List<TrainingCourse>
extension ListManagedCourseExtension on List<TrainingCourse> {
  TrainingCourse? firstWhereOrNull(bool Function(TrainingCourse) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}