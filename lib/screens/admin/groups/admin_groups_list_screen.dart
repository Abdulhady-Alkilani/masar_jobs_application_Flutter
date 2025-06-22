// lib/screens/admin/groups/admin_groups_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_group_provider.dart';
import '../../../models/group.dart';
import 'admin_create_edit_group_screen.dart';
import '../../../services/api_service.dart';

class AdminGroupsListScreen extends StatefulWidget {
  const AdminGroupsListScreen({super.key});

  @override
  State<AdminGroupsListScreen> createState() => _AdminGroupsListScreenState();
}

class _AdminGroupsListScreenState extends State<AdminGroupsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminGroupProvider>(context, listen: false).fetchAllGroups(context);
    });
  }

  // دالة لحذف مجموعة مع تأكيد
  Future<void> _deleteGroup(Group group, AdminGroupProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من رغبتك في حذف هذه المجموعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await provider.deleteGroup(context, group.groupId!);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف بنجاح'), backgroundColor: Colors.green));
      } on ApiException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: ${e.message}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المجموعات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'إضافة مجموعة جديدة',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCreateEditGroupScreen()));
            },
          ),
        ],
      ),
      body: Consumer<AdminGroupProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('خطأ: ${provider.error}'));
          }
          if (provider.groups.isEmpty) {
            return const Center(child: Text('لا توجد مجموعات.'));
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchAllGroups(context),
            child: ListView.builder(
              itemCount: provider.groups.length,
              itemBuilder: (context, index) {
                final group = provider.groups[index];
                return ListTile(
                  leading: const Icon(Icons.group_work, color: Colors.blueGrey),
                  title: Text(group.telegramHyperLink ?? 'رابط غير معروف'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminCreateEditGroupScreen(group: group)));
                      } else if (value == 'delete') {
                        _deleteGroup(group, provider);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}