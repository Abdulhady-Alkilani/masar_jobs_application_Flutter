// lib/screens/admin/skills/admin_skills_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_skill_provider.dart';
import '../../../models/skill.dart';
import 'admin_create_edit_skill_screen.dart';
import '../../../services/api_service.dart';

class AdminSkillsListScreen extends StatefulWidget {
  const AdminSkillsListScreen({super.key});

  @override
  State<AdminSkillsListScreen> createState() => _AdminSkillsListScreenState();
}

class _AdminSkillsListScreenState extends State<AdminSkillsListScreen> {
  @override
  void initState() {
    super.initState();
    // استخدام addPostFrameCallback لضمان أن الـ context متاح
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminSkillProvider>(context, listen: false).fetchAllSkills(context);
    });
  }

  // دالة لحذف مهارة مع تأكيد
  Future<void> _deleteSkill(Skill skill, AdminSkillProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من رغبتك في حذف مهارة "${skill.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await provider.deleteSkill(context, skill.skillId!);
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
        title: const Text('إدارة المهارات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'إضافة مهارة جديدة',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminCreateEditSkillScreen()));
            },
          ),
        ],
      ),
      body: Consumer<AdminSkillProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('خطأ: ${provider.error}'));
          }
          if (provider.skills.isEmpty) {
            return const Center(child: Text('لا توجد مهارات.'));
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchAllSkills(context),
            child: ListView.builder(
              itemCount: provider.skills.length,
              itemBuilder: (context, index) {
                final skill = provider.skills[index];
                return ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: Text(skill.name ?? 'اسم غير معروف'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminCreateEditSkillScreen(skill: skill)));
                      } else if (value == 'delete') {
                        _deleteSkill(skill, provider);
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