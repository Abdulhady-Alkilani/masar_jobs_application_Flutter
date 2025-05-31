import 'package:flutter/material.dart';
import '../models/company.dart';
import '../models/paginated_response.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminCompanyProvider extends ChangeNotifier {
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

  // جلب جميع الشركات (للأدمن)
  Future<void> fetchAllCompanies(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final paginatedResponse = await _apiService.fetchAllCompaniesAdmin(token!, page: 1);
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

  Future<void> fetchMoreCompanies(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchAllCompaniesAdmin(token, page: nextPage);
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


  // إنشاء شركة (بواسطة الأدمن)
  Future<void> createCompany(BuildContext context, Map<String, dynamic> companyData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final newCompany = await _apiService.createCompanyAdmin(token, companyData);
      print(newCompany);

      _companies.insert(0, newCompany); // أضف في البداية (أحدث)

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to create company: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحديث شركة (بواسطة الأدمن)
  Future<void> updateCompany(BuildContext context, int companyId, Map<String, dynamic> companyData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final updatedCompany = await _apiService.updateCompanyAdmin(token, companyId, companyData);
      print(updatedCompany);

      final index = _companies.indexWhere((company) => company.companyId == companyId);
      if (index != -1) {
        _companies[index] = updatedCompany;
      } else {
        fetchAllCompanies(context);
      }

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to update company: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // حذف شركة (بواسطة الأدمن)
  Future<void> deleteCompany(BuildContext context, int companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      await _apiService.deleteCompanyAdmin(token, companyId);

      _companies.removeWhere((company) => company.companyId == companyId);

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to delete company: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Simple extension for List<Company>
extension ListAdminCompanyExtension on List<Company> {
  Company? firstWhereOrNull(bool Function(Company) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}