import 'package:flutter/material.dart';
import '../models/skill.dart';
// لا يوجد Pagination لـ skills
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';


class AdminSkillProvider extends ChangeNotifier {
  List<Skill> _skills = [];
  bool _isLoading = false;
  String? _error;

  List<Skill> get skills => _skills;
  bool get isLoading => _isLoading;
  String? get error => _error;


  final ApiService _apiService = ApiService();

  // لا نحتاج تابع مساعدة للتحويل الآمن لأن مسار Skills Admin لا يستخدم Pagination
  // والـ ApiService يعيد List<Skill> مباشرة

  // جلب جميع المهارات (للأدمن)
  Future<void> fetchAllSkills(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      _skills = await _apiService.fetchAllSkillsAdmin(token!);
      _skills.sort((a, b) => a.name!.compareTo(b.name!)); // ترتيب أبجدي

    } on ApiException catch (e) {
      _error = e.message;
      print('API Exception during fetchAllSkillsAdmin: ${e.toString()}');
    } catch (e) {
      _error = 'Failed to load skills: ${e.toString()}';
      print('Unexpected error during fetchAllSkillsAdmin: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // جلب مهارة واحدة بواسطة الأدمن (لشاشة التفاصيل)
  Future<Skill?> fetchSingleSkill(BuildContext context, int skillId) async {
    // حاول إيجاد المهارة في القائمة المحملة حالياً
    final existingSkill = _skills.firstWhereOrNull((skill) => skill.skillId == skillId);
    if (existingSkill != null) {
      return existingSkill;
    }

    // إذا لم توجد في القائمة، اذهب لجلبه من API
    // لا نغير حالة التحميل الرئيسية هنا
    // setState(() { _isFetchingSingleSkill = true; }); notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final skill = await _apiService.fetchSingleSkillAdmin(token, skillId);
      // لا تضيفه للقائمة هنا

      return skill;
    } on ApiException catch (e) {
      print('API Exception during fetchSingleAdminSkill: ${e.message}');
      _error = e.message; // يمكن تعيين الخطأ العام
      return null;
    } catch (e) {
      print('Unexpected error during fetchSingleAdminSkill: ${e.toString()}');
      _error = 'Failed to load skill details: ${e.toString()}';
      return null;
    } finally {
      // setState(() { _isFetchingSingleSkill = false; }); notifyListeners();
    }
  }


  // إنشاء مهارة جديدة (بواسطة الأدمن)
  Future<void> createSkill(BuildContext context, String skillName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final newSkill = await _apiService.createSkill(token, skillName);
      // print('Created new skill: $newSkill'); // Debug print

      _skills.add(newSkill); // إضافة في النهاية
      _skills.sort((a, b) => a.name!.compareTo(b.name!)); // إعادة ترتيب أبجدي

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to create skill: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحديث مهارة (بواسطة الأدمن)
  Future<void> updateSkill(BuildContext context, int skillId, String newSkillName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final updatedSkill = await _apiService.updateSkill(token, skillId, newSkillName);
      // print('Updated skill: $updatedSkill'); // Debug print

      // العثور على المهارة في القائمة المحلية وتحديثها
      final index = _skills.indexWhere((skill) => skill.skillId == skillId);
      if (index != -1) {
        _skills[index] = updatedSkill;
        _skills.sort((a, b) => a.name!.compareTo(b.name!)); // إعادة الترتيب
      } else {
        // إذا لم يتم العثور عليه، قم بإعادة جلب القائمة
        fetchAllSkills(context);
      }

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to update skill: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // حذف مهارة (بواسطة الأدمن)
  Future<void> deleteSkill(BuildContext context, int skillId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      await _apiService.deleteSkill(token, skillId);

      _skills.removeWhere((skill) => skill.skillId == skillId);

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to delete skill: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Simple extension for List<Skill> if not available elsewhere or using collection package
extension ListAdminSkillExtension on List<Skill> {
  Skill? firstWhereOrNull(bool Function(Skill) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}