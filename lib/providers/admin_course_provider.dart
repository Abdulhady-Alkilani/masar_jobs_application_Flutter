import 'package:flutter/material.dart';
import '../models/training_course.dart';
import '../models/paginated_response.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminCourseProvider extends ChangeNotifier {
  List<TrainingCourse> _courses = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int? _lastPage;
  bool _isFetchingMore = false;

  List<TrainingCourse> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMorePages => _lastPage == null || _currentPage < _lastPage!;

  final ApiService _apiService = ApiService();

  // جلب جميع الدورات (للأدمن)
  Future<void> fetchAllCourses(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final paginatedResponse = await _apiService.fetchAllCoursesAdmin(token!, page: 1);
      print(paginatedResponse);
      _courses.addAll((paginatedResponse.data ?? []) as Iterable<TrainingCourse>);
      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load courses: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreCourses(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchAllCoursesAdmin(token, page: nextPage);
      print(paginatedResponse);
      _courses.addAll((paginatedResponse.data ?? []) as Iterable<TrainingCourse>);
      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('Error fetching more courses: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching more courses: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // إنشاء دورة (بواسطة الأدمن)
  Future<void> createCourse(BuildContext context, Map<String, dynamic> courseData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final newCourse = await _apiService.createCourseAdmin(token, courseData);
      print(newCourse);

      _courses.insert(0, newCourse);

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

  // تحديث دورة (بواسطة الأدمن)
  Future<void> updateCourse(BuildContext context, int courseId, Map<String, dynamic> courseData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final updatedCourse = await _apiService.updateCourseAdmin(token, courseId, courseData);
      print(updatedCourse);

      final index = _courses.indexWhere((course) => course.courseId == courseId);
      if (index != -1) {
        _courses[index] = updatedCourse;
      } else {
        fetchAllCourses(context);
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

  // حذف دورة (بواسطة الأدمن)
  Future<void> deleteCourse(BuildContext context, int courseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      await _apiService.deleteCourseAdmin(token, courseId);

      _courses.removeWhere((course) => course.courseId == courseId);

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
extension ListAdminCourseExtension on List<TrainingCourse> {
  TrainingCourse? firstWhereOrNull(bool Function(TrainingCourse) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}