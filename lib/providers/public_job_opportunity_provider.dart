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

  Future<void> fetchJobOpportunities() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final paginatedResponse = await _apiService.fetchJobOpportunities(page: 1);
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

  Future<void> fetchMoreJobOpportunities() async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    _error = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchJobOpportunities(page: nextPage);
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

  Future<JobOpportunity?> fetchJobOpportunity(int jobId) async {
    final existingJob = _jobs.firstWhereOrNull((job) => job.jobId == jobId);
    print(existingJob);
    if (existingJob != null) {
      return existingJob;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final job = await _apiService.fetchJobOpportunity(jobId);
      print(job);
      return job;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = 'Failed to load job: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Simple extension for List<JobOpportunity>
extension ListJobExtension on List<JobOpportunity> {
  JobOpportunity? firstWhereOrNull(bool Function(JobOpportunity) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}