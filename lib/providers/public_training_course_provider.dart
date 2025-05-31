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

  Future<void> fetchTrainingCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final paginatedResponse = await _apiService.fetchTrainingCourses(page: 1);
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

  Future<void> fetchMoreTrainingCourses() async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    _error = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchTrainingCourses(page: nextPage);
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

  Future<TrainingCourse?> fetchTrainingCourse(int courseId) async {
    final existingCourse = _courses.firstWhereOrNull((course) => course.courseId == courseId);
    print(existingCourse);
    if (existingCourse != null) {
      return existingCourse;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final course = await _apiService.fetchTrainingCourse(courseId);
      print(course);
      return course;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = 'Failed to load course: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Simple extension for List<TrainingCourse>
extension ListCourseExtension on List<TrainingCourse> {
  TrainingCourse? firstWhereOrNull(bool Function(TrainingCourse) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}