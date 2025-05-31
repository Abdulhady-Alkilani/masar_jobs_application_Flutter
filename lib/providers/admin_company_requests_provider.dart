import 'package:flutter/material.dart';
import '../models/company.dart';
import '../models/paginated_response.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminCompanyRequestsProvider extends ChangeNotifier {
  List<Company> _companyRequests = []; // Companies with status 'pending'
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int? _lastPage;
  bool _isFetchingMore = false;

  List<Company> get companyRequests => _companyRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMorePages => _lastPage == null || _currentPage < _lastPage!;


  final ApiService _apiService = ApiService();

  // جلب طلبات إنشاء الشركات المعلقة (لأدمن)
  Future<void> fetchCompanyRequests(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final paginatedResponse = await _apiService.fetchCompanyRequests(token!, page: 1);
      print(paginatedResponse);
      _companyRequests.addAll((paginatedResponse.data ?? []) as Iterable<Company>);
      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load company requests: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreCompanyRequests(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchCompanyRequests(token, page: nextPage);
      print(paginatedResponse);
      _companyRequests.addAll((paginatedResponse.data ?? []) as Iterable<Company>);
      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('Error fetching more company requests: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching more company requests: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // الموافقة على طلب شركة (بواسطة الأدمن)
  Future<void> approveRequest(BuildContext context, int companyId) async {
    _isLoading = true; // Or separate loading state for the action
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final updatedCompany = await _apiService.approveCompanyRequest(token, companyId);
      print(updatedCompany);

      // إزالة الطلب من قائمة الطلبات المعلقة
      _companyRequests.removeWhere((company) => company.companyId == companyId);
      // Optionally add it to the main admin companies list if you have a provider for that

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to approve company request: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // رفض طلب شركة (بواسطة الأدمن)
  Future<void> rejectRequest(BuildContext context, int companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final updatedCompany = await _apiService.rejectCompanyRequest(token, companyId);
      print(updatedCompany);

      // إزالة الطلب من قائمة الطلبات المعلقة
      _companyRequests.removeWhere((company) => company.companyId == companyId);
      // Optionally update it in the main admin companies list if status is set to rejected

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to reject company request: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Simple extension for List<Company>
extension ListAdminCompanyRequestExtension on List<Company> {
  Company? firstWhereOrNull(bool Function(Company) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}