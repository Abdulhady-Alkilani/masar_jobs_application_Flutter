import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_skill_provider.dart'; // لتنفيذ عمليات الحذف
import '../models/skill.dart'; // تأكد من المسار
import '../services/api_service.dart'; // لاستخدام ApiException

// استيراد شاشة إضافة/تعديل مهارة
import 'create_edit_skill_screen.dart'; // <--- تأكد من المسار


class AdminSkillsListScreen extends StatefulWidget {
  const AdminSkillsListScreen({Key? key}) : super(key: key);

  @override
  // الخطأ هنا: يجب أن يطابق اسم كلاس الـ State
  // _AdminSkillsListScreenState createState() => _AdminSkillsListState();
  _AdminSkillsListScreenState createState() => _AdminSkillsListScreenState(); // <--- التصحيح هنا
}

class _AdminSkillsListScreenState extends State<AdminSkillsListScreen> {
  // لا نحتاج ScrollController هنا لأن AdminSkillProvider لا يستخدم Pagination حالياً
  // إذا أضفت Pagination لاحقاً، ستحتاج إضافة ScrollController ومستمع له

  @override
  void initState() {
    super.initState();
    // جلب قائمة المهارات عند تهيئة الشاشة
    Provider.of<AdminSkillProvider>(context, listen: false).fetchAllSkills(context);
    // إذا أضفت Pagination، ستحتاج إضافة مستمع الـ scroll هنا
  }

  @override
  void dispose() {
    // إذا أضفت ScrollController، لا تنسى dispose هنا
    super.dispose();
  }

  // تابع لحذف المهارة
  Future<void> _deleteSkill(int skillId) async {
    // TODO: إضافة AlertDialog للتأكيد قبل الحذف (تم التنفيذ الآن)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد أنك تريد حذف هذه المهارة؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () { Navigator.of(dialogContext).pop(false); },
            ),
            TextButton(
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
              onPressed: () { Navigator.of(dialogContext).pop(true); },
            ),
          ],
        );
      },
    );

    if (confirmed == true) { // إذا أكد المستخدم الحذف
      // يمكن إضافة حالة تحميل هنا إذا أردت (stateful widget)
      // setState(() { _isDeleting = true; }); // مثال
      final provider = Provider.of<AdminSkillProvider>(context, listen: false);
      try {
        await provider.deleteSkill(context, skillId); // استدعاء تابع الحذف
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المهارة بنجاح.')),
        );
      } on ApiException catch (e) {
        String errorMessage = 'فشل الحذف: ${e.message}';
        if (e.errors != null) {
          errorMessage += '\nErrors: ${e.errors!.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("; ")}';
          print(e.errors);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف المهارة: ${e.toString()}')),
        );
      } finally {
        // setState(() { _isDeleting = false; }); // مثال
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // الاستماع لحالة Provider
    final skillProvider = Provider.of<AdminSkillProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المهارات'),
        actions: [
          // زر إضافة مهارة جديدة
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // الانتقال إلى شاشة إضافة مهارة جديدة
              print('Add Skill Tapped');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateEditSkillScreen(), // <--- الانتقال لشاشة الإضافة (بدون تمرير كائن مهارة)
                ),
              );
            },
          ),
        ],
      ),
      body: skillProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : skillProvider.error != null
          ? Center(child: Text('Error: ${skillProvider.error}'))
          : skillProvider.skills.isEmpty
          ? const Center(child: Text('لا توجد مهارات.'))
          : ListView.builder(
        itemCount: skillProvider.skills.length,
        itemBuilder: (context, index) {
          final skill = skillProvider.skills[index];
          // تأكد أن المهارة لديها ID قبل عرض أزرار التعديل/الحذف
          if (skill.skillId == null) return const SizedBox.shrink();

          return ListTile(
            title: Text(skill.name ?? 'بدون اسم'),
            leading: const Icon(Icons.star), // أيقونة للمهارة
            trailing: Row( // أزرار التعديل والحذف في نفس الصف
              mainAxisSize: MainAxisSize.min, // لجعل Row تأخذ فقط المساحة اللازمة لأزرارها
              children: [
                // زر تعديل مهارة
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'تعديل',
                  onPressed: () {
                    // الانتقال إلى شاشة تعديل مهارة
                    print('Edit Skill Tapped for ID ${skill.skillId}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateEditSkillScreen(skill: skill), // <--- الانتقال لشاشة التعديل (مع تمرير كائن المهارة)
                      ),
                    );
                  },
                ),
                // زر حذف مهارة
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'حذف',
                  onPressed: () {
                    _deleteSkill(skill.skillId!); // استدعاء تابع الحذف
                  },
                ),
              ],
            ),
            // onTap لعرض تفاصيل غير موجود في مسار الأدمن skill Show
          );
        },
      ),
    );
  }
}

// Simple extension for List<Skill> if not available elsewhere or using collection package
extension ListSkillExtension on List<Skill> {
  Skill? firstWhereOrNull(bool Function(Skill) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}