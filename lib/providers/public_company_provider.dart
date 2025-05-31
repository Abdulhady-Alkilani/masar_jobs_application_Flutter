import 'package:flutter/material.dart';
import '../models/company.dart';
import '../models/paginated_response.dart';
import '../services/api_service.dart';

class PublicCompanyProvider extends ChangeNotifier {
  List<Company> _companies = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int? _lastPage;
  bool _isFetchingMore = false;

  List<Company> get companies => _companies;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMorePages => _lastPage == null || _currentPage < _lastPage!;

  final ApiService _apiService = ApiService();

  Future<void> fetchCompanies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final paginatedResponse = await _apiService.fetchCompanies(page: 1);
      print(paginatedResponse);
      _companies.addAll((paginatedResponse.data ?? []) as Iterable<Company>);
      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load companies: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreCompanies() async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    _error = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchCompanies(page: nextPage);
      print(paginatedResponse);
      _companies.addAll((paginatedResponse.data ?? []) as Iterable<Company>);
      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('Error fetching more companies: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching more companies: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<Company?> fetchCompany(int companyId) async {
    final existingCompany = _companies.firstWhereOrNull((company) => company.companyId == companyId);
    print(existingCompany);
    if (existingCompany != null) {
      return existingCompany;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final company = await _apiService.fetchCompany(companyId);
      print(company);
      return company;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = 'Failed to load company: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Simple extension for List<Company>
extension ListCompanyExtension on List<Company> {
  Company? firstWhereOrNull(bool Function(Company) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}