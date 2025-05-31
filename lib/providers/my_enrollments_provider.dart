import 'package:flutter/material.dart';
import '../models/enrollment.dart';
import '../models/training_course.dart'; // Needed for enroll method
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class MyEnrollmentsProvider extends ChangeNotifier {
  List<Enrollment> _enrollments = [];
  bool _isLoading = false;
  String? _error;

  List<Enrollment> get enrollments => _enrollments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  // جلب تسجيلات الدورات الخاصة بالمستخدم الحالي
  Future<void> fetchMyEnrollments(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        throw ApiException(401, 'User not authenticated.');
      }
      _enrollments = await _apiService.fetchMyEnrollments(token);
      print(_enrollments);

    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load enrollments: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // التسجيل في دورة تدريبية
  Future<void> enrollInCourse(BuildContext context, int courseId) async {
    _isLoading = true; // Or separate loading state
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        throw ApiException(401, 'User not authenticated.');
      }
      final newEnrollment = await _apiService.enrollInCourse(token, courseId);
      print(newEnrollment);

      // إضافة التسجيل الجديد إلى القائمة المحلية
      _enrollments.add(newEnrollment);
      _enrollments.sort((a, b) => b.date!.compareTo(a.date!)); // Maintain sort order

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to enroll in course: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // حذف تسجيل في دورة
  Future<void> deleteEnrollment(BuildContext context, int enrollmentId) async {
    _isLoading = true; // Or separate loading state
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        throw ApiException(401, 'User not authenticated.');
      }
      await _apiService.deleteEnrollment(token, enrollmentId);

      // إزالة التسجيل من القائمة المحلية
      _enrollments.removeWhere((enroll) => enroll.enrollmentId == enrollmentId);

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to delete enrollment: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Simple extension for List<Enrollment> if needed
extension ListEnrollmentExtension on List<Enrollment> {
  Enrollment? firstWhereOrNull(bool Function(Enrollment) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}