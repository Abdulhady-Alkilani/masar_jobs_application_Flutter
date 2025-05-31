import 'package:flutter/material.dart';
import '../models/job_opportunity.dart';
import '../models/paginated_response.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminJobProvider extends ChangeNotifier {
  List<JobOpportunity> _jobs = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int? _lastPage;
  bool _isFetchingMore = false;

  List<JobOpportunity> get jobs => _jobs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMorePages => _lastPage == null || _currentPage < _lastPage!;

  final ApiService _apiService = ApiService();

  // جلب جميع فرص العمل (للأدمن)
  Future<void> fetchAllJobs(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final paginatedResponse = await _apiService.fetchAllJobsAdmin(token!, page: 1);
      print(paginatedResponse);
      _jobs.addAll((paginatedResponse.data ?? []) as Iterable<JobOpportunity>);
      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load jobs: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreJobs(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchAllJobsAdmin(token, page: nextPage);
      print(paginatedResponse);
      _jobs.addAll((paginatedResponse.data ?? []) as Iterable<JobOpportunity>);
      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('Error fetching more jobs: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching more jobs: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // إنشاء فرصة عمل (بواسطة الأدمن)
  Future<void> createJob(BuildContext context, Map<String, dynamic> jobData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final newJob = await _apiService.createJobAdmin(token, jobData);
      print(newJob);

      _jobs.insert(0, newJob);

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

  // تحديث فرصة عمل (بواسطة الأدمن)
  Future<void> updateJob(BuildContext context, int jobId, Map<String, dynamic> jobData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final updatedJob = await _apiService.updateJobAdmin(token, jobId, jobData);
      print(updatedJob);

      final index = _jobs.indexWhere((job) => job.jobId == jobId);
      if (index != -1) {
        _jobs[index] = updatedJob;
      } else {
        fetchAllJobs(context);
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

  // حذف فرصة عمل (بواسطة الأدمن)
  Future<void> deleteJob(BuildContext context, int jobId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      await _apiService.deleteJobAdmin(token, jobId);

      _jobs.removeWhere((job) => job.jobId == jobId);

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
extension ListAdminJobExtension on List<JobOpportunity> {
  JobOpportunity? firstWhereOrNull(bool Function(JobOpportunity) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}