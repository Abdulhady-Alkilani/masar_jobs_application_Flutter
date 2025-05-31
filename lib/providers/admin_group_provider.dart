import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminGroupProvider extends ChangeNotifier {
  List<Group> _groups = [];
  bool _isLoading = false;
  String? _error;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  // جلب جميع المجموعات (للأدمن)
  Future<void> fetchAllGroups(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      _groups = await _apiService.fetchAllGroupsAdmin(token);
      print(_groups);

    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load groups: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // إنشاء مجموعة (بواسطة الأدمن)
  Future<void> createGroup(BuildContext context, String telegramLink) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final newGroup = await _apiService.createGroup(token, telegramLink);
      print(newGroup);

      _groups.add(newGroup);
      // يمكنك ترتيب القائمة هنا إذا أردت
      // _groups.sort((a, b) => a.telegramHyperLink!.compareTo(b.telegramHyperLink!));

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to create group: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحديث مجموعة (بواسطة الأدمن)
  Future<void> updateGroup(BuildContext context, int groupId, String newTelegramLink) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      final updatedGroup = await _apiService.updateGroup(token, groupId, newTelegramLink);
      print(updatedGroup);

      final index = _groups.indexWhere((group) => group.groupId == groupId);
      if (index != -1) {
        _groups[index] = updatedGroup;
        // يمكنك إعادة ترتيب القائمة هنا إذا أردت
      } else {
        fetchAllGroups(context); // إعادة جلب في حالة عدم العثور
      }

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to update group: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // حذف مجموعة (بواسطة الأدمن)
  Future<void> deleteGroup(BuildContext context, int groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw ApiException(401, 'User not authenticated.');

      await _apiService.deleteGroup(token, groupId);

      _groups.removeWhere((group) => group.groupId == groupId);

    } on ApiException catch (e) {
      _error = e.message;
      throw e;
    } catch (e) {
      _error = 'Failed to delete group: ${e.toString()}';
      throw ApiException(0, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// Simple extension for List<Group>
extension ListAdminGroupExtension on List<Group> {
  Group? firstWhereOrNull(bool Function(Group) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}