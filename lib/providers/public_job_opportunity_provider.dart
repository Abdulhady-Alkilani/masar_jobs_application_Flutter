import 'package:flutter/material.dart';
import '../models/job_opportunity.dart';
import '../models/paginated_response.dart';
import '../services/api_service.dart';

class PublicJobOpportunityProvider extends ChangeNotifier {
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

  // **تم حذف التابع المساعد _convertDynamicListToJobOpportunityList**


  // جلب أول صفحة من فرص العمل العامة
  Future<void> fetchJobOpportunities({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // هذا المسار عام لا يتطلب توكن
      final paginatedResponse = await _apiService.fetchJobOpportunities(page: page);
      // print('Fetched initial public jobs response: $paginatedResponse'); // Debug print

      // **استخدام PaginatedResponse.data مباشرة**
      _jobs = paginatedResponse.data ?? [];


      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
      print('API Exception during fetchPublicJobOpportunities: ${e.toString()}');
    } catch (e) {
      _error = 'Failed to load jobs: ${e.toString()}';
      print('Unexpected error during fetchPublicJobOpportunities: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // جلب الصفحات التالية من فرص العمل العامة
  Future<void> fetchMoreJobOpportunities() async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    // _error = null; // قد لا تريد مسح الخطأ هنا
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchJobOpportunities(page: nextPage);

      // **استخدام PaginatedResponse.data مباشرة**
      _jobs.addAll(paginatedResponse.data ?? []);


      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('API Exception during fetchMorePublicJobOpportunities: ${e.message}');
    } catch (e) {
      print('Unexpected error during fetchMorePublicJobOpportunities: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // جلب تفاصيل فرصة عمل محددة (من القائمة المحملة أو API العام)
  Future<JobOpportunity?> fetchJobOpportunity(int jobId) async {
    // حاول إيجاد الوظيفة في القائمة المحملة حالياً
    final existingJob = _jobs.firstWhereOrNull((job) => job.jobId == jobId);
    if (existingJob != null) {
      return existingJob;
    }

    // إذا لم توجد في القائمة، اذهب لجلبه من API العام
    // لا نغير حالة التحميل الرئيسية هنا، يمكن استخدام حالة تحميل منفصلة
    // setState(() { _isFetchingSingleJob = true; }); notifyListeners();

    try {
      final job = await _apiService.fetchJobOpportunity(jobId);
      // لا تضيفه للقائمة
      return job;
    } on ApiException catch (e) {
      print('API Exception during fetchSinglePublicJobOpportunity: ${e.message}');
      _error = e.message; // يمكن تعيين الخطأ العام
      return null;
    } catch (e) {
      print('Unexpected error during fetchSinglePublicJobOpportunity: ${e.toString()}');
      _error = 'Failed to load job details: ${e.toString()}';
      return null;
    } finally {
      // setState(() { _isFetchingSingleJob = false; }); notifyListeners();
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