import 'package:flutter/material.dart';
import '../models/job_application.dart';
import '../models/job_opportunity.dart'; // Needed for apply method
import '../services/api_service.dart';
import '../providers/auth_provider.dart'; // Needed to get the token
import 'package:provider/provider.dart'; // Needed to access AuthProvider

class MyApplicationsProvider extends ChangeNotifier {
  List<JobApplication> _applications = [];
  bool _isLoading = false;
  String? _error;

  List<JobApplication> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  // جلب طلبات التوظيف الخاصة بالمستخدم الحالي
  Future<void> fetchMyApplications(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        throw ApiException(401, 'User not authenticated.');
      }
      _applications = await _apiService.fetchMyApplications(token);
      print(_applications);

    } on ApiException catch (e) {
      _error = e.message;
      // إذا كان 401، AuthProvider سيتعامل معه ويزيل التوكن
    } catch (e) {
      _error = 'Failed to load applications: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تقديم طلب لوظيفة
  Future<void> applyForJob(BuildContext context, int jobId, {String? description, String? cvPath}) async {
    _isLoading = true; // Or a separate loading state for application action
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        throw ApiException(401, 'User not authenticated.');
      }
      final newApplication = await _apiService.applyForJob(token, jobId, description: description, cvPath: cvPath);
      print(newApplication);

      // إضافة الطلب الجديد إلى القائمة المحلية وتحديثها
      _applications.add(newApplication);
      // يمكنك إعادة ترتيب القائمة إذا أردت بناءً على التاريخ
      _applications.sort((a, b) => b.date!.compareTo(a.date!));

    } on ApiException catch (e) {
      _error = e.message;
      throw e; // رمي الخطأ للواجهة
    } catch (e) {
      _error = 'Failed to apply for job: ${e.toString()}';
      throw ApiException(0, _error!); // تغليف الخطأ
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // حذف طلب توظيف
  Future<void> deleteApplication(BuildContext context, int applicationId) async {
    _isLoading = true; // Or a separate loading state for delete action
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        throw ApiException(401, 'User not authenticated.');
      }
      await _apiService.deleteJobApplication(token, applicationId);

      // إزالة الطلب من القائمة المحلية
      _applications.removeWhere((app) => app.id == applicationId);

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to delete application: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Simple extension for List<JobApplication> if needed
extension ListJobApplicationExtension on List<JobApplication> {
  JobApplication? firstWhereOrNull(bool Function(JobApplication) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}