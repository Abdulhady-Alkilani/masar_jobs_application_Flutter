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

  // تابع مساعدة للتحويل الآمن من List<dynamic> إلى List<TrainingCourse>
  List<TrainingCourse> _convertDynamicListToTrainingCourseList(List<dynamic>? data) {
    if (data == null) return [];
    List<TrainingCourse> courseList = [];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        try {
          courseList.add(TrainingCourse.fromJson(item));
        } catch (e) {
          print('Error parsing individual TrainingCourse item: $e for item $item');
        }
      } else {
        print('Skipping unexpected item type in TrainingCourse list: $item');
      }
    }
    return courseList;
  }


  // جلب جميع الدورات (للأدمن) - الصفحة الأولى
  Future<void> fetchAllCourses(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');
      // Optional: check user type is Admin

      final paginatedResponse = await _apiService.fetchAllCoursesAdmin(token!, page: 1);
      // print('Fetched initial admin courses response: $paginatedResponse'); // Debug print

      // استخدم التابع المساعد للتحويل الآمن
      _courses = _convertDynamicListToTrainingCourseList(paginatedResponse.data);


      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
      print('API Exception during fetchAllCoursesAdmin: ${e.toString()}');
    } catch (e) {
      _error = 'Failed to load courses: ${e.toString()}';
      print('Unexpected error during fetchAllCoursesAdmin: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // جلب الصفحات التالية من الدورات
  Future<void> fetchMoreCourses(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    // _error = null; // قد لا تريد مسح الخطأ هنا
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchAllCoursesAdmin(token, page: nextPage);

      // استخدم التابع المساعد للتحويل الآمن للإضافة
      _courses.addAll(_convertDynamicListToTrainingCourseList(paginatedResponse.data));


      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('API Exception during fetchMoreAdminCourses: ${e.message}');
    } catch (e) {
      print('Unexpected error during fetchMoreAdminCourses: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // جلب دورة تدريبية واحدة بواسطة الأدمن (لشاشة التفاصيل)
  Future<TrainingCourse?> fetchSingleCourse(BuildContext context, int courseId) async {
    // حاول إيجاد الدورة في القائمة المحملة حالياً
    final existingCourse = _courses.firstWhereOrNull((course) => course.courseId == courseId);
    if (existingCourse != null) {
      return existingCourse;
    }

    // إذا لم توجد في القائمة، اذهب لجلبه من API
    // لا نغير حالة التحميل الرئيسية هنا
    // setState(() { _isFetchingSingleCourse = true; }); notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final course = await _apiService.fetchSingleCourseAdmin(token, courseId);
      // لا تضيفه للقائمة هنا

      return course;
    } on ApiException catch (e) {
      print('API Exception during fetchSingleAdminCourse: ${e.message}');
      _error = e.message; // يمكن تعيين الخطأ العام
      return null;
    } catch (e) {
      print('Unexpected error during fetchSingleAdminCourse: ${e.toString()}');
      _error = 'Failed to load course details: ${e.toString()}';
      return null;
    } finally {
      // setState(() { _isFetchingSingleCourse = false; }); notifyListeners();
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
      // print('Created new course: $newCourse'); // Debug print

      _courses.insert(0, newCourse); // أضف الدورة الجديدة في بداية القائمة

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
      // print('Updated course: $updatedCourse'); // Debug print

      // العثور على الدورة في القائمة المحلية وتحديثها
      final index = _courses.indexWhere((course) => course.courseId == courseId);
      if (index != -1) {
        _courses[index] = updatedCourse;
      } else {
        // إذا لم يتم العثور على الدورة في القائمة المحلية (ربما في صفحة أخرى لم يتم جلبها)، قم بإعادة جلب القائمة
        fetchAllCourses(context); // إعادة جلب لتحديث القائمة المعروضة
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

      // إزالة الدورة من القائمة المحلية
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
extension ListTrainingCourseExtension on List<TrainingCourse> {
  TrainingCourse? firstWhereOrNull(bool Function(TrainingCourse) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}