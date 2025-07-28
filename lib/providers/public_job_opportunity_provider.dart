import 'package:flutter/material.dart';
import '../models/job_opportunity.dart';
import '../services/api_service.dart';

class PublicJobOpportunityProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<JobOpportunity> _jobs = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;

  List<JobOpportunity> get jobs => _jobs;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get error => _error;
  bool get hasMorePages => _hasMorePages;

  Future<void> fetchJobOpportunities() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final paginatedResponse = await _apiService.fetchJobOpportunities(page: 1);
      _jobs = paginatedResponse.data!;
      _currentPage = paginatedResponse.currentPage ?? 1;
      _hasMorePages = paginatedResponse.nextPageUrl != null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreJobOpportunities() async {
    if (_isFetchingMore || !_hasMorePages) return;
    _isFetchingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchJobOpportunities(page: nextPage);
      _jobs.addAll(paginatedResponse.data ?? []);
      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _hasMorePages = paginatedResponse.nextPageUrl != null;
    } catch (e) {
      print("Failed to fetch more jobs: $e");
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<JobOpportunity> fetchJobOpportunityDetails(int jobId) async {
    try {
      return await _apiService.fetchJobOpportunity(jobId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
