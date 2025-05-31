import 'package:flutter/material.dart';
import '../models/skill.dart';
import '../services/api_service.dart';

class PublicSkillProvider extends ChangeNotifier {
  List<Skill> _skills = [];
  bool _isLoading = false;
  String? _error;

  List<Skill> get skills => _skills;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  // جلب قائمة المهارات (مع إمكانية البحث)
  Future<void> fetchSkills({String? searchTerm}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _skills = await _apiService.fetchSkills(searchTerm: searchTerm);
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

// جلب تفاصيل مهارة محددة (إذا كان المسار العام يدعمها، وهو لا يدعمها في api.php)
// بناءً على api.php، المسار العام للskills هو index فقط. show هي للأدمن.
// إذا أردت Show في العام، يجب تعديل api.php والمتحكم.
// Future<Skill?> fetchSkill(int skillId) async { ... }
}