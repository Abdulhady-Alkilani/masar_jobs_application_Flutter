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

  // تابع مساعدة للتحويل الآمن من List<dynamic> إلى List<Company>
  List<Company> _convertDynamicListToCompanyList(List<dynamic>? data) {
    if (data == null) return [];
    List<Company> companyList = [];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        try {
          companyList.add(Company.fromJson(item));
        } catch (e) {
          print('Error parsing individual Company item: $e for item $item');
        }
      } else {
        print('Skipping unexpected item type in Company list: $item');
      }
    }
    return companyList;
  }


  // جلب أول صفحة من الشركات العامة
  Future<void> fetchCompanies({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // هذا المسار عام لا يتطلب توكن
      final paginatedResponse = await _apiService.fetchCompanies(page: page);

      // استخدم التابع المساعد للتحويل الآمن
      _companies = _convertDynamicListToCompanyList(paginatedResponse.data);


      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
      print('API Exception during fetchPublicCompanies: ${e.toString()}');
    } catch (e) {
      _error = 'Failed to load companies: ${e.toString()}';
      print('Unexpected error during fetchPublicCompanies: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // جلب الصفحات التالية من الشركات العامة
  Future<void> fetchMoreCompanies() async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    // _error = null; // قد لا تريد مسح الخطأ هنا
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchCompanies(page: nextPage);

      // استخدم التابع المساعد للتحويل الآمن للإضافة
      _companies.addAll(_convertDynamicListToCompanyList(paginatedResponse.data));


      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('API Exception during fetchMorePublicCompanies: ${e.message}');
    } catch (e) {
      print('Unexpected error during fetchMorePublicCompanies: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // جلب تفاصيل شركة محددة (من القائمة المحملة أو API العام)
  Future<Company?> fetchCompany(int companyId) async {
    // حاول إيجاد الشركة في القائمة المحملة حالياً
    final existingCompany = _companies.firstWhereOrNull((company) => company.companyId == companyId);
    if (existingCompany != null) {
      return existingCompany;
    }

    // إذا لم توجد في القائمة، اذهب لجلبه من API العام
    // لا نغير حالة التحميل الرئيسية هنا، يمكن استخدام حالة تحميل منفصلة
    // setState(() { _isFetchingSingleCompany = true; }); notifyListeners();

    try {
      final company = await _apiService.fetchCompany(companyId);
      // لا تضيفه للقائمة
      return company;
    } on ApiException catch (e) {
      print('API Exception during fetchSinglePublicCompany: ${e.message}');
      _error = e.message; // يمكن تعيين الخطأ العام
      return null;
    } catch (e) {
      print('Unexpected error during fetchSinglePublicCompany: ${e.toString()}');
      _error = 'Failed to load company details: ${e.toString()}';
      return null;
    } finally {
      // setState(() { _isFetchingSingleCompany = false; }); notifyListeners();
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