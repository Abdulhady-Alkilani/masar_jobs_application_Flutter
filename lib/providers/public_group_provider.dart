import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/api_service.dart';

class PublicGroupProvider extends ChangeNotifier {
  List<Group> _groups = [];
  bool _isLoading = false;
  String? _error;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  Future<void> fetchGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _groups = await _apiService.fetchGroups();
    } on ApiException catch (e) {
      _error = e.message;
      // --- أضف هذا السطر للطباعة ---
      print("===== API ERROR in PublicGroupProvider: $e =====");
    } catch (e) {
      _error = 'Failed to load groups: ${e.toString()}';
      // --- أضف هذا السطر للطباعة ---
      print("===== GENERIC ERROR in PublicGroupProvider: $e =====");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // جلب تفاصيل مجموعة محددة
  Future<Group?> fetchGroup(int groupId) async {
    final existingGroup = _groups.firstWhereOrNull((group) => group.groupId == groupId);
    print(existingGroup);
    if (existingGroup != null) {
      return existingGroup;
    }



    _isLoading = true; // Can use a separate loading state
    _error = null;
    notifyListeners();

    try {
      final group = await _apiService.fetchGroup(groupId);
      print(group);
      return group;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = 'Failed to load group: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Simple extension for List<Group>
extension ListGroupExtension on List<Group> {
  Group? firstWhereOrNull(bool Function(Group) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}