import 'package:flutter/material.dart';
import '../models/training_course.dart';
import '../models/paginated_response.dart';
import '../services/api_service.dart';

class PublicTrainingCourseProvider extends ChangeNotifier {
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

  // **تم حذف التابع المساعد _convertDynamicListToTrainingCourseList**


  // جلب أول صفحة من الدورات العامة
  Future<void> fetchTrainingCourses({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // هذا المسار عام لا يتطلب توكن
      final paginatedResponse = await _apiService.fetchTrainingCourses(page: page);

      // **استخدام PaginatedResponse.data مباشرة**
      _courses = paginatedResponse.data ?? [];


      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
      print('API Exception during fetchPublicTrainingCourses: ${e.toString()}');
    } catch (e) {
      _error = 'Failed to load courses: ${e.toString()}';
      print('Unexpected error during fetchPublicTrainingCourses: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // جلب الصفحات التالية من الدورات العامة
  Future<void> fetchMoreTrainingCourses() async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    // _error = null; // قد لا تريد مسح الخطأ هنا
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchTrainingCourses(page: nextPage);

      // **استخدام PaginatedResponse.data مباشرة**
      _courses.addAll(paginatedResponse.data ?? []);


      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('API Exception during fetchMorePublicTrainingCourses: ${e.message}');
    } catch (e) {
      print('Unexpected error during fetchMorePublicTrainingCourses: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // جلب تفاصيل دورة تدريبية محددة (من القائمة المحملة أو API العام)
  Future<TrainingCourse?> fetchTrainingCourse(int courseId) async {
    // حاول إيجاد الدورة في القائمة المحملة حالياً
    final existingCourse = _courses.firstWhereOrNull((course) => course.courseId == courseId);
    if (existingCourse != null) {
      return existingCourse;
    }

    // إذا لم توجد في القائمة، اذهب لجلبه من API العام
    // لا نغير حالة التحميل الرئيسية هنا، يمكن استخدام حالة تحميل منفصلة
    // setState(() { _isFetchingSingleCourse = true; }); notifyListeners();

    try {
      final course = await _apiService.fetchTrainingCourse(courseId);
      // لا تضيفه للقائمة
      return course;
    } on ApiException catch (e) {
      print('API Exception during fetchSinglePublicTrainingCourse: ${e.message}');
      _error = e.message; // يمكن تعيين الخطأ العام
      return null;
    } catch (e) {
      print('Unexpected error during fetchSinglePublicTrainingCourse: ${e.toString()}');
      _error = 'Failed to load course details: ${e.toString()}';
      return null;
    } finally {
      // setState(() { _isFetchingSingleCourse = false; }); notifyListeners();
    }
  }
}

// Simple extension for List<TrainingCourse>
extension ListTrainingCourseExtension on List<TrainingCourse> {
  TrainingCourse? firstWhereOrNull(bool Function(TrainingCourse) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}