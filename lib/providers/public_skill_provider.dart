import 'package:flutter/material.dart';
import '../models/skill.dart';
import '../services/api_service.dart';

class PublicSkillProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Skill> _skills = [];
  bool _isLoading = false;
  String? _error;

  List<Skill> get skills => _skills;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSkills({String? searchTerm}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _skills = await _apiService.fetchSkills(searchTerm: searchTerm);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
