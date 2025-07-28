import 'package:flutter/material.dart';
import '../models/company.dart';
import '../services/api_service.dart';

class PublicCompanyProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Company> _companies = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;

  List<Company> get companies => _companies;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get error => _error;
  bool get hasMorePages => _hasMorePages;

  Future<void> fetchCompanies() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final paginatedResponse = await _apiService.fetchCompanies(page: 1);
      _companies = paginatedResponse.data ?? [];
      _currentPage = paginatedResponse.currentPage ?? 1;
      _hasMorePages = paginatedResponse.nextPageUrl != null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreCompanies() async {
    if (_isFetchingMore || !_hasMorePages) return;
    _isFetchingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchCompanies(page: nextPage);
      _companies.addAll(paginatedResponse.data ?? []);
      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _hasMorePages = paginatedResponse.nextPageUrl != null;
    } catch (e) {
      print("Failed to fetch more companies: $e");
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<Company> fetchCompanyDetails(int companyId) async {
    try {
      return await _apiService.fetchCompany(companyId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
