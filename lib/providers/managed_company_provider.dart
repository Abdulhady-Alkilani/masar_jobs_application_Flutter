import 'package:flutter/material.dart';
import 'dart:io'; // Added for File
import '../models/company.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ManagedCompanyProvider extends ChangeNotifier {
  Company? _company;
  bool _isLoading = false;
  String? _error;

  Company? get company => _company;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCompany => _company != null; // للتحقق بسهولة

  final ApiService _apiService = ApiService();


  // جلب بيانات الشركة التي يديرها المستخدم الحالي
  Future<void> fetchManagedCompany(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      // Optional: check user type
      // final userType = Provider.of<AuthProvider>(context, listen: false).user?.type;
      // if (token == null || userType != 'مدير شركة') {
      //    throw ApiException(403, 'User not authorized.');
      // }

      _company = await _apiService.fetchManagedCompany(token!);
      print(_company);

    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // لا يوجد شركة مرتبطة، هذه حالة طبيعية وليست خطأ فادح
        _company = null;
        _error = null; // مسح أي خطأ سابق
        print('No company associated with this manager.');
      } else {
        _error = e.message;
      }
    } catch (e) {
      _error = 'Failed to load managed company: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحديث بيانات الشركة التي يديرها المستخدم
  Future<void> updateManagedCompany(BuildContext context, Map<String, dynamic> companyData) async {
    _isLoading = true; // Or separate loading state for update action
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      // تحقق قبل التحديث إذا كان هناك شركة موجودة بالفعل
      if (_company == null) {
        throw ApiException(404, 'Cannot update: No company associated with this manager.');
      }

      _company = await _apiService.updateManagedCompany(token, companyData);
      print(_company);
      // في حالة النجاح، تم تحديث _company تلقائياً

    } on ApiException catch (e) {
      _error = e.message;
      throw e; // رمي الخطأ للواجهة
    } catch (e) {
      _error = 'Failed to update managed company: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// تابع لإنشاء شركة جديدة إذا لم تكن موجودة (إذا كان هذا المسار موجوداً)
// API doc suggests admin POST /companies. If manager can create one,
// a separate endpoint/logic is needed, and this provider would need a method for it.
// Example placeholder:

   Future<void> requestCompanyCreationAsManager(BuildContext context, {required Map<String, String> fields, File? media}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        throw ApiException(401, 'User not authenticated.');
      }
      _company = await _apiService.createManagedCompany(token, fields);
      print(_company);
    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to create company request: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}