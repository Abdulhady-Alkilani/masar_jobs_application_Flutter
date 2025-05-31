import 'package:flutter/material.dart';
import '../models/job_opportunity.dart';
import '../models/paginated_response.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ManagedJobOpportunityProvider extends ChangeNotifier {
  List<JobOpportunity> _managedJobs = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int? _lastPage;
  bool _isFetchingMore = false;

  List<JobOpportunity> get managedJobs => _managedJobs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMorePages => _lastPage == null || _currentPage < _lastPage!;

  final ApiService _apiService = ApiService();

  // جلب فرص العمل التي نشرها المدير
  Future<void> fetchManagedJobs(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      // Optional: check if user is manager
      // final userType = Provider.of<AuthProvider>(context, listen: false).user?.type;
      // if (token == null || userType != 'مدير شركة') {
      //    throw ApiException(403, 'User not authorized to manage jobs.');
      // }

      final paginatedResponse = await _apiService.fetchManagedJobs(token!, page: 1);
      print(paginatedResponse);
      _managedJobs.addAll((paginatedResponse.data ?? []) as Iterable<JobOpportunity>);
      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load managed jobs: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreManagedJobs(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        // This should ideally not happen if checkAuthStatus is done correctly
        throw ApiException(401, 'User not authenticated.');
      }
      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchManagedJobs(token, page: nextPage);
      print(paginatedResponse);
      _managedJobs.addAll((paginatedResponse.data ?? []) as Iterable<JobOpportunity>);
      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('Error fetching more managed jobs: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching more managed jobs: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }


  // إنشاء فرصة عمل جديدة بواسطة المدير
  Future<void> createJob(BuildContext context, Map<String, dynamic> jobData) async {
    _isLoading = true; // Or separate loading state
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final newJob = await _apiService.createManagedJob(token, jobData);
      print(newJob);

      // إضافة الوظيفة الجديدة للقائمة (أو إعادة جلب القائمة)
      _managedJobs.insert(0, newJob); // أضف في البداية كأحدث عنصر

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to create job: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحديث فرصة عمل بواسطة المدير
  Future<void> updateJob(BuildContext context, int jobId, Map<String, dynamic> jobData) async {
    _isLoading = true; // Or separate loading state
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final updatedJob = await _apiService.updateManagedJob(token, jobId, jobData);
      print(updatedJob);

      // تحديث العنصر في القائمة المحلية
      final index = _managedJobs.indexWhere((job) => job.jobId == jobId);
      if (index != -1) {
        _managedJobs[index] = updatedJob;
      } else {
        // إذا لم يتم العثور عليه (مثال: تم تحديث شيء في صفحة أخرى)، قم بإعادة جلب القائمة
        fetchManagedJobs(context);
      }

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to update job: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // حذف فرصة عمل بواسطة المدير
  Future<void> deleteJob(BuildContext context, int jobId) async {
    _isLoading = true; // Or separate loading state
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      await _apiService.deleteManagedJob(token, jobId);

      // إزالة العنصر من القائمة المحلية
      _managedJobs.removeWhere((job) => job.jobId == jobId);

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to delete job: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Simple extension for List<JobOpportunity>
extension ListManagedJobExtension on List<JobOpportunity> {
  JobOpportunity? firstWhereOrNull(bool Function(JobOpportunity) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}