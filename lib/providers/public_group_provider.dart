import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/api_service.dart';

class PublicGroupProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Group> _groups = [];
  bool _isLoading = false;
  String? _error;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _groups = await _apiService.fetchGroups();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Group> fetchGroupDetails(int groupId) async {
    // This provider doesn't have a loading state for single items,
    // so the UI will have to handle its own loading state if needed.
    try {
      return await _apiService.fetchGroup(groupId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
