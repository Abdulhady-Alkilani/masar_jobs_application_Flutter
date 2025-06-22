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

  // !! تم حذف التابع المساعد _convertDynamicListToJobOpportunityList !!
  // لأن التحويل من Map<String, dynamic> إلى JobOpportunity
  // يتم الآن داخل PaginatedResponse.fromJson باستخدام الدالة الممررة


  // جلب فرص العمل التي نشرها المدير
  Future<void> fetchManagedJobs(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');
      // Optional: check user type is manager
      // final userType = Provider.of<AuthProvider>(context, listen: false).user?.type;
      // if (token == null || userType != 'مدير شركة') {
      //    throw ApiException(403, 'User not authorized to manage jobs.');
      // }

      final paginatedResponse = await _apiService.fetchManagedJobs(token!, page: 1);
      // print('Fetched initial managed jobs response: $paginatedResponse'); // Debug print

      // التصحيح هنا: نستخدم PaginatedResponse.data مباشرة
      _managedJobs = paginatedResponse.data ?? [];


      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
      print('API Exception during fetchManagedJobs: ${e.toString()}');
    } catch (e) {
      _error = 'Failed to load managed jobs: ${e.toString()}';
      print('Unexpected error during fetchManagedJobs: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreManagedJobs(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    // _error = null; // قد لا تريد مسح الخطأ هنا
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchManagedJobs(token, page: nextPage);

      // التصحيح هنا: نستخدم PaginatedResponse.data مباشرة
      _managedJobs.addAll(paginatedResponse.data ?? []);


      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('API Exception during fetchMoreManagedJobs: ${e.message}');
    } catch (e) {
      print('Unexpected error during fetchMoreManagedJobs: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // جلب تفاصيل فرصة عمل محددة (من القائمة المحملة)
  Future<JobOpportunity?> fetchJobOpportunity(int jobId) async {
    // حاول إيجاد الوظيفة في القائمة المحملة حالياً
    final existingJob = _managedJobs.firstWhereOrNull((job) => job.jobId == jobId);
    // لا تذهب لـ API لجلب عنصر فردي في هذا Provider، فقط من القائمة المحملة
    return existingJob;
  }


  // إنشاء فرصة عمل جديدة بواسطة المدير
  Future<void> createJob(BuildContext context, Map<String, dynamic> jobData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final newJob = await _apiService.createManagedJob(token, jobData);
      // print('Created new job: $newJob'); // Debug print

      _managedJobs.insert(0, newJob); // أضف الوظيفة الجديدة في بداية القائمة

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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final updatedJob = await _apiService.updateManagedJob(token, jobId, jobData);
      // print('Updated job: $updatedJob'); // Debug print

      // العثور على الوظيفة في القائمة المحلية وتحديثها
      final index = _managedJobs.indexWhere((job) => job.jobId == jobId);
      if (index != -1) {
        _managedJobs[index] = updatedJob;
      } else {
        // إذا لم يتم العثور على الوظيفة في القائمة المحلية (ربما في صفحة أخرى لم يتم جلبها)، قم بإعادة جلب القائمة
        fetchManagedJobs(context); // إعادة جلب لتحديث القائمة المعروضة
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      await _apiService.deleteManagedJob(token, jobId);

      // إزالة الوظيفة من القائمة المحلية
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
extension ListJobOpportunityExtension on List<JobOpportunity> {
  JobOpportunity? firstWhereOrNull(bool Function(JobOpportunity) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}