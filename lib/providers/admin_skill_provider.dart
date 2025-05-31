import 'package:flutter/material.dart';
import '../models/skill.dart';
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

  // جلب جميع المهارات (للأدمن)
  Future<void> fetchAllSkills(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      _skills = await _apiService.fetchAllSkillsAdmin(token);
      print(_skills);

    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load skills: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
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
      print(newSkill);

      _skills.add(newSkill); // إضافة في النهاية أو ترتيب أبجدي حسب الحاجة
      _skills.sort((a, b) => a.name!.compareTo(b.name!)); // ترتيب أبجدي

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
      print(updatedSkill);

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

// Simple extension for List<Skill> if needed
extension ListAdminSkillExtension on List<Skill> {
  Skill? firstWhereOrNull(bool Function(Skill) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}