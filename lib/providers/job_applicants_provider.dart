import 'package:flutter/material.dart';
import '../models/applicant.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class JobApplicantsProvider extends ChangeNotifier {
  List<Applicant> _applicants = [];
  bool _isLoading = false;
  String? _error;
  int? _currentJobId; // لتتبع الوظيفة التي يتم جلب المتقدمين لها

  List<Applicant> get applicants => _applicants;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get currentJobId => _currentJobId;

  final ApiService _apiService = ApiService();

  // جلب المتقدمين لوظيفة محددة
  Future<void> fetchApplicants(BuildContext context, int jobId) async {
    // تجنب إعادة الجلب لنفس الوظيفة إذا كانت البيانات موجودة بالفعل وغير قديمة جداً
    if (_currentJobId == jobId && _applicants.isNotEmpty && !_isLoading) {
      return;
    }

    _isLoading = true;
    _error = null;
    _currentJobId = jobId; // حفظ معرف الوظيفة
    _applicants = []; // مسح القائمة القديمة عند جلب وظيفة جديدة
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');
      // Optional: check user type/authorization for this specific job on backend

      _applicants = await _apiService.fetchJobApplicants(token, jobId);
      print(_applicants);

    } on ApiException catch (e) {
      _error = e.message;
      _applicants = []; // مسح القائمة في حالة الخطأ
    } catch (e) {
      _error = 'Failed to load applicants: ${e.toString()}';
      _applicants = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// TODO: Add methods to update an applicant's status (e.g., mark as reviewed, rejected)
// These methods would call the API and then update the list (_applicants) locally.

  Future<void> updateApplicantStatus(BuildContext context, int applicationId, String newStatus) async {
    // ... loading state ...
    try {
      final token = Provider
          .of<AuthProvider>(context, listen: false)
          .token;
      if (token == null) throw ApiException(401, 'User not authenticated.');
      // Assume API has a PUT endpoint like /company-manager/applications/{id} with {status: newStatus}
      // Or a dedicated endpoint like /company-manager/applications/{id}/status
      final updatedApplicant = await _apiService.updateApplicantStatus(
          token, applicationId, newStatus);
      print(updatedApplicant);

      // Find and update the applicant in the local list
      final index = _applicants.indexWhere((app) => app.id == applicationId);
      if (index != -1) {
        _applicants[index] = updatedApplicant as Applicant;
        notifyListeners();
      }
    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to update applicant status: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally { // ... loading state ... }
    }
  }
}