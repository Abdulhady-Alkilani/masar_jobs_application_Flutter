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

  // **تم حذف التابع المساعد _convertDynamicListToTrainingCourseList**


  // جلب الدورات التي نشرها المستخدم (المدير أو الاستشاري)
  Future<void> fetchManagedCourses(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');
      // Optional: check user type is manager or consultant
      // final userType = Provider.of<AuthProvider>(context, listen: false).user?.type;
      // if (token == null || !['مدير شركة', 'خبير استشاري'].contains(userType)) {
      //    throw ApiException(403, 'User not authorized to manage courses.');
      // }

      final paginatedResponse = await _apiService.fetchManagedCourses(token!, page: 1);
      // print('Fetched initial managed courses response: $paginatedResponse'); // Debug print

      // **استخدام PaginatedResponse.data مباشرة**
      _managedCourses = paginatedResponse.data ?? [];


      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
      print('API Exception during fetchManagedCourses: ${e.toString()}');
    } catch (e) {
      _error = 'Failed to load managed courses: ${e.toString()}';
      print('Unexpected error during fetchManagedCourses: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreManagedCourses(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    // _error = null; // قد لا تريد مسح الخطأ هنا
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchManagedCourses(token, page: nextPage);

      // **استخدام PaginatedResponse.data مباشرة**
      _managedCourses.addAll(paginatedResponse.data ?? []);


      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('API Exception during fetchMoreManagedCourses: ${e.message}');
    } catch (e) {
      print('Unexpected error during fetchMoreManagedCourses: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // جلب تفاصيل دورة تدريبية محددة (من القائمة المحملة)
  Future<TrainingCourse?> fetchCourseOpportunity(int courseId) async {
    // حاول إيجاد الدورة في القائمة المحملة حالياً
    final existingCourse = _managedCourses.firstWhereOrNull((course) => course.courseId == courseId);
    // لا تذهب لـ API لجلب عنصر فردي في هذا Provider، فقط من القائمة المحملة
    return existingCourse;
  }


  // إنشاء دورة تدريبية جديدة بواسطة المستخدم (المدير أو الاستشاري)
  Future<void> createCourse(BuildContext context, Map<String, dynamic> courseData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final newCourse = await _apiService.createManagedCourse(token, courseData);
      // print('Created new course: $newCourse'); // Debug print

      _managedCourses.insert(0, newCourse); // أضف الدورة الجديدة في بداية القائمة

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

  // تحديث دورة تدريبية بواسطة المستخدم (المدير أو الاستشاري)
  Future<void> updateCourse(BuildContext context, int courseId, Map<String, dynamic> courseData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final updatedCourse = await _apiService.updateManagedCourse(token, courseId, courseData);
      // print('Updated course: $updatedCourse'); // Debug print

      // العثور على الدورة في القائمة المحلية وتحديثها
      final index = _managedCourses.indexWhere((course) => course.courseId == courseId);
      if (index != -1) {
        _managedCourses[index] = updatedCourse;
      } else {
        // إذا لم يتم العثور على الدورة في القائمة المحلية (ربما في صفحة أخرى لم يتم جلبها)، قم بإعادة جلب القائمة
        fetchManagedCourses(context); // إعادة جلب لتحديث القائمة المعروضة
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

  // حذف دورة تدريبية بواسطة المستخدم (المدير أو الاستشاري)
  Future<void> deleteCourse(BuildContext context, int courseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      await _apiService.deleteManagedCourse(token, courseId);

      // إزالة الدورة من القائمة المحلية
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
extension ListTrainingCourseExtension on List<TrainingCourse> {
  TrainingCourse? firstWhereOrNull(bool Function(TrainingCourse) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}