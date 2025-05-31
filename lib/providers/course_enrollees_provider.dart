import 'package:flutter/material.dart';
import '../models/enrollee.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class CourseEnrolleesProvider extends ChangeNotifier {
  List<Enrollee> _enrollees = [];
  bool _isLoading = false;
  String? _error;
  int? _currentCourseId; // لتتبع الدورة

  List<Enrollee> get enrollees => _enrollees;

  bool get isLoading => _isLoading;

  String? get error => _error;

  int? get currentCourseId => _currentCourseId;


  final ApiService _apiService = ApiService();

  // جلب المسجلين بدورة محددة
  Future<void> fetchEnrollees(BuildContext context, int courseId) async {
    if (_currentCourseId == courseId && _enrollees.isNotEmpty && !_isLoading) {
      return;
    }

    _isLoading = true;
    _error = null;
    _currentCourseId = courseId; // حفظ معرف الدورة
    _enrollees = []; // مسح القائمة القديمة
    notifyListeners();

    try {
      final token = Provider
          .of<AuthProvider>(context, listen: false)
          .token;
      if (token == null) throw ApiException(401, 'User not authenticated.');
      // Optional: check user type/authorization for this course on backend

      _enrollees = await _apiService.fetchCourseEnrollees(token, courseId);
      print(_enrollees);
    } on ApiException catch (e) {
      _error = e.message;
      _enrollees = [];
    } catch (e) {
      _error = 'Failed to load enrollees: ${e.toString()}';
      _enrollees = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// TODO: Add methods to update an enrollee's status (e.g., mark as complete, cancel)

  Future<void> updateEnrolleeStatus(BuildContext context, int enrollmentId,
      String newStatus) async {
    // ... loading state ...
    try {
      final token = Provider
          .of<AuthProvider>(context, listen: false)
          .token;
      if (token == null) throw ApiException(401, 'User not authenticated.');
      // Assume API has a PUT endpoint like /managed-enrollments/{id} with {status: newStatus}
      final updatedEnrollee = await _apiService.updateEnrolleeStatus(
          token, enrollmentId, newStatus);
      print(updatedEnrollee);

      final index = _enrollees.indexWhere((enrollee) =>
      enrollee.enrollmentId == enrollmentId);
      if (index != -1) {
        _enrollees[index] = updatedEnrollee as Enrollee;
        notifyListeners();
      }
    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to update enrollee status: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally { // ... loading state ... }
    }
  }
}