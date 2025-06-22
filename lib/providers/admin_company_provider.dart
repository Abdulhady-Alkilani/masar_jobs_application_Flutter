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

  // !! تم حذف التابع المساعد _convertDynamicListToCompanyList !!
  // لأن التحويل من Map<String, dynamic> إلى Company
  // يتم الآن داخل PaginatedResponse.fromJson باستخدام الدالة الممررة


  // جلب جميع الشركات (للأدمن) - الصفحة الأولى
  Future<void> fetchAllCompanies(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');
      // Optional: check user type is Admin

      final paginatedResponse = await _apiService.fetchAllCompaniesAdmin(token!, page: 1);
      // print('Fetched initial admin companies response: $paginatedResponse'); // Debug print


      // التصحيح هنا: نستخدم PaginatedResponse.data مباشرة
      _companies = paginatedResponse.data ?? [];


      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
      print('API Exception during fetchAllCompaniesAdmin: ${e.toString()}');
    } catch (e) {
      _error = 'Failed to load companies: ${e.toString()}';
      print('Unexpected error during fetchAllCompaniesAdmin: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // جلب الصفحات التالية من الشركات
  Future<void> fetchMoreCompanies(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    // _error = null; // قد لا تريد مسح الخطأ هنا
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchAllCompaniesAdmin(token, page: nextPage);

      // التصحيح هنا: نستخدم PaginatedResponse.data مباشرة
      _companies.addAll(paginatedResponse.data ?? []);


      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('API Exception during fetchMoreAdminCompanies: ${e.message}');
    } catch (e) {
      print('Unexpected error during fetchMoreAdminCompanies: ${e.toString()}');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // جلب شركة واحدة بواسطة الأدمن (لشاشة التفاصيل)
  Future<Company?> fetchSingleCompany(BuildContext context, int companyId) async {
    // حاول إيجاد الشركة في القائمة المحملة حالياً
    final existingCompany = _companies.firstWhereOrNull((company) => company.companyId == companyId);
    if (existingCompany != null) {
      return existingCompany;
    }

    // إذا لم توجد في القائمة، اذهب لجلبه من API
    // لا نغير حالة التحميل الرئيسية هنا، يمكن استخدام حالة تحميل منفصلة
    // setState(() { _isFetchingSingleCompany = true; }); notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final company = await _apiService.fetchSingleCompanyAdmin(token, companyId);
      // لا تضيفه للقائمة هنا

      return company;
    } on ApiException catch (e) {
      print('API Exception during fetchSingleAdminCompany: ${e.message}');
      _error = e.message; // يمكن تعيين الخطأ العام
      return null;
    } catch (e) {
      print('Unexpected error during fetchSingleAdminCompany: ${e.toString()}');
      _error = 'Failed to load company details: ${e.toString()}';
      return null;
    } finally {
      // setState(() { _isFetchingSingleCompany = false; }); notifyListeners();
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
      // print('Created new company: $newCompany'); // Debug print

      _companies.insert(0, newCompany); // أضف في البداية

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
      // print('Updated company: $updatedCompany'); // Debug print

      // العثور على الشركة في القائمة المحلية وتحديثها
      final index = _companies.indexWhere((company) => company.companyId == companyId);
      if (index != -1) {
        _companies[index] = updatedCompany;
      } else {
        // إذا لم يتم العثور عليها، قم بإعادة جلب القائمة
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
extension ListAdminCompanyExtension on List<Company> { // ربما يجب تغيير الاسم ليكون أكثر وضوحاً
  Company? firstWhereOrNull(bool Function(Company) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}