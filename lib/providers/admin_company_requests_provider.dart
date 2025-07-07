import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // تأكد من المسار
import '../models/company.dart'; // تأكد من المسار
import '../models/paginated_response.dart'; // تأكد من المسار
import '../services/api_service.dart'; // تأكد من المسار

class AdminCompanyRequestsProvider extends ChangeNotifier {
  List<Company> _companyRequests = []; // Companies with status 'pending'
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int? _lastPage;
  bool _isFetchingMore = false;
  int? _processingCompanyId;
  bool isProcessing(int companyId) => _processingCompanyId == companyId;


  List<Company> get companyRequests => _companyRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMorePages => _lastPage == null || _currentPage < _lastPage!;


  final ApiService _apiService = ApiService();

  Future<void> _processRequest(BuildContext context, int companyId, Future<Company> Function(String, int) apiCall) async {
    _processingCompanyId = companyId; // تحديد الشركة قيد المعالجة
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      await apiCall(token, companyId);

      _companyRequests.removeWhere((company) => company.companyId == companyId);

    } on ApiException catch (e) {
      // يمكنك عرض رسالة خطأ هنا إذا أردت
      print('Failed to process request for company $companyId: ${e.message}');
      rethrow; // رمي الخطأ للواجهة
    } finally {
      _processingCompanyId = null; // إنهاء حالة المعالجة
      notifyListeners();
    }
  }

  // تابع مساعدة للتحويل الآمن من List<dynamic> إلى List<Company>
  List<Company> _convertDynamicListToCompanyList(List<dynamic>? data) {
    if (data == null) return []; // إذا كانت القائمة الأصلية null، أعد قائمة فارغة

    List<Company> companyList = [];
    for (final item in data) {
      // تحقق مما إذا كان العنصر هو خريطة قبل محاولة فك ترميزه كـ Company
      if (item is Map<String, dynamic>) {
        try {
          // حاول فك ترميز العنصر كـ Company
          companyList.add(Company.fromJson(item));
        } catch (e) {
          // إذا فشل فك ترميز عنصر واحد، قم بتسجيل الخطأ وتجاهل هذا العنصر
          print('Error parsing individual Company item in requests list: $e for item $item');
        }
      } else {
        // إذا لم يكن العنصر خريطة، قم بتسجيل الخطأ وتجاهله
        print('Skipping unexpected item type in Company requests list: $item');
      }
    }
    return companyList; // أعد القائمة التي تم بناؤها بأمان
  }


  // جلب طلبات إنشاء الشركات المعلقة (لأدمن) - الصفحة الأولى
  Future<void> fetchCompanyRequests(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final paginatedResponse = await _apiService.fetchCompanyRequests(token!, page: 1);
      // print('Fetched initial company requests response: $paginatedResponse'); // Debug print

      // استخدم التابع المساعد للتحويل الآمن
      _companyRequests = _convertDynamicListToCompanyList(paginatedResponse.data);


      _currentPage = paginatedResponse.currentPage ?? 1;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      _error = e.message;
      print('API Exception during fetchCompanyRequests: ${e.toString()}');
    } catch (e) {
      _error = 'Failed to load company requests: ${e.toString()}';
      print('Unexpected error during fetchCompanyRequests: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // جلب الصفحات التالية من طلبات الشركات المعلقة
  Future<void> fetchMoreCompanyRequests(BuildContext context) async {
    if (!hasMorePages || _isFetchingMore) return;

    _isFetchingMore = true;
    // _error = null; // قد لا تريد مسح الخطأ هنا
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        // هذا لا ينبغي أن يحدث إذا كان المستخدم مصادقاً عليه أساساً
        throw ApiException(401, 'User not authenticated.');
      }

      final nextPage = _currentPage + 1;
      final paginatedResponse = await _apiService.fetchCompanyRequests(token, page: nextPage);
      // print('Fetched more company requests response: $paginatedResponse'); // Debug print

      // استخدم التابع المساعد للتحويل الآمن للإضافة
      _companyRequests.addAll(_convertDynamicListToCompanyList(paginatedResponse.data));


      _currentPage = paginatedResponse.currentPage ?? _currentPage;
      _lastPage = paginatedResponse.lastPage;

    } on ApiException catch (e) {
      print('API Exception during fetchMoreCompanyRequests: ${e.message}');
      // لا تعين _error العام هنا
    } catch (e) {
      print('Unexpected error during fetchMoreCompanyRequests: ${e.toString()}');
      // لا تعين _error العام هنا
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
      // print('Approved company: $updatedCompany'); // Debug print


      // إزالة الطلب من قائمة الطلبات المعلقة (لأن حالته تغيرت)
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
      // print('Rejected company: $updatedCompany'); // Debug print

      // إزالة الطلب من قائمة الطلبات المعلقة (لأن حالته تغيرت)
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