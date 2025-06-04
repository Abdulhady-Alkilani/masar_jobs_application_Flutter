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

  // تابع مساعدة للتحويل الآمن من List<dynamic> إلى List<JobOpportunity>
  List<JobOpportunity> _convertDynamicListToJobOpportunityList(List<dynamic>? data) {
    if (data == null) return [];
    List<JobOpportunity> jobList = [];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        try {
          jobList.add(JobOpportunity.fromJson(item));
        } catch (e) {
          print('Error parsing individual JobOpportunity item: $e for item $item');
        }
      } else {
        print('Skipping unexpected item type in JobOpportunity list: $item');
      }
    }
    return jobList;
  }


  // جلب جميع فرص العمل (للأدمن) - الصفحة الأولى
  Future<void> fetchAllJobs(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');
      // Optional: check user type is Admin

      final paginatedResponse = await _apiService.fetchAllJobsAdmin(token!, page: 1);
      // print('Fetched initial admin jobs response: $paginatedResponse'); // Debug print

      // استخدم التابع المساعد للتحويل الآمن
      _jobs = _convertDynamicListToJobOpportunityList(paginatedResponse.data);


      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
      print('API Exception during fetchAllJobsAdmin: ${e.toString()}');
    } catch (e) {
      _error = 'Failed to load jobs: ${e.toString()}';
      print('Unexpected error during fetchAllJobsAdmin: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // جلب الصفحات التالية من فرص العمل
  Future<void> fetchMoreJobs(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    // _error = null; // قد لا تريد مسح الخطأ هنا
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchAllJobsAdmin(token, page: nextPage);
      // print('Fetched more admin jobs response: $paginatedResponse'); // Debug print

      // استخدم التابع المساعد للتحويل الآمن للإضافة
      _jobs.addAll(_convertDynamicListToJobOpportunityList(paginatedResponse.data));


      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('API Exception during fetchMoreAdminJobs: ${e.message}');
    } catch (e) {
      print('Unexpected error during fetchMoreAdminJobs: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // جلب فرصة عمل واحدة بواسطة الأدمن (لشاشة التفاصيل)
  Future<JobOpportunity?> fetchSingleJob(BuildContext context, int jobId) async {
    // حاول إيجاد الوظيفة في القائمة المحملة حالياً
    final existingJob = _jobs.firstWhereOrNull((job) => job.jobId == jobId);
    if (existingJob != null) {
      return existingJob;
    }

    // إذا لم يوجد في القائمة، اذهب لجلبه من API
    // لا نغير حالة التحميل الرئيسية هنا
    // setState(() { _isFetchingSingleJob = true; }); notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final job = await _apiService.fetchSingleJobAdmin(token, jobId);
      // لا تضيفه للقائمة هنا

      return job;
    } on ApiException catch (e) {
      print('API Exception during fetchSingleAdminJob: ${e.message}');
      _error = e.message; // يمكن تعيين الخطأ العام
      return null;
    } catch (e) {
      print('Unexpected error during fetchSingleAdminJob: ${e.toString()}');
      _error = 'Failed to load job details: ${e.toString()}';
      return null;
    } finally {
      // setState(() { _isFetchingSingleJob = false; }); notifyListeners();
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
      // print('Created new job: $newJob'); // Debug print

      _jobs.insert(0, newJob); // أضف الوظيفة الجديدة في بداية القائمة

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
      // print('Updated job: $updatedJob'); // Debug print


      // العثور على الوظيفة في القائمة المحلية وتحديثها
      final index = _jobs.indexWhere((job) => job.jobId == jobId);
      if (index != -1) {
        _jobs[index] = updatedJob;
      } else {
        // إذا لم يتم العثور على الوظيفة في القائمة المحلية (ربما في صفحة أخرى لم يتم جلبها)، قم بإعادة جلب القائمة
        fetchAllJobs(context); // إعادة جلب لتحديث القائمة المعروضة
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

      // إزالة الوظيفة من القائمة المحلية
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
extension ListJobOpportunityExtension on List<JobOpportunity> {
  JobOpportunity? firstWhereOrNull(bool Function(JobOpportunity) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}